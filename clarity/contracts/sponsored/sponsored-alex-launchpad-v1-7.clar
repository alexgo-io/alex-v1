(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorized (err u1000))

(define-data-var contract-owner principal tx-sender)
(define-data-var sponsored-fee uint u0)

;; read-only calls

(define-read-only (get-sponsored-fee)
    (var-get sponsored-fee)
)

;; governance calls

(define-public (set-sponsored-fee (fee uint))
    (begin 
        (try! (check-is-owner))
        (ok (var-set sponsored-fee fee))))

;; sponsored / public calls

(define-public (register (launch-id uint) (payment-amount uint) (payment-token-trait <ft-trait>))
    (begin
        (try! (pay-to-sponsor))
        (contract-call? .alex-launchpad-v1-7 register launch-id payment-amount payment-token-trait)))

;; private calls

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized))
)

(define-private (pay-to-sponsor)
    (match tx-sponsor? sponsor (contract-call? .token-abtc transfer-fixed (var-get sponsored-fee) tx-sender sponsor none) (ok false))
)