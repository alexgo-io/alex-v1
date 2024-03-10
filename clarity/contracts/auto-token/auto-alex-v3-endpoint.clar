;; -- autoALEX creation/staking/redemption

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-ACTIVATED (err u2044))
(define-constant ERR-PAUSED (err u2046))
(define-constant ERR-INVALID-PERCENT (err u5000))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-CLAIM-AND-STAKE (err u10018))
(define-constant ERR-REQUEST-ID-NOT-FOUND (err u10019))
(define-constant ERR-REQUEST-FINALIZED-OR-REVOKED (err u10020))
(define-constant ERR-REDEMPTION-TOO-HIGH (err u10021))
(define-constant ERR-END-CYCLE-V2 (err u10022))

(define-constant ONE_8 u100000000)

(define-constant REWARD-CYCLE-INDEXES (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32))

;; data maps and vars
;;

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-data-var create-paused bool true)
(define-data-var redeem-paused bool true)

;; read-only calls

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner)))

(define-read-only (get-pending)
  (contract-call? .auto-alex-v3-registry get-pending))

(define-read-only (get-finalized)
  (contract-call? .auto-alex-v3-registry get-finalized))

(define-read-only (get-revoked)
  (contract-call? .auto-alex-v3-registry get-revoked))

(define-read-only (get-start-cycle)
  (contract-call? .auto-alex-v3-registry get-start-cycle))

(define-read-only (is-cycle-staked (reward-cycle uint))
  (contract-call? .auto-alex-v3-registry is-cycle-staked reward-cycle))

(define-read-only (get-redeem-shares-per-cycle-or-default (reward-cycle uint))
  (contract-call? .auto-alex-v3-registry get-redeem-shares-per-cycle-or-default reward-cycle))

(define-read-only (get-redeem-tokens-per-cycle-or-default (reward-cycle uint))
  (contract-call? .auto-alex-v3-registry get-redeem-tokens-per-cycle-or-default reward-cycle))

(define-read-only (get-redeem-request-or-fail (request-id uint))
  (contract-call? .auto-alex-v3-registry get-redeem-request-or-fail request-id))

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
      (auto-alex-v2-bal (unwrap! (contract-call? .auto-alex-v2 get-balance-fixed .auto-alex-v3) ERR-GET-BALANCE-FIXED-FAIL)))
    (asserts! (or (is-eq current-cycle (get-start-cycle)) (is-cycle-staked (- current-cycle u1))) ERR-CLAIM-AND-STAKE)
    (ok 
      (+         
        (get amount-staked (as-contract (get-staker-at-cycle (+ current-cycle u1)))) 
        (get to-return (as-contract (get-staker-at-cycle current-cycle)))
        (as-contract (get-staking-reward current-cycle))
        (unwrap! (contract-call? .age000-governance-token get-balance-fixed .auto-alex-v3) ERR-GET-BALANCE-FIXED-FAIL)
        (if (is-eq auto-alex-v2-bal u0) u0 (mul-down auto-alex-v2-bal (try! (contract-call? .auto-alex-v2 get-intrinsic))))))))

;; @desc get the intrinsic value of auto-alex-v3
;; @desc intrinsic = next capital base of the vault / total supply of auto-alex-v3
(define-read-only (get-intrinsic)
  (ok (div-down (try! (get-next-base)) (unwrap-panic (contract-call? .auto-alex-v3 get-total-supply-fixed)))))

(define-read-only (get-shares-to-tokens (dx uint))
  (let (
      (total-supply (unwrap-panic (contract-call? .auto-alex-v3 get-total-supply-fixed))))
    (ok (if (is-eq u0 total-supply) dx (div-down (mul-down (try! (get-next-base)) dx) total-supply)))))

(define-read-only (get-tokens-to-shares (dx uint))
  (let (
      (total-supply (unwrap-panic (contract-call? .auto-alex-v3 get-total-supply-fixed))))  
    (ok (if (is-eq u0 total-supply) dx (div-down (mul-down total-supply dx) (try! (get-next-base)))))))

;; governance calls

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

(define-public (set-approved-contract (owner principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts owner approved))))

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

;; @desc add to position
;; @desc transfers dx to vault, stake them for 32 cycles and mints auto-alex-v3, the number of which is determined as % of total supply / next base
;; @param dx the number of $ALEX in 8-digit fixed point notation
(define-public (add-to-position (dx uint))
  (let (            
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (start-cycle (get-start-cycle))
      (check-start-cycle (asserts! (<= start-cycle current-cycle) ERR-NOT-ACTIVATED))
      (check-claim-and-stake (and (> current-cycle start-cycle) (not (is-cycle-staked (- current-cycle u1))) (try! (claim-and-stake (- current-cycle u1)))))
      (new-supply (try! (get-tokens-to-shares dx)))
      (sender tx-sender))
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    (asserts! (not (is-create-paused)) ERR-PAUSED)

    ;; transfer dx to contract to stake for max cycles
    (try! (contract-call? .age000-governance-token transfer-fixed dx sender .auto-alex-v3 none))
    (try! (fold stake-tokens-iter REWARD-CYCLE-INDEXES (ok { current-cycle: current-cycle, remaining: dx })))
        
    ;; mint pool token and send to tx-sender
    (as-contract (try! (contract-call? .auto-alex-v3 mint-fixed new-supply sender)))
    (print { object: "pool", action: "position-added", data: new-supply })
    (ok true)))

(define-public (upgrade (dx uint))
  (let (            
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (start-cycle (get-start-cycle))
      (end-cycle-v2 (contract-call? .auto-alex-v2 get-end-cycle))
      (check-start-cycle (asserts! (<= start-cycle current-cycle) ERR-NOT-ACTIVATED))
      (check-claim-and-stake (and (> current-cycle start-cycle) (not (is-cycle-staked (- current-cycle u1))) (try! (claim-and-stake (- current-cycle u1)))))
      (intrinsic-dx (mul-down dx (try! (contract-call? .auto-alex-v2 get-intrinsic))))
      (new-supply (try! (get-tokens-to-shares intrinsic-dx)))
      (sender tx-sender))
    (asserts! (> intrinsic-dx u0) ERR-INVALID-LIQUIDITY)
    (asserts! (not (is-create-paused)) ERR-PAUSED)
    (asserts! (< end-cycle-v2 (+ current-cycle u32)) ERR-END-CYCLE-V2) ;; auto-alex-v2 is not configured correctly

    ;; transfer dx to contract to stake for max cycles
    (try! (contract-call? .auto-alex-v2 transfer-fixed dx sender .auto-alex-v3 none))
    (and (< end-cycle-v2 current-cycle) (as-contract (try! (reduce-position-v2))))
        
    ;; mint pool token and send to tx-sender
    (as-contract (try! (contract-call? .auto-alex-v3 mint-fixed new-supply sender)))
    (print { object: "pool", action: "position-added", data: new-supply })
    (ok true)))

;; claims alex for the reward-cycles and mint auto-alex-v3
(define-public (claim-and-mint (reward-cycles (list 200 uint)))
  (let (
      (claimed (unwrap-panic (contract-call? .staking-helper claim-staking-reward .age000-governance-token reward-cycles))))
    (try! (add-to-position (fold sum-claimed claimed u0)))
    (ok claimed)))

;; @desc triggers external event that claims all that's available and stake for another 32 cycles
;; @desc this can be triggered by anyone
;; @param reward-cycle the target cycle to claim (and stake for current cycle + 32 cycles). reward-cycle must be < current cycle.
(define-public (claim-and-stake (reward-cycle uint))
  (let (      
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (end-cycle-v2 (get-end-cycle-v2))    
      ;; claim all that's available to claim for the reward-cycle
      (claimed (and (> (get-user-id) u0) (is-ok (as-contract (claim-staking-reward reward-cycle)))))
      (claimed-v2 (if (< end-cycle-v2 current-cycle) (as-contract (try! (reduce-position-v2))) (try! (claim-and-stake-v2 reward-cycle))))
      (tokens (unwrap! (contract-call? .age000-governance-token get-balance-fixed .auto-alxex-v3) ERR-GET-BALANCE-FIXED-FAIL))
      (set-staked (as-contract (contract-call? .auto-alex-v3-registry set-staked-cycle reward-cycle true))))
    (asserts! (> current-cycle reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (try! (fold stake-tokens-iter REWARD-CYCLE-INDEXES (ok { current-cycle: current-cycle, remaining: tokens })))
    (as-contract (contract-call? .auto-alex-v3-registry set-redeem-tokens-per-cycle reward-cycle (try! (get-shares-to-tokens (get-redeem-shares-per-cycle-or-default reward-cycle)))))))

(define-public (request-redeem (amount uint))
  (let (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (redeem-cycle (+ current-cycle u32))
      (request-details { requested-by: tx-sender, shares: amount, redeem-cycle: redeem-cycle, status: (get-pending) }))
    (asserts! (not (is-redeem-paused)) ERR-PAUSED)
    (try! (contract-call? .auto-alex-v3 transfer-fixed amount tx-sender .auto-alex-v3 none))    
    (as-contract (try! (contract-call? .auto-alex-v3-registry set-redeem-shares-per-cycle redeem-cycle (+ (get-redeem-shares-per-cycle-or-default redeem-cycle) amount))))
    (print { object: "pool", action: "redeem-request", data: request-details })
    (as-contract (contract-call? .auto-alex-v3-registry set-redeem-request u0 request-details))))

(define-public (finalize-redeem (request-id uint))
  (let (      
      (request-details (try! (get-redeem-request-or-fail request-id)))
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (check-claim-and-stake (and (not (is-cycle-staked (get redeem-cycle request-details))) (try! (claim-and-stake (get redeem-cycle request-details)))))
      (redeem-cycle (get redeem-cycle request-details))
      (redeem-tokens (div-down (mul-down (get shares request-details) (get-redeem-tokens-per-cycle-or-default redeem-cycle)) (get-redeem-shares-per-cycle-or-default redeem-cycle))))
    (asserts! (not (is-redeem-paused)) ERR-PAUSED) 
    (asserts! (is-eq (get-pending) (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    
    (as-contract (try! (contract-call? .auto-alex-v3 transfer-token .age000-governance-token redeem-tokens (get requested-by request-details))))
    (as-contract (try! (contract-call? .auto-alex-v3 burn-fixed (get shares request-details) .auto-alex-v3)))
    (as-contract (contract-call? .auto-alex-v3-registry set-redeem-request request-id (merge request-details { status: (get-finalized) })))))

(define-public (revoke-redeem (request-id uint))
  (let (
      (request-details (try! (get-redeem-request-or-fail request-id)))
      (redeem-cycle (get redeem-cycle request-details)))
    (asserts! (is-eq tx-sender (get requested-by request-details)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-cycle-staked redeem-cycle)) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (is-eq (get-pending) (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    (as-contract (try! (contract-call? .auto-alex-v3 transfer-token .auto-alex-v3 (get shares request-details) (get requested-by request-details))))
    (as-contract (try! (contract-call? .auto-alex-v3-registry set-redeem-shares-per-cycle redeem-cycle (- (get-redeem-shares-per-cycle-or-default redeem-cycle) (get shares request-details)))))
    (as-contract (contract-call? .auto-alex-v3-registry set-redeem-request request-id (merge request-details { status: (get-revoked) })))))

;; private functions
;;

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (check-is-approved)
  (ok (asserts! (or (default-to false (map-get? approved-contracts tx-sender)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)))

(define-private (sum-claimed (claimed-response (response (tuple (entitled-token uint) (to-return uint)) uint)) (sum-so-far uint))
  (match claimed-response
    claimed (+ sum-so-far (get to-return claimed) (get entitled-token claimed))
    err sum-so-far))

(define-private (stake-tokens-iter (cycles-to-stake uint) (previous-response (response { current-cycle: uint, remaining: uint } uint)))
  (match previous-response
    ok-value
    (let (
      (reward-cycle (+ (get current-cycle ok-value) cycles-to-stake))
      (redeeming (try! (get-shares-to-tokens (get-redeem-shares-per-cycle-or-default reward-cycle))))
      (returning (get to-return (get-staker-at-cycle reward-cycle)))
      (staking (if (is-eq cycles-to-stake u32) 
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
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .age000-governance-token .auto-alex-v3)))

(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .auto-alex-v3 stake-tokens amount-tokens lock-period))

(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .auto-alex-v3 claim-staking-reward reward-cycle))

(define-private (reduce-position-v2)
  (contract-call? .auto-alex-v3 reduce-position-v2))

(define-private (claim-and-stake-v2 (reward-cycle uint))
  (contract-call? .auto-alex-v2 claim-and-stake reward-cycle))

(define-private (get-end-cycle-v2)
  (contract-call? .auto-alex-v2 get-end-cycle))

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8))

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0) u0 (/ (* a ONE_8) b)))

;; contract initialisation