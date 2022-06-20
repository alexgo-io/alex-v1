(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; faucet

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-EXCEEDS-MAX-USE (err u9000))
(define-constant ERR-UNKNOWN-TOKEN (err u1001))

(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-map users principal uint)
(define-data-var max-use uint u1)

(define-map token-amounts principal uint)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-read-only (get-max-use)
    (var-get max-use)
)

(define-public (set-max-use (amount uint))
    (begin
        (try! (check-is-owner))
        (ok (var-set max-use amount))
    )
)

(define-read-only (get-users-or-default (user principal))
  (default-to u0 (map-get? users user))
)

(define-read-only (get-token-amount-or-fail (token principal))
  (ok (unwrap! (map-get? token-amounts token) ERR-UNKNOWN-TOKEN))
)

(define-public (set-token-amount (token principal) (amount uint))
  (begin 
    (try! (check-is-owner))
    (ok (map-set token-amounts token amount))
  )
)

(define-public (get-some-token (recipient principal) (token-trait <ft-trait>))
    (begin
        (try! (check-is-approved))
        (match (map-get? users recipient)
            old-use
            (begin
                (asserts! (<= (+ u1 old-use) (var-get max-use)) ERR-EXCEEDS-MAX-USE)
                (map-set users recipient (+ u1 old-use))
            )
            (map-set users recipient u1)
        )
        (as-contract (contract-call? token-trait transfer-fixed (try! (get-token-amount-or-fail (contract-of token-trait))) tx-sender recipient none))
    )
)

(define-private (get-some-token-iter (recipient principal) (token-traits (list 200 <ft-trait>)))
  (begin 
    (map 
      get-some-token 
      (list 
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient
        recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient	recipient      
      )
      token-traits
    )
    token-traits
  )
)

(define-public (get-some-tokens-many (recipients (list 200 principal)) (token-traits (list 200 <ft-trait>)))
    (ok (fold get-some-token-iter recipients token-traits))
)

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved)
  (ok (asserts! (or (default-to false (map-get? approved-contracts tx-sender)) (is-eq tx-sender (var-get contract-owner))) ERR-NOT-AUTHORIZED))
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

