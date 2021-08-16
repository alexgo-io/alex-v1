;; yield-token-equation
;; implementation of Yield Token AMM (https://docs.alexgo.io/whitepaper/automated-market-making-of-alex)

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant no-liquidity-err (err u2002))
(define-constant weight-sum-err (err u4000))
(define-constant max-in-ratio-err (err u4001))
(define-constant max-out-ratio-err (err u4002))
(define-constant math-call-err (err u4003))

;; max in/out as % of liquidity
(define-constant MAX_IN_RATIO (* u3 (pow u10 u7))) ;;0.3e8
(define-constant MAX_OUT_RATIO (* u3 (pow u10 u7))) ;;0.3e8

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;

;; d_x = dx
;; d_y = dy 
;; b_x = balance-x
;; b_y = balance-y
;;
;; d_y = b_y - (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_x + d_x) ^ (1 - t)) ^ (1 / (1 - t))
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (t uint) (dx uint))
    (let 
        (
            (max-in (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x MAX_IN_RATIO)))
            (t-comp (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 t)))
            (x-pow (unwrap-panic (contract-call? .math-fixed-point pow-down balance-x t-comp)))
            (y-pow (unwrap-panic (contract-call? .math-fixed-point pow-down balance-y t-comp)))
            (x-dx-pow (unwrap-panic (contract-call? .math-fixed-point pow-down (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)) t-comp)))
            (term (unwrap-panic (contract-call? .math-fixed-point sub-fixed (unwrap-panic (contract-call? .math-fixed-point add-fixed x-pow y-pow)) x-dx-pow)))
            (term-pow (unwrap-panic (contract-call? .math-fixed-point pow-down term (unwrap-panic (contract-call? .math-fixed-point div-down ONE_8 t-comp)))))
        )
        (asserts! (< dx max-in) max-in-ratio-err)        
        
        (contract-call? .math-fixed-point sub-fixed balance-y term-pow)
    )
)

;; d_x = dx
;; d_y = dy 
;; b_x = balance-x
;; b_y = balance-y
;;
;; d_x = (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_y - d_y) ^ (1 - t)) ^ (1 / (1 - t)) - b_x
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (t uint) (dy uint))
    (let 
        (
            (max-out (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y MAX_OUT_RATIO)))            
            (t-comp (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 t)))
            (x-pow (unwrap-panic (contract-call? .math-fixed-point pow-down balance-x t-comp)))
            (y-pow (unwrap-panic (contract-call? .math-fixed-point pow-down balance-y t-comp)))
            (y-dy-pow (unwrap-panic (contract-call? .math-fixed-point pow-down
                                        (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-y dy)) t-comp)))
            (term (unwrap-panic (contract-call? .math-fixed-point sub-fixed 
                                        (unwrap-panic (contract-call? .math-fixed-point add-fixed x-pow y-pow)) y-dy-pow)))
            (term-pow (unwrap-panic (contract-call? .math-fixed-point pow-down term 
                                        (unwrap-panic (contract-call? .math-fixed-point div-down ONE_8 t-comp)))))
        )
        (asserts! (< dy max-out) max-out-ratio-err)        

        (contract-call? .math-fixed-point sub-fixed term-pow balance-x)
    )
)

;; d_x = dx
;; d_y = dy 
;; b_x = balance-x
;; b_y = balance-y
;; 
;; spot = (b_y / b_x) ^ t
;; d_x = b_x * ((1 + spot ^ ((1 - t) / t) / (1 + price ^ ((1 - t) / t)) ^ (1 / (1 - t)) - 1)
(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (t uint) (price uint))
    (let 
        (
            (t-comp (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 t)))
            (numer (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8 
                                    (unwrap-panic (contract-call? .math-fixed-point pow-down 
                                    (unwrap-panic (contract-call? .math-fixed-point div-down balance-y balance-x)) t-comp)))))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8
                                    (unwrap-panic (contract-call? .math-fixed-point pow-down 
                                    price (unwrap-panic (contract-call? .math-fixed-point div-down t-comp t)))))))
            (term (unwrap-panic (contract-call? .math-fixed-point sub-fixed 
                                    (unwrap-panic (contract-call? .math-fixed-point pow-down 
                                    (unwrap-panic (contract-call? .math-fixed-point div-down numer denom)) 
                                    (unwrap-panic (contract-call? .math-fixed-point div-down ONE_8 t-comp)))) ONE_8)))           
        )

        (contract-call? .math-fixed-point mul-up balance-x term)
   )
)

(define-read-only (get-x-given-yield (balance-x uint) (balance-y uint) (t uint) (yield uint))
    (let 
        (
            (t-yield (unwrap-panic (contract-call? .math-fixed-point mul-up t yield)))
            (price (to-uint (unwrap-panic (contract-call? .math-log-exp exp-fixed (to-int t-yield)))))
        )
        (get-x-given-price balance-x balance-y t price)
    )
)

(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (dx uint))
    (let
        (
            (t-comp (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 t)))
        )
        (ok
            (if (is-eq total-supply u0)
                {token: dx, dy: dx}
                (let
                    (
                        ;; if total-supply > zero, we calculate dy proportional to dx / balance-x
                        (dy (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y 
                                (unwrap-panic (contract-call? .math-fixed-point div-down dx balance-x)))))
                        (token (unwrap-panic (contract-call? .math-fixed-point mul-down total-supply  
                                (unwrap-panic (contract-call? .math-fixed-point div-down dx balance-x)))))
                    )
                    {token: token, dy: dy}
                )
            )            
        )
    )    
)

;; 
(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
    (if (> total-supply u0) 
        (let
            (
                (token-div-supply (unwrap-panic (contract-call? .math-fixed-point div-down token total-supply)))
                (dx (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x token-div-supply)))
                (dy (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y token-div-supply)))
            )                
            (ok {dx: dx, dy: dy})
        )
        no-liquidity-err
    )
)

(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y t total-supply token)
)