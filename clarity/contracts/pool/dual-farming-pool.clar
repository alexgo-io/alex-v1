(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait transfer-trait .trait-transfer.transfer-trait)

;; dual-farm-pool

(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-data-var contract-owner principal tx-sender)

(define-map approved-pair principal principal)
(define-map multiplier-in-fixed principal uint)

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

(define-private (check-is-approved-pair (token principal) (dual-token principal))
  (ok (asserts! (is-eq dual-token (map-get? approved-pair token)) ERR-NOT-AUTHORIZED))
)

(define-read-only (get-multiplier-in-fixed-or-default (token principal))
  (default-to u0 (map-get? multiplier-in-fixed token))
)

(define-public (set-multiplier-in-fixed (token principal) (new-multiplier-in-fixed uint))
  (begin
    (try! (check-is-owner))
    (ok (map-set multiplier-in-fixed token new-multiplier-in-fixed))
  )
)

;; @desc add-token 
;; @params token
;; @returns (response bool)
(define-public (add-token (token principal) (dual-token principal))
  (begin
    (try! (check-is-owner))
    (map-set approved-pair token dual-token)
    (contract-call? .alex-reserve-pool add-token token)
  )
)

(define-read-only (get-apower-multiplier-in-fixed-or-default (token principal) (dual-token principal))
  (contract-call? .alex-reserve-pool get-apower-multiplier-in-fixed-or-default token)
)

(define-public (set-apower-multiplier-in-fixed (token principal) (dual-token principal) (new-apower-multiplier-in-fixed uint))
  (begin
    (try! (check-is-approved-pair token dual-token))
    (contract-call? .alex-reserve-pool set-apower-multiplier-in-fixed-or-default token new-apower-multiplier-in-fixed)
  )
)

;; @desc get-activation-block-or-default 
;; @params token
;; @returns uint
(define-read-only (get-activation-block-or-default (token principal))
  (default-to u100000000 (map-get? activation-block token))
)

(define-public (set-activation-block (token principal) (new-activation-block uint))
  (begin
    (try! (check-is-owner))
    (ok (map-set activation-block token new-activation-block))
  )
)


;; STAKING REWARD CLAIMS

;; calls function to claim staking reward in active logic contract
;; @desc claim-staking-reward
;; @params token-trait; ft-trait
;; @params target-cycle
;; @returns (response tuple)
(define-public (claim-staking-reward (token-trait <ft-trait>) (dual-token-trait <transfer-trait>) (target-cycle uint))
  (let
    (
      (sender tx-sender)
      ;; { to-return: to-return, entitled-token: entitled-token }
      (claimed (contract-call? .alex-reserve-pool claim-staking-reward-at-cycle token-trait sender block-height target-cycle))      
    )
    (try! (check-is-approved-pair (contract-of token-trait) (contract-of dual-token-trait)))
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
