(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)


;; futures pool
;;

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-STAKING-IN-PROGRESS (err u2018))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u2027))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))

(define-data-var contract-owner principal tx-sender)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    staked-token: principal, ;; token to be staked
    start-cycle: uint
  }
)

(define-map pools-data-map
  {
    staked-token: principal,
    start-cycle: uint
  }
  {
    total-supply: uint,
    pool-token: principal,
    reward-cycles: (list 32 uint)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 500 uint) (list))

;; private functions
;;
(define-private (sum-staking-reward (reward-cycle uint) (token-reward { token: principal, sum-so-far: uint }))
  {
    token: (get token token-reward),
    sum-so-far: (+ (get sum-so-far token-reward) (get-staking-reward (get token token-reward) reward-cycle))
  } 
)
(define-private (get-staking-reward (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward token (get-user-id token) reward-cycle)
)
(define-private (register-user (token principal))
  (as-contract (contract-call? .alex-reserve-pool register-user token none))
)
(define-private (get-user-id (token principal))
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id token (as-contract tx-sender)))
)
(define-private (get-reward-cycle (token principal) (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle token stack-height)
)
(define-private (stake-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (as-contract (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period))
)
(define-private (get-first-stacks-block-in-reward-cycle (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle token reward-cycle)
)
(define-private (claim-staking-reward (reward-cycle uint) (token-trait <ft-trait>))
  (as-contract (contract-call? .alex-reserve-pool claim-staking-reward token-trait reward-cycle))
)

;; public functions
;;
(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) ERR-INVALID-POOL))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; immunefi-4384
(define-read-only (get-pools-by-ids (pool-ids (list 26 uint)))
  (ok (map get-pool-contracts pool-ids))
)

(define-read-only (get-pool-details (staked-token-trait <ft-trait>) (start-cycle uint))
    (ok (unwrap! (map-get? pools-data-map { staked-token: (contract-of staked-token-trait), start-cycle: start-cycle }) ERR-INVALID-POOL))
)

(define-read-only (get-balance (staked-token-trait <ft-trait>) (start-cycle uint))
    (ok (get total-supply (unwrap! (map-get? pools-data-map { staked-token: (contract-of staked-token-trait), start-cycle: start-cycle }) ERR-INVALID-POOL)))
)

(define-public (create-pool (staked-token-trait <ft-trait>) (reward-cycles (list 32 uint)) (yield-token <sft-trait>)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))
            (staked-token (contract-of staked-token-trait))
            (pool-data {
                total-supply: u0,
                pool-token: (contract-of yield-token),
                reward-cycles: reward-cycles
            })
            (start-cycle (default-to u0 (element-at reward-cycles u0)))
        )
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

        ;; register if not registered
        (try! (register-user (contract-of staked-token-trait)))

        (asserts! (is-none (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle })) ERR-POOL-ALREADY-EXISTS)

        (map-set pools-map { pool-id: pool-id } { staked-token: staked-token, start-cycle: start-cycle })
        (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u500) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)

        (try! (contract-call? .alex-vault add-approved-token staked-token))
        (try! (contract-call? .alex-vault add-approved-token (contract-of yield-token)))

        (print { object: "pool", action: "created", pool-data: pool-data })
        (ok true)
   )
)   

(define-public (add-to-position (staked-token-trait <ft-trait>) (start-cycle uint) (yield-token <sft-trait>) (dx uint))
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
        (asserts! (is-eq (get pool-token pool) (contract-of yield-token)) ERR-INVALID-TOKEN)
        ;; check if staking already started
        (asserts! (> start-cycle current-cycle) ERR-STAKING-IN-PROGRESS)        

        ;; transfer dx to contract and send to stake
        (try! (contract-call? staked-token-trait transfer-fixed dx tx-sender (as-contract tx-sender) none))
        (try! (stake-tokens staked-token-trait dx u32))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-updated)
        (as-contract (try! (contract-call? yield-token mint-fixed start-cycle dx sender)))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)

(define-private (create-tuple (token principal) (reward-cycle uint))
  {token: token, reward-cycle: reward-cycle}
)

(define-public (reduce-position (staked-token-trait <ft-trait>) (start-cycle uint) (yield-token <sft-trait>) (percent uint))
  (begin
    (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
    (let
        (
            (staked-token (contract-of staked-token-trait))
            (pool (unwrap! (map-get? pools-data-map { staked-token: staked-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
            (shares (mul-down (unwrap-panic (contract-call? yield-token get-balance-fixed start-cycle tx-sender)) percent))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool { total-supply: (- total-supply shares) }))
            (reward-cycles (get reward-cycles pool))
            (shares-to-supply (div-down shares total-supply))
            (total-rewards (get sum-so-far (fold sum-staking-reward reward-cycles { token: staked-token, sum-so-far: u0 })))
            (portioned-rewards (mul-down total-rewards shares-to-supply))
            (trait-lists (list staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait staked-token-trait))
            (recipient tx-sender)
        )
        (asserts! (is-eq (get pool-token pool) (contract-of yield-token)) ERR-INVALID-TOKEN)
        (asserts! (> block-height (+ (get-first-stacks-block-in-reward-cycle staked-token (+ start-cycle u32)) (contract-call? .alex-reserve-pool get-reward-cycle-length))) ERR-STAKING-IN-PROGRESS)
        
        ;; the first call claims rewards
        (try! (fold check-err (map claim-staking-reward reward-cycles trait-lists) (ok { entitled-token: u0, to-return: u0 })))

        (and (> shares u0) (as-contract (try! (contract-call? staked-token-trait transfer-fixed shares tx-sender recipient none))))
        (and (> portioned-rewards u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed portioned-rewards tx-sender recipient none))))

        (map-set pools-data-map { staked-token: staked-token, start-cycle: start-cycle } pool-updated)
        (as-contract (try! (contract-call? yield-token burn-fixed start-cycle shares recipient)))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {staked-token: shares, reward-token: portioned-rewards})
    )
  )
)

(define-private (check-err (result (response (tuple (entitled-token uint) (to-return uint)) uint)) (prior (response (tuple (entitled-token uint) (to-return uint)) uint)))
    (match prior 
        ok-value result
        err-value (err err-value)
    )
)

(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)