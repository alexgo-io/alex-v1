
;; helper functions:

(define-private (get-staker-at-cycle-or-default-by-tx-sender (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .token-alex reward-cycle (default-to u0 (contract-call? .alex-reserve-pool get-user-id .token-alex tx-sender)))
)
(define-read-only (get-staked (reward-cycles (list 2000 uint)))
  (map get-staker-at-cycle-or-default-by-tx-sender reward-cycles)
)
(define-private (get-staking-reward-by-tx-sender (target-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .token-alex (default-to u0 (contract-call? .alex-reserve-pool get-user-id .token-alex tx-sender)) target-cycle)
)
(define-read-only (get-staking-rewards (reward-cycles (list 2000 uint)))
  (map get-staking-reward-by-tx-sender reward-cycles)
)