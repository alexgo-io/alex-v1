(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-private (claim-staking-reward (token-trait <ft-trait>) (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward token-trait reward-cycle)
)
(define-private (stake-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period)
)

(define-public (claim-and-stake (token-trait <ft-trait>) (reward-cycle uint) (lock-period uint))
  (let 
    (
      (claimed (try! (claim-staking-reward token-trait reward-cycle)))
    )
    (and (> (get to-return claimed) u0) (try! (stake-tokens token-trait (get to-return claimed) lock-period)))
    (and (> (get entitled-token claimed) u0) (try! (stake-tokens .age000-governance-token (get entitled-token claimed) lock-period)))
    (ok claimed)
  )
)