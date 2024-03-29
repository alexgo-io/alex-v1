;; (impl-trait .trait-ownable.ownable-trait)
;; (impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)
(use-trait flash-loan-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-PAUSED (err u1001))
(define-constant ERR-INVALID-BALANCE (err u1002))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-AMOUNT-EXCEED-RESERVE (err u2024))

(define-data-var contract-owner principal tx-sender)

(define-map approved-contracts principal bool)
(define-map approved-tokens principal bool)
(define-map approved-flash-loan-users principal bool)

(define-map reserve principal uint)

(define-data-var flash-loan-fee-rate uint u0)

(define-data-var flash-loan-enabled bool false)
(define-data-var paused bool false)

;; read-only calls

(define-read-only (get-flash-loan-enabled)
  (var-get flash-loan-enabled)
)

(define-read-only (is-paused)
  (var-get paused)
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-flash-loan-fee-rate)
  (var-get flash-loan-fee-rate)
)

(define-read-only (get-reserve (the-token principal))
  (default-to u0 (map-get? reserve the-token))
)

(define-public (get-balance (the-token <ft-trait>))
  (begin 
    (try! (check-is-approved-token (contract-of the-token))) 
    (contract-call? the-token get-balance-fixed (as-contract tx-sender))
  )
)

;; governance calls

(define-public (set-flash-loan-enabled (enabled bool))
  (begin
    (try! (check-is-owner)) 
    (ok (var-set flash-loan-enabled enabled))
  )
)

(define-public (pause (new-paused bool))
    (begin 
        (try! (check-is-owner))
        (ok (var-set paused new-paused))
    )
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner)) 
    (ok (var-set contract-owner owner))
  )
)

(define-public (set-approved-contract (the-contract principal) (approved bool))
  (begin 
    (try! (check-is-owner)) 
    (ok (map-set approved-contracts the-contract approved))
  )
)

(define-public (set-approved-flash-loan-user (the-flash-loan-user principal) (approved bool))
  (begin 
    (try! (check-is-owner)) 
    (ok (map-set approved-flash-loan-users the-flash-loan-user approved))
  )
)

(define-public (set-approved-token (the-token principal) (approved bool))
  (begin 
    (try! (check-is-owner)) 
    (ok (map-set approved-tokens the-token approved))
  )
)

(define-public (set-flash-loan-fee-rate (fee uint))
  (begin 
    (try! (check-is-owner)) 
    (ok (var-set flash-loan-fee-rate fee))
  )
)

;; priviliged calls

(define-public (transfer-ft (the-token <ft-trait>) (amount uint) (recipient principal))
  (begin     
    (asserts! (not (is-paused)) ERR-PAUSED)
    (asserts! (and (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) (is-ok (check-is-approved-token (contract-of the-token)))) ERR-NOT-AUTHORIZED)
    (as-contract (contract-call? the-token transfer-fixed amount tx-sender recipient none))
  )
)

(define-public (transfer-ft-two (token-x-trait <ft-trait>) (dx uint) (token-y-trait <ft-trait>) (dy uint) (recipient principal))
  (begin 
    (try! (transfer-ft token-x-trait dx recipient))
    (transfer-ft token-y-trait dy recipient)
  )
)

(define-public (transfer-sft (the-token <sft-trait>) (token-id uint) (amount uint) (recipient principal))
  (begin     
    (asserts! (not (is-paused)) ERR-PAUSED)
    (asserts! (and (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) (is-ok (check-is-approved-token (contract-of the-token)))) ERR-NOT-AUTHORIZED) 
    (as-contract (contract-call? the-token transfer-fixed token-id amount tx-sender recipient))
  )
)

(define-public (flash-loan (the-flash-loan-user <flash-loan-trait>) (the-token <ft-trait>) (amount uint) (memo (optional (buff 16))))
  (begin
    (asserts! (not (is-paused)) ERR-PAUSED)
    (asserts! (and (is-ok (check-is-approved-flash-loan-user (contract-of the-flash-loan-user))) (is-ok (check-is-approved-token (contract-of the-token)))) ERR-NOT-AUTHORIZED)
    (let 
      (
        (pre-bal (unwrap! (get-balance the-token) ERR-INVALID-BALANCE))
        (fee-with-principal (+ ONE_8 (var-get flash-loan-fee-rate)))
        (amount-with-fee (mul-up amount fee-with-principal))
        (recipient tx-sender)
      )
    
      ;; make sure current balance > loan amount
      (asserts! (> pre-bal amount) ERR-INVALID-BALANCE)

      ;; transfer loan to flash-loan-user
      (as-contract (try! (contract-call? the-token transfer-fixed amount tx-sender recipient none)))

      ;; flash-loan-user executes with loan received
      (try! (contract-call? the-flash-loan-user execute the-token amount memo))

      ;; return the loan + fee
      (try! (contract-call? the-token transfer-fixed amount-with-fee tx-sender (as-contract tx-sender) none))
      (ok amount-with-fee)
    )
  )
)

(define-public (add-to-reserve (the-token principal) (amount uint))
  (begin
    (asserts! (not (is-paused)) ERR-PAUSED)
    (asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED) 
    (ok (map-set reserve the-token (+ amount (get-reserve the-token))))
  )
)

(define-public (remove-from-reserve (the-token principal) (amount uint))
  (begin
    (asserts! (not (is-paused)) ERR-PAUSED)
    (asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (get-reserve the-token)) ERR-AMOUNT-EXCEED-RESERVE)
    (ok (map-set reserve the-token (- (get-reserve the-token) amount)))
  )
)

;; private calls

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved-flash-loan-user (the-flash-loan-user principal))
  (ok (asserts! (default-to false (map-get? approved-flash-loan-users the-flash-loan-user)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved-token (flash-loan-token principal))
  (ok (asserts! (default-to false (map-get? approved-tokens flash-loan-token)) ERR-NOT-AUTHORIZED))
)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (mul-up (a uint) (b uint))
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
;; (set-contract-owner .executor-dao)
