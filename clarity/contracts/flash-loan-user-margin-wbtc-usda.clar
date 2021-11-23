(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ONE_8 (pow u10 u8))

(define-public (execute (collateral <ft-trait>) (amount uint) (memo (optional uint)))
    (let
        (   
            ;; gross amount * ltv / price = amount
            ;; gross amount = amount * price / ltv
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv .token-wbtc .token-usda (default-to u0 memo))))
            (price (try! (contract-call? .yield-token-pool get-price (default-to u0 memo) .yield-wbtc)))
            (gross-amount (mul-up amount (div-down price ltv)))
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-wbtc .token-usda (default-to u0 memo) .yield-wbtc .key-wbtc-usda gross-amount))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (try! (contract-call? .fixed-weight-pool swap .token-usda .token-wbtc u50000000 u50000000 swapped-token none))
        (print { object: "flash-loan-user-margin-wbtc-usda", action: "execute", data: gross-amount })
        (ok true)
    )
)

(define-private (mul-up (a uint) (b uint))
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

(define-private (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_8) b)
   )
)