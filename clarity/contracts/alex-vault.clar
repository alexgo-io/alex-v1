(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible-token.semi-fungible-token-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-FLASH-LOAN-BALANCE (err u3003))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-STX-TRANSFER-FAILED (err u9003))
(define-constant ERR-LOAN-TRANSFER-FAILED (err u3006))
(define-constant ERR-POST-LOAN-TRANSFER-FAILED (err u3007))
(define-constant ERR-INVALID-FLASH-LOAN (err u3008))

(define-data-var CONTRACT-OWNER principal tx-sender)

(define-map approved-contracts principal bool)

;; flash loan fee rate
(define-data-var flash-loan-fee-rate uint u0)

;; @desc get-owner
;; @returns (response principal)
(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

;; @desc set-owner
;; @restricted Contract-Owner
;; @returns (response boolean)
(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

;; @desc get-flash-loan-free-rate
;; @returns (response boolean)
(define-read-only (get-flash-loan-fee-rate)
  (ok (var-get flash-loan-fee-rate))
)

;; @desc check-is-approved
;; @restricted Approved-Contracts
;; @params sender
;; @returns (response boolean)
(define-private (check-is-approved (sender principal))
  (ok (asserts! (default-to false (map-get? approved-contracts sender)) ERR-NOT-AUTHORIZED))
)

;; @desc set-flash-loan-fee-rate
;; @restricted Contract-Owner
;; @params fee
;; @returns (response boolean)
(define-public (set-flash-loan-fee-rate (fee uint))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set flash-loan-fee-rate fee))
  )
)

;; return token balance held by vault
;; @desc get-balance
;; @params token; ft-trait
;; @returns (response uint)
(define-public (get-balance (token <ft-trait>))
  (contract-call? token get-balance-fixed (as-contract tx-sender))
)

;; if sender is an approved contract, then transfer requested amount :qfrom vault to recipient
;; @desc transfer-ft
;; @params token; ft-trait
;; @params amount
;; @params recipient
;; @restricted Contrac-Owner
;; @returns (response boolean)
(define-public (transfer-ft (token <ft-trait>) (amount uint) (recipient principal))
  (begin     
    (try! (check-is-approved contract-caller))
    (as-contract (unwrap! (contract-call? token transfer-fixed amount tx-sender recipient none) ERR-TRANSFER-FAILED))
    (ok true)
  )
)

;; @desc transfer-stx
;; @restricted Approved-Contracts
;; @params amount
;; @params sender
;; @recipient
;; @returns (response boolean)
(define-public (transfer-stx (amount uint) (sender principal) (recipient principal))
  (begin
    (try! (check-is-approved sender))
    (as-contract (unwrap! (stx-transfer? (/ (* amount (pow u10 u6)) ONE_8) tx-sender recipient) ERR-STX-TRANSFER-FAILED))
    (ok true)
  )
)

;; @desc transfer-sft
;; @restricted Contract-Owner
;; @params token ; sft-trait
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response boolean)
(define-public (transfer-sft (token <sft-trait>) (token-id uint) (amount uint) (recipient principal))
  (begin     
    (try! (check-is-approved contract-caller))
    (as-contract (unwrap! (contract-call? token transfer-fixed token-id amount tx-sender recipient) ERR-TRANSFER-FAILED))
    (ok true)
  )
)

;; perform flash loan
;; @desc flash-loan
;; @params flash-loan-user; flash-loan-user-trait
;; @params token; ft-trait
;; @params amount
;; @params memo; expiry
;; @returns (response uint)
(define-public (flash-loan (flash-loan-user <flash-loan-user-trait>) (token <ft-trait>) (amount uint) (memo (optional (buff 16))))
  (let 
    (
      (pre-bal (unwrap! (get-balance token) ERR-INVALID-FLASH-LOAN))
      (fee-with-principal (+ ONE_8 (var-get flash-loan-fee-rate)))
      (amount-with-fee (mul-up amount fee-with-principal))
      (recipient tx-sender)
    )

    ;; make sure current balance > loan amount
    (asserts! (> pre-bal amount) ERR-INSUFFICIENT-FLASH-LOAN-BALANCE)

    ;; transfer loan to flash-loan-user
    (as-contract (unwrap! (contract-call? token transfer-fixed amount tx-sender recipient none) ERR-LOAN-TRANSFER-FAILED))

    ;; flash-loan-user executes with loan received
    (try! (contract-call? flash-loan-user execute token amount memo))

    ;; return the loan + fee
    (unwrap! (contract-call? token transfer amount-with-fee tx-sender (as-contract tx-sender) none) ERR-POST-LOAN-TRANSFER-FAILED)
    (ok amount-with-fee)
  )
)

;; @desc ft-transfer-multi
;; @params token-x; ft-trait
;; @params amount-x; uint
;; @params token-y; ft-trait
;; @params amount-y;
;; @params recipient
;; @returns (response boolean)
(define-public (ft-transfer-multi (token-x <ft-trait>) (amount-x uint) (token-y <ft-trait>) (amount-y uint) (recipient principal))
  (begin 
    (try! (transfer-ft token-x amount-x recipient)) 
    (try! (transfer-ft token-y amount-y recipient))
    (ok true)
  )
)

;; @desc mul-down
;; @params a
;; @params b
;; @returns uint
(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc mul-up
;; @params a
;; @params b
;; @returns uint
(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)

;; contract initialisation
(begin
  (map-set approved-contracts .alex-reserve-pool true)
  (map-set approved-contracts .collateral-rebalancing-pool true)  
  (map-set approved-contracts .fixed-weight-pool true)  
  (map-set approved-contracts .liquidity-bootstrapping-pool true)  
  (map-set approved-contracts .yield-token-pool true)  
  (map-set approved-contracts .token-wstx true)
)