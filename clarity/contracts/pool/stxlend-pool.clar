(impl-trait .trait-ownable.ownable-trait)

(use-trait pool-trait .trait-stacking-pool.staking-pool-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-STACKING-POOL (err u21001))
(define-constant ERR-ZERO-COMMITTED (err u21002))

(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)
(define-data-var approved-pool principal tx-sender)

(define-data-var lock-period uint u6)
(define-data-var leverage uint u10)

(define-map total-lend-committed-per-cycle uint uint)
(define-map total-borrow-commited-per-cycle uint uint)

(define-map lend-commited-per-cycle uint { lender: principal, commited: uint })
(define-map borrow-commited-per-cycle uint { borrower: principal, commited: uint })

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

(define-read-only (get-max-lend-rate-in-fixed)
  (- (div-down (* ONE_8 (var-get leverage)) (* ONE_8 (- (var-get leverage) u1))) ONE_8)
)

(define-read-only (get-lock-period)
  (var-get lock-period)
)

(define-public (set-lock-period (new-lock-period uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set lock-period new-lock-period))
  )
)

(define-read-only (get-approved-pool)
    (var-get approved-pool)
)

(define-public (set-approved-pool (pool principal))
    (begin 
        (try! (check-is-owner))
        ;; (contract-call? 'SP000000000000000000002Q6VF78.pox disallow-contract-caller (var-get approved-pool))        
        ;; (contract-call? 'SP000000000000000000002Q6VF78.pox allow-contract-caller pool none)
        (ok (var-set approved-pool pool))
    )
)


;; SPXVRSEH2BKSXAEJ00F1BY562P45D5ERPSKR4Q33.xverse-pool-v2
;; assume rewards paid to Stacks address
(define-public (delegate-stx (approved-pool-trait <pool-trait>) (cycle uint))
    (begin 
        (asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-approved))) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (contract-of approved-pool-trait) (var-get approved-pool)) ERR-STACKING-POOL)
        (asserts! (and (> (map-get? cycle total-lend-committed-per-cycle) u0) (> (map-get? cycle total-borrow-committed-per-cycle) u0)) ERR-ZERO-COMMITTED)
        ;; (contract-call? approved-pool-trait delegate-stx  )
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