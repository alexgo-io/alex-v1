(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-semi-fungible.semi-fungible-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-INVALID-BALANCE (err u2008))

(define-fungible-token auto-farm)
(define-map token-balances {token-id: uint, owner: principal} uint)
(define-map token-supplies uint uint)
(define-map token-owned principal (list 200 uint))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

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

(define-private (check-is-approved (sender principal))
  (ok (asserts! (or (default-to false (map-get? approved-contracts sender)) (is-eq sender (var-get contract-owner))) ERR-NOT-AUTHORIZED))
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

(define-read-only (get-token-owned (owner principal))
    (default-to (list) (map-get? token-owned owner))
)

(define-private (set-balance (token-id uint) (balance uint) (owner principal))
    (begin
		(and 
			(is-none (index-of (get-token-owned owner) token-id))
			(map-set token-owned owner (unwrap! (as-max-len? (append (get-token-owned owner) token-id) u200) ERR-TOO-MANY-POOLS))
		)	
	    (map-set token-balances {token-id: token-id, owner: owner} balance)
        (ok true)
    )
)

(define-private (get-balance-or-default (token-id uint) (who principal))
	(default-to u0 (map-get? token-balances {token-id: token-id, owner: who}))
)

(define-read-only (get-balance (token-id uint) (who principal))
	(ok (get-balance-or-default token-id who))
)

(define-read-only (get-overall-balance (who principal))
	(ok (ft-get-balance auto-farm who))
)

(define-read-only (get-total-supply (token-id uint))
	(ok (default-to u0 (map-get? token-supplies token-id)))
)

(define-read-only (get-overall-supply)
	(ok (ft-get-supply auto-farm))
)

(define-read-only (get-decimals (token-id uint))
  	(ok u8)
)

(define-read-only (get-token-uri (token-id uint))
	(ok none)
)

(define-public (transfer (token-id uint) (amount uint) (sender principal) (recipient principal))
	(let
		(
			(sender-balance (get-balance-or-default token-id sender))
		)
		(asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
		(asserts! (<= amount sender-balance) ERR-INVALID-BALANCE)
		(try! (ft-transfer? auto-farm amount sender recipient))
		(try! (set-balance token-id (- sender-balance amount) sender))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(print {type: "sft_transfer_event", token-id: token-id, amount: amount, sender: sender, recipient: recipient})
		(ok true)
	)
)

(define-public (transfer-memo (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
	(let
		(
			(sender-balance (get-balance-or-default token-id sender))
		)
		(asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
		(asserts! (<= amount sender-balance) ERR-INVALID-BALANCE)
		(try! (ft-transfer? auto-farm amount sender recipient))
		(try! (set-balance token-id (- sender-balance amount) sender))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(print {type: "sft_transfer_event", token-id: token-id, amount: amount, sender: sender, recipient: recipient, memo: memo})
		(ok true)
	)
)

(define-public (mint (token-id uint) (amount uint) (recipient principal))
	(begin
		(try! (check-is-approved tx-sender))
		(try! (ft-mint? auto-farm amount recipient))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(map-set token-supplies token-id (+ (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_mint_event", token-id: token-id, amount: amount, recipient: recipient})
		(ok true)
	)
)

(define-public (burn (token-id uint) (amount uint) (sender principal))
	(begin
		(try! (check-is-approved tx-sender))
		(try! (ft-burn? auto-farm amount sender))
		(try! (set-balance token-id (- (get-balance-or-default token-id sender) amount) sender))
		(map-set token-supplies token-id (- (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_burn_event", token-id: token-id, amount: amount, sender: sender})
		(ok true)
	)
)

(define-constant ONE_8 u100000000)

(define-private (pow-decimals)
  	(pow u10 (unwrap-panic (get-decimals u0)))
)

(define-read-only (fixed-to-decimals (amount uint))
  	(/ (* amount (pow-decimals)) ONE_8)
)

(define-private (decimals-to-fixed (amount uint))
  	(/ (* amount ONE_8) (pow-decimals))
)

(define-read-only (get-total-supply-fixed (token-id uint))
  	(ok (decimals-to-fixed (default-to u0 (map-get? token-supplies token-id))))
)

(define-read-only (get-balance-fixed (token-id uint) (who principal))
  	(ok (decimals-to-fixed (get-balance-or-default token-id who)))
)

(define-read-only (get-overall-supply-fixed)
	(ok (decimals-to-fixed (ft-get-supply auto-farm)))
)

(define-read-only (get-overall-balance-fixed (who principal))
	(ok (decimals-to-fixed (ft-get-balance auto-farm who)))
)

(define-public (transfer-fixed (token-id uint) (amount uint) (sender principal) (recipient principal))
  	(transfer token-id (fixed-to-decimals amount) sender recipient)
)

(define-public (transfer-memo-fixed (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
  	(transfer-memo token-id (fixed-to-decimals amount) sender recipient memo)
)

(define-public (mint-fixed (token-id uint) (amount uint) (recipient principal))
  	(mint token-id (fixed-to-decimals amount) recipient)
)

(define-public (burn-fixed (token-id uint) (amount uint) (sender principal))
  	(burn token-id (fixed-to-decimals amount) sender)
)

(define-private (transfer-many-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer (get token-id item) (get amount item) (get sender item) (get recipient item)) prev-err previous-response)
)

(define-public (transfer-many (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal})))
	(fold transfer-many-iter transfers (ok true))
)

(define-private (transfer-many-memo-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer-memo (get token-id item) (get amount item) (get sender item) (get recipient item) (get memo item)) prev-err previous-response)
)

(define-public (transfer-many-memo (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)})))
	(fold transfer-many-memo-iter transfers (ok true))
)

(define-private (transfer-many-fixed-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer-fixed (get token-id item) (get amount item) (get sender item) (get recipient item)) prev-err previous-response)
)

(define-public (transfer-many-fixed (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal})))
	(fold transfer-many-fixed-iter transfers (ok true))
)

(define-private (transfer-many-memo-fixed-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer-memo-fixed (get token-id item) (get amount item) (get sender item) (get recipient item) (get memo item)) prev-err previous-response)
)

(define-public (transfer-many-memo-fixed (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)})))
	(fold transfer-many-memo-fixed-iter transfers (ok true))
)

(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; yield vault
;; DOES NOT WORK DUE TO alex-reserve-pool requiring 1 principal <> user-id

;; constants
;;

(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-ACTIVATED (err u2044))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2045))

;; data maps and vars
;;

(define-data-var nonce uint u0)
(define-map total-supply principal uint)
(define-map token-nonce principal uint)
(define-map activated principal bool)
(define-map bounty-in-fixed principal uint)  

(define-public (add-token (token principal))
  (let 
    (
      (new-nonce (+ (var-get nonce) u1))
    ) 
    (try! (check-is-owner))
    (map-set token-nonce token new-nonce)
    (map-set activated token false)
    (ok (var-set nonce new-nonce))
  )
)

(define-read-only (get-bounty-in-fixed-or-default (token principal))
  (default-to u0 (map-get? bounty-in-fixed token))
)

(define-public (set-bounty-in-fixed (token principal) (new-bounty-in-fixed uint))
  (begin 
    (try! (check-is-owner))
    (ok (map-set bounty-in-fixed token new-bounty-in-fixed))
  )
)

(define-read-only (get-nonce-or-default (token principal))
  (default-to u0 (map-get? token-nonce token))
)

(define-read-only (get-activated-or-default (token principal))
  (default-to false (map-get? activated token))
)

(define-public (set-activated (token principal) (new-activated bool))
  (begin
    (try! (check-is-owner))
    (ok (map-set activated token new-activated))
  )
)

(define-read-only (get-total-supply-or-default (token principal))
  (default-to u0 (map-get? total-supply token))
)

;; private functions
;;
(define-private (get-staking-reward (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward token (get-user-id token) reward-cycle)
)
(define-private (get-staker-at-cycle (token principal) (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default token reward-cycle (get-user-id token))
)
(define-private (get-user-id (token principal))
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id token tx-sender))
)
(define-private (get-reward-cycle (token principal) (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle token stack-height)
)
(define-private (stake-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period)
)
(define-private (claim-staking-reward (token-trait <ft-trait>) (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward token-trait reward-cycle)
)

;; public functions
;;   

;; @desc get the next capital base of the vault
;; @desc next-base = principal to be staked at the next cycle 
;; @desc           + principal to be claimed at the next cycle and staked for the following cycle
;; @desc           + reward to be claimed at the next cycle and staked for the following cycle
(define-read-only (get-next-base (token principal))
  (let 
    (
      (current-cycle (unwrap! (get-reward-cycle token block-height) ERR-STAKING-NOT-AVAILABLE))
      (principal 
        (+ 
          (get amount-staked (as-contract (get-staker-at-cycle token (+ current-cycle u1)))) 
          (get to-return (as-contract (get-staker-at-cycle token current-cycle)))
        )
      )
      (rewards 
        (+ 
          (as-contract (get-staking-reward token current-cycle))
          (get amount-staked (as-contract (get-staker-at-cycle .age000-governance-token (+ current-cycle u1)))) 
          (get to-return (as-contract (get-staker-at-cycle .age000-governance-token current-cycle)))
          (as-contract (get-staking-reward .age000-governance-token current-cycle))
        )
      )
    )
    (ok { principal: principal, rewards: rewards })
  )
)

;; @desc get the intrinsic value of auto-alex
;; @desc intrinsic = next capital base of the vault / total supply of auto-alex
(define-read-only (get-intrinsic (token principal))
  (let 
    (
      (next-base (try! (get-next-base token)))
      (current-supply (get-total-supply-or-default token))
    )
    (ok { principal: (div-down (get principal next-base) current-supply), rewards: (div-down (get rewards next-base) current-supply) })
  )  
)

(define-read-only (get-token-given-position (token principal) (dx uint))
  (let 
    (
      (next-base (try! (get-next-base token)))
      (current-supply (get-total-supply-or-default token))
    )
    (ok 
      (if (is-eq u0 current-supply)
        { token: dx, rewards: u0 }
        { 
          token: (div-down (mul-down current-supply dx) (get principal next-base)), 
          rewards: (div-down (mul-down (get rewards next-base) dx) (get principal next-base))
        }
      )
    )
  )
)

(define-read-only (is-cycle-bountiable (token principal) (reward-cycle uint))
  (> (as-contract (get-staking-reward token reward-cycle)) (get-bounty-in-fixed-or-default token))
)

;; @desc add to position
;; @desc transfers dx to vault, stake them for 32 cycles and mints auto-alex, the number of which is determined as % of total supply / next base
;; @param dx the number of $ALEX in 8-digit fixed point notation
(define-public (add-to-position (token-trait <ft-trait>) (dx uint))
  (let
    (
      (token (contract-of token-trait))
      (new-supply (try! (get-token-given-position token dx)))
      (new-total-supply (+ (get-total-supply-or-default token) (get token new-supply)))
      (sender tx-sender)
	  (token-id (get-nonce-or-default token))
    )
    (asserts! (get-activated-or-default token) ERR-NOT-ACTIVATED)
    (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
    
    ;; transfer dx to contract to stake for max cycles
    (try! (contract-call? token-trait transfer-fixed dx sender (as-contract tx-sender) none))
    (as-contract (try! (stake-tokens token-trait dx u32)))

    (and 
      (> (get rewards new-supply) u0) 
      (try! (contract-call? .age000-governance-token transfer-fixed (get rewards new-supply) sender (as-contract tx-sender) none))
      (as-contract (try! (stake-tokens .age000-governance-token (get rewards new-supply) u32)))
    )
        
    ;; mint pool token and send to tx-sender
    (map-set total-supply token new-total-supply)
	(try! (ft-mint? auto-farm (fixed-to-decimals (get token new-supply)) sender))
	(try! (set-balance token-id (+ (get-balance-or-default token-id sender) (get token new-supply)) sender))
	(map-set token-supplies token-id (+ (unwrap-panic (get-total-supply token-id)) (get token new-supply)))
	(print {type: "sft_mint_event", token-id: token-id, amount: (get token new-supply), recipient: sender})	
    (print { object: "pool", action: "position-added", data: { new-supply: (get token new-supply), total-supply: new-total-supply }})
    (ok true)
  )
)

;; @desc triggers external event that claims all that's available and stake for another 32 cycles
;; @desc this can be triggered by anyone at a fee (at the moment 0.1% of whatever is claimed)
;; @param reward-cycle the target cycle to claim (and stake for current cycle + 32 cycles). reward-cycle must be < current cycle.
(define-public (claim-and-stake (token-trait <ft-trait>) (reward-cycle uint))
  (let 
    (
      (token (contract-of token-trait))
      (sender tx-sender)
      ;; claim all that's available to claim for the reward-cycle
      (claimed (and (> (as-contract (get-user-id token)) u0) (is-ok (as-contract (claim-staking-reward token-trait reward-cycle)))))
      (alex-claimed (and (> (as-contract (get-user-id .age000-governance-token)) u0) (is-ok (as-contract (claim-staking-reward .age000-governance-token reward-cycle)))))
      (alex-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (principal-balance (unwrap! (contract-call? token-trait get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (bounty (get-bounty-in-fixed-or-default token))
    )
    (asserts! (get-activated-or-default token) ERR-NOT-ACTIVATED)
    (asserts! (> (unwrap! (get-reward-cycle token block-height) ERR-STAKING-NOT-AVAILABLE) reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (> alex-balance bounty) ERR-INSUFFICIENT-BALANCE)
    (and 
      (> principal-balance u0)
      (as-contract (try! (stake-tokens token-trait principal-balance u32)))
    )
    (and     
      (as-contract (try! (stake-tokens .age000-governance-token (- alex-balance bounty) u32)))
      (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none)))
    )
    
    (ok true)
  )
)


(define-public (reduce-position (token-trait <ft-trait>))
  (let 
    (
      (token (contract-of token-trait))
      (sender tx-sender)
      (current-cycle (unwrap! (get-reward-cycle token block-height) ERR-STAKING-NOT-AVAILABLE))
      (current-supply (get-total-supply-or-default token))
      ;; claim last cycle just in case claim-and-stake has not yet been triggered    
      (claimed (as-contract (try! (claim-staking-reward token-trait (- current-cycle u1)))))
      (alex-claimed (as-contract (try! (claim-staking-reward .age000-governance-token (- current-cycle u1)))))
      (alex-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (principal-balance (unwrap! (contract-call? token-trait get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (reduce-supply (unwrap! (get-balance-fixed (get-nonce-or-default token) sender) ERR-GET-BALANCE-FIXED-FAIL))
      (reduce-principal-balance (div-down (mul-down principal-balance reduce-supply) current-supply))
      (reduce-alex-balance (div-down (mul-down alex-balance reduce-supply) current-supply))
      (reduce-total-supply (- (get-total-supply-or-default token) reduce-supply))
	  (token-id (get-nonce-or-default token))
    )
    ;; only if de-activated
    (asserts! (not (get-activated-or-default token)) ERR-ACTIVATED)
    ;; only if no staking positions
    (asserts! (is-eq u0 (get amount-staked (as-contract (get-staker-at-cycle token current-cycle)))) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (is-eq u0 (get amount-staked (as-contract (get-staker-at-cycle .age000-governance-token current-cycle)))) ERR-REWARD-CYCLE-NOT-COMPLETED)
    ;; transfer relevant balance to sender
    (as-contract (try! (contract-call? .age000-governance-token transfer-fixed reduce-alex-balance tx-sender sender none)))
    (as-contract (try! (contract-call? token-trait transfer-fixed reduce-principal-balance tx-sender sender none)))
    
    ;; burn pool token
    (map-set total-supply token reduce-total-supply)
	(try! (ft-burn? auto-farm (fixed-to-decimals reduce-supply) sender))
	(try! (set-balance token-id (- (get-balance-or-default token-id sender) reduce-supply) sender))
	(map-set token-supplies token-id (- (unwrap-panic (get-total-supply token-id)) reduce-supply))
	(print {type: "sft_burn_event", token-id: token-id, amount: reduce-supply, sender: sender})
    (print { object: "pool", action: "position-removed", data: { reduce-supply: reduce-supply, total-supply: reduce-total-supply }})
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
;; (contract-call? .alex-vault add-approved-token .auto-farm)