#lang info

(define license 'BSD-3-Clause)
(define version "0.2")
(define collection "postmark")

(define deps '("base"))
(define build-deps '("racket-doc" "rackunit-lib" "scribble-lib" "web-server-lib"))
(define scribblings '(("postmark.scrbl")))
