(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-sip-010.sip-010-trait)

(define-fungible-token wstx)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var CONTRACT-OWNER principal tx-sender)

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-NOT-TOKEN-OWNER (err u1001))

(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-total-supply)
  (ok (ft-get-supply wstx))
)

(define-read-only (get-name)
  (ok "wstx")
)

(define-read-only (get-symbol)
  (ok "wstx")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance wstx account))
)

(define-public (set-token-uri (value (string-utf8 256)))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set token-uri value))
  )
)

(define-read-only (get-token-uri)
  (ok (some (var-get token-uri)))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
    (match (ft-transfer? wstx amount sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )
  )
)

;; This can only be called by recipient since stx-transfer is involved ;; tx-sender -> .alex-vault
(define-public (mint (amount uint) (recipient principal)) 
  (begin
    (asserts! (is-eq tx-sender recipient) ERR-NOT-TOKEN-OWNER)
    (try! (stx-transfer? (/ (* amount (pow u10 u6)) ONE_8) recipient .alex-vault))
    (ft-mint? wstx amount recipient)
  )
)

;; This can only be called by sender since ft-burn is involved
(define-public (burn (amount uint) (sender principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-TOKEN-OWNER)
    (as-contract (try! (contract-call? .alex-vault transfer-stx (decimals-to-fixed amount) tx-sender sender)))
    (ft-burn? wstx amount sender)
  )
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

(define-read-only (get-total-supply-fixed)
  (ok (decimals-to-fixed (ft-get-supply wstx)))
)

(define-read-only (get-balance-fixed (account principal))
  (ok (decimals-to-fixed (ft-get-balance wstx account)))
)

(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (transfer (fixed-to-decimals amount) sender recipient memo)
)

(define-public (mint-fixed (amount uint) (recipient principal))
  (mint (fixed-to-decimals amount) recipient)
)

(define-public (burn-fixed (amount uint) (sender principal))
  (burn (fixed-to-decimals amount) sender)
)