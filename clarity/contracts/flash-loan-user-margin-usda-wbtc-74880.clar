(impl-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant math-call-err (err u2010))

(define-data-var amount uint u0)

(define-read-only (get-amount)
    (ok (var-get amount))
)

;; user MUST call this to provide borrow and margin amount (both in collateral terms) before calling flash-loan to execute
(define-public (execute-margin-usda-wbtc-74880 (the-amount uint))
    (ok (var-set amount the-amount))
)

(define-public (execute)
    (let
        (            
            (swapped-token (get dx (try! (contract-call? .collateral-rebalancing-pool add-to-position-and-switch .token-wbtc .token-usda .yield-wbtc-74880 .key-wbtc-74880-usda (var-get amount)))))            
        )
        ;; swap token to collateral so we can return flash-loan
        (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-wbtc .token-usda u50000000 u50000000 swapped-token))
        
        (print { object: "flash-loan-user-margin-usda-wbtc-74880", action: "execute", data: (var-get amount) })
        (ok true)
    )
)