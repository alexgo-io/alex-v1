;; weighted-equation
;; implementation of Balancer WeightedMath (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol)

;;(impl-trait .trait-equation.equation-trait)

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant no-liquidity-err (err u61))
(define-constant weight-sum-err (err u62))
(define-constant max-in-ratio-err (err u63))
(define-constant max-out-ratio-err (err u64))

;; max in/out as % of liquidity
(define-constant MAX_IN_RATIO (* u3 (pow u10 u7))) ;;0.3e8
(define-constant MAX_OUT_RATIO (* u3 (pow u10 u7))) ;;0.3e8

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dx uint))
    ;; TODO add fee
    (let 
        (
            (max-in (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x MAX_IN_RATIO)))
            (denominator (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)))
            (base (unwrap-panic (contract-call? .math-fixed-point div-up balance-x denominator)))
            (exponent (unwrap-panic (contract-call? .math-fixed-point div-down weight-x weight-y)))
            (power (unwrap-panic (contract-call? .math-fixed-point pow-up base exponent)))
            (complement (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 power)))
        )
        (asserts! (< dx max-in) max-in-ratio-err)
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) weight-sum-err)

        (contract-call? .math-fixed-point mul-down balance-y complement)
    )
)

(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dy uint))
    ;; TODO add fee
    (let 
        (
            (max-out (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y MAX_OUT_RATIO)))
            (denominator (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-y dy)))
            (base (unwrap-panic (contract-call? .math-fixed-point div-up balance-y denominator)))
            (exponent (unwrap-panic (contract-call? .math-fixed-point div-up weight-y weight-x)))
            (power (unwrap-panic (contract-call? .math-fixed-point pow-up base exponent)))
            (ratio (unwrap-panic (contract-call? .math-fixed-point sub-fixed power ONE_8)))
        )
        (asserts! (< dy max-out) max-out-ratio-err)
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) weight-sum-err)
        ;;(ok power)
        (contract-call? .math-fixed-point mul-up balance-x ratio)
   )
)

(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (price uint))
    ;; TODO add fee
    (let 
        (
            (denominator (unwrap-panic (contract-call? .math-fixed-point mul-up balance-y weight-x)))
            (numerator (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x weight-y)))
            (spot (unwrap-panic (contract-call? .math-fixed-point div-down numerator denominator)))
            (base (unwrap-panic (contract-call? .math-fixed-point div-up price spot)))
            (power (unwrap-panic (contract-call? .math-fixed-point pow-up base weight-y)))
            ;;(ratio (unwrap-panic (contract-call? .math-fixed-point sub-fixed power ONE_8)))            
        )
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) weight-sum-err)
        (ok power)
        ;;(contract-call? .math-fixed-point mul-up balance-x ratio)
   )
)

(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (dx uint) (dy uint))
    (let
        (
            ;; if total-supply is zero
            (dy-wy (unwrap-panic (contract-call? .math-fixed-point pow-down dy weight-y)))
            (dx-wx (unwrap-panic (contract-call? .math-fixed-point pow-down dx weight-x)))
            (invariant (unwrap-panic (contract-call? .math-fixed-point mul-down dx-wx dy-wy)))

            (dx-supply (unwrap-panic (contract-call? .math-fixed-point mul-down dx total-supply)))
            (token (unwrap-panic (contract-call? .math-fixed-point div-down dx-supply balance-x)))
            (dx-baly (unwrap-panic (contract-call? .math-fixed-point mul-down dx balance-y)))
            (new-dy (unwrap-panic (contract-call? .math-fixed-point div-down dx-baly balance-x)))
        )
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) weight-sum-err)        
        (ok
            (if (is-eq total-supply u0)
                ;; burn a fraction of initial lp token to avoid attack as described in WP https://uniswap.org/whitepaper.pdf
                {token: (unwrap-panic (contract-call? .math-fixed-point pow-down invariant u50000000)), dy: dy}
                {token: token, dy: new-dy}
            )
        )
    )    
)

(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (let
        (
            (token-supply (unwrap-panic (contract-call? .math-fixed-point div-down token total-supply)))
            (dx (unwrap-panic (contract-call? .math-fixed-point mul-down balance-x token-supply)))
            (wy-wx (unwrap-panic (contract-call? .math-fixed-point div-down weight-y weight-x)))
            (dy (unwrap-panic (contract-call? .math-fixed-point mul-down dx wy-wx)))
        )
        (asserts! (> total-supply u0) no-liquidity-err)
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) weight-sum-err)       
        (ok {dx: dx, dy: dy})
   )
)

(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y weight-x weight-y total-supply token)
)