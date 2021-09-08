(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant insufficient-flash-loan-balance-err (err u3003))
(define-constant invalid-post-loan-balance-err (err u3004))
(define-constant user-execute-err (err u3005))
(define-constant transfer-one-by-one-err (err u3006))
(define-constant transfer-failed-err (err u3000))
(define-constant none-token-err (err u3007))
(define-constant get-token-fail (err u3008))
(define-constant token-type-err (err u3009))
(define-constant token-absent (err u3010))
(define-constant invalid-balance (err u3011))
(define-constant unwrap-err (err u3012))
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))

;; flash loan fee rate
(define-data-var flash-loan-fee-rate uint u0)

;; return token balance held by vault
(define-public (get-balance (token <ft-trait>))
  (contract-call? token get-balance (as-contract tx-sender))
)

;; perform flash loan
(define-public (flash-loan
                (flash-loan-user <flash-loan-user-trait>) 
                (token-1 <ft-trait>) 
                (token-2 <ft-trait>) 
                (token-3 <ft-trait>) 
                (amount-1 uint) 
                (amount-2 uint)
                (amount-3 uint))
  
  (begin 
      (let 
        (
          (pre-bal-1 (unwrap! (get-balance token-1) invalid-balance))
          (pre-bal-2 (unwrap! (get-balance token-2) invalid-balance))
          (pre-bal-3 (unwrap! (get-balance token-3) invalid-balance))
          (fee-with-principal (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 (var-get flash-loan-fee-rate)) math-call-err))
          (amount-with-fee-1 (unwrap! (contract-call? .math-fixed-point mul-up amount-1 fee-with-principal) math-call-err))
          (amount-with-fee-2 (unwrap! (contract-call? .math-fixed-point mul-up amount-2 fee-with-principal) math-call-err))
          (amount-with-fee-3 (unwrap! (contract-call? .math-fixed-point mul-up amount-3 fee-with-principal) math-call-err))
        )

        ;; make sure current balance > loan amount
        (asserts! (> pre-bal-1 amount-1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-bal-2 amount-2) insufficient-flash-loan-balance-err)
        (asserts! (> pre-bal-3 amount-3) insufficient-flash-loan-balance-err)

        ;; transfer loan to flash-loan-user
        (asserts! (is-ok (contract-call? token-1 transfer amount-1 (as-contract tx-sender) (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token-2 transfer amount-2 (as-contract tx-sender) (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token-3 transfer amount-3 (as-contract tx-sender) (contract-of flash-loan-user) none)) transfer-failed-err)

        ;; flash-loan-user executes with loan received
        (asserts! (is-ok (contract-call? flash-loan-user execute)) user-execute-err)

        ;; return the loan + fee
        (asserts! (is-ok (contract-call? token-1 transfer amount-with-fee-1 (contract-of flash-loan-user) (as-contract tx-sender) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token-2 transfer amount-with-fee-2 (contract-of flash-loan-user) (as-contract tx-sender) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token-3 transfer amount-with-fee-3 (contract-of flash-loan-user) (as-contract tx-sender) none)) transfer-failed-err)
        
        ;; make sure the loan + fee are returned to vault
        ;; do we need this given the above?
        (let
          (
            (post-bal-1 (unwrap! (get-balance token-1) invalid-balance))
            (post-bal-2 (unwrap! (get-balance token-1) invalid-balance))
            (post-bal-3 (unwrap! (get-balance token-3) invalid-balance))
          )
          (asserts! (>= post-bal-1 pre-bal-1) invalid-post-loan-balance-err)
          (asserts! (>= post-bal-2 pre-bal-2) invalid-post-loan-balance-err)
          (asserts! (>= post-bal-3 pre-bal-3) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)
