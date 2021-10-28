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
            (expiry (unwrap! (contract-call? .yield-usda-23040 get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv .token-usda .token-wbtc expiry)))
            (price (try! (contract-call? .yield-token-pool get-price .yield-usda-23040)))
            (gross-amount (contract-call? .math-fixed-point mul-up amount (contract-call? .math-fixed-point div-down price ltv)))
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-usda .token-wbtc .yield-usda-23040 .key-usda-23040-wbtc gross-amount))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wbtc .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-wbtc .token-usda u50000000 u50000000 swapped-token none))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda .token-wbtc u50000000 u50000000 swapped-token none))
        )
        
        (print { object: "flash-loan-user-margin-usda-wbtc-23040", action: "execute", data: gross-amount })
        (ok true)
    )
)