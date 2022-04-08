(impl-trait .trait-ownable.ownable-trait)

;; yield vault - fwp-wstx-alex-50-50-v1-01
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-ACTIVATED (err u2044))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2045))

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
(define-map total-supply principal uint)
(define-map activated principal bool)
(define-map bounty-in-fixed principal uint)  

(define-read-only (get-bounty-in-fixed-or-default (token principal))
  (default-to u0 (map-get? bounty-in-fixed token))
)

(define-public (set-bounty-in-fixed (new-bounty-in-fixed uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set bounty-in-fixed new-bounty-in-fixed))
  )
)

(define-read-only (get-activated-or-default (token principal))
  (default-to false (map-get? activated token))
)

(define-public (set-activated (new-activated bool))
  (begin
    (try! (check-is-owner))
    (ok (var-set activated new-activated))
  )
)

;; private functions
;;
(define-private (get-alex-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .age000-governance-token (get-alex-user-id) reward-cycle)
)
(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .fwp-wstx-alex-50-50-v1-01 (get-user-id) reward-cycle)
)
(define-private (get-alex-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .age000-governance-token reward-cycle (get-alex-user-id))
)
(define-private (get-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .fwp-wstx-alex-50-50-v1-01 reward-cycle (get-user-id))
)
(define-private (get-alex-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .age000-governance-token tx-sender))
)
(define-private (get-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .fwp-wstx-alex-50-50-v1-01 tx-sender))
)
(define-private (get-alex-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .age000-governance-token stack-height)
)
(define-private (get-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .fwp-wstx-alex-50-50-v1-01 stack-height)
)
(define-private (stake-alex-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens .age000-governance-token amount-tokens lock-period)
)
(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens .fwp-wstx-alex-50-50-v1-01 amount-tokens lock-period)
)
(define-private (claim-alex-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .age000-governance-token reward-cycle)
)
(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .fwp-wstx-alex-50-50-v1-01 reward-cycle)
)

;; public functions
;;   

;; @desc get the next capital base of the vault
;; @desc next-base = principal to be staked at the next cycle 
;; @desc           + principal to be claimed at the next cycle and staked for the following cycle
;; @desc           + reward to be claimed at the next cycle and staked for the following cycle
(define-read-only (get-next-base)
  (let 
    (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (principal 
        (+ 
          (get amount-staked (as-contract (get-staker-at-cycle (+ current-cycle u1)))) 
          (get to-return (as-contract (get-staker-at-cycle current-cycle)))
        )
      )
      (rewards 
        (+ 
          (as-contract (get-staking-reward current-cycle))
          (get amount-staked (as-contract (get-alex-staker-at-cycle (+ current-cycle u1)))) 
          (get to-return (as-contract (get-alex-staker-at-cycle current-cycle)))
          (as-contract (get-alex-staking-reward current-cycle))
        )
      )
    )
    (ok { principal: principal, rewards: rewards })
  )
)

;; @desc get the intrinsic value of auto-alex
;; @desc intrinsic = next capital base of the vault / total supply of auto-alex
(define-read-only (get-intrinsic)
  (let 
    (
      (next-base (try! (get-next-base)))
    )
    (ok { principal: (div-down (get principal next-base) (var-get total-supply)), rewards: (div-down (get rewards next-base) (var-get total-supply)) })
  )  
)

(define-read-only (get-token-given-position (dx uint))
  (let 
    (
      (next-base (try! (get-next-base)))
    )
    (ok 
      (if (is-eq u0 (var-get total-supply))
        { token: dx, rewards: u0 }
        { 
          token: (div-down (mul-down (var-get total-supply) dx) (get principal next-base)), 
          rewards: (div-down (mul-down (get rewards next-base) dx) (get principal next-base))
        }
      )
    )
  )
)

(define-read-only (is-cycle-bountiable (reward-cycle uint))
  (> (as-contract (get-staking-reward reward-cycle)) (var-get bounty-in-fixed))
)

;; @desc add to position
;; @desc transfers dx to vault, stake them for 32 cycles and mints auto-alex, the number of which is determined as % of total supply / next base
;; @param dx the number of $ALEX in 8-digit fixed point notation
(define-public (add-to-position (dx uint))
  (let
    (
      (new-supply (try! (get-token-given-position dx)))
      (sender tx-sender)
    )
    (asserts! (var-get activated) ERR-NOT-ACTIVATED)
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    
    ;; transfer dx to contract to stake for max cycles
    (try! (contract-call? .fwp-wstx-alex-50-50-v1-01 transfer-fixed dx sender (as-contract tx-sender) none))
    (as-contract (try! (stake-tokens dx u32)))

    (and 
      (> (get rewards new-supply) u0) 
      (try! (contract-call? .age000-governance-token transfer-fixed (get rewards new-supply) sender (as-contract tx-sender) none))
      (as-contract (try! (stake-alex-tokens (get rewards new-supply) u32)))
    )
        
    ;; mint pool token and send to tx-sender
    (var-set total-supply (+ (var-get total-supply) (get token new-supply)))
    (as-contract (try! (contract-call? .auto-fwp-wstx-alex mint-fixed (get token new-supply) sender)))
    (print { object: "pool", action: "liquidity-added", data: { new-supply: (get token new-supply), total-supply: (var-get total-supply) }})
    (ok true)
  )
)

;; @desc triggers external event that claims all that's available and stake for another 32 cycles
;; @desc this can be triggered by anyone at a fee (at the moment 0.1% of whatever is claimed)
;; @param reward-cycle the target cycle to claim (and stake for current cycle + 32 cycles). reward-cycle must be < current cycle.
(define-public (claim-and-stake (reward-cycle uint))
  (let 
    (
      (sender tx-sender)
      ;; claim all that's available to claim for the reward-cycle
      (claimed (and (> (as-contract (get-user-id)) u0) (is-ok (as-contract (claim-staking-reward reward-cycle)))))
      (alex-claimed (and (> (as-contract (get-alex-user-id)) u0) (is-ok (as-contract (claim-alex-staking-reward reward-cycle)))))
      (alex-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (principal-balance (unwrap! (contract-call? .fwp-wstx-alex-50-50-v1-01 get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (bounty (var-get bounty-in-fixed))
    )
    (asserts! (> (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE) reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (> alex-balance bounty) ERR-INSUFFICIENT-BALANCE)
    (and 
      (> principal-balance u0)
      (as-contract (try! (stake-tokens principal-balance u32)))
    )
    (and 
      (var-get activated)      
      (as-contract (try! (stake-alex-tokens (- alex-balance bounty) u32)))
      (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none)))
    )
    
    (ok true)
  )
)

;; @desc dissolves the vault and allows auto-alex holders to withdraw $ALEX unstaked from the vault
;; @desc burn all auto-alex held by tx-sender and transfer $ALEX due to tx-sender
;; @assert contract-owner to set-activated to false before such withdrawal can happen.
;; @assert there are no staking positions (i.e. all $ALEX are unstaked)
(define-public (reduce-position)
  (let 
    (
      (sender tx-sender)
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      ;; claim last cycle just in case claim-and-stake has not yet been triggered    
      (claimed (as-contract (try! (claim-staking-reward (- current-cycle u1)))))
      (alex-claimed (as-contract (try! (claim-alex-staking-reward (- current-cycle u1)))))
      (alex-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (principal-balance (unwrap! (contract-call? .fwp-wstx-alex-50-50-v1-01 get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (reduce-supply (unwrap! (contract-call? .auto-fwp-wstx-alex get-balance-fixed sender) ERR-GET-BALANCE-FIXED-FAIL))
      (reduce-principal-balance (div-down (mul-down principal-balance reduce-supply) (var-get total-supply)))
      (reduce-alex-balance (div-down (mul-down alex-balance reduce-supply) (var-get total-supply)))
    )
    ;; only if de-activated
    (asserts! (not (var-get activated)) ERR-ACTIVATED)
    ;; only if no staking positions
    (asserts! (is-eq u0 (get amount-staked (as-contract (get-staker-at-cycle current-cycle)))) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (is-eq u0 (get amount-staked (as-contract (get-alex-staker-at-cycle current-cycle)))) ERR-REWARD-CYCLE-NOT-COMPLETED)
    ;; transfer relevant balance to sender
    (as-contract (try! (contract-call? .age000-governance-token transfer-fixed reduce-alex-balance tx-sender sender none)))
    (as-contract (try! (contract-call? .fwp-wstx-alex-50-50-v1-01 transfer-fixed reduce-principal-balance tx-sender sender none)))
    
    ;; burn pool token
    (var-set total-supply (- (var-get total-supply) reduce-supply))
    (as-contract (try! (contract-call? .auto-fwp-wstx-alex burn-fixed reduce-supply sender)))
    (print { object: "pool", action: "liquidity-removed", data: reduce-supply })
    (ok true)
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

;; contract initialisation
;; (set-contract-owner .executor-dao)
(contract-call? .alex-vault add-approved-token .auto-fwp-wstx-alex)