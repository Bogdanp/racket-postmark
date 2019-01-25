#lang scribble/manual

@(require (for-label json racket postmark))

@title{Postmark API Client}
@author[(author+email "Bogdan Popa" "bogdan@defn.io")]

@defmodule[postmark]


@;; Introduction ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@section[#:tag "intro"]{Introduction}

This library lets you send emails with @link["https://postmarkapp.com/"]{Postmark}
from Racket.  To use this library, you'll need a valid server token
from Postmark.

@;; Reference ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@section[#:tag "reference"]{Reference}

@defstruct[postmark ([token string?])]{
  A container for a Postmark token.
}

@defproc[(postmark-send-email [client postmark?]
                              [#:to to address/c]
                              [#:from from address/c]
                              [#:subject subject string?]
                              [#:cc cc (or/c false/c address/c)]
                              [#:bcc bcc (or/c false/c address/c)]
                              [#:reply-to reply-to (or/c false/c address/c)]
                              [#:tag tag (or/c false/c string?)]
                              [#:text-body text-body (or/c false/c string?)]
                              [#:html-body html-body (or/c false/c string?)]
                              [#:track-opens track-opens boolean?]
                              [#:track-links track-links (or/c false/c track-links/c)]
                              [#:headers headers (or/c false/c (hash/c symbol? string?))]
                              [#:metadata metadata (or/c false/c (hash/c symbol? string?))]) jsexpr?]{
  Send an e-mail via Postmark.

  Raises an @racket[exn:fail:user?] if the token is invalid.
}

@defproc[(postmark-send-email-with-template [client postmark?]
                                            [#:to to address/c]
                                            [#:from from address/c]
                                            [#:template-id template-id (or/c false/c exact-positive-integer?)]
                                            [#:template-alias template-alias (or/c false/c string?)]
                                            [#:template-model template-model jsexpr?]
                                            [#:cc cc (or/c false/c address/c)]
                                            [#:bcc bcc (or/c false/c address/c)]
                                            [#:reply-to reply-to (or/c false/c address/c)]
                                            [#:tag tag (or/c false/c string?)]
                                            [#:track-opens track-opens boolean?]
                                            [#:track-links track-links (or/c false/c track-links/c)]
                                            [#:headers headers (or/c false/c (hash/c symbol? string?))]
                                            [#:metadata metadata (or/c false/c (hash/c symbol? string?))]) jsexpr?]{
  Send a templated e-mail via Postmark.

  Raises an @racket[exn:fail:user?] if the token is invalid.
}

@deftogether[
  (@defthing[address/c (or/c string? (listof string?))]
   @defthing[track-links/c (or/c 'None 'HtmlAndText 'HtmlOnly 'TextOnly)])]
