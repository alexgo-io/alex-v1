(impl-trait .trait-sip-010.sip-010-trait)
(impl-trait .trait-yield-token.yield-token-trait) ;; To be discussed : ERROR

;; Defines ayUSDA which conforms sip010-trait and yield-token-trait. 

(define-fungible-token ayUSDA-Aug2021)

(define-data-var token-uri (string-utf8 256) u"")
(define-data-var token-expiry uint u1853000000000)  ;; token-expiry is expressed as specific blochheight * 10e8
(define-data-var underlying-token principal .token-usda)

;; errors
(define-constant not-authorized-err u1000)

;; ---------------------------------------------------------
;; SIP-10 Functions
;; ---------------------------------------------------------

(define-read-only (get-name)
  (ok "ayUSDA-Aug2021")
)

(define-read-only (get-symbol)
  (ok "ayUSDA-Aug2021")
)

(define-read-only (get-decimals)
  (ok u8)
)

(define-read-only (get-underlying-token)
  (ok (var-get underlying-token))
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance ayUSDA-Aug2021 account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply ayUSDA-Aug2021))
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
  (begin 
    (asserts! (is-eq tx-sender sender) (err not-authorized-err))
    (match (ft-transfer? ayUSDA-Aug2021 amount sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )
  )
)

;; ---------------------------------------------------------
;; ayUSDA token trait
;; ---------------------------------------------------------

;; Mint method for ayUSDA-Aug2021
(define-public (mint (recipient principal) (amount uint))
  (begin
    ;; TODO : Authorization Check
    ;;(asserts! (is-eq contract-caller .OWNER) (err not-authorized-err))
    (ft-mint? ayUSDA-Aug2021 amount recipient)
  )
)

;; Burn method for ayUSDA-Aug2021
(define-public (burn (sender principal) (amount uint))
  (begin
    ;; TODO : Authorization Check
    ;;(asserts! (is-eq contract-caller .OWNER) (err not-authorized-err))
    (ft-burn? ayUSDA-Aug2021 amount sender)
  )
)

;; ;; Mint method for ayUSDA-Aug2021
;; (define-public (mint-from-registry (amount uint) (recipient principal))
;;   (begin
;;     ;; TODO : Authorization Check
;;     ;;(asserts! (is-eq contract-caller .OWNER) (err not-authorized-err))
;;     (ft-mint? ayUSDA-Aug2021 amount recipient)
;;   )
;; )

;; ;; burn method for ayUSDA-Aug2021
;; (define-public (burn-from-registry (amount uint) (recipient principal))
;;   (begin
;;     ;; TODO : Authorization Check
;;     ;;(asserts! (is-eq contract-caller .OWNER) (err not-authorized-err))
;;     (ft-mint? ayUSDA-Aug2021 amount recipient)
;;   )
;; )



(define-public (get-token)
    (ok (var-get underlying-token))
)

(define-public (get-expiry)
    (ok (var-get token-expiry))
)


;; Initialize the contract for Testing.
(begin
  ;; TODO: Erase on testnet or mainnet
  (try! (ft-mint? ayUSDA-Aug2021 u1000000000000 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)) ;; Deployer
  (try! (ft-mint? ayUSDA-Aug2021 u1000000000000 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)) ;; Wallet 1
)