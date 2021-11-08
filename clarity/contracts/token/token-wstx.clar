(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-pool-token.pool-token-trait)

(define-fungible-token wstx)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var contract-owner principal tx-sender)

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-read-only (get-owner)
  (ok (var-get contract-owner))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (decimals-to-fixed (ft-get-supply wstx)))
)

(define-read-only (get-name)
  (ok "wstx")
)

(define-read-only (get-symbol)
  (ok "wstx")
)

(define-read-only (get-decimals)
  (ok u0)
)

(define-read-only (get-balance (account principal))
  (ok (decimals-to-fixed (ft-get-balance wstx account)))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set token-uri value))
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-constant ONE_8 (pow u10 u8))

(define-private (pow-decimals)
  (pow u10 (unwrap-panic (get-decimals)))
)

(define-read-only (fixed-to-decimals (amount uint))
  (/ (* amount (pow-decimals)) ONE_8)
)

(define-private (decimals-to-fixed (amount uint))
  (/ (* amount ONE_8) (pow-decimals))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
    (match (ft-transfer? wstx (fixed-to-decimals amount) sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )
  )
)

;; This can only be called by recipient since stx-transfer is involved ;; tx-sender -> .alex-vault
(define-public (mint (recipient principal) (amount uint)) 
  (begin
    (try! (stx-transfer? amount recipient .alex-vault))
    (ft-mint? wstx (fixed-to-decimals amount) recipient)
  )
)

;; This can only be called by contract since stx-transfer is involved ;; .alex-vault -> sender
(define-public (burn (sender principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (as-contract (try! (contract-call? .alex-vault transfer-stx amount tx-sender sender)))
    (ft-burn? wstx (fixed-to-decimals amount) sender)
  )
)

;; Initialize the contract for Testing.
(begin
  (try! (ft-mint? wstx u2000000000000 tx-sender))
  (try! (ft-mint? wstx u2000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;;wallet_1
)