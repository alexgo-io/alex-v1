(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines keyusda for taking the collateral from CRP. 
;; keyUSDA with expiry of one month

(define-fungible-token key-wbtc-59760-usda)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u5976000000000)  ;; 27-10-21
(define-data-var underlying-token principal .token-wbtc) ;; Token is wbtc

;; errors
(define-constant err-not-authorized u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "key-wbtc-59760-usda")
)

(define-read-only (get-symbol)
  (ok "key-wbtc-59760-usda")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance key-wbtc-59760-usda account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply key-wbtc-59760-usda))
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
  (match (ft-transfer? key-wbtc-59760-usda amount sender recipient)
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

;; Mint method for key-wbtc-59760-usda
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-mint? key-wbtc-59760-usda amount recipient)
  )
)

;; Burn method for key-wbtc-59760-usda
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-burn? key-wbtc-59760-usda amount sender)
  )
)

(define-public (get-token)
    (ok (var-get underlying-token))
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)