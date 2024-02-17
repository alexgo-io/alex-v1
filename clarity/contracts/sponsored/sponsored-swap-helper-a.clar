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

(define-public (swap-helper-v1-03 (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)) (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .swap-helper-v1-03 swap-helper token-x-trait token-y-trait dx min-dy)))

(define-public (swap-helper-to-amm-v1-1 (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-y uint) (dx uint) (min-dz (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .swap-helper-bridged-v1-1 swap-helper-to-amm token-x-trait token-y-trait token-z-trait factor-y dx min-dz)))

(define-public (swap-helper-from-amm-v1-1 (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-x uint) (dx uint) (min-dz (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .swap-helper-bridged-v1-1 swap-helper-from-amm token-x-trait token-y-trait token-z-trait factor-x dx min-dz)))

(define-public (swap-helper-to-amm (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-y uint) (dx uint) (min-dz (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .swap-helper-bridged swap-helper-to-amm token-x-trait token-y-trait token-z-trait factor-y dx min-dz)))

(define-public (swap-helper-from-amm (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-x uint) (dx uint) (min-dz (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .swap-helper-bridged swap-helper-from-amm token-x-trait token-y-trait token-z-trait factor-x dx min-dz)))

;; private calls

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized))
)

(define-private (pay-to-sponsor (fee (optional uint)))
    (match tx-sponsor? 
        sponsor 
        (let (
            (fee-floored (match fee some-value (max some-value (var-get sponsored-fee)) (var-get sponsored-fee))))
            (ok (and (> fee-floored u0) (try! (contract-call? .token-abtc transfer-fixed fee-floored tx-sender sponsor none))))) 
        (ok false)))

(define-private (max (a uint) (b uint))
    (if (<= a b) b a))
