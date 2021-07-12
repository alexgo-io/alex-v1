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

;; Flash Loan draft work - Sidney


;; flash loan to flash loan user up to 3 tokens of amounts specified
;; (define-public (flash-loan (loan-user <flash-loan-user-trait>) (token-list (list 3 <ft-trait>)) (amount-list (list 3 uint)))

;;     ;; Basic Idea : for each token list and amount list, 
;;     (begin
;;         (token-length (len token-list))
;;         (current-token (element-at token-list counter)) 
;;         (current-amount (element-at amount-list counter))

;;         token-list 
;;         amount-list

;;     ;; Basic Idea : for each token list and amount list, 

;;     (unwrap! (as-contract (contract-call? current-token transfer current-amount tx-sender (contract-of loan-user))) FUNDING_ERR)
    
;;     (let
;;       (
;;         (current-balance (stx-get-balance (as-contract tx-sender)))
;;         ;; (fee (/ (* loan-amount loan-fee-num) loan-fee-den))  ;; INTEREST OF FLASH LOAN ??
;;         ;; 
;;       )

;;       ;; call the flash loan operation
;;       (unwrap! (contract-call? loan-user execute loan-id (as-contract tx-sender) current-amount) loan-err)

;;       ;; check transferred back with fee

;;       (print "Executuon Result")
;;       (print { amount: loan-amount, balance: balance, fee: fee, new-balance: (stx-get-balance (as-contract tx-sender)) })
;;       ;; TODO : ASSERTING
;;       ;; (ok Final Fee)
;;     )
;;     (ok (var-get token-balances)) ;; 
;;     )
;; )
