(impl-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant user-execute-err (err u3005))

(define-public (execute)
    (let 
        (
            (weight-1 u50000000)
            (weight-2 u50000000)
        )
        
        (asserts! (is-ok (contract-call? .fixed-weight-pool swap-x-for-y .token-alex .token-wbtc weight-1 weight-2 (* u200 u1000000))) user-execute-err)
        (ok true)
    )
)

