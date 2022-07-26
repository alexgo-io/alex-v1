(impl-trait .trait-ownable.ownable-trait)

(use-trait pool-trait .trait-stacking-pool.staking-pool-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-STACKING-POOL (err u1001))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)
(define-data-var approved-pool principal tx-sender)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
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

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

(define-public (disallow-contract-caller (caller principal))
    (begin 
        (try! (check-is-owner))
        (var-set approved-pool tx-sender)
        ;; (contract-call? 'SP000000000000000000002Q6VF78.pox disallow-contract-caller caller)
        (ok true)
    )
)

(define-public (allow-contract-caller (caller principal) (until-burn-ht (optional uint)))
    (begin 
        (try! (check-is-owner))
        (var-set approved-pool caller)
        ;; (contract-call? 'SP000000000000000000002Q6VF78.pox allow-contract-caller caller until-burn-ht)
        (ok true)
    )
)

;; (tuple (hashbytes 0xfcec7445c8c394238ee3dc8d9fc746c0e97bd9b9) (version 0x01))
(define-public (delegate-stx (pool-trait <pool-trait>) (amount-ustx uint) (delegate-to principal) (until-burn-ht (optional uint))
              (pool-pox-addr (optional (tuple (hashbytes (buff 20)) (version (buff 1)))))
              (user-pox-addr (tuple (hashbytes (buff 20)) (version (buff 1))))
              (lock-period uint))
    (begin 
        (asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-approved))) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (contract-of pool-trait) (var-get approved-pool)) ERR-STACKING-POOL)
        (contract-call? pool-trait delegate-stx  )
        (ok true)
    )

)