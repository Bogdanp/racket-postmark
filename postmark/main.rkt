#lang racket/base

(require json
         net/http-client
         racket/contract/base
         racket/function
         racket/string)

;; Public ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 addresses/c
 track-links/c
 (contract-out
  [postmark-host (parameter/c string?)]
  [postmark-port (parameter/c exact-positive-integer?)]
  [postmark-ssl? (parameter/c boolean?)]
  [struct postmark ([token string?])]
  [postmark-send-email
   (->* (postmark?
         #:to addresses/c
         #:from string?
         #:subject string?)
        (#:cc (or/c false/c addresses/c)
         #:bcc (or/c false/c addresses/c)
         #:reply-to (or/c false/c string?)
         #:tag (or/c false/c string?)
         #:text-body (or/c false/c string?)
         #:html-body (or/c false/c string?)
         #:track-opens (or/c false/c string?)
         #:track-links track-links/c
         #:headers (or/c false/c (hash/c symbol? string?))
         #:metadata (or/c false/c (hash/c symbol? string?)))
        jsexpr?)]
  [postmark-send-email-with-template
   (->* (postmark?
         #:to addresses/c
         #:from string?)
        (#:template-id (or/c false/c exact-positive-integer?)
         #:template-alias (or/c false/c string?)
         #:template-model jsexpr?
         #:cc (or/c false/c addresses/c)
         #:bcc (or/c false/c addresses/c)
         #:reply-to (or/c false/c string?)
         #:tag (or/c false/c string?)
         #:track-opens (or/c false/c string?)
         #:track-links track-links/c
         #:headers (or/c false/c (hash/c symbol? string?))
         #:metadata (or/c false/c (hash/c symbol? string?)))
        jsexpr?)]))

(define addresses/c
  (or/c string? (listof string?)))

(define track-links/c
  (or/c false/c 'None 'HtmlAndText 'HtmlOnly 'TextOnly))

(define postmark-host
  (make-parameter "api.postmarkapp.com"))

(define postmark-port
  (make-parameter 443))

(define postmark-ssl?
  (make-parameter #t))

(struct postmark (token))

(define (postmark-send-email client
                             #:to to
                             #:from from
                             #:subject subject
                             #:cc [cc #f]
                             #:bcc [bcc #f]
                             #:reply-to [reply-to #f]
                             #:tag [tag #f]
                             #:text-body [text-body #f]
                             #:html-body [html-body #f]
                             #:track-opens [track-opens #f]
                             #:track-links [track-links #f]
                             #:headers [headers #f]
                             #:metadata [metadata #f])
  (unless (or text-body html-body)
    (raise-user-error 'postmark-send-email "You must provide at least one of text-body or html-body."))

  (make-post-request
   client
   #:path "/email"
   #:json (remove-false-params
           (hasheq 'To          (addresses->string to)
                   'From        from
                   'Subject     subject
                   'Cc          (addresses->string cc)
                   'Bcc         (addresses->string bcc)
                   'ReplyTo     reply-to
                   'Tag         tag
                   'TextBody    text-body
                   'HtmlBody    html-body
                   'TrackOpens  track-opens
                   'TrackLinks  (and track-links (symbol->string track-links))
                   'Headers     headers
                   'Metadata    metadata))))

(define (postmark-send-email-with-template client
                                           #:template-id [template-id #f]
                                           #:template-alias [template-alias #f]
                                           #:template-model [template-model (hasheq)]
                                           #:to to
                                           #:from from
                                           #:cc [cc #f]
                                           #:bcc [bcc #f]
                                           #:reply-to [reply-to #f]
                                           #:tag [tag #f]
                                           #:track-opens [track-opens #f]
                                           #:track-links [track-links #f]
                                           #:headers [headers #f]
                                           #:metadata [metadata #f])
  (unless (or template-id template-alias)
    (raise-user-error 'postmark-send-email-with-template "You must provide at least one of template-id or template-alias."))

  (make-post-request
   client
   #:path "/email/withTemplate"
   #:json (remove-false-params
           (hasheq 'TemplateId    template-id
                   'TemplateAlias template-alias
                   'TemplateModel template-model
                   'To            (addresses->string to)
                   'From          from
                   'Cc            (addresses->string cc)
                   'Bcc           (addresses->string bcc)
                   'ReplyTo       reply-to
                   'Tag           tag
                   'Headers       headers
                   'TrackOpens    track-opens
                   'TrackLinks    (and track-links (symbol->string track-links))
                   'Metadata      metadata))))


;; Private ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define USER-AGENT
  (format "Postmark Client for Racket ~a [0.1.0]" (version)))

(define (call-with-postmark-connection client f)
  (f (http-conn-open (postmark-host)
                     #:port (postmark-port)
                     #:ssl? (postmark-ssl?))))

(define (make-post-request client #:path path #:json json)
  (call-with-postmark-connection client
    (lambda (conn)
      (define-values (status-line _ in)
        (http-conn-sendrecv!
         conn path
         #:method "POST"
         #:headers (list "Accept: application/json"
                         "Content-Type: application/json; charset=utf-8"
                         (format "User-Agent: ~a" USER-AGENT)
                         (format "X-Postmark-Server-Token: ~a" (postmark-token client)))
         #:data (jsexpr->string json)))

      (define response (read-json in))
      (when (> (hash-ref response 'ErrorCode 0) 0)
        (error 'make-post-request (hash-ref response 'Message)))

      response)))

(define (addresses->string address-or-addresses)
  (cond
    [(not address-or-addresses) #f]
    [(string? address-or-addresses) address-or-addresses]
    [else (string-join address-or-addresses ", ")]))

(define (remove-false-params params)
  (for/fold ([params (hasheq)])
            ([(name value) params]
             #:when value)
    (hash-set params name value)))
