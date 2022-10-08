(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-AUTHORIZED (err u1001))
(define-constant ERR-SCHEDULE-NOT-FOUND (err u1002))

(define-data-var contract-owner principal tx-sender)
(define-map approved-tokens principal bool)
(define-map token-schedule 
    {
        token: principal,
        address: principal,
        block-height: uint
    }
    uint
)

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

(define-public (set-approved-token (token principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-tokens token approved))
	)
)

(define-private (check-is-approved-token (token principal))
  (ok (asserts! (default-to false (map-get? approved-tokens token)) ERR-TOKEN-NOT-AUTHORIZED))
)

(define-public (set-token-schedule (token principal) (address principal) (height uint) (amount uint))
    (begin 
        (try! (check-is-owner))
        (try! (check-is-approved-token token))
        (ok (map-set token-schedule { token: token, address: address, block-height: height } amount))    
    )
)

(define-private (set-token-schedule-iter (item { token: principal, address: principal, block-height: uint, amount: uint }))
    (set-token-schedule (get token item) (get address item) (get block-height item) (get amount item))
)

(define-public (set-token-schedule-many (items (list 200 { token: principal, address: principal, block-height: uint, amount: uint })))
    (ok (map set-token-schedule-iter items))
)

(define-read-only (get-token-schedule-or-fail (token principal) (address principal) (height uint))
    (ok (unwrap! (map-get? token-schedule { token: token, address: address, block-height: height }) ERR-SCHEDULE-NOT-FOUND))
)
