
;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant ONE_18 (pow u10 u18)) ;;18 decimal places
(define-constant SCALE_UP_OVERFLOW (err u10000))
(define-constant SCALE_DOWN_OVERFLOW (err u10001))
(define-constant ADD_OVERFLOW (err u10002))
(define-constant SUB_OVERFLOW (err u10003))
(define-constant MUL_OVERFLOW (err u10004))
(define-constant DIV_OVERFLOW (err u10005))
(define-constant POW_OVERFLOW (err u10006))
(define-constant MAX_POW_RELATIVE_ERROR u10007) 

;; public functions
;;

(define-read-only (scale-up (a uint))
  (let
    ((r (* a ONE_18)))
    (asserts! (is-eq (/ r ONE_18) a) (err SCALE_UP_OVERFLOW))
    (ok r)
  )
)

(define-read-only (scale-down (a uint))
  (let
    ((r (/ a ONE_18)))
    (asserts! (is-eq (* r ONE_18) a) (err SCALE_DOWN_OVERFLOW))
    (ok r)
  )
)

(define-read-only (add-fixed (a uint) (b uint))
  (let
    ((c (+ a b)))
    (asserts! (>= c a) (err ADD_OVERFLOW))
    (ok c)
  )
)

(define-read-only (sub-fixed (a uint) (b uint))
  (begin
    (asserts! (<= b a) (err SUB_OVERFLOW))
    (ok (- a b))
  )
)

(define-read-only (mulDown (a uint) (b uint))
    (let 
        (
            (product (* a b))
        )
        (ok (/ product ONE_18))
    )
)

(define-read-only (mulUp (a uint) (b uint))
    (let
        (
            (product (* a b))
        )
        (if (is-eq product u0)
            (ok u0)
            (ok (+ u1 (/ (- product u1) ONE_18)))
        )
    )
)

(define-read-only (divDown (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_18))
        )
        (if (is-eq a u0)
            (ok u0)
            (ok (/ a-inflated b))
        )
    )
)

(define-read-only (divUp (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_18))
        )
        (if (is-eq a u0)
            (ok u0)
            (ok (+ u1 (/ (- a-inflated u1) b)))
        )
    )
)

(define-read-only (powDown (a uint) (b uint))    
    (let
        (
            (raw (pow u2 (/ (* b (log2 a)) ONE_18)))
            (max-error (+ u1 (unwrap-panic (mulUp raw MAX_POW_RELATIVE_ERROR))))
        )
        (if (< raw max-error)
            (ok u0)
            (ok (- raw max-error))
        )
    )
)
