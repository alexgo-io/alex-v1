(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; stacked-poxl-pool
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant invalid-pool-err (err u2001))
(define-constant no-liquidity-err (err u2002))
(define-constant invalid-liquidity-err (err u2003))
(define-constant transfer-x-failed-err (err u3001))
(define-constant transfer-y-failed-err (err u3002))
(define-constant pool-already-exists-err (err u2000))
(define-constant too-many-pools-err (err u2004))
(define-constant percent-greater-than-one (err u5000))
(define-constant no-fee-x-err (err u2005))
(define-constant no-fee-y-err (err u2006))
(define-constant already-expiry-err (err u2010))
(define-constant weighted-equation-call-err (err u2009))
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))
(define-constant internal-get-weight-err (err u2012))
(define-constant stacking-in-progress-err (err u2018))

(define-constant BLOCK-PER-CYCLE u2100)

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
    fee-to-address: principal,
    pool-token: principal,
    reward-cycles: (list 32 uint)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;
(define-private (sum-stacking-reward (reward-cycle uint) (sum-so-far uint))
    (+ sum-so-far (get-stacking-reward (get-user-id) reward-cycle))
)

;; to be replaced by proper calls to CityCoins
(define-private (get-stacking-reward (reward-cycle uint)) u1)
(define-private (register-user) true)
(define-private (get-user-id) u1)
(define-private (get-reward-cycle (stack-height uint)) u0)
(define-private (stack-tokens (amount-tokens uint) (lock-period uint)) true)
(define-private (get-first-stacks-block-in-reward-cycle (reward-cycle uint)) u1)
(define-private (claim-stacking-reward (reward-cycle uint)) true)

;; public functions
;;
(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) invalid-pool-err))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

(define-read-only (get-pool-details (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint))
    (ok (unwrap! (map-get? pools-data-map { poxl-token: (contract-of poxl-token-trait), reward-token: (contract-of reward-token-trait), start-cycle: start-cycle }) invalid-pool-err))
)

(define-read-only (get-balance (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint))
    (ok (get total-supply (unwrap! (map-get? pools-data-map { poxl-token: (contract-of poxl-token-trait), reward-token: (contract-of reward-token-trait), start-cycle: start-cycle }) invalid-pool-err)))
)

(define-public (create-pool (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (reward-cycles (list 32 uint)) (yield-token <yield-token-trait>) (multisig <multisig-trait>)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool-data {
                total-supply: u0,
                fee-to-address: (contract-of multisig),
                pool-token: (contract-of yield-token),
                reward-cycles: reward-cycles
            })
            (start-cycle (default-to u0 (element-at reward-cycles u0)))
        )
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

        ;; register if not registered
        (as-contract (register-user))

        (asserts! (is-none (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle })) pool-already-exists-err)

        (map-set pools-map { pool-id: pool-id } { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle })
        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)
        (print { object: "pool", action: "created", pool-data: pool-data })
        (ok true)
   )
)   

(define-public (add-to-position (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint) (yield-token <yield-token-trait>) (dx uint))
    (let
        (
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool (unwrap! (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle }) invalid-pool-err))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (+ dx total-supply)
            }))
        )
        ;; check if stacking already started
        (asserts! (is-eq start-cycle (get-reward-cycle block-height)) stacking-in-progress-err)
        
        ;; transfer dx to contract and send to stack
        (try! (contract-call? poxl-token-trait transfer dx tx-sender (as-contract tx-sender) none))
        (as-contract (stack-tokens dx u32))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-updated)
        (try! (contract-call? yield-token mint tx-sender dx))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)

(define-public (reduce-position (poxl-token-trait <ft-trait>) (reward-token-trait <ft-trait>) (start-cycle uint) (yield-token <yield-token-trait>) (percent uint))
    (let
        (
            (poxl-token (contract-of poxl-token-trait))
            (reward-token (contract-of reward-token-trait))
            (pool (unwrap! (map-get? pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle }) invalid-pool-err))
            (shares (mul-down (unwrap-panic (contract-call? yield-token get-balance tx-sender)) percent))
            (total-supply (get total-supply pool))
            (pool-updated (merge pool {
                total-supply: (- total-supply shares)
                })
            )
            (reward-cycles (get reward-cycles pool))
            (shares-to-supply (div-down shares total-supply))
            (total-rewards (fold sum-stacking-reward reward-cycles u0))
            (portioned-rewards (unwrap! (contract-call? .math-fixed-point mul-down total-rewards shares-to-supply) math-call-err))
        )

        (asserts! (> block-height (+ (get-first-stacks-block-in-reward-cycle (+ start-cycle u32)) BLOCK-PER-CYCLE)) stacking-in-progress-err)
        
        ;; the first call claims rewards
        (as-contract (map claim-stacking-reward reward-cycles))

        (try! (contract-call? poxl-token-trait transfer shares (as-contract tx-sender) tx-sender none))
        (try! (contract-call? reward-token-trait transfer portioned-rewards (as-contract tx-sender) tx-sender none))

        (map-set pools-data-map { poxl-token: poxl-token, reward-token: reward-token, start-cycle: start-cycle } pool-updated)
        (try! (contract-call? yield-token burn tx-sender shares))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {poxl-token: shares, reward-token: portioned-rewards})
    )
)