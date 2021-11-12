(impl-trait .trait-yield-token.yield-token-trait) 
(impl-trait .trait-ownable.ownable-trait)

(define-fungible-token key-usda-23040-wbtc)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal .collateral-rebalancing-pool)
(define-data-var token-expiry uint u2304000000000)  
(define-data-var underlying-token principal .token-usda)

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
  (ok (ft-get-supply key-usda-23040-wbtc))
)

(define-read-only (get-name)
  (ok "key-usda-23040-wbtc")
)

(define-read-only (get-symbol)
  (ok "key-usda-23040-wbtc")
)

(define-read-only (get-decimals)
  (ok (unwrap-panic (contract-call? .token-usda get-decimals)))
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance key-usda-23040-wbtc account))
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
    (match (ft-transfer? key-usda-23040-wbtc amount sender recipient)
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
    (ft-mint? key-usda-23040-wbtc amount recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ft-burn? key-usda-23040-wbtc amount sender)
  )
)

(define-public (get-token)
    (ok (var-get underlying-token))
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)