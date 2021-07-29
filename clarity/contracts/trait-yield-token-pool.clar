

(use-trait yield-token-trait .trait-yield-token.yield-token-trait)

(define-trait yield-token-pool-trait
  (
    ;; get yield token price for centralized oracle 
    (get-price (<yield-token-trait>) (response uint uint))
)
)