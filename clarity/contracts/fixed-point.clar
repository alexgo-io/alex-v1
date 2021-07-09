
;; fixed-point
;; Fixed Point Math

;; constants
;;
(define-constant one (pow u10 u18))
(define-constant scale-up-overflow (err u100))
(define-constant scale-down-overflow (err u101))
(define-constant add-overflow (err u102))
(define-constant sub-overflow (err u103))
(define-constant mul-overflow (err u104))
(define-constant div-overflow (err u105))
(define-constant pow-overflow (err u106))

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;

(define-read-only (scale-up (a uint))
  (let
    ((r (* a one)))
    (asserts! (is-eq (/ r one) a) (err scale-up-overflow))
    (ok r)
  )
)

(define-read-only (scale-down (a uint))
  (let
    ((r (/ a one)))
    (asserts! (is-eq (* r one) a) (err scale-down-overflow))
    (ok r)
  )
)

(define-read-only (add (a uint) (b uint))
  (let
    ((c (+ a b)))
    (asserts! (>= c a) (err add-overflow))
    (ok c)
  )
)
