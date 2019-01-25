#lang racket/base

(module+ test
  (require json
           rackunit
           rackunit/text-ui
           web-server/dispatch
           web-server/http
           web-server/servlet-dispatch
           web-server/web-server
           "main.rkt")

  (define (response/json #:code [code 200]
                         #:status [status #"OK"]
                         #:json [json (hasheq)])
    (response/full
     code status
     (current-seconds) #"application/json; charset=utf-8"
     (list) (list (jsexpr->bytes json))))

  (define ((guard-auth f) req)
    (define token-header
      (headers-assq* #"x-postmark-server-token" (request-headers/raw req)))

    (cond
      [(or (not token-header)
           (not (bytes=? (header-value token-header) #"supersecret")))
       (response/json
        #:code 403
        #:status #"Forbidden"
        #:json (hasheq 'ErrorCode 10
                       'Message "The Server Token you provided in the X-Postmark-Server-Token request header was invalid. Please verify that you are using a valid token."))]

      [else (f req)]))

  (define (echo req)
    (response/json
     #:json (hasheq 'ErrorCode 0
                    'RequestData (bytes->jsexpr (request-post-data/raw req)))))

  (define-values (start _)
    (dispatch-rules
     [("email") #:method "post" (guard-auth echo)]
     [("email" "withTemplate") #:method "post" (guard-auth echo)]))

  (define server-stopper #f)

  (postmark-host "127.0.0.1")
  (postmark-port 9922)
  (postmark-ssl? #f)

  (define (start-server)
    (set! server-stopper (serve #:dispatch (dispatch/servlet start)
                                #:listen-ip (postmark-host)
                                #:port (postmark-port)))
    (sleep 1))

  (define (stop-server)
    (server-stopper))

  (define postmark-tests
    (test-suite
     "postmark"
     #:before start-server
     #:after stop-server

     (test-suite
      "postmark-send-email"

      (test-case "raises an error when neither text or html body is provided"
        (check-exn
         exn:fail:user?
         (lambda ()
           (postmark-send-email (postmark "invalid")
                                #:to "bogdan@defn.io"
                                #:from "bogdan@defn.io"
                                #:subject "hello"))))

      (test-case "raises an error when the token is invalid"
        (check-exn
         exn:fail?
         (lambda ()
           (postmark-send-email (postmark "invalid")
                                #:to "bogdan@defn.io"
                                #:from "bogdan@defn.io"
                                #:subject "hello!"
                                #:text-body "hi"))))

      (test-case "sends only non-#f parameters to postmark"
        (check-equal?
         (postmark-send-email (postmark "supersecret")
                              #:to "bogdan@defn.io"
                              #:from "bogdan@defn.io"
                              #:subject "hello"
                              #:html-body "<h1>Hi!</h1>")
         (hasheq 'ErrorCode 0
                 'RequestData (hasheq 'To "bogdan@defn.io"
                                      'From "bogdan@defn.io"
                                      'Subject "hello"
                                      'HtmlBody "<h1>Hi!</h1>")))))))

  (run-tests postmark-tests))
