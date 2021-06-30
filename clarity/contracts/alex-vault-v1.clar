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