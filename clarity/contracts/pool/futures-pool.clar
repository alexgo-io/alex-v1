(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)

;; futures pool
;; DOES NOT WORK DUE TO alex-reserve-pool requiring 1 principal <> user-id

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-STAKING-IN-PROGRESS (err u2018))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u2027))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))

(define-data-var contract-owner principal tx-sender)

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

;; data maps and vars
;;
(define-map pools-data-map
  {
    staked-token: principal,
    start-cycle: uint
  }
  {
    total-supply: uint,
    pool-token: principal,
    reward-cycles: (list 32 uint),
    claimed: bool
  }
)

(define-data-var claim-and-stake-bounty-in-fixed uint u1000000) ;; 1%

(define-public (get-claim-and-stake-bounty-in-fixed)
  (ok (var-get claim-and-stake-bounty-in-fixed))
)

(define-public (set-claim-and-stake-bounty-in-fixed (new-claim-and-stake-bounty-in-fixed uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set claim-and-stake-bounty-in-fixed new-claim-and-stake-bounty-in-fixed))
  )
)

;; private functions
;;
(define-private (get-user-id (token principal))
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id token tx-sender))
)
(define-private (get-reward-cycle (token principal) (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle token stack-height)
)
(define-private (stake-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period)
)
(define-private (get-first-stacks-block-in-reward-cycle (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle token reward-cycle)
)
(define-private (claim-staking-reward (token-trait <ft-trait>) (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward token-trait reward-cycle)
)
(define-private (claim-alex-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .age000-governance-token reward-cycle)
)

;; public functions
;;
(define-read-only (get-pool-details (staked-token principal) (start-cycle uint))
    (ok (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
)

(define-read-only (get-balance (staked-token principal) (start-cycle uint))
    (ok (get total-supply (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL)))
)

(define-public (create-pool (staked-token principal) (reward-cycles (list 32 uint)) (yield-token principal)) 
    (let
        (
            (pool-data {
                total-supply: u0,
                pool-token: yield-token,
                reward-cycles: reward-cycles,
                claimed: false
            })
            (start-cycle (default-to u0 (element-at reward-cycles u0)))
        )
        (try! (check-is-owner))
        (asserts! (is-none (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle })) ERR-POOL-ALREADY-EXISTS)

        (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-data)

        (try! (contract-call? .alex-vault add-approved-token staked-token))
        (try! (contract-call? .alex-vault add-approved-token yield-token))

        (print { object: "pool", action: "created", pool-data: pool-data })
        (ok true)
   )
)   

(define-public (add-to-position (staked-token-trait <ft-trait>) (start-cycle uint) (yield-token-trait <sft-trait>) (dx uint))
    (let
        (
            (staked-token (contract-of staked-token-trait))
            (pool (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (+ dx total-supply)
            }))
            (current-cycle (unwrap! (get-reward-cycle staked-token block-height) ERR-STAKING-NOT-AVAILABLE))
            (sender tx-sender)
        )
        (asserts! (is-eq (get pool-token pool) (contract-of yield-token-trait)) ERR-INVALID-TOKEN)
        ;; check if staking already started
        (asserts! (> start-cycle current-cycle) ERR-STAKING-IN-PROGRESS)        

        ;; transfer dx to contract and send to stake
        (try! (contract-call? staked-token-trait transfer-fixed dx sender (as-contract tx-sender) none))
        (as-contract (try! (stake-tokens staked-token-trait dx u32)))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-updated)
        (as-contract (try! (contract-call? yield-token-trait mint-fixed start-cycle dx sender)))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
    )
)

(define-public (claim-and-stake (staked-token-trait <ft-trait>) (start-cycle uint))
  (let 
    (
      (staked-token (contract-of staked-token-trait))
      (pool (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL))      
      (reward-cycles (get reward-cycles pool))
      (trait-lists (list staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait))
      (current-cycle (unwrap! (get-reward-cycle .age000-governance-token block-height) ERR-STAKING-NOT-AVAILABLE))
      (sender tx-sender)
    )
    (asserts! 
      (and 
        (> current-cycle start-cycle)
        (< current-cycle (+ start-cycle u31))
      ) 
      ERR-STAKING-IN-PROGRESS
    )

    (as-contract (map claim-staking-reward trait-lists reward-cycles))

    (let 
      (
        (claimed (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
        (bounty (mul-down claimed (var-get claim-and-stake-bounty-in-fixed)))
      )
      (and 
        (> claimed u0) 
        (as-contract (try! (stake-tokens .age000-governance-token (- claimed bounty) (- u31 (- current-cycle start-cycle)))))        
      )
      (and 
        (> bounty u0)
        (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none)))
      )
      (ok true)
    )

  )
)

(define-public (reduce-position (staked-token-trait <ft-trait>) (start-cycle uint) (yield-token-trait <sft-trait>) (percent uint))
  (begin
    (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
    (let
        (
          (staked-token (contract-of staked-token-trait))
          (pool (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
          (reward-cycles (get reward-cycles pool))
          (trait-lists (list staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait))          
          (recipient tx-sender)
        )
        (asserts! (is-eq (get pool-token pool) (contract-of yield-token-trait)) ERR-INVALID-TOKEN)
        (asserts! (> block-height (+ (get-first-stacks-block-in-reward-cycle staked-token (+ start-cycle u31)) (contract-call? .alex-reserve-pool get-reward-cycle-length))) ERR-STAKING-IN-PROGRESS)
        
        ;; the first call claims rewards/stakes
        (and 
          (not (get claimed pool))
          (> (as-contract (get-user-id .age000-governance-token)) u0) 
          (is-ok (as-contract (fold check-err (map claim-alex-staking-reward reward-cycles) (ok { entitled-token: u0, to-return: u0 }))))
        )
        (and 
          (not (get claimed pool))          
          (> (as-contract (get-user-id staked-token)) u0) 
          (is-ok (as-contract (fold check-err (map claim-staking-reward trait-lists reward-cycles) (ok { entitled-token: u0, to-return: u0 }))))
        )        

        (let 
          (
            (reward-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
            (stake-balance (unwrap! (contract-call? staked-token-trait get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
            (shares (mul-down (unwrap! (contract-call? yield-token-trait get-balance-fixed start-cycle recipient) ERR-GET-BALANCE-FIXED-FAIL) percent))
            (total-supply (get total-supply pool))                        
            (shares-to-supply (div-down shares total-supply))
            (pool-updated (merge pool { total-supply: (- total-supply shares), claimed: true }))
            (portioned-rewards (mul-down reward-balance shares-to-supply))
            (portioned-stake (mul-down stake-balance shares-to-supply))
          )

          (and (> portioned-stake u0) (is-ok (as-contract (contract-call? staked-token-trait transfer-fixed portioned-stake tx-sender recipient none))))
          (and (> portioned-rewards u0) (is-ok (as-contract (contract-call? .age000-governance-token transfer-fixed portioned-rewards tx-sender recipient none))))

          (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-updated)
          (as-contract (try! (contract-call? yield-token-trait burn-fixed start-cycle shares recipient)))
          (print { object: "pool", action: "liquidity-removed", data: pool-updated })
          (ok {staked-token: stake-balance, reward-token: reward-balance})
        )
    )
  )
)

(define-private (check-err (result (response (tuple (entitled-token uint) (to-return uint)) uint)) (prior (response (tuple (entitled-token uint) (to-return uint)) uint)))
    (match prior 
        ok-value result
        err-value (err err-value)
    )
)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)