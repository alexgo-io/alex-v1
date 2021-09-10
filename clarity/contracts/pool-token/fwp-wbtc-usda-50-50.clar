(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-pool-token.pool-token-trait)

(define-fungible-token fwp-wbtc-usda-50-50)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal tx-sender)

;; errors
(define-constant err-not-authorized u1000)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? fwp-wbtc-usda-50-50 amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

(define-read-only (get-name)
  (ok "fwp-wbtc-usda-50-50")
)

(define-read-only (get-symbol)
  (ok "fwp-wbtc-usda-50-50")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (owner principal))
  (ok (ft-get-balance fwp-wbtc-usda-50-50 owner))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply fwp-wbtc-usda-50-50))
)

(define-read-only (get-token-uri)
  (ok (some u"https://docs.alexgo.io/"))
)


;; one stop function to gather all the data relevant to the LP token in one call
(define-read-only (get-data (owner principal))
  (ok {
    name: (unwrap-panic (get-name)),
    symbol: (unwrap-panic (get-symbol)),
    decimals: (unwrap-panic (get-decimals)),
    uri: (unwrap-panic (get-token-uri)),
    supply: (unwrap-panic (get-total-supply)),
    balance: (unwrap-panic (get-balance owner))
  })
)

;; the extra mint method used when adding liquidity
;; can only be used by arkadiko swap main contract
(define-public (mint (recipient principal) (amount uint))
  (begin
    (print "alex-token-swap.mint")
    (print contract-caller)
    (print amount)
    ;; TODO - make dynamic
    ;;(asserts! (is-eq contract-caller .yield-usda-pool) (err err-not-authorized))
    (ft-mint? fwp-wbtc-usda-50-50 amount recipient)
  )
)


;; the extra burn method used when removing liquidity
;; can only be used by arkadiko swap main contract
(define-public (burn (recipient principal) (amount uint))
  (begin
    (print "alex-token-swap.burn")
    (print contract-caller)
    (print amount)
    ;; TODO - make dynamic
    ;;(asserts! (is-eq contract-caller .yield-usda-pool) (err err-not-authorized))
    (ft-burn? fwp-wbtc-usda-50-50 amount recipient)
  )
)