
;; helper functions:

;; @desc get-staker-at-cycle-or-default-by-tx-sender
;; @param reward-cyce; reward-cycle
;; @returns (response principal uint uint)
(define-read-only (get-staker-at-cycle-or-default-by-tx-sender (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .token-alex reward-cycle (default-to u0 (contract-call? .alex-reserve-pool get-user-id .token-alex tx-sender)))
)

;; @desc get-staked
;; @param reward-cycles; list of reward-cycle
;; @returns list
(define-read-only (get-staked (reward-cycles (list 2000 uint)))
  (map get-staker-at-cycle-or-default-by-tx-sender reward-cycles)
)

;; @desc get-staking-reward-by-tx-sender
;; @param target-cycle; 
;; @returns uint
(define-read-only (get-staking-reward-by-tx-sender (target-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .token-alex (default-to u0 (contract-call? .alex-reserve-pool get-user-id .token-alex tx-sender)) target-cycle)
)

;; @desc get-staking-rewards
;; @param reward-cycles; list of reward-cycles 
;; @returns list 
(define-read-only (get-staking-rewards (reward-cycles (list 2000 uint)))
  (map get-staking-reward-by-tx-sender reward-cycles)
)

;; @desc claim-staking-reward-by-tx-sender
;; @param reward-cycle; 
;; @returns uint uint 
(define-public (claim-staking-reward-by-tx-sender (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .token-alex reward-cycle)
)

;; @desc claim-staking-reward
;; @param reward-cycles; list of reward cycles 
;; @returns list
(define-public (claim-staking-reward (reward-cycles (list 2000 uint)))
  (ok (map claim-staking-reward-by-tx-sender reward-cycles))
)