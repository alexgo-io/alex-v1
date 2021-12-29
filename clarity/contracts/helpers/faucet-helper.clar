(define-private (get-some-tokens (recipient principal))
    (contract-call? .faucet get-some-tokens recipient)
)

(define-public (send-many-map (recipients (list 200 principal)))
    (begin
        (ok (map get-some-tokens recipients))
    )
)