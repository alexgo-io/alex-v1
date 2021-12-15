
;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant ONE_16 (pow u10 u16)) ;; 16 decimal places

;; With 16 fixed digits you would have a maximum error of 0.5 * 10^-16 in each entry, 
;; which could aggregate to about 16 x 0.5 * 10^-16 = 8 * 10^-16 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u8) 
;; public functions
;;

(define-read-only (get_one)
    (ok ONE_16)
)

(define-read-only (scale-up (a uint))
    (* a ONE_16)
)

(define-read-only (scale-down (a uint))
    (/ a ONE_16)
)

(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_16)
)

(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_16))
       )
   )
)

(define-read-only (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_16) b)
   )
)

(define-read-only (div-up (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (+ u1 (/ (- (* a ONE_16) u1) b))
    )
)

(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp-16 pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (if (< raw max-error)
            u0
            (- raw max-error)
        )
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp-16 pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (+ raw max-error)
    )
)