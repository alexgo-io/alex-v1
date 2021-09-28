(impl-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant math-call-err (err u2010))

(define-data-var amount uint u0)

(define-read-only (get-amount)
    (ok (var-get amount))
)

;; user MUST call this to provide borrow and margin amount (both in collateral terms) before calling flash-loan to execute
(define-public (execute-margin-wbtc-usda-23040 (the-amount uint))
    (ok (var-set amount the-amount))
)

(define-public (execute)
    (let
        (            
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-usda .token-wbtc .yield-usda-23040 .key-usda-23040-wbtc (var-get amount)))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wbtc .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-wbtc .token-usda u50000000 u50000000 swapped-token))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda .token-wbtc u50000000 u50000000 swapped-token))
        )
        
        (print { object: "flash-loan-user-margin-wbtc-usda-23040", action: "execute", data: (var-get amount) })
        (ok true)
    )
)