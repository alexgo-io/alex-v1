(impl-trait .trait-ownable.ownable-trait)

;; yield vault
;;

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-STAKING-IN-PROGRESS (err u2018))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u2027))
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
(define-data-var total-supply uint u0)
(define-data-var claim-and-stake-bounty-in-fixed uint u1000000) ;; 1%

(define-read-only (get-claim-and-stake-bounty-in-fixed)
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
(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .age000-governance-token (get-user-id) reward-cycle)
)
(define-read-only (get-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .age000-governance-token reward-cycle (get-user-id))
)
(define-private (get-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .age000-governance-token tx-sender))
)
(define-private (get-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .age000-governance-token stack-height)
)
(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens .age000-governance-token amount-tokens lock-period)
)
(define-private (get-first-stacks-block-in-reward-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle .age000-governance-token reward-cycle)
)
(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .age000-governance-token reward-cycle)
)

;; public functions
;;   

(define-read-only (get-next-base)
  (let 
    (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
    )
    (ok 
      (+ 
        (get amount-staked (as-contract (get-staker-at-cycle (+ current-cycle u1)))) 
        (get to-return (as-contract (get-staker-at-cycle current-cycle))) 
        (as-contract (get-staking-reward current-cycle))
      )
    )
  )
)

(define-public (add-to-position (dx uint))
  (let
    (
      (new-supply (div-down (mul-down dx (var-get total-supply)) (try! (get-next-base))))
    )
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    
    ;; transfer dx to contract to stake for max cycles
    (try! (contract-call? .age000-governance-token transfer-fixed dx tx-sender (as-contract tx-sender) none))
    (as-contract (try! (stake-tokens dx u32)))
        
    ;; mint pool token and send to tx-sender
    (var-set total-supply (+ (var-get total-supply) new-supply))
    (as-contract (try! (contract-call? .auto-alex mint-fixed dx tx-sender)))
    (print { object: "pool", action: "liquidity-added", data: new-supply })
    (ok true)
  )
)

(define-public (claim-and-stake (reward-cycle uint))
  (let 
    (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (sender tx-sender)
      ;; claim all that's available to claim for the reward-cycle
      (claimed (as-contract (try! (claim-staking-reward reward-cycle))))
      (balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (bounty (mul-down balance (var-get claim-and-stake-bounty-in-fixed)))
    )
    (asserts! (> current-cycle reward-cycle) ERR-STAKING-IN-PROGRESS)
    (and (> balance u0) (as-contract (try! (stake-tokens (- balance bounty) u32))))
    (and (> bounty u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none))))
    (ok true)
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