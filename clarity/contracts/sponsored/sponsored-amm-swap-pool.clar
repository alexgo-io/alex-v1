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

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (percent uint))
    (begin 
        (try! (pay-to-sponsor))
        (contract-call? .amm-swap-pool reduce-position token-x-trait token-y-trait factor percent)))

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dx uint) (min-dy (optional uint)))
    (begin 
        (try! (pay-to-sponsor))
        (contract-call? .amm-swap-pool swap-helper token-x-trait token-y-trait factor dx min-dy)))

(define-public (swap-helper-a (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-x uint) (factor-y uint) (dx uint) (min-dz (optional uint)))
    (begin 
        (try! (pay-to-sponsor))
        (contract-call? .amm-swap-pool swap-helper-a token-x-trait token-y-trait token-z-trait factor-x factor-y dx min-dz)))

(define-public (swap-helper-b 
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) 
    (factor-x uint) (factor-y uint) (factor-z uint)
    (dx uint) (min-dw (optional uint)))
    (begin 
        (try! (pay-to-sponsor))
        (contract-call? .amm-swap-pool swap-helper-b token-x-trait token-y-trait token-z-trait token-w-trait factor-x factor-y factor-z dx min-dw)))

(define-public (swap-helper-c
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) (token-v-trait <ft-trait>)
    (factor-x uint) (factor-y uint) (factor-z uint) (factor-w uint)
    (dx uint) (min-dv (optional uint)))
    (begin 
        (try! (pay-to-sponsor))
        (contract-call? .amm-swap-pool swap-helper-c token-x-trait token-y-trait token-z-trait token-w-trait token-v-trait factor-x factor-y factor-z factor-w dx min-dv)
    )
)

;; private calls

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized))
)

(define-private (pay-to-sponsor)
    (match tx-sponsor? sponsor (contract-call? .token-abtc transfer-fixed (var-get sponsored-fee) tx-sender sponsor none) (ok false))
)