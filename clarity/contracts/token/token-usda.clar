(impl-trait .trait-pool-token.pool-token-trait)

;; Defines the USDA Stablecoin according to the SIP-010 Standard
(define-fungible-token usda)

(define-data-var token-uri (string-utf8 256) u"")

;; errors
(define-constant not-authorized-err u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply usda))
)

(define-read-only (get-name)
  (ok "USDA")
)

(define-read-only (get-symbol)
  (ok "USDA")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance usda account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  ;;(if (is-eq tx-sender (contract-call? .arkadiko-dao get-dao-owner))
    (ok (var-set token-uri value))
  ;;  (err not-authorized-err)
  ;;)
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? usda amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender sender) (err not-authorized-err))
    (match (ft-transfer? usda amount sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )  
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    ;;(asserts! (is-eq contract-caller .arkadiko-dao) (err ERR-NOT-AUTHORIZED))
    (ft-burn? usda amount sender)
  )
)

;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? usda u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? usda u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)