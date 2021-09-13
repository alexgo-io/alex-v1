;; weighted-equation
;; implementation of Balancer WeightedMath (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol)

;;(impl-trait .trait-equation.equation-trait)

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant no-liquidity-err (err u2002))
(define-constant weight-sum-err (err u4000))
(define-constant max-in-ratio-err (err u4001))
(define-constant max-out-ratio-err (err u4002))
(define-constant math-call-err (err 4003))

;; max in/out as % of liquidity
;; (define-constant MAX_IN_RATIO (* u2 (pow u10 u6))) ;; 2%
;; (define-constant MAX_OUT_RATIO (* u2 (pow u10 u6))) ;; 2%
;; for testing only
(define-constant MAX_IN_RATIO (* u5 (pow u10 u7)))
(define-constant MAX_OUT_RATIO (* u5 (pow u10 u7)))

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
;;

;; get-invariant
;; invariant = b_x ^ w_x * b_y ^ w_y 
(define-read-only (get-invariant (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (ok (unwrap-panic (contract-call? .math-fixed-point mul-down 
                (unwrap-panic (contract-call? .math-fixed-point pow-down balance-x weight-x)) 
                (unwrap-panic (contract-call? .math-fixed-point pow-down balance-y weight-y)))))
        weight-sum-err
    )
)

;; get-y-given-x
;; d_y = dy
;; b_y = balance-y
;; b_x = balance-x                /      /            b_x             \    (w_x / w_y) \           
;; d_x = dx          d_y = b_y * |  1 - | ---------------------------  | ^             |          
;; w_x = weight-x                 \      \       ( b_x + d_x )        /                /           
;; w_y = weight-y                                                                       
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dx uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (let 
            (
                (max-in (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x MAX_IN_RATIO)))
                (denominator (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)))
                (base (unwrap-panic (contract-call? .math-fixed-point div-up balance-x denominator)))
                (uncapped-exponent (unwrap-panic (contract-call? .math-fixed-point div-up weight-x weight-y)))
                (bound (unwrap-panic (contract-call? .math-log-exp get-exp-bound)))
                (exponent (if (< uncapped-exponent bound) uncapped-exponent bound))
                (power (unwrap-panic (contract-call? .math-fixed-point pow-up base exponent)))
                (complement (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 power)))
            )
            (asserts! (< dx max-in) max-in-ratio-err)

            (contract-call? .math-fixed-point mul-down balance-y complement)
        )
        weight-sum-err
    )    
)

;; d_y = dy                                                                            
;; b_y = balance-y
;; b_x = balance-x              /  /            b_y             \    (w_y / w_x)      \          
;; d_x = dx         d_x = b_x * |  | --------------------------  | ^             - 1  |         
;; w_x = weight-x               \  \       ( b_y - d_y )         /                    /          
;; w_y = weight-y                                                           
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dy uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (let 
            (
                (max-out (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y MAX_OUT_RATIO)))
                (denominator (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-y dy)))
                (base (unwrap-panic (contract-call? .math-fixed-point div-down balance-y denominator)))
                (uncapped-exponent (unwrap-panic (contract-call? .math-fixed-point div-down weight-x weight-y)))
                (bound (unwrap-panic (contract-call? .math-log-exp get-exp-bound)))
                (exponent (if (< uncapped-exponent bound) uncapped-exponent bound))
                (power (unwrap-panic (contract-call? .math-fixed-point pow-down base exponent)))
                (ratio (unwrap-panic (contract-call? .math-fixed-point sub-fixed power ONE_8)))
            )
            (asserts! (< dy max-out) max-out-ratio-err)
            (contract-call? .math-fixed-point mul-down balance-x ratio)
        )
        weight-sum-err
    )
)

;; d_x = dx
;; d_y = dy 
;; b_x = balance-x
;; b_y = balance-y
;; w_x = weight-x 
;; w_y = weight-y
;; spot = b_x * w_y / b_y / w_x
;; d_x = b_x * ((price / spot) ^ w_y - 1)
(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (price uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (let 
            (
                (denominator (unwrap-panic (contract-call? .math-fixed-point mul-up balance-y weight-x)))
                (numerator (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x weight-y)))
                (spot (unwrap-panic (contract-call? .math-fixed-point div-down numerator denominator)))
                (base (unwrap-panic (contract-call? .math-fixed-point div-up price spot)))
                (power (unwrap-panic (contract-call? .math-fixed-point pow-down base weight-y)))
                (ratio (unwrap-panic (contract-call? .math-fixed-point sub-fixed power ONE_8)))            
            )
            (contract-call? .math-fixed-point mul-up balance-x ratio)
        )
        weight-sum-err    
    )   
)

(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (dx uint) (dy uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (ok
            (if (is-eq total-supply u0)
                (let
                    (
                        ;; if total-supply is zero
                        ;;
                        ;; invariant = (b_x ^ w_x) * (b_y ^ w_y)
                        ;;
                        ;;(dy-wy (unwrap-panic (contract-call? .math-fixed-point pow-down dy weight-y)))
                        ;;(dx-wx (unwrap-panic (contract-call? .math-fixed-point pow-down dx weight-x)))
                        ;;(invariant (unwrap-panic (contract-call? .math-fixed-point mul-down dx-wx dy-wy)))
                        (invariant (unwrap-panic (get-invariant dx dy weight-x weight-y)))
                    )                    
                    {token: invariant, dy: dy}
                )
                (let
                    (
                        ;; if total-supply > zero, we calculate dy proportional to dx / balance-x
                        (new-dy (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y 
                                (unwrap-panic (contract-call? .math-fixed-point div-down dx balance-x)))))
                        (token (unwrap-panic (contract-call? .math-fixed-point mul-down total-supply  
                                (unwrap-panic (contract-call? .math-fixed-point div-down dx balance-x)))))
                    )
                    {token: token, dy: new-dy}
                )   
            )
        )
        weight-sum-err    
    )    
)

(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (if (is-eq (+ weight-x weight-y) ONE_8)
        (if (> total-supply u0)
            (let
                (   
                    ;; first calculate what % you need to mint
                    (token-supply (unwrap-panic (contract-call? .math-fixed-point div-down token total-supply)))
                    ;; calculate dx as % of balance-x corresponding to % you need to mint
                    (dx (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x token-supply)))
                    (dy (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y token-supply)))
                )
                (ok {dx: dx, dy: dy})
            )
            no-liquidity-err
        )
        weight-sum-err
    )
)

(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y weight-x weight-y total-supply token)
)