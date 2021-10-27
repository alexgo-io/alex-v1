
;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places
(define-constant ERR-SCALE-UP-OVERFLOW (err u5001))
(define-constant ERR-SCALE-DOWN-OVERFLOW (err u5002))
(define-constant ERR-ADD-OVERFLOW (err u5003))
(define-constant ERR-SUB-OVERFLOW (err u5004))
(define-constant ERR-MUL-OVERFLOW (err u5005))
(define-constant ERR-DIV-OVERFLOW (err u5006))
(define-constant ERR-POW-OVERFLOW (err u5007))

;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 
(define-constant TOLERANCE_CONSTANT u10000)
;; public functions
;;

(define-read-only (get_one)
    (ok ONE_8)
)

(define-read-only (scale-up (a uint))
    (* a ONE_8)
)

(define-read-only (scale-down (a uint))
    (/ a ONE_8)
)

(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)


(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)

(define-read-only (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_8) b)
   )
)

(define-read-only (div-up (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (+ u1 (/ (- (* a ONE_8) u1) b))
    )
)

(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        ;;(if (>= a ONE_8) (round-for-up raw TOLERANCE_CONSTANT)
            (if (< raw max-error)
                u0
                (- raw max-error)
            )
        ;;)
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (+ raw max-error)
        ;;(if (>= a ONE_8)  (round-for-up raw TOLERANCE_CONSTANT) (+ raw max-error))
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