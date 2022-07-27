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
(define-data-var cap-ref-rewards-in-fixed uint u0)

(define-data-var min-ref-rewards-in-fixed uint u1400000) ;; 1.4% abs
(define-data-var max-ref-rewards-in-fixed uint u1800000) ;; 1.8% abs

(define-map total-lend-committed-in-fixed-per-cycle uint uint)
(define-map total-borrow-commited-in-fixed-per-cycle uint uint)

(define-map lend-commited-in-fixed-per-cycle { lender: principal, cycle: uint } uint)
(define-map borrow-commited-in-fixed { borrower: principal, cycle: uint } uint)

(define-data-var pool-close-length uint u144)

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

(define-read-only (get-leverage)
  (var-get leverage)
)

(define-public (set-leverage (new-leverage uint))
  (begin 
    (try! (check-is-owner))
    (asserts! (> new-leverage u1) ERR-INVALID-LEVERAGE)
    (var-set leverage new-leverage)
    (ok (var-set cap-ref-rewards-in-fixed (- (div-down (* ONE_8 new-leverage) (* ONE_8 (- new-leverage u1))) ONE_8)))
  )
)

(define-read-only (get-cap-ref-rewards-in-fixed)
  (var-get cap-ref-rewards-in-fixed)
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

(define-read-only (get-total-lend-committed-in-fixed-per-cycle-or-default (cycle uint))
  (default-to u340282366920938463463374607431768211455 (map-get? total-lend-commited-in-fixed-per-cycle cycle))
)

(define-read-only (get-total-borrow-committed-in-fixed-per-cycle-or-default (cycle uint))
  (default-to u340282366920938463463374607431768211455 (map-get? total-borrow-commited-in-fixed-per-cycle cycle))
)

(define-read-only (get-lend-committed-in-fixed-per-cycle-or-default (lender principal) (cycle uint))
  (default-to u0 (map-get? lend-committed-in-fixed-per-cycle { lender: lender, cycle: cycle }))
)

(define-read-only (get-borrow-committed-in-fixed-per-cycle-or-default (borrower principal) (cycle uint))
  (default-to u0 (map-get? borrow-committed-in-fixed-per-cycle { borrower: borrower, cycle: cycle }))
)

(define-read-only (get-lend-borrow-ratio-in-fixed (cycle uint))
  (mul-down (get-total-lend-commited-in-fixed-per-cycle-or-default cycle) (get-total-borrow-commited-in-fixed-per-cycle-or-default cycle))
)

(define-read-only (burn-height-to-reward-cycle (height uint))
  (let 
    (
      (pox-info (unwrap-panic (contract-call? 'SP000000000000000000002Q6VF78.pox get-pox-info)))
    )
    (/ (- height (get first-burnchain-block-height pox-info)) (get reward-cycle-length pox-info))
  )
)

(define-read-only (reward-cycle-to-burn-height (cycle uint))
  (let 
    (
      (pox-info (unwrap-panic (contract-call? 'SP000000000000000000002Q6VF78.pox get-pox-info)))
    )
    (+ (get first-burnchain-block-height pox-info) (* cycle (get reward-cycle-length pox-info)))
  )
)

(define-read-only (current-pox-reward-cycle)
  (burn-height-to-reward-cycle burn-block-height)
)

(define-read-only (get-rewards-for-lender-per-cycle (cycle uint))
  (let 
    (
      (mid-rewards (/ (+ (var-get max-ref-rewards-in-fixed) (var-get min-ref-rewards-in-fixed)) u2))
      (mul-down (get-lend-borrow-ratio cycle) mid-rewards)
    )     
  )
)

(define-read-only (is-pool-open)
  (> (- (reward-cycle-to-burn-height current-pox-reward-cycle) (var-get pool-close-length)) burn-block-height)
)

(define-public (register-lender-for-next-cycle (amount-in-fixed uint))
  (begin 
    (asserts! (is-pool-open) ERR-POOL-NOT-AVAILABLE)
    (asserts! (is-eq u0 (get-lend-committed-in-fixed-per-cycle-or-default tx-sender (+ current-pox-reward-cycle u1))) ERR-ALREADY-RESIGERED)
    (try! (contract-call? .token-wstx transfer-fixed amount-in-fixed tx-sender (as-contract tx-sender) none))
    (map-set lend-committed-in-fixed-per-cycle { lender: tx-sender, cycle: (+ current-pox-reward-cycle u1) } amount-in-fixed)
    (ok { lender: tx-sender, cycle: (+ current-pox-reward-cycle u1), amount-in-fixed: amount-in-fixed })
  )
)

(define-public (register-borrower-for-next-cycle (amount-in-fixed uint))
  (begin 
    (asserts! (is-pool-open) ERR-POOL-NOT-AVAILABLE)
    (asserts! (is-eq u0 (get-borrower-committed-in-fixed-per-cycle-or-default tx-sender (+ current-pox-reward-cycle u1))) ERR-ALREADY-RESIGERED)
    (try! (contract-call? .token-wstx transfer-fixed amount-in-fixed tx-sender (as-contract tx-sender) none))
    (map-set borrow-committed-in-fixed-per-cycle { borrower: tx-sender, cycle: (+ current-pox-reward-cycle u1) } amount-in-fixed)
    (ok { borrower: tx-sender, cycle: (+ current-pox-reward-cycle u1), amount-in-fixed: amount-in-fixed })
  )
)

(define-public (refund-lender (lender principal) (cycle uint))
  (begin 
    (asserts! (or (is-ok (check-is-approved)) (is-eq tx-sender lender) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (> current-pox-reward-cycle cycle) ERR-REFUND-NOT-AVAILABLE)    
    (asserts! (> (get-lend-borrow-ratio-in-fixed cycle) (* ONE_8 (var-get leverage))) ERR-REFUND-NOT-AVAILABLE)
    (as-contract (contract-call? .token-wstx transfer-fixed (mul-down (get-lend-commited-in-fixed-per-cycle-or-default lender cycle) (- ONE_8 (div-down (* ONE_8 (var-get leverage)) (get-lend-borrow-ratio-in-fixed cycle)))) tx-sender lender none))
  )
)

(define-public (refund-borrower (borrower principal) (cycle uint))
  (begin 
    (asserts! (or (is-ok (check-is-approved)) (is-eq tx-sender borrower) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (> current-pox-reward-cycle cycle) ERR-REFUND-NOT-AVAILABLE)    
    (asserts! (< (get-lend-borrow-ratio-in-fixed cycle) (* ONE_8 (var-get leverage))) ERR-REFUND-NOT-AVAILABLE)
    (as-contract (contract-call? .token-wstx transfer-fixed (mul-down (get-borrow-commited-in-fixed-per-cycle-or-default borrower cycle) (- ONE_8 (div-down (get-lend-borrow-ratio-in-fixed cycle) (* ONE_8 (var-get leverage))))) tx-sender borrower none))
  )
)

(define-public (pay-rewards-to-lender (lender principal))
  (begin 
    (asserts! (or (is-ok (check-is-approved)) (is-eq tx-sender lender) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-pool-open)) ERR-POOL-NOT-AVAILABLE)

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