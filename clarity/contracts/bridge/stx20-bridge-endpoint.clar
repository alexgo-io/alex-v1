(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorised (err u1000))
(define-constant err-invalid-token-or-ticker (err u1001))
(define-constant err-invalid-peg-in-address (err u1002))
(define-constant err-invalid-txid (err u1003))
(define-constant err-amount-exceeds-max-len (err u1004))

(define-constant ONE_8 u100000000)

(define-map tx-sent (buff 32) { from: principal, to: principal, ticker: (string-ascii 8), amount: uint })
(define-data-var contract-owner principal tx-sender)
(define-map approved-operators principal bool)
(define-map ticker-to-tokens (string-ascii 8) principal)
(define-map token-to-tickers principal (string-ascii 8))

(define-read-only (get-approved-operator-or-default (operator principal))
    (default-to false (map-get? approved-operators operator)))

(define-read-only (get-ticker-to-token-or-fail (ticker (string-ascii 8)))
    (ok (unwrap! (map-get? ticker-to-tokens ticker) err-invalid-token-or-ticker)))

(define-read-only (get-token-to-ticker-or-fail (token principal))
    (ok (unwrap! (map-get? token-to-tickers token) err-invalid-token-or-ticker)))

(define-read-only (get-tx-sent-or-fail (txid (buff 32)))
    (ok (unwrap! (map-get? tx-sent txid) err-invalid-txid)))

(define-public (finalize-peg-in (txid (buff 32)) (transfer { from: principal, to: principal, ticker: (string-ascii 8), amount: uint }) (token-trait <ft-trait>))
    (begin 
        (asserts! (get-approved-operator-or-default tx-sender) err-not-authorised)
        (asserts! (is-eq (get to transfer) (as-contract tx-sender)) err-invalid-peg-in-address)
        (asserts! (is-err (get-tx-sent-or-fail txid)) err-invalid-txid)
        (asserts! (is-eq (contract-of token-trait) (try! (get-ticker-to-token-or-fail (get ticker transfer)))) err-invalid-token-or-ticker)
        (map-set tx-sent txid transfer)
        (as-contract (contract-call? token-trait mint-fixed (* (get amount transfer) ONE_8) (get from transfer)))))

(define-public (finalize-peg-out (token-trait <ft-trait>) (amount uint))
    (let (
            (sender tx-sender)
            (ticker (try! (get-token-to-ticker-or-fail (contract-of token-trait))))
            (memo (unwrap-panic (to-consensus-buff? (concat "t" (concat ticker (unwrap! (as-max-len? (int-to-ascii (/ amount ONE_8)) u20) err-amount-exceeds-max-len)))))))
        (as-contract (try! (contract-call? token-trait burn-fixed amount sender)))
        (as-contract (stx-transfer-memo? u1 tx-sender sender memo))))
        