(impl-trait .sip010-ft-trait.sip010-ft-trait)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin
		(try! (stx-transfer? amount sender recipient))
		(match memo to-print (print to-print) 0x)
		(ok true)
	)
)

(define-read-only (get-name)
	(ok "WSTX")
)

(define-read-only (get-symbol)
	(ok "WSTX")
)

(define-read-only (get-decimals)
	(ok u6)
)

(define-read-only (get-balance (who principal))
	(ok (stx-get-balance who))
)

(define-read-only (get-total-supply)
	(ok u0)
)

(define-read-only (get-token-uri)
	(ok none)
)

(define-public (transfer-many-ido (amount uint) (recipients (list 200 principal)))
	(err u0)
)

