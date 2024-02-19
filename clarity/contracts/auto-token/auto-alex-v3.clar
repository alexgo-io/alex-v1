(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 u100000000)

;; -- token implementation

(define-fungible-token auto-alex-v3)

(define-data-var contract-owner principal tx-sender)
(define-data-var token-name (string-ascii 32) "Auto ALEX")
(define-data-var token-symbol (string-ascii 32) "auto-alex-v3")
(define-data-var token-uri (optional (string-utf8 256)) (some u"https://cdn.alexlab.co/metadata/token-auto-alex-v3.json"))

(define-data-var token-decimals uint u8)

(define-map approved-contracts principal bool)

;; read-only calls

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-name)
	(ok (var-get token-name))
)

(define-read-only (get-symbol)
	(ok (var-get token-symbol))
)

(define-read-only (get-decimals)
	(ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance auto-alex-v3 who))
)

(define-read-only (get-total-supply)
	(ok (ft-get-supply auto-alex-v3))
)

(define-read-only (get-token-uri)
	(ok (var-get token-uri))
)

;; @desc fixed-to-decimals
;; @params amount
;; @returns uint
(define-read-only (fixed-to-decimals (amount uint))
  (/ (* amount (pow-decimals)) ONE_8)
)

;; @desc get-total-supply-fixed
;; @params token-id
;; @returns (response uint)
(define-read-only (get-total-supply-fixed)
  (ok (decimals-to-fixed (unwrap-panic (get-total-supply))))
)

;; @desc get-balance-fixed
;; @params token-id
;; @params who
;; @returns (response uint)
(define-read-only (get-balance-fixed (account principal))
  (ok (decimals-to-fixed (unwrap-panic (get-balance account))))
)

;; governance calls

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-public (set-name (new-name (string-ascii 32)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-name new-name))
	)
)

(define-public (set-symbol (new-symbol (string-ascii 10)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-symbol new-symbol))
	)
)

(define-public (set-decimals (new-decimals uint))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-decimals new-decimals))
	)
)

(define-public (set-token-uri (new-uri (optional (string-utf8 256))))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-uri new-uri))
	)
)

(define-public (add-approved-contract (new-approved-contract principal))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts new-approved-contract true))
	)
)

(define-public (set-approved-contract (owner principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts owner approved))
	)
)

;; priviliged calls

;; @desc mint
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response bool)
(define-public (mint (amount uint) (recipient principal))
	(begin		
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ft-mint? auto-alex-v3 amount recipient)
	)
)

;; @desc burn
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response bool)
(define-public (burn (amount uint) (sender principal))
	(begin
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ft-burn? auto-alex-v3 amount sender)
	)
)

;; @desc mint-fixed
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response bool)
(define-public (mint-fixed (amount uint) (recipient principal))
  (mint (fixed-to-decimals amount) recipient)
)

;; @desc burn-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response bool)
(define-public (burn-fixed (amount uint) (sender principal))
  (burn (fixed-to-decimals amount) sender)
)

(define-public (mint-fixed-many (recipients (list 200 {amount: uint, recipient: principal})))
	(begin
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ok (map mint-fixed-many-iter recipients))
	)
)

;; public calls

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (begin
        (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
        (try! (ft-transfer? auto-alex-v3 amount sender recipient))
        (match memo to-print (print to-print) 0x)
        (ok true)
    )
)

;; @desc transfer-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @params recipient
;; @returns (response bool)
(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (transfer (fixed-to-decimals amount) sender recipient memo)
)

;; private calls

(define-private (mint-fixed-many-iter (item {amount: uint, recipient: principal}))
	(mint-fixed (get amount item) (get recipient item))
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

;; @desc decimals-to-fixed 
;; @params amount
;; @returns uint
(define-private (decimals-to-fixed (amount uint))
  (/ (* amount ONE_8) (pow-decimals))
)

;; @desc pow-decimals
;; @returns uint
(define-private (pow-decimals)
  (pow u10 (unwrap-panic (get-decimals)))
)


;; -- autoALEX creation/staking/redemption

;; constants
;;

(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-ACTIVATED (err u2044))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2045))
(define-constant ERR-PAUSED (err u2046))
(define-constant ERR-INVALID-PERCENT (err u5000))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-CLAIM-AND-STAKE (err u10018))
(define-constant ERR-REQUEST-ID-NOT-FOUND (err u10019))
(define-constant ERR-REQUEST-FINALIZED-OR-REVOKED (err u10020))

(define-constant PENDING 0x00)
(define-constant FINALIZED 0x01)
(define-constant REVOKED 0x02)

;; data maps and vars
;;
(define-data-var start-cycle uint u340282366920938463463374607431768211455)
(define-data-var end-cycle uint u340282366920938463463374607431768211455)

(define-data-var create-paused bool true)
(define-data-var redeem-paused bool true)

(define-map staked-cycle uint bool)

(define-data-var redeem-request-nonce uint u0)
(define-map redeem-requests uint { requested-by: principal, shares: uint, redeem-cycle: uint, status: (buff 1) })
(define-map redeem-shares-per-cycle uint uint)
(define-map redeem-tokens-per-cycle uint uint)

;; read-only calls

(define-read-only (get-start-cycle)
  (var-get start-cycle)
)

(define-read-only (get-end-cycle)
  (var-get end-cycle)
)

(define-read-only (is-create-paused)
  (var-get create-paused)
)

(define-read-only (is-redeem-paused)
  (var-get redeem-paused)
)

;; @desc get the next capital base of the vault
;; @desc next-base = principal to be staked at the next cycle 
;; @desc           + principal to be claimed at the next cycle and staked for the following cycle
;; @desc           + reward to be claimed at the next cycle and staked for the following cycle
;; @desc           + balance of ALEX in the contract
(define-read-only (get-next-base)
  (let 
    (
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
    )
    (asserts! (or (is-eq current-cycle (var-get start-cycle)) (is-cycle-staked (- current-cycle u1))) ERR-CLAIM-AND-STAKE)
    (ok 
      (+         
        (get amount-staked (as-contract (get-staker-at-cycle (+ current-cycle u1)))) 
        (get to-return (as-contract (get-staker-at-cycle current-cycle)))
        (as-contract (get-staking-reward current-cycle))
        (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL)
      )
    )
  )
)

;; @desc get the intrinsic value of auto-alex-v3
;; @desc intrinsic = next capital base of the vault / total supply of auto-alex-v3
(define-read-only (get-intrinsic)
  (ok (div-down (try! (get-next-base)) (unwrap-panic (get-total-supply-fixed))))  
)

(define-read-only (get-shares-to-tokens (dx uint))
  (ok 
    (if (is-eq u0 (unwrap-panic (get-total-supply-fixed)))
      dx ;; initial position
      (div-down (mul-down (try! (get-next-base)) dx) (unwrap-panic (get-total-supply-fixed)))
    )
  )
)

(define-read-only (get-tokens-to-shares (dx uint))  
  (ok 
    (if (is-eq u0 (unwrap-panic (get-total-supply-fixed)))
      dx ;; initial position
      (div-down (mul-down (unwrap-panic (get-total-supply-fixed)) dx) (try! (get-next-base)))
    )
  )
)

(define-read-only (is-cycle-staked (reward-cycle uint))
  (default-to false (map-get? staked-cycle reward-cycle))
)

(define-read-only (get-redeem-shares-per-cycle-or-default (reward-cycle uint))
  (default-to u0 (map-get? redeem-shares-per-cycle reward-cycle)))

(define-read-only (get-redeem-tokens-per-cycle-or-default (reward-cycle uint))
  (default-to u0 (map-get? redeem-tokens-per-cycle reward-cycle)))

(define-read-only (get-redeem-request-or-fail (request-id uint))
  (ok (unwrap! (map-get? redeem-requests request-id) ERR-REQUEST-ID-NOT-FOUND)))

;; governance calls

(define-public (set-start-cycle (new-start-cycle uint))
  (begin 
    (try! (check-is-owner))
    (map-set staked-cycle new-start-cycle true)
    (var-set start-cycle new-start-cycle)
    (ok true)
  )
)

(define-public (set-end-cycle (new-end-cycle uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set end-cycle new-end-cycle))
  )
)

(define-public (set-staked-cycle (cycle uint) (staked bool))
  (begin 
    (try! (check-is-owner))
    (ok (map-set staked-cycle cycle staked))
  )
)

(define-public (pause-create (pause bool))
  (begin 
    (try! (check-is-owner))
    (ok (var-set create-paused pause))
  )
)

(define-public (pause-redeem (pause bool))
  (begin 
    (try! (check-is-owner))
    (ok (var-set redeem-paused pause))
  )
)

;; public functions
;;   

;; @desc add to position
;; @desc transfers dx to vault, stake them for 32 cycles and mints auto-alex-v3, the number of which is determined as % of total supply / next base
;; @param dx the number of $ALEX in 8-digit fixed point notation
(define-public (add-to-position (dx uint))
  (let
    (            
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
    )
    (asserts! (> (var-get end-cycle) current-cycle) ERR-STAKING-NOT-AVAILABLE)
    (asserts! (<= (var-get start-cycle) current-cycle) ERR-NOT-ACTIVATED)        
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    (asserts! (not (is-create-paused)) ERR-PAUSED)
    (and (> current-cycle (var-get start-cycle)) (not (is-cycle-staked (- current-cycle u1))) (try! (claim-and-stake (- current-cycle u1))))
    
    (let
      (
        (sender tx-sender)
        (cycles-to-stake (if (> (var-get end-cycle) (+ current-cycle u32)) u32 (- (var-get end-cycle) current-cycle)))
        (new-supply (try! (get-tokens-to-shares dx)))        
      )
      ;; transfer dx to contract to stake for max cycles
      (try! (contract-call? .age000-governance-token transfer-fixed dx sender (as-contract tx-sender) none))
      (as-contract (try! (stake-tokens dx cycles-to-stake)))
        
      ;; mint pool token and send to tx-sender
	    (try! (ft-mint? auto-alex-v3 (fixed-to-decimals new-supply) sender))
      (print { object: "pool", action: "position-added", data: new-supply })
      (ok true)
    )
  )
)

;; claims alex for the reward-cycles and mint auto-alex-v3
(define-public (claim-and-mint (reward-cycles (list 200 uint)))
  (let 
    (
      (claimed (unwrap-panic (contract-call? .staking-helper claim-staking-reward .age000-governance-token reward-cycles)))
    )
    (try! (add-to-position (fold sum-claimed claimed u0)))
    (ok claimed)
  )
)

;; @desc triggers external event that claims all that's available and stake for another 32 cycles
;; @desc this can be triggered by anyone
;; @param reward-cycle the target cycle to claim (and stake for current cycle + 32 cycles). reward-cycle must be < current cycle.
(define-public (claim-and-stake (reward-cycle uint))
  (let 
    (      
      ;; claim all that's available to claim for the reward-cycle
      (claimed (and (> (as-contract (get-user-id)) u0) (is-ok (as-contract (claim-staking-reward reward-cycle)))))
      (tokens (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))      
      (cycles-to-stake (if (>= (var-get end-cycle) (+ current-cycle u32)) u32 (- (var-get end-cycle) current-cycle)))
      (redeem-tokens (try! (get-shares-to-tokens (get-redeem-shares-per-cycle-or-default reward-cycle))))
      (sender tx-sender)
    )
    (asserts! (> current-cycle reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (>= (var-get end-cycle) current-cycle) ERR-STAKING-NOT-AVAILABLE)
    (and (> cycles-to-stake u0) (as-contract (try! (stake-tokens (- tokens redeem-tokens) cycles-to-stake))))
    (map-set redeem-tokens-per-cycle reward-cycle redeem-tokens)
    (map-set staked-cycle reward-cycle true)
    (ok true)
  )
)

(define-public (request-redeem (amount uint))
  (let 
    (
      (request-id (var-get redeem-request-nonce))
      (redeem-cycle (+ (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE) u32))
    )
    (asserts! (not (is-redeem-paused)) ERR-PAUSED)
    (try! (transfer-fixed amount tx-sender (as-contract tx-sender) none))
    (map-set redeem-requests request-id { requested-by: tx-sender, shares: amount, redeem-cycle: redeem-cycle, status: PENDING })
    (map-set redeem-shares-per-cycle redeem-cycle (+ (get-redeem-shares-per-cycle-or-default redeem-cycle) amount))
    (var-set redeem-request-nonce (+ request-id u1))
    (ok true)))

(define-public (finalize-redeem (request-id uint))
  (let 
    (
      (request-details (try! (get-redeem-request-or-fail request-id)))
      (check-staked (asserts! (is-cycle-staked (get redeem-cycle request-details)) ERR-REWARD-CYCLE-NOT-COMPLETED))
      (redeem-cycle (get redeem-cycle request-details))
      (redeem-tokens (div-down (mul-down (get shares request-details) (get-redeem-tokens-per-cycle-or-default redeem-cycle)) (get-redeem-shares-per-cycle-or-default redeem-cycle)))
    )
    (asserts! (not (is-redeem-paused)) ERR-PAUSED) 
    (asserts! (is-eq PENDING (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    (as-contract (try! (contract-call? .age000-governance-token transfer-fixed redeem-tokens tx-sender (get requested-by request-details) none)))
    (try! (ft-burn? auto-alex-v3 (get shares request-details) (as-contract tx-sender)))
    (map-set redeem-requests request-id (merge request-details { status: FINALIZED }))
    (ok true)
  )
)

(define-public (revoke-redeem (request-id uint))
  (let 
    (
      (request-details (try! (get-redeem-request-or-fail request-id)))
    )
    (asserts! (is-eq tx-sender (get requested-by request-details)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-cycle-staked (get redeem-cycle request-details))) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (is-eq PENDING (get status request-details)) ERR-REQUEST-FINALIZED-OR-REVOKED)
    (as-contract (try! (transfer-fixed (get shares request-details) tx-sender (get requested-by request-details) none)))
    (map-set redeem-requests request-id (merge request-details { status: REVOKED }))
    (ok true)    
  )
)

;; private functions
;;
(define-private (sum-claimed (claimed-response (response (tuple (entitled-token uint) (to-return uint)) uint)) (sum-so-far uint))
  (match claimed-response
    claimed (+ sum-so-far (get to-return claimed) (get entitled-token claimed))
    err sum-so-far
  )
)

(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .age000-governance-token (get-user-id) reward-cycle)
)
(define-private (get-staker-at-cycle (reward-cycle uint))
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
(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .age000-governance-token reward-cycle)
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
