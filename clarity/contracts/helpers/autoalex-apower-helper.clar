(impl-trait .trait-ownable.ownable-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 (pow u10 u8))

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

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
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

(define-private (set-recipient-amount-iter (recipient {recipient: principal, ratio: uint}) (prior {recipient-amount: (list 200 {recipient: principal, amount: uint}), apower-balance: uint}))
	{recipient-amount: (unwrap-panic (as-max-len? (append (get recipient-amount prior) {recipient: (get recipient recipient), amount: (mul-down (get apower-balance prior) (get ratio recipient))}) u200)), apower-balance: (get apower-balance prior)}
)

(define-public (mint-apower (recipients (list 200 {recipient: principal, ratio: uint})))
	(begin 
		(asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-approved))) ERR-NOT-AUTHORIZED)		
		(as-contract 
      (contract-call? .token-apower mint-fixed-many 
        (get recipient-amount 
          (fold set-recipient-amount-iter 
            recipients 
            {recipient-amount: (list), apower-balance: (unwrap-panic (contract-call? .token-apower get-balance-fixed .auto-alex))}
          )
        )
      )
    )
	)
)

(define-public (burn-apower)
	(begin 
		(asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-approved))) ERR-NOT-AUTHORIZED)
		(as-contract (contract-call? .token-apower burn-fixed (unwrap-panic (contract-call? .token-apower get-balance-fixed .auto-alex)) .auto-alex))
	)
)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

