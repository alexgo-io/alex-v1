(impl-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant math-call-err (err u2010))

(define-data-var amount uint u0)

(define-read-only (get-amount)
    (ok (var-get amount))
)

;; user MUST call this to provide borrow and margin amount (both in collateral terms) before calling flash-loan to execute
(define-public (execute-margin-usda-wbtc-23670 (the-amount uint))
    (ok (var-set amount the-amount))
)

(define-public (execute)
    (let
        (            
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-wbtc .token-usda .yield-wbtc-23670 .key-wbtc-23670-usda (var-get amount)))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wbtc .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-wbtc .token-usda u50000000 u50000000 swapped-token))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda .token-wbtc u50000000 u50000000 swapped-token))
        )
        
        (print { object: "flash-loan-user-margin-usda-wbtc-23670", action: "execute", data: (var-get amount) })
        (ok true)
    )
)