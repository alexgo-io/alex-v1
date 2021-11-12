(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-pool-token.pool-token-trait)

(define-fungible-token fwp-wbtc-usda-50-50)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal .fixed-weight-pool)

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 (pow u10 u8))

(define-read-only (get-owner)
  (ok (var-get contract-owner))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply fwp-wbtc-usda-50-50))
)

(define-read-only (get-name)
  (ok "fwp-wbtc-usda-50-50")
)

(define-read-only (get-symbol)
  (ok "fwp-wbtc-usda-50-50")
)

(define-read-only (get-decimals)
  (ok u0)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance fwp-wbtc-usda-50-50 account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set token-uri value))
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
    (match (ft-transfer? fwp-wbtc-usda-50-50 amount sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ft-mint? fwp-wbtc-usda-50-50 amount recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ft-burn? fwp-wbtc-usda-50-50 amount sender)
  )
)