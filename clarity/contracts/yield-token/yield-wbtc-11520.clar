(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

(define-fungible-token yield-wbtc-11520)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal .collateral-rebalancing-pool)
(define-data-var token-expiry uint u1152000000000)  
(define-data-var underlying-token principal .token-wbtc)

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 (pow u10 u8))

(define-private (pow-decimals)
  (pow u10 (unwrap-panic (get-decimals)))
)

(define-read-only (fixed-to-decimals (amount uint))
  (/ (* amount (pow-decimals)) ONE_8)
)

(define-private (decimals-to-fixed (amount uint))
  (/ (* amount ONE_8) (pow-decimals))
)

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
  (ok (decimals-to-fixed (ft-get-supply yield-wbtc-11520)))
)

(define-read-only (get-name)
  (ok "yield-wbtc-11520")
)

(define-read-only (get-symbol)
  (ok "yield-wbtc-11520")
)

(define-read-only (get-decimals)
  (ok (unwrap-panic (contract-call? .token-wbtc get-decimals)))
)

(define-read-only (get-balance (account principal))
  (ok (decimals-to-fixed (ft-get-balance yield-wbtc-11520 account)))
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
    (match (ft-transfer? yield-wbtc-11520 (fixed-to-decimals amount) sender recipient)
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
    (ft-mint? yield-wbtc-11520 (fixed-to-decimals amount) recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ft-burn? yield-wbtc-11520 (fixed-to-decimals amount) sender)
  )
)

(define-public (get-token)
    (ok (var-get underlying-token))
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)

;; Initialize the contract for Testing.
(begin
  (try! (ft-mint? yield-wbtc-11520 u2000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;;wallet_1
)