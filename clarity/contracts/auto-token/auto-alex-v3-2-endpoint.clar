;; -- autoALEX creation/staking/redemption

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-PAUSED (err u2046))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-CLAIM-AND-STAKE (err u10018))
(define-constant ERR-NO-REDEEM-REVOKE (err u10019))
(define-constant ERR-REQUEST-FINALIZED-OR-REVOKED (err u10020))
(define-constant ERR-REDEEM-IMBALANCE (err u10021))
(define-constant ERR-END-CYCLE-V2 (err u10022))

(define-constant ONE_8 u100000000)

(define-constant REWARD-CYCLE-INDEXES (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32))

;; data maps and vars
;;

(define-data-var contract-owner principal tx-sender)

(define-data-var create-paused bool true)
(define-data-var redeem-paused bool true)

;; __IF_MAINNET__
(define-constant max-cycles u32)
;; (define-constant max-cycles u2)
;; __ENDIF__

;; read-only calls

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-read-only (get-pending)
  (contract-call? .auto-alex-v3-2-registry get-pending))

(define-read-only (get-finalized)
  (contract-call? .auto-alex-v3-2-registry get-finalized))

(define-read-only (get-revoked)
  (contract-call? .auto-alex-v3-2-registry get-revoked))

(define-read-only (get-start-cycle)
  (contract-call? .auto-alex-v3-2-registry get-start-cycle))

(define-read-only (is-cycle-staked (reward-cycle uint))
  (contract-call? .auto-alex-v3-2-registry is-cycle-staked reward-cycle))

(define-read-only (get-shares-to-tokens-per-cycle-or-default (reward-cycle uint))
  (contract-call? .auto-alex-v3-2-registry get-shares-to-tokens-per-cycle-or-default reward-cycle))

(define-read-only (get-redeem-shares-per-cycle-or-default (reward-cycle uint))
  (contract-call? .auto-alex-v3-2-registry get-redeem-shares-per-cycle-or-default reward-cycle))

(define-read-only (get-redeem-request-or-fail (request-id uint))
  (contract-call? .auto-alex-v3-2-registry get-redeem-request-or-fail request-id))

(define-read-only (is-create-paused)
  (var-get create-paused))

(define-read-only (is-redeem-paused)
  (var-get redeem-paused))

;; @desc get the next capital base of the vault
;; @desc next-base = principal to be staked at the next cycle
;; @desc           + principal to be claimed at the next cycle and staked for the following cycle
;; @desc           + reward to be claimed at the next cycle and staked for the following cycle
;; @desc           + balance of ALEX in the contract
;; @desc           + intrinsic of autoALEXv2 in the contract
(define-read-only (get-next-base)
  (let (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (auto-alex-v2-bal (unwrap-panic (contract-call? .auto-alex-v2 get-balance-fixed .auto-alex-v3-2))))
    (asserts! (or (is-eq current-cycle (get-start-cycle)) (is-cycle-staked (- current-cycle u1))) ERR-CLAIM-AND-STAKE)
    (ok
      (+
        (get amount-staked (as-contract (get-staker-at-cycle (+ current-cycle u1))))
        (get to-return (as-contract (get-staker-at-cycle current-cycle)))
        (as-contract (get-staking-reward current-cycle))
        (unwrap-panic (contract-call? .age000-governance-token get-balance-fixed .auto-alex-v3-2))
        (if (is-eq auto-alex-v2-bal u0) u0 (mul-down auto-alex-v2-bal (try! (contract-call? .auto-alex-v2 get-intrinsic))))))))

;; @desc get the intrinsic value of auto-alex-v3
;; @desc intrinsic = next capital base of the vault / total supply of auto-alex-v3
(define-read-only (get-intrinsic)
  (get-shares-to-tokens ONE_8))

;; governance calls

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

(define-public (pause-create (pause bool))
  (begin
    (try! (check-is-owner))
    (ok (var-set create-paused pause))))

(define-public (pause-redeem (pause bool))
  (begin
    (try! (check-is-owner))
    (ok (var-set redeem-paused pause))))

;; public functions
;;

(define-public (rebase)
  (let (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (start-cycle (get-start-cycle))
      (check-start-cycle (asserts! (<= start-cycle current-cycle) ERR-NOT-ACTIVATED)))
    (and (> current-cycle start-cycle) (not (is-cycle-staked (- current-cycle u1))) (try! (claim-and-stake (- current-cycle u1))))
    (as-contract (try! (contract-call? .auto-alex-v3-2 set-reserve (try! (get-next-base)))))    
    (ok current-cycle)))

;; @desc triggers external event that claims all that's available and stake for another 32 cycles
;; @desc this can be triggered by anyone
;; @param reward-cycle the target cycle to claim (and stake for current cycle + 32 cycles). reward-cycle must be < current cycle.
(define-public (claim-and-stake (reward-cycle uint))
  (let (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (end-cycle-v2 (get-end-cycle-v2))
      ;; claim all that's available to claim for the reward-cycle
      (claimed (as-contract (try! (claim-staking-reward reward-cycle))))
      (claimed-v2 (if (< end-cycle-v2 current-cycle) (as-contract (try! (reduce-position-v2))) (begin (try! (claim-and-stake-v2 reward-cycle)) u0)))
      (tokens (+ (get to-return claimed) (get entitled-token claimed) claimed-v2))
      (previous-shares-to-tokens (get-shares-to-tokens-per-cycle-or-default (- reward-cycle u1)))
      (redeeming (mul-down previous-shares-to-tokens (get-redeem-shares-per-cycle-or-default reward-cycle)))
      (intrinsic (get-shares-to-tokens ONE_8)))
    (asserts! (> current-cycle reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (>= tokens redeeming) ERR-REDEEM-IMBALANCE)
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-staked-cycle reward-cycle true)))
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-shares-to-tokens-per-cycle reward-cycle intrinsic)))
    (try! (fold stake-tokens-iter REWARD-CYCLE-INDEXES (ok { current-cycle: current-cycle, remaining: (- tokens redeeming) })))
    (print { notification: "claim-and-stake", payload: { redeeming: redeeming, tokens: tokens }})
    (ok true)))  

;; claims alex for the reward-cycles and mint auto-alex-v3
(define-public (claim-and-mint (reward-cycles (list 200 uint)))
  (let (
      (claimed (unwrap-panic (contract-call? .staking-helper claim-staking-reward .age000-governance-token reward-cycles))))
    (try! (add-to-position (try! (fold sum-claimed claimed (ok u0)))))
    (ok claimed)))  

;; @desc add to position
;; @desc transfers dx to vault, stake them for 32 cycles and mints auto-alex-v3, the number of which is determined as % of total supply / next base
;; @param dx the number of $ALEX in 8-digit fixed point notation
(define-public (add-to-position (dx uint))
  (let (
      (current-cycle (try! (rebase)))
      (sender tx-sender))
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    (asserts! (not (is-create-paused)) ERR-PAUSED)
    (try! (contract-call? .age000-governance-token transfer-fixed dx sender .auto-alex-v3-2 none))
    (try! (fold stake-tokens-iter REWARD-CYCLE-INDEXES (ok { current-cycle: current-cycle, remaining: dx })))
    (as-contract (try! (contract-call? .auto-alex-v3-2 mint-fixed dx sender)))
    (print { notification: "position-added", payload: { new-supply: dx } })
    (rebase)))

(define-public (upgrade (dx uint))
  (let (
      (end-cycle-v2 (get-end-cycle-v2))
      (current-cycle (try! (rebase)))
      (intrinsic-dx (mul-down dx (try! (contract-call? .auto-alex-v2 get-intrinsic))))
      (sender tx-sender))
    (asserts! (> intrinsic-dx u0) ERR-INVALID-LIQUIDITY)
    (asserts! (not (is-create-paused)) ERR-PAUSED)
    (asserts! (< end-cycle-v2 (+ current-cycle max-cycles)) ERR-END-CYCLE-V2) ;; auto-alex-v2 is not configured correctly
    (try! (contract-call? .auto-alex-v2 transfer-fixed dx sender .auto-alex-v3-2 none))
    (and (< end-cycle-v2 current-cycle) (begin (as-contract (try! (reduce-position-v2))) true))
    (as-contract (try! (contract-call? .auto-alex-v3-2 mint-fixed intrinsic-dx sender)))
    (print { notification: "upgrade-position-added", payload: { new-supply: intrinsic-dx } })
    (rebase)))

(define-public (request-redeem (amount uint))
  (let (
      (current-cycle (try! (rebase)))
      (redeem-cycle (+ current-cycle max-cycles))
      (request-details { requested-by: tx-sender, amount: amount, redeem-cycle: redeem-cycle, status: (get-pending) }))
    (asserts! (not (is-redeem-paused)) ERR-PAUSED)
    (try! (contract-call? .auto-alex-v3-2 transfer-fixed amount tx-sender .auto-alex-v3-2 none))
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-redeem-shares-per-cycle redeem-cycle (+ (get-redeem-shares-per-cycle-or-default redeem-cycle) amount))))
    (print { notification: "redeem-request", payload: request-details })
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-redeem-request u0 request-details)))
    (rebase)))

(define-public (finalize-redeem (request-id uint))
  (let (
      (request-details (try! (get-redeem-request-or-fail request-id)))
      (redeem-cycle (get redeem-cycle request-details))
      (check-claim-and-stake (and (not (is-cycle-staked redeem-cycle)) (try! (claim-and-stake redeem-cycle))))
      (current-cycle (try! (rebase)))
      (tokens (mul-down (get-shares-to-tokens-per-cycle-or-default (- redeem-cycle u1)) (get amount request-details)))
      (updated-request-details (merge request-details { status: (get-finalized) })))
    (asserts! (not (is-redeem-paused)) ERR-PAUSED)
    (asserts! (is-eq (get-pending) (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    
    (as-contract (try! (contract-call? .auto-alex-v3-2 burn-fixed (get amount request-details) .auto-alex-v3-2)))
    (as-contract (try! (contract-call? .auto-alex-v3-2 transfer-token .age000-governance-token tokens (get requested-by request-details))))
    (print { notification: "finalize-redeem", payload: updated-request-details })
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-redeem-request request-id updated-request-details)))
    (rebase)))

(define-public (revoke-redeem (request-id uint))
  (let (
      (request-details (try! (get-redeem-request-or-fail request-id)))
      (current-cycle (try! (rebase)))
      (redeem-cycle (get redeem-cycle request-details))
      (check-cycle (asserts! (> redeem-cycle current-cycle) ERR-NO-REDEEM-REVOKE))      
      (tokens (mul-down (get-shares-to-tokens-per-cycle-or-default (- current-cycle u1)) (get amount request-details)))
      (updated-request-details (merge request-details { status: (get-revoked) })))    
    (asserts! (is-eq tx-sender (get requested-by request-details)) ERR-NOT-AUTHORIZED)    
    (asserts! (is-eq (get-pending) (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    (as-contract (try! (contract-call? .auto-alex-v3-2 transfer-token .auto-alex-v3-2 tokens (get requested-by request-details))))
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-redeem-shares-per-cycle redeem-cycle (- (get-redeem-shares-per-cycle-or-default redeem-cycle) (get amount request-details)))))
    (print { notification: "revoke-redeem", payload: updated-request-details })
    (as-contract (try! (contract-call? .auto-alex-v3-2-registry set-redeem-request request-id updated-request-details)))
    (rebase)))

;; private functions
;;

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (sum-claimed (claimed-response (response (tuple (entitled-token uint) (to-return uint)) uint)) (prior (response uint uint)))
  (match prior 
    ok-value (match claimed-response claimed (ok (+ ok-value (get to-return claimed) (get entitled-token claimed))) err (err err))
    err-value (err err-value)))

(define-private (stake-tokens-iter (cycles-to-stake uint) (previous-response (response { current-cycle: uint, remaining: uint } uint)))
  (match previous-response
    ok-value
    (let (
      (reward-cycle (+ (get current-cycle ok-value) cycles-to-stake))
      (redeeming (get-shares-to-tokens (get-redeem-shares-per-cycle-or-default reward-cycle)))
      (returning (get to-return (get-staker-at-cycle reward-cycle)))
      (staking (if (is-eq cycles-to-stake max-cycles)
        (get remaining ok-value)
        (if (> returning redeeming)
          u0
          (if (> (get remaining ok-value) (- redeeming returning))
            (- redeeming returning)
            (get remaining ok-value))))))
      (and (> staking u0) (as-contract (try! (stake-tokens staking cycles-to-stake))))
      (ok { current-cycle: (get current-cycle ok-value), remaining: (- (get remaining ok-value) staking) }))
    err-value previous-response))

(define-private (get-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .age000-governance-token stack-height))

(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .age000-governance-token (get-user-id) reward-cycle))

(define-private (get-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .age000-governance-token reward-cycle (get-user-id)))

(define-private (get-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .age000-governance-token .auto-alex-v3-2)))

(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .auto-alex-v3-2 stake-tokens amount-tokens lock-period))

(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .auto-alex-v3-2 claim-staking-reward reward-cycle))

(define-private (reduce-position-v2)
  (contract-call? .auto-alex-v3-2 reduce-position-v2))

(define-private (get-shares-to-tokens (dx uint))
  (contract-call? .auto-alex-v3-2 get-shares-to-tokens dx))

(define-private (claim-and-stake-v2 (reward-cycle uint))
  (contract-call? .auto-alex-v2 claim-and-stake reward-cycle))

(define-private (get-end-cycle-v2)
  (contract-call? .auto-alex-v2 get-end-cycle))

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8))

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0) u0 (/ (* a ONE_8) b)))

;; contract initialisation
