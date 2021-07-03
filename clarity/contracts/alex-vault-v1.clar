(use-trait vault-trait .trait-vault-v1.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)


;; TODO : DEFINE ALL VAULT ERRORS - by type!!!
(define-constant ERR-NOT-AUTHORIZED u20401)
(define-constant INVALID-PAIR-ERR (err u201))
(define-constant ERR-INVALID-LIQUIDITY u202)

(define-map pairs-data-map
  {
    token-x: principal,
    token-y: principal,
  }
  {
    shares-total: uint,
    balance-x: uint,
    balance-y: uint,
    fee-balance-x: uint,
    fee-balance-y: uint,
    fee-to-address: principal,
    swap-token: principal,
    name: (string-ascii 32),
  }
)



;; ---------------------------------------------------------
;; Getters
;; ---------------------------------------------------------

(define-read-only (get-name (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
    (let
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pair (unwrap! (map-get? pairs-data-map { token-x: token-x, token-y: token-y }) (err INVALID-PAIR-ERR)))
        )
    (ok (get name pair))
    ) 
)

(define-public (get-symbol (token-x <ft-trait>) (token-y <ft-trait>))
  (ok
    (concat
      (unwrap-panic (as-max-len? (unwrap-panic (contract-call? token-x get-symbol)) u15))
      (concat "-"
        (unwrap-panic (as-max-len? (unwrap-panic (contract-call? token-y get-symbol)) u15))
      )
    )
  )
)

(define-read-only (get-total-supply (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
  (let
    (
      (token-x (contract-of token-x-trait))
      (token-y (contract-of token-y-trait))
      (pair (unwrap! (map-get? pairs-data-map { token-x: token-x, token-y: token-y }) (err INVALID-PAIR-ERR)))
    )
    (ok (get shares-total pair))
  )
)

(define-public (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
  (let
    (
      (token-x (contract-of token-x-trait))
      (token-y (contract-of token-y-trait))
      (pair (unwrap! (map-get? pairs-data-map { token-x: token-x, token-y: token-y }) (err INVALID-PAIR-ERR)))
    )
    (ok (list (get balance-x pair) (get balance-y pair)))
  )
)


;; ---------------------------------------------------------
;; Create Pool
;; ---------------------------------------------------------

;; (create-pool (<ft-trait> <ft-trait> <pool-token-trait> <equation-trait> (string-ascii 32)) (response bool uint))    ;; WHY NEED EQUATION ? UML ERROR ?

;; (define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (pool-token-trait <pool-token-trait>) (equation-trait <equation-trait>) (pool-name (string-ascii 32))


;; )


;; (define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
;;   (let
;;     (
;;       (token-x (contract-of token-x-trait))
;;       (token-y (contract-of token-y-trait))
;;       (pair (unwrap-panic (map-get? pairs-data-map { token-x: token-x, token-y: token-y })))
;;       (address (get fee-to-address pair))
;;       (fee-x (get fee-balance-x pair))
;;       (fee-y (get fee-balance-y pair))
;;     )

;;     ;; (asserts! (is-eq fee-x u0) no-fee-x-err)
;;     ;; (asserts! (is-ok (contract-call? token-x-trait transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
;;     ;; (asserts! (is-eq fee-y u0) no-fee-y-err)
;;     ;; (asserts! (is-ok (contract-call? token-y-trait transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

;;     (map-set pairs-data-map
;;       { token-x: token-x, token-y: token-y }
;;       (merge pair { fee-balance-x: u0, fee-balance-y: u0 })
;;     )
;;     (ok (list fee-x fee-y))
;;   )
;; )