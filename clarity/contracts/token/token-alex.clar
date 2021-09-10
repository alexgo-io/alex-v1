(impl-trait .trait-pool-token.pool-token-trait)

;; Defines the ALEX according to the SIP-010 Standard
(define-fungible-token alex)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal tx-sender)

;; errors
(define-constant not-authorized-err u1000)

(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err not-authorized-err))

    (ok (var-set contract-owner owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply alex))
)

(define-read-only (get-name)
  (ok "ALEX")
)

(define-read-only (get-symbol)
  (ok "ALEX")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance alex account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (var-set token-uri value))
    (err not-authorized-err)
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? alex amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    (ft-mint? alex amount recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    (ft-burn? alex amount sender)
  )
)

;; Initialize the contract for Testing.
(begin
  (try! (ft-mint? alex u1000000000000 tx-sender))
)
