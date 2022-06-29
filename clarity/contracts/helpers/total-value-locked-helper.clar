(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-TOKEN (err u2026))

(define-data-var contract-owner principal tx-sender)
(define-map approved-tokens principal bool)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner)) 
    (ok (var-set contract-owner owner))
  )
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved-token (token principal))
  (ok (asserts! (default-to false (map-get? approved-tokens token)) ERR-NOT-AUTHORIZED))
)

(define-public (set-approved-token (token principal) (approved bool))
  (begin 
    (try! (check-is-owner)) 
    (ok (map-set approved-tokens token approved))
  )
)

(define-public (get-total-value-locked (token-trait <ft-trait>))
    (let 
        (
            (token (contract-of token-trait))
            (staked (contract-call? .alex-reserve-pool get-balance token))
            (balance (try! (contract-call? token-trait get-total-supply-fixed)))
        )
        (try! (check-is-approved-token token))
        (ok { pool_token: token, total_supply: balance, reserved_balance: staked })
    )
)

(define-public (get-total-value-locked-many (token-traits (list 200 <ft-trait>)))
    (map get-total-value-locked token-traits)
)