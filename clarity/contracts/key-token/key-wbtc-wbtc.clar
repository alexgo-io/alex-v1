(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-semi-fungible.semi-fungible-trait)


(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-INVALID-BALANCE (err u1001))

(define-fungible-token key-wbtc-wbtc)
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
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; @desc check-is-approved
;; @restricted Approved-Contracts/Contract-Owner
;; @params sender
;; @returns (response boolean)
(define-private (check-is-approved (sender principal))
  (ok (asserts! (or (default-to false (map-get? approved-contracts sender)) (is-eq sender (var-get contract-owner))) ERR-NOT-AUTHORIZED))
)

(define-public (add-approved-contract (new-approved-contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set approved-contracts new-approved-contract true)
    (ok true)
  )
)

;; @desc get-token-owned
;; @params owner
;; @returns list
(define-read-only (get-token-owned (owner principal))
    (default-to (list) (map-get? token-owned owner))
)

;; @desc set-balance
;; @params token-id
;; @params balance
;; @params owner
;; @returns (response true)
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

;; @desc get-balance-or-default
;; @params token-id
;; @params who
;; @returns uint
(define-private (get-balance-or-default (token-id uint) (who principal))
	(default-to u0 (map-get? token-balances {token-id: token-id, owner: who}))
)

;; @desc get-balance
;; @params token-id
;; @params who
;; @returns (response uint)
(define-read-only (get-balance (token-id uint) (who principal))
	(ok (get-balance-or-default token-id who))
)

;; @desc get-overall-balance
;; @params who
;; @returns (response uint)
(define-read-only (get-overall-balance (who principal))
	(ok (ft-get-balance key-wbtc-wbtc who))
)

;; @desc get-total-supply
;; @params token-id
;; @returns (response uint)
(define-read-only (get-total-supply (token-id uint))
	(ok (default-to u0 (map-get? token-supplies token-id)))
)

;; @desc get-overall-supply
;; @returns (response uint)
(define-read-only (get-overall-supply)
	(ok (ft-get-supply key-wbtc-wbtc))
)

;; @desc get-decimals
;; @params token-id
;; @returns (response uint)
(define-read-only (get-decimals (token-id uint))
  	(ok u8)
)

;; @desc get-token-uri 
;; @params token-id
;; @returns (response none)
(define-read-only (get-token-uri (token-id uint))
	(ok none)
)

;; @desc transfer
;; @restricted sender
;; @params token-id 
;; @params amount
;; @params sender
;; @params recipient
;; @returns (response boolean)
(define-public (transfer (token-id uint) (amount uint) (sender principal) (recipient principal))
	(let
		(
			(sender-balance (get-balance-or-default token-id sender))
		)
		(asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
		(asserts! (<= amount sender-balance) ERR-INVALID-BALANCE)
		(try! (ft-transfer? key-wbtc-wbtc amount sender recipient))
		(try! (set-balance token-id (- sender-balance amount) sender))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(print {type: "sft_transfer_event", token-id: token-id, amount: amount, sender: sender, recipient: recipient})
		(ok true)
	)
)

;; @desc transfer-memo 
;; @params token-id
;; @params amount
;; @params sender
;; @params recipient
;; @params memo ; expiry
;; @returns (response boolean)
(define-public (transfer-memo (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
	(let
		(
			(sender-balance (get-balance-or-default token-id sender))
		)
		(asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
		(asserts! (<= amount sender-balance) ERR-INVALID-BALANCE)
		(try! (ft-transfer? key-wbtc-wbtc amount sender recipient))
		(try! (set-balance token-id (- sender-balance amount) sender))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(print {type: "sft_transfer_event", token-id: token-id, amount: amount, sender: sender, recipient: recipient, memo: memo})
		(ok true)
	)
)

;; @desc mint
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response boolean)
(define-public (mint (token-id uint) (amount uint) (recipient principal))
	(begin
		(try! (check-is-approved tx-sender))
		(try! (ft-mint? key-wbtc-wbtc amount recipient))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(map-set token-supplies token-id (+ (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_mint_event", token-id: token-id, amount: amount, recipient: recipient})
		(ok true)
	)
)

;; @desc burn
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response boolean)
(define-public (burn (token-id uint) (amount uint) (sender principal))
	(begin
		(try! (check-is-approved tx-sender))
		(try! (ft-burn? key-wbtc-wbtc amount sender))
		(try! (set-balance token-id (- (get-balance-or-default token-id sender) amount) sender))
		(map-set token-supplies token-id (- (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_burn_event", token-id: token-id, amount: amount, sender: sender})
		(ok true)
	)
)

(define-constant ONE_8 (pow u10 u8))

;; @desc pow-decimals
;; @returns uint
(define-private (pow-decimals)
  	(pow u10 (unwrap-panic (get-decimals u0)))
)

;; @desc fixed-to-decimals
;; @params amount
;; @returns uint
(define-read-only (fixed-to-decimals (amount uint))
  	(/ (* amount (pow-decimals)) ONE_8)
)

;; @desc decimals-to-fixed 
;; @params amount
;; @returns uint
(define-private (decimals-to-fixed (amount uint))
  	(/ (* amount ONE_8) (pow-decimals))
)

;; @desc get-total-supply-fixed
;; @params token-id
;; @returns (response uint)
(define-read-only (get-total-supply-fixed (token-id uint))
  	(ok (decimals-to-fixed (default-to u0 (map-get? token-supplies token-id))))
)

;; @desc get-balance-fixed
;; @params token-id
;; @params who
;; @returns (response uint)
(define-read-only (get-balance-fixed (token-id uint) (who principal))
  	(ok (decimals-to-fixed (get-balance-or-default token-id who)))
)

;; @desc get-overall-supply-fixed
;; @returns (response uint)
(define-read-only (get-overall-supply-fixed)
	(ok (decimals-to-fixed (ft-get-supply key-wbtc-wbtc)))
)

;; @desc get-overall-balance-fixed
;; @params who
;; @returns (response uint)
(define-read-only (get-overall-balance-fixed (who principal))
	(ok (decimals-to-fixed (ft-get-balance key-wbtc-wbtc who)))
)

;; @desc transfer-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @params recipient
;; @returns (response boolean)
(define-public (transfer-fixed (token-id uint) (amount uint) (sender principal) (recipient principal))
  	(transfer token-id (fixed-to-decimals amount) sender recipient)
)

;; @desc transfer-memo-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @params recipient
;; @params memo ; expiry
;; @returns (response boolean)
(define-public (transfer-memo-fixed (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
  	(transfer-memo token-id (fixed-to-decimals amount) sender recipient memo)
)

;; @desc mint-fixed
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response boolean)
(define-public (mint-fixed (token-id uint) (amount uint) (recipient principal))
  	(mint token-id (fixed-to-decimals amount) recipient)
)

;; @desc burn-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response boolean)
(define-public (burn-fixed (token-id uint) (amount uint) (sender principal))
  	(burn token-id (fixed-to-decimals amount) sender)
)

(map-set approved-contracts .collateral-rebalancing-pool true)
(map-set approved-contracts .yield-collateral-rebalancing-pool true)