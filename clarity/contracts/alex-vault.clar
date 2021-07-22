(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant insufficient-flash-loan-balance-err (err u528))
(define-constant invalid-post-loan-balance-err (err u515))
(define-constant user-execute-err (err u101))
(define-constant transfer-one-by-one-err (err u102))
(define-constant transfer-failed-err (err u72))
(define-constant none-token-err (err u103))
(define-constant get-token-fail (err u104))

(define-data-var pre-loan-balance uint u0)
(define-data-var post-loan-balance uint u0)
(define-data-var pre-loan-balances (list 3 uint) (list))
(define-data-var fee-amount uint u0)

(define-data-var balances (list 2000 {token: (string-ascii 32), balance: uint}) (list))

(define-public (get-balance (token <ft-trait>))
  ;;use https://docs.stacks.co/references/language-functions#ft-get-balance
  ;; 
  (ok (unwrap! (contract-call? token get-balance tx-sender) get-token-fail))
)
;; returns list of {token, balance}
(define-read-only (get-balances)
  ;;Clarity doesn't support loop, so we need to maintain a list of tokens to apply map to get-balance
  ;;See get-pool-contracts and get-pools in fixed-weight-pool
  (ok (var-get balances))
)

;; flash loan to flash loan user up to 3 tokens of amounts specified
(define-public (flash-loan (flash-loan-user <flash-loan-user-trait>) (tokens (list 3 <ft-trait>)) (amounts (list 3 uint)))
  ;; get the requested tokens
  ;; call execute of flash-loan-user
  ;; if all good, then return true, otherwise, roll back and return false
  (ok true)
)