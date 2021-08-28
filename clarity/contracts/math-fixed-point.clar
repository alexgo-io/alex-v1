
;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; TODO: overflow causes runtime error, should handle before operation rather than after

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places
(define-constant SCALE_UP_OVERFLOW (err u5001))
(define-constant SCALE_DOWN_OVERFLOW (err u5002))
(define-constant ADD_OVERFLOW (err u5003))
(define-constant SUB_OVERFLOW (err u5004))
(define-constant MUL_OVERFLOW (err u5005))
(define-constant DIV_OVERFLOW (err u5006))
(define-constant POW_OVERFLOW (err u5007))

;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 

;; public functions
;;

(define-read-only (get_one)
    (ok ONE_8)
)

(define-read-only (scale-up (a uint))
    (let
        (
            (r (* a ONE_8))
        )
        (asserts! (is-eq (/ r ONE_8) a) SCALE_UP_OVERFLOW)
        (ok r)
    )
)

(define-read-only (scale-down (a uint))
  (let
    ((r (/ a ONE_8)))
    (asserts! (is-eq (* r ONE_8) a) SCALE_DOWN_OVERFLOW)
    (ok r)
 )
)

(define-read-only (add-fixed (a uint) (b uint))
    (let
        (
            (c (+ a b))
        )
        (asserts! (>= c a) ADD_OVERFLOW)
        (ok c)
    )
)

(define-read-only (sub-fixed (a uint) (b uint))
    (let
        ()
        (asserts! (<= b a) SUB_OVERFLOW)
        (ok (- a b))
    )
)

(define-read-only (mul-down (a uint) (b uint))
    (let
        (
            (product (* a b))
        )
        (ok (/ product ONE_8))
    )
)


(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            (ok u0)
            (ok (+ u1 (/ (- product u1) ONE_8)))
       )
   )
)

(define-read-only (div-down (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_8))
       )
        (if (is-eq a u0)
            (ok u0)
            (ok (/ a-inflated b))
       )
   )
)

(define-read-only (div-up (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_8))
       )
        (if (is-eq a u0)
            (ok u0)
            (ok (+ u1 (/ (- a-inflated u1) b)))
       )
   )
)

(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
            (max-error (+ u1 (unwrap-panic (mul-up raw MAX_POW_RELATIVE_ERROR))))
        )
        (if (< raw max-error)
            (ok u0)
            (sub-fixed raw max-error)
        )
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
            (max-error (+ u1 (unwrap-panic (mul-up raw MAX_POW_RELATIVE_ERROR))))
        )
        (add-fixed raw max-error)
    )
)
