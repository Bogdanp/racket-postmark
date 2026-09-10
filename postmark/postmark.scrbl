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
  A client for the Postmark API.
}

@defproc[(postmark-send-email
          [client postmark?]
          [#:to to addresses/c]
          [#:from from string?]
          [#:subject subject string?]
          [#:cc cc (or/c #f addresses/c)]
          [#:bcc bcc (or/c #f addresses/c)]
          [#:reply-to reply-to (or/c #f string?)]
          [#:tag tag (or/c #f string?)]
          [#:text-body text-body (or/c #f string?)]
          [#:html-body html-body (or/c #f string?)]
          [#:track-opens track-opens boolean?]
          [#:track-links track-links (or/c #f track-links/c)]
          [#:headers headers (or/c #f (hash/c symbol? string?))]
          [#:metadata metadata (or/c #f (hash/c symbol? string?))]
          [#:message-stream message-stream (or/c #f string?)]) jsexpr?]{
 Send an e-mail via Postmark.

 Raises an @racket[exn:fail:user?] if the token is invalid.

 @history[#:changed "0.2" @elem{Added the @racket[#:message-stream] argument.}]
}

@defproc[(postmark-send-email-with-template
          [client postmark?]
          [#:to to addresses/c]
          [#:from from string?]
          [#:template-id template-id (or/c #f exact-positive-integer?)]
          [#:template-alias template-alias (or/c #f string?)]
          [#:template-model template-model jsexpr?]
          [#:cc cc (or/c #f addresses/c)]
          [#:bcc bcc (or/c #f addresses/c)]
          [#:reply-to reply-to (or/c #f string?)]
          [#:tag tag (or/c #f string?)]
          [#:track-opens track-opens boolean?]
          [#:track-links track-links (or/c #f track-links/c)]
          [#:headers headers (or/c #f (hash/c symbol? string?))]
          [#:metadata metadata (or/c #f (hash/c symbol? string?))]
          [#:message-stream message-stream (or/c #f string?)]) jsexpr?]{
 Send a templated e-mail via Postmark.

 Raises an @racket[exn:fail:user?] if the token is invalid.

 @history[#:changed "0.2" @elem{Added the @racket[#:message-stream] argument.}]
}

@deftogether[(
  @defthing[addresses/c (or/c string? (listof string?))]
  @defthing[track-links/c (or/c 'None 'HtmlAndText 'HtmlOnly 'TextOnly)]
)]{
 Contracts for addresses and tracking link config, respectively.
}
