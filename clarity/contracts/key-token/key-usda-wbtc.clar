(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-semi-fungible-token.semi-fungible-token-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-INVALID-BALANCE (err u2008))

(define-fungible-token key-usda-wbtc)
(define-map token-balances {token-id: uint, owner: principal} uint)
(define-map token-supplies uint uint)
(define-map token-owned principal (list 2000 uint))

(define-data-var contract-owner principal .collateral-rebalancing-pool)

(define-read-only (get-owner)
  (ok (var-get contract-owner))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)



(define-read-only (get-token-owned (owner principal))
    (default-to (list) (map-get? token-owned owner))
)

(define-private (set-balance (token-id uint) (balance uint) (owner principal))
    (begin
	    (map-set token-balances {token-id: token-id, owner: owner} balance)
        (map-set token-owned owner (unwrap! (as-max-len? (append (get-token-owned owner) token-id) u2000) ERR-TOO-MANY-POOLS))
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
	(ok (ft-get-balance key-usda-wbtc who))
)

(define-read-only (get-total-supply (token-id uint))
	(ok (default-to u0 (map-get? token-supplies token-id)))
)

(define-read-only (get-overall-supply)
	(ok (ft-get-supply key-usda-wbtc))
)

(define-read-only (get-decimals (token-id uint))
	(ok u0)
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
		(try! (ft-transfer? key-usda-wbtc amount sender recipient))
		(try! (set-balance token-id (- sender-balance amount) sender))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(print {type: "sft_transfer_event", token-id: token-id, amount: amount, sender: sender, recipient: recipient})
		(ok true)
	)
)

(define-public (transfer-memo (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
	(begin
		(try! (transfer token-id amount sender recipient))
		(print memo)
		(ok true)
	)
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

(define-public (mint (token-id uint) (amount uint) (recipient principal))
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(try! (ft-mint? key-usda-wbtc amount recipient))
		(try! (set-balance token-id (+ (get-balance-or-default token-id recipient) amount) recipient))
		(map-set token-supplies token-id (+ (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_mint_event", token-id: token-id, amount: amount, recipient: recipient})
		(ok true)
	)
)

(define-public (burn (token-id uint) (amount uint) (sender principal))
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(try! (ft-burn? key-usda-wbtc amount sender))
		(try! (set-balance token-id (- (get-balance-or-default token-id sender) amount) sender))
		(map-set token-supplies token-id (- (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_burn_event", token-id: token-id, amount: amount, sender: sender})
		(ok true)
	)
)