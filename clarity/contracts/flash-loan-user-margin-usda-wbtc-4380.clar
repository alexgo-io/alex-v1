(impl-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant math-call-err (err u2010))

(define-data-var borrow-in-collateral uint u0)
(define-data-var margin-in-token uint u0)

;; user MUST call this to provide borrow and margin amount before calling flash-loan to execute
(define-public (execute-margin-usda-wbtc-4380 (the-borrow-in-collateral uint) (the-margin-in-token uint))
    (begin
        (var-set borrow-in-collateral the-borrow-in-collateral)
        (var-set margin-in-token the-margin-in-token)
        (ok true)
    )    
)

(define-public (execute)

    (let
        (
            ;; swap margin-in-token to collateral ccy
            (swapped-margin (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda .token-wbtc u50000000 u50000000 (var-get margin-in-token)))))
            ;; calculate new dy based on swapped margin and flash loan
            (collateral-amount (unwrap! (contract-call? .math-fixed-point add-fixed swapped-margin (var-get borrow-in-collateral)) math-call-err))
            
            ;; mint yield-token and key-token using new-dy
            (minted (try! (contract-call? .collateral-rebalancing-pool add-to-position .token-usda .token-wbtc .yield-usda-4380 .key-usda-wbtc-4380 collateral-amount)))
            (minted-yield-token (get yield-token minted))
            ;; swap minted yield-token for token
            (swapped-token (get dx (try! (contract-call? .yield-token-pool swap-y-for-x .yield-usda-4380 .token-usda minted-yield-token))))
        )
        ;; swap token to collateral so we can return flash-loan
        (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda .token-wbtc u50000000 u50000000 swapped-token))
        
        (print { object: "flash-loan-user-margin-usda-wbtc-4380", action: "execute", data: collateral-amount })
        (ok true)
    )
)