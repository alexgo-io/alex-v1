(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant insufficient-flash-loan-balance-err (err u3003))
(define-constant invalid-post-loan-balance-err (err u3004))
(define-constant user-execute-err (err u3005))
(define-constant transfer-failed-err (err u3000))
(define-constant loan-transfer-failed-err (err u3006))
(define-constant post-loan-transfer-failed-err (err u3007))
(define-constant invalid-balance (err u3011))
(define-constant math-call-err (err u2010))
(define-constant not-authorized-err (err u1000))

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
(define-public (transfer-on-behalf-of (token <ft-trait>) (amount uint) (sender principal) (recipient principal))
  (begin     
    (asserts! (default-to false (get can-transfer (map-get? approved-contracts { name: sender }))) not-authorized-err)
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) recipient none) transfer-failed-err)
    (ok true)
  )
)

;; perform flash loan
(define-public (flash-loan (flash-loan-user <flash-loan-user-trait>) (token <ft-trait>) (amount uint))
  (let 
    (
      (pre-bal (unwrap! (get-balance token) invalid-balance))
      (fee-with-principal (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 (var-get flash-loan-fee-rate)) math-call-err))
      (amount-with-fee (unwrap! (contract-call? .math-fixed-point mul-up amount fee-with-principal) math-call-err))
    )

    ;; make sure current balance > loan amount
    (asserts! (> pre-bal amount) insufficient-flash-loan-balance-err)

    ;; transfer loan to flash-loan-user
    (unwrap! (contract-call? token transfer amount (as-contract tx-sender) tx-sender none) loan-transfer-failed-err)

    ;; flash-loan-user executes with loan received
    (unwrap! (contract-call? flash-loan-user execute) user-execute-err)

    ;; return the loan + fee
    (unwrap! (contract-call? token transfer amount-with-fee tx-sender (as-contract tx-sender) none) post-loan-transfer-failed-err) 
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