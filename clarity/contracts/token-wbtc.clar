(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-alex-token.dao-token-trait)

;; Defines the wBTC according to the SIP-010 Standard
(define-fungible-token wbtc)

(define-data-var token-uri (string-utf8 256) u"")

;; errors
(define-constant err-not-authorized u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply wbtc))
)

(define-read-only (get-name)
  (ok "WBTC")
)

(define-read-only (get-symbol)
  (ok "WBTC")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance wbtc account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  ;;(if (is-eq tx-sender (contract-call? . get-dao-owner))
    (ok (var-set token-uri value))
  ;;  (err ERR-NOT-AUTHORIZED)
  ;;)
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? wbtc amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

;; ---------------------------------------------------------
;; wbtc token trait
;; ---------------------------------------------------------

;; Mint method for wbtc
(define-public (mint-for-dao (amount uint) (recipient principal))
  (begin
    ;;(asserts! (is-eq contract-caller .) (err ERR-NOT-AUTHORIZED))
    (ft-mint? wbtc amount recipient)
  )
)

;; Burn method for wbtc
(define-public (burn-for-dao (amount uint) (sender principal))
  (begin
    ;;(asserts! (is-eq contract-caller .) (err ERR-NOT-AUTHORIZED))
    (ft-burn? wbtc amount sender)
  )
)


;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? wbtc u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? wbtc u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)