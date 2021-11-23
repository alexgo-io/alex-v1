(impl-trait .trait-ownable.ownable-trait)
(use-trait sft-trait .trait-semi-fungible-token.semi-fungible-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; alex-futures-pool
;; ideally we want to make this a "generic" pool, but there is an issue with iterating over trait (claim-staking-rewards)
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-staking-IN-PROGRESS (err u2018))
(define-constant ERR-staking-NOT-AVAILABLE (err u2027))

(define-data-var CONTRACT-OWNER principal tx-sender)

(define-constant REWARD-CYCLE-INDEXES (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31))

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
;; pools-map = pool-id, start-cycle
(define-map pools-map uint uint)

(define-map pools-data-map
  uint
  {
    total-supply: uint,
    fee-to-address: principal,
    pool-token: principal,
    reward-cycles: (list 32 uint)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;
(define-private (sum-staking-reward (reward-cycle uint) (sum-so-far uint))
  (+ sum-so-far (get-staking-reward reward-cycle))
)
(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .token-alex (get-user-id) reward-cycle)
)
(define-private (register-user)
  (as-contract (contract-call? .alex-reserve-pool register-user .token-alex none))
)
(define-private (get-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .token-alex (as-contract tx-sender)))
)
(define-private (get-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .token-alex stack-height)
)
(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (as-contract (contract-call? .alex-reserve-pool stake-tokens .token-alex amount-tokens lock-period))
)
(define-private (get-first-stacks-block-in-reward-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle .token-alex reward-cycle)
)
(define-private (claim-staking-reward (reward-cycle uint))
  (as-contract (contract-call? .alex-reserve-pool claim-staking-reward .token-alex reward-cycle))
)

;; public functions
;;
(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map pool-id) ERR-INVALID-POOL))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

(define-read-only (get-pool-details (start-cycle uint))
    (ok (unwrap! (map-get? pools-data-map start-cycle) ERR-INVALID-POOL))
)

(define-read-only (get-balance (start-cycle uint))
    (ok (get total-supply (unwrap! (map-get? pools-data-map start-cycle) ERR-INVALID-POOL)))
)

(define-public (create-pool (reward-cycles (list 32 uint)) (futures-token <sft-trait>) (multisig <multisig-trait>)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))
            (pool-data {
                total-supply: u0,
                fee-to-address: (contract-of multisig),
                pool-token: (contract-of futures-token),                
                reward-cycles: reward-cycles
            })  
            (start-cycle (default-to u0 (element-at reward-cycles u0)))          
        )
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

        ;; register if not registered
        (try! (register-user))

        (asserts! (is-none (map-get? pools-data-map start-cycle)) ERR-POOL-ALREADY-EXISTS)

        (map-set pools-map pool-id start-cycle)
        (map-set pools-data-map start-cycle pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)
        (print { object: "pool", action: "created", pool-data: pool-data })
        (ok true)
   )
)   

(define-public (add-to-position (start-cycle uint) (futures-token <sft-trait>) (dx uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map start-cycle) ERR-INVALID-POOL))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (+ dx total-supply)
            }))
            (current-cycle (unwrap! (get-reward-cycle block-height) ERR-staking-NOT-AVAILABLE))
        )
        ;; check if staking already started
        (asserts! (> start-cycle current-cycle) ERR-staking-IN-PROGRESS)

        ;; transfer dx to contract and send to stake
        (try! (contract-call? .token-alex transfer-fixed dx tx-sender (as-contract tx-sender) none))
        (try! (stake-tokens dx u32))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map start-cycle pool-updated)
        (try! (contract-call? futures-token mint-fixed start-cycle dx tx-sender))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)

(define-public (reduce-position (start-cycle uint) (futures-token <sft-trait>) (percent uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map start-cycle) ERR-INVALID-POOL))
            (shares (mul-down (unwrap-panic (contract-call? futures-token get-balance-fixed start-cycle tx-sender)) percent))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (- total-supply shares)
                })
            )
            (reward-cycles (get reward-cycles pool))
            (shares-to-supply (div-down shares total-supply))
            (total-rewards (fold sum-staking-reward reward-cycles u0))
            (portioned-rewards (mul-down total-rewards shares-to-supply))
        )

        (asserts! (> block-height (+ (get-first-stacks-block-in-reward-cycle (+ start-cycle u32)) (contract-call? .alex-reserve-pool get-reward-cycle-length))) ERR-staking-IN-PROGRESS)
        
        ;; the first call claims rewards
        (map claim-staking-reward reward-cycles)

        (try! (contract-call? .token-alex transfer-fixed (+ shares portioned-rewards) (as-contract tx-sender) tx-sender none))

        (map-set pools-data-map start-cycle pool-updated)
        (try! (contract-call? futures-token burn-fixed start-cycle shares tx-sender))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {staked: shares, rewards: portioned-rewards})
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