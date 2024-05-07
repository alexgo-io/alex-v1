(define-fungible-token auto-alex-v3-wrapped)

(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 u100000000)
(define-constant token-decimals u8)

(define-data-var contract-owner principal tx-sender)

(define-data-var token-name (string-ascii 32) "vLiALEX")
(define-data-var token-symbol (string-ascii 32) "vLiALEX")
(define-data-var token-uri (optional (string-utf8 256)) (some u"https://cdn.alexlab.co/metadata/auto-alex-v3-wrapped.json"))

;; governance functions

(define-public (set-contract-owner (owner principal))
	(begin
    	(try! (check-is-owner))
    	(ok (var-set contract-owner owner))))

(define-public (set-name (new-name (string-ascii 32)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-name new-name))))

(define-public (set-symbol (new-symbol (string-ascii 32)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-symbol new-symbol))))

(define-public (set-token-uri (new-uri (optional (string-utf8 256))))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-uri new-uri))))

;; public functions

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin
		(asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR-NOT-AUTHORIZED)
		(try! (ft-transfer? auto-alex-v3-wrapped amount sender recipient))
		(print { type: "transfer", amount: amount, sender: sender, recipient: recipient, memo: memo })
		(ok true)))

(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (transfer amount sender recipient memo))

(define-public (mint (amount uint) (recipient principal))
	(begin 
		(asserts! (or (is-eq tx-sender recipient) (is-eq contract-caller recipient)) ERR-NOT-AUTHORIZED)				
		(try! (ft-mint? auto-alex-v3-wrapped (get-tokens-to-shares amount) recipient))
		(contract-call? .auto-alex-v3-2 transfer amount recipient (as-contract tx-sender) none)))

(define-public (mint-fixed (amount uint) (recipient principal))
    (mint amount recipient))

(define-public (burn (amount uint) (sender principal))
	(begin
		(asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR-NOT-AUTHORIZED)
		(as-contract (try! (contract-call? .auto-alex-v3-2 transfer (get-shares-to-tokens amount) tx-sender sender none)))
		(ft-burn? auto-alex-v3-wrapped amount sender)))

(define-public (burn-fixed (amount uint) (sender principal))
    (burn amount sender))

;; read-only functions

(define-read-only (get-contract-owner)
  (var-get contract-owner))
	
(define-read-only (get-name)
	(ok (var-get token-name)))

(define-read-only (get-symbol)
	(ok (var-get token-symbol)))

(define-read-only (get-token-uri)
	(ok (var-get token-uri)))

(define-read-only (get-decimals)
	(ok token-decimals))

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance auto-alex-v3-wrapped who)))

(define-read-only (get-balance-fixed (who principal))
	(get-balance who))

(define-read-only (get-total-supply)
	(ok (ft-get-supply auto-alex-v3-wrapped)))

(define-read-only (get-total-supply-fixed)
	(get-total-supply))

(define-read-only (get-share (who principal))
	(ok (get-shares-to-tokens (unwrap-panic (get-balance who)))))

(define-read-only (get-total-shares)
	(contract-call? .auto-alex-v3-2 get-balance (as-contract tx-sender)))

(define-read-only (get-tokens-to-shares (amount uint))
	(if (is-eq (get-total-shares) (ok u0))
		amount
		(/ (* amount (unwrap-panic (get-total-supply))) (unwrap-panic (get-total-shares)))))

(define-read-only (get-shares-to-tokens (shares uint))
	(if (is-eq (get-total-supply) (ok u0))
		shares
		(/ (* shares (unwrap-panic (get-total-shares))) (unwrap-panic (get-total-supply)))))

;; private functions

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(contract-call? .alex-vault-v1-1 set-approved-token .auto-alex-v3-2-wrapped true)