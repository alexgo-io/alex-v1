(define-public (faucet-one (recipient principal))
    (begin
        (try! (contract-call? .token-wxusd-tokensoft transfer-fixed u1000000000000 (as-contract tx-sender) recipient none))
        (ok u0)
    )
)

(define-public (faucet-many (recipient-list (list 299 principal)))
    (begin
        (map faucet-one recipient-list)
        (ok u0)
    )
)