(impl-trait .trait-ownable.ownable-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-AVAIALBLE-ALEX (err u20000))

(define-data-var contract-owner principal tx-sender)
(define-map available-alex principal uint)

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

(define-public (set-available-alex (user principal) (new-amount uint))
    (begin 
        (try! (check-is-owner))
        (ok (map-set available-alex user new-amount))
    )
)

(define-read-only (get-available-alex-or-default (user principal))
    (default-to u0 (map-get? available-alex user))
)

(define-public (add-position (dx uint))
    (let 
        (
            (pool (try! (contract-call? .fixed-weight-pool-v1-01 get-token-given-position .token-wstx .age000-governance-token u50000000 u50000000 dx none)))
            (vault (try! (contract-call? .yield-vault-fwp-wstx-alex get-token-given-position (get token pool))))
            (auto-tokens (get token vault))
            (required-alex (+ (get dy pool) (get rewards vault)))
            (available-alex (get-available-alex-or-default tx-sender))            
        )
        (asserts! (>= available-alex required-alex) ERR-AVAILABLE-ALEX)

        (as-contract (try! (contract-call? .age000-governance-token mint-fixed required-alex tx-sender)))
        (try! (contract-call? .fixed-weight-pool-v1-01 add-position .token-wstx .age000-governance-token u50000000 u50000000 dx))
        (map-set available-alex tx-sender (- available-alex required-alex))

    )
)