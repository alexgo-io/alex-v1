(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines keyusda for taking the collateral from CRP. 
;; keyUSDA with expiry of one month

(define-fungible-token key-usda-4380-wbtc)

(define-constant token-expiry u438000000000)  ;; 4380 * 10e8, where 52560(One year mainnet block height)/12 = 4380 
(define-constant underlying-token .token-usda)
(define-constant underlying-collateral .token-wbtc)

;; errors
(define-constant not-authorized-err u1000)

(define-data-var token-uri (string-utf8 256) u"")

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "key-usda-4380-wbtc")
)

(define-read-only (get-symbol)
  (ok "key-usda-4380-wbtc")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-underlying-collateral)
  (ok underlying-collateral)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance key-usda-4380-wbtc account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply key-usda-4380-wbtc))
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? key-usda-4380-wbtc amount sender recipient)
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

;; Mint method for key-usda-4380-wbtc
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err not-authorized-err))
    (ft-mint? key-usda-4380-wbtc amount recipient)
  )
)

;; Burn method for key-usda-4380-wbtc
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .collateral-rebalancing-pool) (err not-authorized-err))
    (ft-burn? key-usda-4380-wbtc amount sender)
  )
)

(define-public (get-token)
    (ok underlying-token)
)

(define-public (get-expiry)
    (ok token-expiry)
)


;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? key-usda-4380-wbtc u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? key-usda-4380-wbtc u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)