(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorized (err u1000))

(define-data-var contract-owner principal tx-sender)
(define-data-var sponsored-fee uint u0)

;; read-only calls

(define-read-only (get-sponsored-fee)
    (var-get sponsored-fee))

;; governance calls

(define-public (set-sponsored-fee (fee uint))
    (begin 
        (try! (check-is-owner))
        (ok (var-set sponsored-fee fee))))

;; sponsored / public calls

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (pool-owner principal) (dx uint) (dy uint) (fee (optional uint))) 
    (begin
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 create-pool token-x-trait token-y-trait factor pool-owner dx dy)))

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dx uint) (max-dy (optional uint)) (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 add-to-position token-x-trait token-y-trait factor dx max-dy)))

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (percent uint) (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 reduce-position token-x-trait token-y-trait factor percent)))

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dx uint) (min-dy (optional uint)) (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 swap-helper token-x-trait token-y-trait factor dx min-dy)))

(define-public (swap-helper-a (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-x uint) (factor-y uint) (dx uint) (min-dz (optional uint)) (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 swap-helper-a token-x-trait token-y-trait token-z-trait factor-x factor-y dx min-dz)))

(define-public (swap-helper-b 
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) 
    (factor-x uint) (factor-y uint) (factor-z uint)
    (dx uint) (min-dw (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 swap-helper-b token-x-trait token-y-trait token-z-trait token-w-trait factor-x factor-y factor-z dx min-dw)))

(define-public (swap-helper-c
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) (token-v-trait <ft-trait>)
    (factor-x uint) (factor-y uint) (factor-z uint) (factor-w uint)
    (dx uint) (min-dv (optional uint))
    (fee (optional uint)))
    (begin 
        (try! (pay-to-sponsor fee))
        (contract-call? .amm-swap-pool-v1-1 swap-helper-c token-x-trait token-y-trait token-z-trait token-w-trait token-v-trait factor-x factor-y factor-z factor-w dx min-dv)))

;; private calls

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized)))

(define-private (pay-to-sponsor (fee (optional uint)))
    (match tx-sponsor? 
        sponsor 
        (let (
            (fee-floored (match fee some-value (max some-value (var-get sponsored-fee)) (var-get sponsored-fee))))
            (ok (and (> fee-floored u0) (try! (contract-call? .token-abtc transfer-fixed fee-floored tx-sender sponsor none))))) 
        (ok false)))

(define-private (min (a uint) (b uint))
    (if (> a b) b a))

(define-private (max (a uint) (b uint))
    (if (<= a b) b a))