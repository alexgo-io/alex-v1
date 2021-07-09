;;(use-trait vault-trait .trait-vault.vault-trait) ;; TO DO : CHANGE LATER
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

;; TODO : DEFINE ALL VAULT ERRORS - by type!!!
(define-constant ERR-NOT-AUTHORIZED u20401)
(define-constant INVALID-PAIR-ERR (err u201))
(define-constant ERR-INVALID-LIQUIDITY u202)
(define-constant INVALID-TOKEN-ERR u203)
(define-constant INVALID-BALANCES u204)
(define-constant FUNDING_ERR (err u205))

(define-data-var tokens-list (list 2000 uint) (list ))

(define-data-var token-balances (list 2000 {token: (string-ascii 32), balance: uint}) (list ))


(define-map token-data-map
  { token : principal }
  {
    shares-total: uint,
    balance: uint,
    fee-balance: uint,
    fee-to-address: principal,
    swap-token: principal,
    name: (string-ascii 32),
  }
)

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

(define-read-only (get-balance (token-x-trait <ft-trait>))
    (let
        (
        (token-x (contract-of token-x-trait))   
        (token-data (unwrap! (map-get? token-data-map { token : token-x }) (err INVALID-TOKEN-ERR)))
        )
    (ok (get balance token-data))
    )
)



(define-read-only (get-balances)

    (ok (var-get token-balances))
    ;;(err INVALID-BALANCES)

)

(define-public (flash-loan (loan-user <flash-loan-user-trait>) (var1 (list 3 <ft-trait>)) (var2 (list 3 uint)))

    ;; (unwrap! (as-contract (contract-call? token transfer loan-amount tx-sender (contract-of loan-user))) FUNDING_ERR)
    ;; TO DO : get TOKEN from the loan user
    ;; TO DO : transfer loan amount from tx-sender to loan user principal
    (ok (var-get token-balances)) ;; 
)

;; (define-read-only (get-balance (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
;;     (let
;;         (
;;         (token-x (contract-of token-x-trait))
;;         (token-y (contract-of token-y-trait))
;;         (pair (unwrap! (map-get? pairs-data-map { token-x: token-x, token-y: token-y }) (err INVALID-PAIR-ERR)))
;;         )
;;     (ok (get name pair))
;;     ) 
;; )

;; (define-public (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
;;   (let
;;     (
;;       (token-x (contract-of token-x-trait))
;;       (token-y (contract-of token-y-trait))
;;       (pair (unwrap! (map-get? pairs-data-map { token-x: token-x, token-y: token-y }) (err INVALID-PAIR-ERR)))
;;     )
;;     (ok (list (get balance-x pair) (get balance-y pair)))
;;   )
;; )

