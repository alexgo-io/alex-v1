(impl-trait .trait-ownable.ownable-trait)

;; faucet

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-EXCEEDS-MAX-USE (err u9000))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-constant ONE_8 (pow u10 u8))

(define-data-var usda-amount uint u0)
(define-data-var xbtc-amount uint u0)
(define-data-var stx-amount uint u0)
(define-data-var alex-amount uint u0)

;; save faucet users and no. of times the user used faucet
(define-map users principal uint)

;; default max-use is once
(define-data-var max-use uint u1)

;; @desc get-contract-owner
;; @returns (response principal)
(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)
;; @desc set-contract-owner
;; @restricted Contract-Owner
;; @returns (response boolean)
(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; @desc get-max-use
;; @returns (response uint)
(define-read-only (get-max-use)
    (ok (var-get max-use))
)

;; @desc set-max-use
;; @restricted Contract-Owner
;; @params amount
;; @returns (response boolean)
(define-public (set-max-use (amount uint))
    (begin
        (try! (check-is-approved tx-sender))
        (ok (var-set max-use amount))
    )
)

;; @desc get-user-use
;; @params user
;; @returns (some uint) or none
(define-read-only (get-user-use (user principal))
  (map-get? users user)
)

;; @desc get-usda-amount
;; @returns (response uint)
(define-read-only (get-usda-amount)
    (ok (var-get usda-amount))
)

;; @desc get-xbtc-amount
;; @returns (response uint)
(define-read-only (get-xbtc-amount)
    (ok (var-get xbtc-amount))
)

;; @desc get-stx-amount
;; @returns (response uint)
(define-read-only (get-stx-amount)
    (ok (var-get stx-amount))
)

;; @desc get-alex-amount
;; @returns (response uint)
(define-read-only (get-alex-amount)
    (ok (var-get alex-amount))
)

;; @desc get-usda-amount
;; @restricted Contract-Owner
;; @params amount
;; @returns (response uint)
(define-public (set-usda-amount (amount uint))
    (begin
        (try! (check-is-approved tx-sender))
        (ok (var-set usda-amount amount))
    )
)

;; @desc set-xbtc-amount
;; @restricted Contract-Owner
;; @params amount
;; @returns (response uint)
(define-public (set-xbtc-amount (amount uint))
    (begin
        (try! (check-is-approved tx-sender))
        (ok (var-set xbtc-amount amount))
    )
)

;; @desc set-stx-amount
;; @restricted Contract-Owner
;; @params amount
;; @returns (response uint)
(define-public (set-stx-amount (amount uint))
    (begin
        (try! (check-is-approved tx-sender))
        (ok (var-set stx-amount amount))
    )
)

;; desc set-alex-amount
;; @restricted Contract-Owner
;; @params amount
;; @returns (response uint)
(define-public (set-alex-amount (amount uint))
    (begin
        (try! (check-is-approved tx-sender))
        (ok (var-set alex-amount amount))
    )
)

;; @desc get-some-tokens
;; @restricted Contract-Owner
;; @params recipient
;; @returns (response boolean)
(define-public (get-some-tokens (recipient principal))
    (begin
        (asserts! (or (is-eq tx-sender recipient) (is-ok (check-is-approved tx-sender))) ERR-NOT-AUTHORIZED)
        (match (map-get? users recipient)
            old-use
            (begin
                (asserts! (<= (+ u1 old-use) (var-get max-use)) ERR-EXCEEDS-MAX-USE)
                (map-set users recipient (+ u1 old-use))
            )
            (map-set users recipient u1)
        )
        (and (> (var-get xbtc-amount) u0) (as-contract (unwrap! (contract-call? .token-xbtc mint-fixed (var-get xbtc-amount) recipient) ERR-TRANSFER-FAILED)))
        (and (> (var-get usda-amount) u0) (as-contract (unwrap! (contract-call? .token-usda mint-fixed (var-get usda-amount) recipient) ERR-TRANSFER-FAILED)))
        (and (> (var-get alex-amount) u0) (as-contract (unwrap! (contract-call? .age000-governance-token mint-fixed (var-get alex-amount) recipient) ERR-TRANSFER-FAILED)))
        (and (> (var-get stx-amount) u0) (as-contract (unwrap! (stx-transfer? (/ (* (var-get stx-amount) (pow u10 u6)) ONE_8) tx-sender recipient) ERR-TRANSFER-FAILED)))
        (ok true)
    )
)

;; SEND-MANY
;; @desc send-many
;; @restricted Contract-Owner
;; @params recipients ; list
;; @returns (response bool)
(define-public (send-many (recipients (list 200 principal)))
    (begin
        (try! (check-is-approved tx-sender))
        (fold check-err (map get-some-tokens recipients) (ok true))    
    )
)

;; @desc check-err
;; @params result 
;; @params prior
;; @returns (response bool uint)
(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior 
        ok-value result
        err-value (err err-value)
    )
)

;; @desc mint-alex
;; @params recipient; tuple
;; returns (response bool uint)
(define-private (mint-alex (recipient { to: principal, amount: uint }))
    (begin
        (and (> (get amount recipient) u0) (unwrap! (contract-call? .age000-governance-token mint-fixed (get amount recipient) (get to recipient)) ERR-TRANSFER-FAILED))
        (and (> (var-get stx-amount) u0) (as-contract (unwrap! (stx-transfer? (/ (* (var-get stx-amount) (pow u10 u6)) ONE_8) tx-sender (get to recipient)) ERR-TRANSFER-FAILED)))
        (ok true)
    )
)

;; @desc mint-alex-many
;; @params recipient; list of tuple
;; returns (bool uint)
(define-public (mint-alex-many (recipients (list 200 { to: principal, amount: uint })))
    (begin
        (try! (check-is-approved tx-sender))
        (fold check-err (map mint-alex recipients) (ok true))
    )
)

(define-private (check-is-approved (sender principal))
  (ok (asserts! (or (default-to false (map-get? approved-contracts sender)) (is-eq sender (var-get contract-owner))) ERR-NOT-AUTHORIZED))
)

(define-public (add-approved-contract (new-approved-contract principal))
  (begin
    (try! (check-is-approved tx-sender))
    (map-set approved-contracts new-approved-contract true)
    (ok true)
  )
)

