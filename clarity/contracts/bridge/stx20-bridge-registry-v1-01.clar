(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorised (err u1000))
(define-constant err-invalid-token-or-ticker (err u1001))
(define-constant err-invalid-peg-in-address (err u1002))
(define-constant err-invalid-txid (err u1003))
(define-constant err-amount-exceeds-max-len (err u1004))

(define-data-var contract-owner principal tx-sender)
(define-map approved-operators principal bool)
(define-map approved-contracts principal bool)

(define-map tx-sent { txid: (buff 32), from: principal, to: principal, ticker: (string-ascii 8), amount: uint } bool)
(define-map ticker-to-tokens (string-ascii 8) principal)
(define-map token-to-tickers principal (string-ascii 8))

;; read-only calls

(define-read-only (get-approved-operator-or-default (operator principal))
    (default-to false (map-get? approved-operators operator)))

(define-read-only (get-approved-contract-or-default (contract principal))
    (default-to false (map-get? approved-contracts contract)))

(define-read-only (get-ticker-to-token-or-fail (ticker (string-ascii 8)))
    (ok (unwrap! (map-get? ticker-to-tokens ticker) err-invalid-token-or-ticker)))

(define-read-only (get-token-to-ticker-or-fail (token principal))
    (ok (unwrap! (map-get? token-to-tickers token) err-invalid-token-or-ticker)))

(define-read-only (get-tx-sent-or-default (tx { txid: (buff 32), from: principal, to: principal, ticker: (string-ascii 8), amount: uint }))
    (default-to false (map-get? tx-sent tx)))

;; governance calls

(define-public (set-contract-owner (owner principal))
    (begin 
        (try! (check-is-owner))
        (ok (var-set contract-owner owner))))

(define-public (set-approved-operator (operator principal) (approved bool))
    (begin 
        (try! (check-is-owner))
        (ok (map-set approved-operators operator approved))))

(define-public (set-approved-contract (contract principal) (approved bool))
    (begin 
        (try! (check-is-owner))
        (ok (map-set approved-contracts contract approved))))

(define-public (set-ticker-to-token (ticker (string-ascii 8)) (token principal))
    (begin 
        (try! (check-is-owner))
        (map-set ticker-to-tokens ticker token)
        (ok (map-set token-to-tickers token ticker))))

(define-public (set-token-to-ticker (token principal) (ticker (string-ascii 8)))
    (set-ticker-to-token ticker token))

;; privileged calls

(define-public (set-tx-sent (tx { txid: (buff 32), from: principal, to: principal, ticker: (string-ascii 8), amount: uint }) (sent bool))
    (begin 
        (try! (check-is-approved))
        (ok (map-set tx-sent tx sent))))

(define-public (transfer-stx (amount uint) (recipient principal) (memo  (buff 34)))
    (begin 
        (try! (check-is-approved))
        (as-contract (stx-transfer-memo? amount tx-sender recipient memo))))

;; internal call

(define-private (check-is-owner)
    (ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorised)))

(define-private (check-is-approved)
    (ok (asserts! (or (get-approved-contract-or-default tx-sender) (is-ok (check-is-owner))) err-not-authorised)))