(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines keyusda for taking the collateral from CRP. 
;; keyUSDA with expiry of one month

(define-fungible-token key-usda-59760-wbtc)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u5976000000000)  ;; 27-10-21
(define-data-var underlying-token principal .token-usda)

;; errors
(define-constant err-not-authorized u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "key-usda-59760-wbtc")
)

(define-read-only (get-symbol)
  (ok "key-usda-59760-wbtc")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance key-usda-59760-wbtc account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply key-usda-59760-wbtc))
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
  (match (ft-transfer? key-usda-59760-wbtc amount sender recipient)
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

;; Mint method for key-usda-59760-wbtc
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-mint? key-usda-59760-wbtc amount recipient)
  )
)

;; Burn method for key-usda-59760-wbtc
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err err-not-authorized))
    (ft-burn? key-usda-59760-wbtc amount sender)
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
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? key-usda-59760-wbtc u1000000000000 'ST1RKT6V51K1G3DXWZC22NX6PFM6GBZ8FQKSGSNFY)) ;; Deployer
  (try! (ft-mint? key-usda-59760-wbtc u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)