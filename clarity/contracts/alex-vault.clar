(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-INSUFFICIENT-FLASH-LOAN-BALANCE (err u3003))
(define-constant ERR-INVALID-POST-LOAN-BALANCE (err u3004))
(define-constant ERR-USER-EXECUTE (err u3005))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-LOAN-TRANSFER-FAILED (err u3006))
(define-constant ERR-POST-LOAN-TRANSFER-FAILED (err u3007))
(define-constant ERR-INVALID-FLASH-LOAN (err u3008))
(define-constant ERR-INVALID-BALANCE (err u3011))
(define-constant ERR-MATH-CALL (err u2010))
(define-constant ERR-INTERNAL-FUNCTION-CALL (err u1001))

;; flash loan fee rate
(define-data-var flash-loan-fee-rate uint u0)

(define-read-only (get-flash-loan-fee-rate)
  (ok (var-get flash-loan-fee-rate))
)

;; TODO: multisig
(define-public (set-flash-loan-fee-rate (fee uint))
  (ok (var-set flash-loan-fee-rate fee))
)

;; return token balance held by vault
(define-public (get-balance (token <ft-trait>))
  (contract-call? token get-balance (as-contract tx-sender))
)

;; perform flash loan
(define-public (flash-loan (flash-loan-user <flash-loan-user-trait>) (token <ft-trait>) (amount uint))
  (let 
    (
      (pre-bal (unwrap! (get-balance token) ERR-INVALID-FLASH-LOAN))
      (fee-with-principal (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 (var-get flash-loan-fee-rate)) ERR-MATH-CALL))
      (amount-with-fee (unwrap! (contract-call? .math-fixed-point mul-up amount fee-with-principal) ERR-MATH-CALL))
    )

    ;; make sure current balance > loan amount
    (asserts! (> pre-bal amount) ERR-INSUFFICIENT-FLASH-LOAN-BALANCE)

    ;; transfer loan to flash-loan-user
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) tx-sender none) ERR-LOAN-TRANSFER-FAILED)

    ;; flash-loan-user executes with loan received
    (unwrap! (contract-call? flash-loan-user execute) ERR-USER-EXECUTE)

    ;; return the loan + fee
    (unwrap! (contract-call? token transfer amount-with-fee tx-sender (as-contract tx-sender) none) ERR-POST-LOAN-TRANSFER-FAILED) 
    (ok amount-with-fee)
  )
)