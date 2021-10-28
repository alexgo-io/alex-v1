(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant math-call-err (err u2010))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))

(define-constant ONE_8 (pow u10 u8))

(define-public (execute (token <ft-trait>) (amount uint))
    (let
        (   
            ;; gross amount * ltv / price = amount
            ;; gross amount = amount * price / ltv
            (expiry (unwrap! (contract-call? .yield-wbtc-59760 get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv .token-wbtc .token-usda expiry)))
            (price (try! (contract-call? .yield-token-pool get-price .yield-wbtc-59760)))
            (gross-amount (unwrap! (contract-call? .math-fixed-point mul-up amount (contract-call? .math-fixed-point div-down price ltv) math-call-err)))
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-wbtc .token-usda .yield-wbtc-59760 .key-wbtc-59760-usda gross-amount))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wbtc .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-wbtc .token-usda u50000000 u50000000 swapped-token none))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda .token-wbtc u50000000 u50000000 swapped-token none))
        )
        
        (print { object: "flash-loan-user-margin-usda-wbtc-59760", action: "execute", data: gross-amount })
        (ok true)
    )
)