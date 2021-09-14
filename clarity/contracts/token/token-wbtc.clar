(impl-trait .trait-pool-token.pool-token-trait)

;; Defines the wBTC according to the SIP-010 Standard
(define-fungible-token wbtc)

(define-data-var token-uri (string-utf8 256) u"")

;; errors
(define-constant not-authorized-err u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply wbtc))
)

(define-read-only (get-name)
  (ok "WBTC")
)

(define-read-only (get-symbol)
  (ok "WBTC")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance wbtc account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  ;;(if (is-eq tx-sender (contract-call? . get-dao-owner))
    (ok (var-set token-uri value))
  ;;  (err not-authorized-err)
  ;;)
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? wbtc amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    (ft-mint? wbtc amount recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    (ft-burn? wbtc amount sender)
  )
)

;; Initialize the contract for Testing.
(begin
  (try! (ft-mint? wbtc u2000000000000 tx-sender))
  (try! (ft-mint? wbtc u2000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;;wallet_1
)
