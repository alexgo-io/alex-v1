(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible-token.semi-fungible-token-trait)

;; stacked-poxl-pool
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-STACKING-IN-PROGRESS (err u2018))
(define-constant ERR-STACKING-NOT-AVAILABLE (err u2027))

(define-data-var CONTRACT-OWNER principal tx-sender)

(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    poxl-token: principal, ;; token to be stacked
    reward-token: principal, ;; reward token
    start-cycle: uint
  }
)

(define-map pools-data-map
  {
    poxl-token: principal,
    reward-token: principal,
    start-cycle: uint
  }
  {
    total-supply: uint,
    pool-token: principal,
    reward-cycles: (list 32 uint)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;
(define-private (sum-stacking-reward (reward-cycle uint) (token-reward { token: principal, sum-so-far: uint }))
  {
    token: (get token token-reward),
    sum-so-far: (+ (get sum-so-far token-reward) (get-stacking-reward (get token token-reward) reward-cycle))
  } 
)
(define-private (get-stacking-reward (token principal) (reward-cycle uint))
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
(define-private (stack-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (as-contract (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period))
)
(define-private (get-first-stacks-block-in-reward-cycle (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle token reward-cycle)
)
(define-private (claim-stacking-reward (reward-cycle uint) (token-trait <ft-trait>))
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

(define-read-only (get-pool-details (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint))
    (ok (unwrap! (map-get? pools-data-map { poxl-token: (contract-of poxl-token-trait), reward-token: (contract-of reward-token-trait), start-cycle: start-cycle }) ERR-INVALID-POOL))
)

(define-read-only (get-balance (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint))
    (ok (get total-supply (unwrap! (map-get? pools-data-map { poxl-token: (contract-of poxl-token-trait), reward-token: (contract-of reward-token-trait), start-cycle: start-cycle }) ERR-INVALID-POOL)))
)

(define-public (create-pool (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (reward-cycles (list 32 uint)) (yield-token <sft-trait>)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool-data {
                total-supply: u0,
                pool-token: (contract-of yield-token),
                reward-cycles: reward-cycles
            })
            (start-cycle (default-to u0 (element-at reward-cycles u0)))
        )
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

        ;; register if not registered
        (try! (register-user (contract-of poxl-token-trait)))

        (asserts! (is-none (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle })) ERR-POOL-ALREADY-EXISTS)

        (map-set pools-map { pool-id: pool-id } { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle })
        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)
        (print { object: "pool", action: "created", pool-data: pool-data })
        (ok true)
   )
)   

(define-public (add-to-position (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint) (yield-token <sft-trait>) (dx uint))
    (let
        (
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool (unwrap! (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (+ dx total-supply)
            }))
            (current-cycle (unwrap! (get-reward-cycle poxl-token block-height) ERR-STACKING-NOT-AVAILABLE))
        )
        ;; check if stacking already started
        (asserts! (> start-cycle current-cycle) ERR-STACKING-IN-PROGRESS)

        ;; transfer dx to contract and send to stack
        (try! (contract-call? poxl-token-trait transfer-fixed dx tx-sender (as-contract tx-sender) none))
        (try! (stack-tokens poxl-token-trait dx u32))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-updated)
        (try! (contract-call? yield-token mint-fixed start-cycle dx tx-sender))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)

(define-private (create-tuple (token principal) (reward-cycle uint))
  {token: token, reward-cycle: reward-cycle}
)

(define-public (reduce-position (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint) (yield-token <sft-trait>) (percent uint))
    (let
        (
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool (unwrap! (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle }) ERR-INVALID-POOL))
            (shares (mul-down (unwrap-panic (contract-call? yield-token get-balance-fixed start-cycle tx-sender)) percent))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool { total-supply: (- total-supply shares) }))
            (reward-cycles (get reward-cycles pool))
            (shares-to-supply (div-down shares total-supply))
            (total-rewards (get sum-so-far (fold sum-stacking-reward reward-cycles { token: poxl-token, sum-so-far: u0 })))
            (portioned-rewards (mul-down total-rewards shares-to-supply))
            (trait-lists (list poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait poxl-token-trait))
        )

        (asserts! (> block-height (+ (get-first-stacks-block-in-reward-cycle poxl-token (+ start-cycle u32)) (contract-call? .alex-reserve-pool get-reward-cycle-length))) ERR-STACKING-IN-PROGRESS)
        
        ;; the first call claims rewards
        (map claim-stacking-reward reward-cycles trait-lists)

        (try! (contract-call? poxl-token-trait transfer-fixed shares (as-contract tx-sender) tx-sender none))
        (try! (contract-call? reward-token-trait transfer-fixed portioned-rewards (as-contract tx-sender) tx-sender none))

        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-updated)
        (try! (contract-call? yield-token burn-fixed start-cycle shares tx-sender))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {poxl-token: shares, reward-token: portioned-rewards})
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