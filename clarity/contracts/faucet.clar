(impl-trait .trait-ownable.ownable-trait)

;; faucet

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-USDA-TRANSFER-FAILED (err u9001))
(define-constant ERR-WBTC-TRANSFER-FAILED (err u9002))
(define-constant ERR-STX-TRANSFER-FAILED (err u9003))
(define-constant ERR-ALEX-TRANSFER-FAILED (err u9004))
(define-constant ERR-EXCEEDS-MAX-USE (err u9000))

(define-data-var CONTRACT-OWNER principal tx-sender)
(define-constant ONE_8 (pow u10 u8))

(define-data-var usda-amount uint u0)
(define-data-var wbtc-amount uint u0)
(define-data-var stx-amount uint u0)
(define-data-var alex-amount uint u0)

;; save faucet users and no. of times the user used faucet
(define-map users principal uint)

;; default max-use is once
(define-data-var max-use uint u1)

(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

(define-read-only (get-max-use)
    (ok (var-get max-use))
)

(define-public (set-max-use (amount uint))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (ok (var-set max-use amount))
    )
)

;; returns (some uint) or none
(define-read-only (get-user-use (user principal))
  (map-get? users user)
)

(define-read-only (get-usda-amount)
    (ok (var-get usda-amount))
)

(define-read-only (get-wbtc-amount)
    (ok (var-get wbtc-amount))
)

(define-read-only (get-stx-amount)
    (ok (var-get stx-amount))
)

(define-read-only (get-alex-amount)
    (ok (var-get alex-amount))
)

(define-public (set-usda-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (ok (var-set usda-amount amount))
    )
)

(define-public (set-wbtc-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (ok (var-set wbtc-amount amount))
    )
)

(define-public (set-stx-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (ok (var-set stx-amount amount))
    )
)

(define-public (set-alex-amount (amount uint))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (ok (var-set alex-amount amount))
    )
)

(define-public (get-some-tokens (recipient principal))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (match (map-get? users recipient)
            old-use
            (begin
                (asserts! (<= (+ u1 old-use) (var-get max-use)) ERR-EXCEEDS-MAX-USE)
                (map-set users recipient (+ u1 old-use))
            )
            (map-set users recipient u1)
        )
        (and (> (var-get wbtc-amount) u0) (unwrap! (contract-call? .token-wbtc mint recipient (var-get wbtc-amount)) ERR-WBTC-TRANSFER-FAILED))
        (and (> (var-get usda-amount) u0) (unwrap! (contract-call? .token-usda mint recipient (var-get usda-amount)) ERR-USDA-TRANSFER-FAILED))
        (and (> (var-get alex-amount) u0) (unwrap! (contract-call? .token-alex mint recipient (var-get alex-amount)) ERR-ALEX-TRANSFER-FAILED))
        (and (> (var-get stx-amount) u0) (unwrap! (stx-transfer? (/ (* (var-get stx-amount) (pow u10 u6)) ONE_8) tx-sender recipient) ERR-STX-TRANSFER-FAILED))
        (ok true)
    )
)

;; SEND-MANY

(define-public (send-many (recipients (list 200 principal)))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (fold check-err (map get-some-tokens recipients) (ok true))    
    )
)

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior 
        ok-value result
        err-value (err err-value)
    )
)

(define-private (mint-alex (recipient { to: principal, amount: uint }))
    (ok (and (> (get amount recipient) u0) (unwrap! (contract-call? .token-alex mint (get to recipient) (get amount recipient)) ERR-ALEX-TRANSFER-FAILED)))
)

(define-public (mint-alex-many (recipients (list 200 { to: principal, amount: uint })))
    (begin
        (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (fold check-err (map mint-alex recipients) (ok true))
    )
)

