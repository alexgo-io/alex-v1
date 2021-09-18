(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
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

(define-map approved-contracts
  { name: principal }
  {
    can-transfer: bool
  }
)

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

;; if sender is an approved contract, then transfer requested amount :qfrom vault to recipient
(define-public (transfer-ft (token <ft-trait>) (amount uint) (sender principal) (recipient principal))
  (begin     
    (asserts! (default-to false (get can-transfer (map-get? approved-contracts { name: sender }))) ERR-NOT-AUTHORIZED)
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) recipient none) ERR-TRANSFER-FAILED)
    (ok true)
  )
)

(define-public (transfer-yield (token <yield-token-trait>) (amount uint) (sender principal) (recipient principal))
  (begin     
    (asserts! (default-to false (get can-transfer (map-get? approved-contracts { name: sender }))) ERR-NOT-AUTHORIZED)
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) recipient none) ERR-TRANSFER-FAILED)
    (ok true)
  )
)

(define-public (transfer-pool (token <pool-token-trait>) (amount uint) (sender principal) (recipient principal))
  (begin     
    (asserts! (default-to false (get can-transfer (map-get? approved-contracts { name: sender }))) ERR-NOT-AUTHORIZED)
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) recipient none) ERR-TRANSFER-FAILED)
    (ok true)
  )
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

;; contract initialisation
(begin
  (map-set approved-contracts
    { name: .alex-reserve-pool }
    {
      can-transfer: true
    }
  )
  (map-set approved-contracts
    { name: .collateral-rebalancing-pool }
    {
      can-transfer: true
    }
  )  
  (map-set approved-contracts
    { name: .fixed-weight-pool }
    {
      can-transfer: true
    }
  )  
  (map-set approved-contracts
    { name: .liquidity-bootstrapping-pool }
    {
      can-transfer: true
    }
  )  
  (map-set approved-contracts
    { name: .yield-token-pool }
    {
      can-transfer: true
    }
  )  
)