(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines keyusda for taking the collateral from CRP. 
;; keyUSDA with expiry of one month

(define-fungible-token key-usda-wbtc-4380)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u438000000000)  ;; 4380 * 10e8, where 52560(One year mainnet block height)/12 = 4380 
(define-data-var underlying-token principal .token-usda)

;; errors
(define-constant err-not-authorized u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "key-usda-wbtc-4380")
)

(define-read-only (get-symbol)
  (ok "key-usda-wbtc-4380")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance key-usda-wbtc-4380 account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply key-usda-wbtc-4380))
)

(define-public (set-token-uri (value (string-utf8 256)))
  ;; TODO : Authorization Check
  ;;(if (is-eq tx-sender (contract-call? .OWNER))
    (ok (var-set token-uri value))
  ;;  (err ERR-NOT-AUTHORIZED)
  ;;)
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? key-usda-wbtc-4380 amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

;; ---------------------------------------------------------
;; ayUSDA token trait
;; ---------------------------------------------------------

;; Mint method for key-usda-wbtc-4380
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-mint? key-usda-wbtc-4380 amount recipient)
  )
)

;; Burn method for key-usda-wbtc-4380
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-burn? key-usda-wbtc-4380 amount sender)
  )
)

(define-public (get-token)
    (ok (var-get underlying-token))
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)
