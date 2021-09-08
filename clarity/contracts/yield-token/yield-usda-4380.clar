(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) 

;; Defines ayUSDA which conforms sip010-trait and yield-token-trait. 
;; yield-usda-wbtc with expiry of one month

(define-fungible-token yield-usda-4380)

(define-constant token-expiry u438000000000)  ;; 4380 * 10e8, where 52560(One year mainnet block height)/12 = 4380 
(define-constant underlying-token .token-usda)

;; errors
(define-constant not-authorized-err u1000)

(define-data-var token-uri (string-utf8 256) u"")

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "yield-usda-4380")
)

(define-read-only (get-symbol)
  (ok "yield-usda-4380")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance yield-usda-4380 account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply yield-usda-4380))
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? yield-usda-4380 amount sender recipient)
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

;; Mint method for yield-usda-4380
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .yield-usda-pool) (err not-authorized-err))
    (ft-mint? yield-usda-4380 amount recipient)
  )
)

;; Burn method for yield-usda-4380
(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .yield-usda-pool) (err not-authorized-err))
    (ft-burn? yield-usda-4380 amount sender)
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
  ;;(try! (ft-mint? yield-usda-4380 u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? yield-usda-4380 u1000000000000 'ST20ATRN26N9P05V2F1RHFRV24X8C8M3W54E427B2)) ;; Wallet 2
)