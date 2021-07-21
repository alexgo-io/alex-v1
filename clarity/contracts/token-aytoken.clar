(impl-trait .trait-sip-010.sip-010-trait)
;;(impl-trait .trait-yield-token.yield-token-trait) ;; To be discussed : ERROR

;; Defines ayToken which conforms sip010-trait and yield-token-trait. 

(define-fungible-token ayToken)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u52560)  ;; 1 year 
(define-data-var underlying-token (string-utf8 256) u"")    ;; To be discussed : hard code? 

;; errors
(define-constant ERR-NOT-AUTHORIZED u14401)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "ayTOKEN")
)

(define-read-only (get-symbol)
  (ok "ayTOKEN")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance ayToken account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply ayToken))
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
  (match (ft-transfer? ayToken amount sender recipient)
    response (begin
      (print memo)
      (ok response)
    )
    error (err error)
  )
)

;; ---------------------------------------------------------
;; ayToken token trait
;; ---------------------------------------------------------

;; Mint method for ayToken
(define-public (mint (amount uint) (recipient principal))
  (begin
    ;; TODO : Authorization Check
    ;;(asserts! (is-eq contract-caller .OWNER) (err ERR-NOT-AUTHORIZED))
    (ft-mint? ayToken amount recipient)
  )
)

;; Burn method for ayToken
(define-public (burn (amount uint) (sender principal))
  (begin
    ;; TODO : Authorization Check
    ;;(asserts! (is-eq contract-caller .OWNER) (err ERR-NOT-AUTHORIZED))
    (ft-burn? ayToken amount sender)
  )
)

(define-public (get-token)
    ;; TODO : What the current ayToken is against for. 
    (ok (as-contract tx-sender))    ;; Temporary return because this function is currently not used
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)

