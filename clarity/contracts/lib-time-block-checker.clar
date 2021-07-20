;; Time locked library
;; Might be useful in future for maturity calculation

(define-constant err-beneficiary-only (err u1))
(define-constant err-maturity-not-reached (err u2))

(define-constant unlock-height-year (+ block-height u52560))
(define-data-var beneficiary principal 'SP000000000000000000002Q6VF78)

(define-public (bestow (recipient principal))
	(begin
		(asserts! (is-eq tx-sender (var-get beneficiary)) (err-beneficiary-only))
        (asserts! (>= block-height unlock-height-year) (err-maturity-not-reached))
		(ok (var-set beneficiary recipient))
	)
)

(define-public (claim)
	(begin
		(asserts! (is-eq tx-sender (var-get beneficiary)) (err-beneficiary-only))
		(asserts! (>= block-height unlock-height-year) (err-maturity-not-reached))
        ;; contract-call? corresponding token to the beneficiary
	;;	(as-contract (ft-transfer? (stx-get-balance tx-sender) tx-sender (var-get beneficiary)))
        (ok u1)
    )
)