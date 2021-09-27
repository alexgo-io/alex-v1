
;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; TODO: overflow causes runtime error, should handle before operation rather than after

;; constants
;;
(define-constant ONE_10 (pow u10 u10)) ;; 10 decimal places
(define-constant ERR-SCALE-UP-OVERFLOW (err u5001))
(define-constant ERR-SCALE-DOWN-OVERFLOW (err u5002))
(define-constant ERR-ADD-OVERFLOW (err u5003))
(define-constant ERR-SUB-OVERFLOW (err u5004))
(define-constant ERR-MUL-OVERFLOW (err u5005))
(define-constant ERR-DIV-OVERFLOW (err u5006))
(define-constant ERR-POW-OVERFLOW (err u5007))

;; With 10 fixed digits you would have a maximum error of 0.5 * 10^-10 in each entry, 
;; which could aggregate to about 10 x 0.5 * 10^-10 = 4 * 10^-10 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 
(define-constant TOLERANCE_CONSTANT u10000)
;; public functions
;;

(define-read-only (get_one)
    (ok ONE_10)
)

(define-read-only (scale-up (a uint))
    (let
        (
            (r (* a ONE_10))
        )
        (asserts! (is-eq (/ r ONE_10) a) ERR-SCALE-UP-OVERFLOW)
        (ok r)
    )
)

(define-read-only (scale-down (a uint))
  (let
    ((r (/ a ONE_10)))
    (asserts! (is-eq (* r ONE_10) a) ERR-SCALE-DOWN-OVERFLOW)
    (ok r)
 )
)

(define-read-only (add-fixed (a uint) (b uint))
    (let
        (
            (c (+ a b))
        )
        (asserts! (>= c a) ERR-ADD-OVERFLOW)
        (ok c)
    )
)

(define-read-only (sub-fixed (a uint) (b uint))
    (let
        ()
        (asserts! (<= b a) ERR-SUB-OVERFLOW)
        (ok (- a b))
    )
)

(define-read-only (mul-down (a uint) (b uint))
    (let
        (
            (product (* a b))
        )
        (ok (/ product ONE_10))
    )
)


(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            (ok u0)
            (ok (+ u1 (/ (- product u1) ONE_10)))
       )
   )
)

(define-read-only (div-down (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_10))
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
            (a-inflated (* a ONE_10))
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
        ;;(if (>= a ONE_10) (round-for-up raw TOLERANCE_CONSTANT)
            (if (< raw max-error)
                (ok u0)
                (sub-fixed raw max-error)
            )
        ;;)
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
            (max-error (+ u1 (unwrap-panic (mul-up raw MAX_POW_RELATIVE_ERROR))))
        )
        (add-fixed raw max-error)
        ;;(if (>= a ONE_10)  (round-for-up raw TOLERANCE_CONSTANT) (add-fixed raw max-error))
    )
)

;; TODO : Precision for 6 Decimals should be introduced later on. 
(define-read-only (round-for-up (a uint) (tolerance uint))
    (begin
    (if (is-eq (mod a tolerance) u0) (ok a)
        (let
            (
                (divided (/ a tolerance))
                (new-value (+ divided u1))
                (rounded (* new-value tolerance))
            )
        (ok rounded)
        )
    )
    )
)