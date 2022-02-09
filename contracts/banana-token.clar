(impl-trait .sip010-ft-trait.sip010-ft-trait)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))

(define-fungible-token banana-token)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin
		(asserts! (is-eq tx-sender sender) err-owner-only)
		(try! (ft-transfer? banana-token amount sender recipient))
		(match memo to-print (print to-print) 0x)
		(ok true)
	)
)

(define-read-only (get-name)
	(ok "Banana Token")
)

(define-read-only (get-symbol)
	(ok "BT")
)

(define-read-only (get-decimals)
	(ok u0)
)

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance banana-token who))
)

(define-read-only (get-total-supply)
	(ok (ft-get-supply banana-token))
)

(define-read-only (get-token-uri)
	(ok none)
)

(define-public (mint (amount uint) (recipient principal))
	(begin
		(asserts! (is-eq tx-sender contract-owner) err-owner-only)
		(ft-mint? banana-token amount recipient)
	)
)

(define-private (transfer-many-ido-iter (recipient principal) (params {amount: uint, result: (response bool uint)}))
	(begin
		(unwrap! (get result params) params)
		{amount: (get amount params), result: (ft-transfer? banana-token (get amount params) tx-sender recipient)}
	)
)

(define-public (transfer-many-ido (amount uint) (recipients (list 200 principal)))
	(get result (fold transfer-many-ido-iter recipients {amount: amount, result: (ok true)}))
)
