(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-alex-token.dao-token-trait)

;; Defines the Alex Governance Token according to the SRC20 Standard
(define-fungible-token galex)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal tx-sender)

;; errors
(define-constant ERR-NOT-AUTHORIZED u1401)

(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))

    (ok (var-set contract-owner owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply galex))
)

(define-read-only (get-name)
  (ok "Alex Token")
)

(define-read-only (get-symbol)
  (ok "ALEX")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance galex account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (if (is-eq tx-sender (var-get contract-owner))
    (ok (var-set token-uri value))
    (err ERR-NOT-AUTHORIZED)
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (match (ft-transfer? galex amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

;; ---------------------------------------------------------
;; alex token trait
;; ---------------------------------------------------------

;; Mint method for glaex
(define-public (mint-for-dao (amount uint) (recipient principal))
  (begin
    ;; (asserts! (is-eq contract-caller .arkadiko-dao) (err ERR-NOT-AUTHORIZED))
    (ft-mint? galex amount recipient)
  )
)

;; Burn method for DAO
(define-public (burn-for-dao (amount uint) (sender principal))
  (begin
    ;; (asserts! (is-eq contract-caller .arkadiko-dao) (err ERR-NOT-AUTHORIZED))
    (ft-burn? galex amount sender)
  )
)


;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? galex u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? galex u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)