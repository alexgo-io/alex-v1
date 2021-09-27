
;; faucet

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-STX-TRANSFER-FAILED (err u6004))

(define-constant contract-owner tx-sender)
(define-constant ONE_8 (pow u10 u8))

(define-data-var usda-amount uint u0)
(define-data-var wbtc-amount uint u0)
(define-data-var stx-amount uint u0)

(define-read-only (get-usda-amount)
    (ok (var-get usda-amount))
)

(define-read-only (get-wbtc-amount)
    (ok (var-get wbtc-amount))
)

(define-read-only (get-stx-amount)
    (ok (var-get stx-amount))
)

(define-public (set-usda-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller contract-owner) ERR-NOT-AUTHORIZED)
        (ok (var-set usda-amount amount))
    )
)

(define-public (set-wbtc-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller contract-owner) ERR-NOT-AUTHORIZED)
        (ok (var-set wbtc-amount amount))
    )
)

(define-public (set-stx-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller contract-owner) ERR-NOT-AUTHORIZED)
        (ok (var-set stx-amount amount))
    )
)

(define-public (get-some-tokens (recipient principal))
    (begin
        (asserts! (is-eq contract-caller contract-owner) ERR-NOT-AUTHORIZED)
        (try! (contract-call? .token-wbtc mint recipient (var-get wbtc-amount)))
        (try! (contract-call? .token-usda mint recipient (var-get usda-amount)))
        (unwrap! (stx-transfer? (/ (* (var-get stx-amount) (pow u10 u6)) ONE_8) tx-sender recipient) ERR-STX-TRANSFER-FAILED)
        (ok true)        
    )
)

