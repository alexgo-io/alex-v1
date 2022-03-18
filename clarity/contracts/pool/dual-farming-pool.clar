(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait transfer-trait .trait-transfer.transfer-trait)

;; dual-farm-pool

;; STAKING REWARD CLAIMS

;; calls function to claim staking reward in active logic contract
;; @desc claim-staking-reward
;; @params token-trait; ft-trait
;; @params target-cycle
;; @returns (response tuple)
(define-public (claim-staking-reward (token-trait <ft-trait>) (dual-token-trait <transfer-trait>) (target-cycle uint))
  (let
    (
      ;; { to-return: to-return, entitled-token: entitled-token }
      (claimed (contract-call? .alex-reserve-pool claim-staking-reward-at-cycle token-trait tx-sender block-height target-cycle))
      (sender tx-sender)
    )
    (try! (check-is-approved-token (contract-of token-trait)))
    (try! (check-is-approved-dual-token (contract-of dual-token-trait)))
    (and 
      (> (get entitled-token claimed) u0) 
      (> (get-multiplier-in-fixed-or-default token) u0) 
      (as-contract (try! (contract-call? dual-token-trait transfer-fixed (mul-down (get entitled-token claimed) (get-multiplier-in-fixed-or-default token)) tx-sender sender)))
    )
  )
)

;; @desc mul-down
;; @params a
;; @params b
;; @returns uint
(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc div-down
;; @params a
;; @params b
;; @returns uint
(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)
