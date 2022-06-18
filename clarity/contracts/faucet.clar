(impl-trait .trait-ownable.ownable-trait)

;; faucet

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-EXCEEDS-MAX-USE (err u9000))

(define-constant ONE_8 u100000000)
(define-constant STX-AMOUNT ONE_8)
(define-constant ALEX-AMOUNT ONE_8)

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-map users principal uint)
(define-data-var max-use uint u1)

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

(define-public (get-some-tokens (recipient principal))
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
        (as-contract (try! (contract-call? .token-wstx transfer STX-AMOUNT tx-sender recipient none)))
        (as-contract (try! (contract-call? .age000-governance-token transfer ALEX-AMOUNT tx-sender recipient none)))
        (ok true)
    )
)

(define-public (get-some-tokens-many (recipients (list 200 principal)))
    (ok (map get-some-tokens recipients))
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

