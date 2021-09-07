(impl-trait .trait-pool-token.pool-token-trait)

(define-fungible-token alex)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal tx-sender)

;; errors
(define-constant not-authorized-err u1000)

(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err not-authorized-err))

    (ok (var-set contract-owner owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply alex))
)

(define-read-only (get-name)
  (ok "ALEX")
)

(define-read-only (get-symbol)
  (ok "ALEX")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance alex account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (var-set token-uri value))
    (err not-authorized-err)
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? alex amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

(define-public (mint (recipient principal) (amount uint))
  (begin
    ;; (asserts! (is-eq contract-caller .dao) (err ERR-NOT-AUTHORIZED))
    (ft-mint? alex amount recipient)
  )
)

(define-public (burn (sender principal) (amount uint))
  (begin
    ;; (asserts! (is-eq contract-caller .dao) (err ERR-NOT-AUTHORIZED))
    (ft-burn? alex amount sender)
  )
)


;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? alex u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? alex u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)