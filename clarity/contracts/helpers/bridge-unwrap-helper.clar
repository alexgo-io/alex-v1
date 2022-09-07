(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-AUTHORIZED (err u1001))
(define-constant ERR-RECIPIENT-NOT-AUTHORIZED (err u1002))
(define-constant ERR-CHAIN-NOT-AUTHORIZED (err u1003))

(define-data-var contract-owner principal tx-sender)
(define-map approved-tokens principal bool)
(define-map approved-recipients principal bool)
(define-data-var chain-nonce uint u0)
(define-map approved-chains uint { name: (string-utf8 256), approved: bool, buff-length: uint })

(define-read-only (get-approved-chain-or-fail (chain-id uint))
  (ok (unwrap! (map-get? approved-chains chain-id) ERR-CHAIN-NOT-AUTHORIZED))
)

(define-public (set-approved-chain (chain-details { name: (string-utf8 256), approved: bool, buff-length: uint })))

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

(define-public (set-approved-recipient (recipient principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-recipients recipient approved))
	)
)

(define-private (check-is-approved-recipient (recipient principal))
  (ok (asserts! (default-to false (map-get? approved-recipients recipient)) ERR-RECIPIENT-NOT-AUTHORIZED))
)

(define-public (transfer-to-settle (token-trait <ft-trait>) (amount-in-fixed uint) (recipient principal) (to-settle (buff 40)))
    (begin 
        (try! (check-is-approved-token (contract-of token-trait)))
        (try! (check-is-approved-recipient recipient))
        (try! (contract-call? token-trait transfer-fixed amount-in-fixed tx-sender recipient none))
        (ok to-settle)
    )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)