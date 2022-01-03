
(define-constant ONE_16 (pow u10 u16)) ;; 16 decimal places

;; The maximum digits clarity can give in uint is 39 digits, otherwise it overflows
(define-read-only (maximum-integer (a uint) (b uint))
    (* a b)
)

;; we reduced a and b so that it won't overflow
(define-read-only (mul (a uint) (b uint))
    (let
        (
            (reduced-a (/ a ONE_16))
            (reduced-b (/ b ONE_16))
        )
        (* (* reduced-a reduced-b) ONE_16)
    )
)

;; decimal says how many decimals are there in a and b together
(define-read-only (mul-16 (a uint) (a-decimals uint) (b uint) (b-decimals uint))
    (let
        (
            (result (* a b)) ;; 50*5 is actually 5 * 0.5
            (decimals (- a-decimals b-decimals))
        )
        {result: result, decimals: decimals}
    )
)

;; 2.5*4 = 10

;; 2.5 * 4
;; 25*10^-1 * 4*10^0
;; (25*4) * (10^-1 * 10^0)
;; (100) * (10^(-1+0))
;; 100 * 10^-1
;; 10

;; (25*10^-1) * (4*10^0) = 100*10^-1 = 10
;; base is 10
(define-read-only (mul-with-scientific-notation (a uint) (a-exp int) (b uint) (b-exp int))
    (let
        (
            (product (* a b)) ;; 25*4=100
            (exponent (+ a-exp b-exp)) ;;10^-1 + 10^0 = 10^(-1+0) = 10^-1
        )
        {result: product, exponent: exponent} ;;100*10^-1
    )
)

(define-read-only (div-with-scientific-notation (a uint) (a-exp int) (b uint) (b-exp int))
    (let
        (
            (division (/ a b)) ;; 25*4=100
            (exponent (- a-exp b-exp)) ;;10^-1 + 10^0 = 10^(-1+0) = 10^-1
        )
        {result: division, exponent: exponent} ;;100*10^-1
    )
)

;; we reduced a and b so that it won't overflow
(define-read-only (div (a uint) (b uint))
    (/ a b)
)


(define-read-only (scale-up (a uint))
    (* a ONE_16)
)

(define-read-only (scale-down (a uint))
    (/ a ONE_16)
)

