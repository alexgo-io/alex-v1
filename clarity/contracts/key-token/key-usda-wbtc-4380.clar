(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines keyusda for taking the collateral from CRP. 
;; keyUSDA with expiry of one month

(define-fungible-token key-usda-wbtc-4380)

;; Let's keep this for now, seems like I can't fetch constant values using contract-call
(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u438000000000)  ;; 4380 * 10e8, where 52560(One year mainnet block height)/12 = 4380 
(define-data-var underlying-token principal .token-usda)
(define-data-var underlying-collateral principal .token-wbtc)

;; errors
(define-constant not-authorized-err u1000)

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

(define-read-only (get-underlying-token)
  (ok (var-get underlying-token))
)

(define-read-only (get-underlying-collateral)
  (ok (var-get underlying-collateral))
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
  ;;  (err not-authorized-err)
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
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err not-authorized-err))
    (ft-mint? key-usda-wbtc-4380 amount recipient)
  )
)

;; Burn method for key-usda-wbtc-4380
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err not-authorized-err))
    (ft-burn? key-usda-wbtc-4380 amount sender)
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
  (try! (ft-mint? key-usda-wbtc-4380 u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? key-usda-wbtc-4380 u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)