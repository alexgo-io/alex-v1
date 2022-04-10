(impl-trait .trait-ownable.ownable-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-AVAIALBLE-ALEX (err u20000))

(define-data-var contract-owner principal tx-sender)
(define-map available-alex principal uint)
(define-map borrowed-alex principal uint)

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

(define-read-only (get-borrowed-alex-or-default (user principal))
  (default-to u0 (map-get? borrowed-alex user))
)

(define-public (add-position (dx uint))
    (let 
        (
          (sender tx-sender)
          (pool (try! (contract-call? .fixed-weight-pool-v1-01 get-token-given-position .token-wstx .age000-governance-token u50000000 u50000000 dx none)))
          (vault (try! (contract-call? .yield-vault-fwp-wstx-alex get-token-given-position (get token pool))))
          (required-alex (+ (get dy pool) (get rewards vault)))
          (available-alex (get-available-alex-or-default sender))
          (borrowed-alex (get-borrowed-alex-or-default sender))                        
        )
        (asserts! (>= available-alex required-alex) ERR-AVAILABLE-ALEX)

        (try! (contract-call? .token-wstx transfer-fixed dx sender (as-contract tx-sender) none))
        (as-contract (try! (contract-call? .age000-governance-token mint-fixed required-alex tx-sender)))
        (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 add-position .token-wstx .age000-governance-token u50000000 u50000000 dx (get dy pool))))
        (as-contract (try! (contract-call? .yield-vault-fwp-wstx-alex add-position (get token pool))))
        (map-set available-alex sender (- available-alex required-alex))
        (map-set borrowed-alex sender (+ borrowed-alex required-alex))
        (as-contract (try! (contract-call? .auto-fwp-wstx-alex-120x mint-fixed (get token vault) sender)))
        (print { object: "pool", action: "position-added", data: (get token vault)})
        (ok true)
    )
)

(define-public (reduce-position)
  (let 
    (
      (sender tx-sender)
      (borrowed-alex (get-borrowed-alex-or-default sender))
      (supply (try! (contract-call? .auto-fwp-wstx-alex-120x get-balance-fixed sender)))
      (total-supply (try! (contract-call? .auto-fwp-wstx-alex-120x get-total-supply-fixed)))
      (share (div-down supply total-supply))
    )
    (as-contract (try! (contract-call? .yield-vault-fwp-wstx-alex reduce-position supply)))
    (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 reduce-position .token-wstx .age000-governance-token u50000000 u50000000 share)))
    ;; convert required amount of wstx to alex and send alex to foundation
    ;; send the balance to tx-sender
    (ok true)
  )
)