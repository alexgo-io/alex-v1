(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))

(define-constant ONE_8 (pow u10 u8))

(define-public (execute (token <ft-trait>) (amount uint))
    (let
        (   
            ;; gross amount * ltv / price = amount
            ;; gross amount = amount * price / ltv
            (expiry (unwrap! (contract-call? .yield-usda-23040 get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv .token-usda .token-wstx expiry)))
            (price (try! (contract-call? .yield-token-pool get-price .yield-usda-23040)))
            (gross-amount (mul-up amount (div-down price ltv)))
            (minted-yield-token (get yield-token (try! (contract-call? .collateral-rebalancing-pool add-to-position .token-usda .token-wstx .yield-usda-23040 .key-usda-23040-wstx gross-amount))))
            (swapped-token (get dx (try! (contract-call? .yield-token-pool swap-y-for-x .yield-usda-23040 .token-usda minted-yield-token none))))
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-wstx .token-usda u50000000 u50000000 swapped-token none))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda .token-wstx u50000000 u50000000 swapped-token none))
        )
        
        (print { object: "flash-loan-user-margin-usda-wstx-23040", action: "execute", data: gross-amount })
        (ok true)
    )
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