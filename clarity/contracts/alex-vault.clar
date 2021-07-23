(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant token-galex-name "Alex Token")
(define-constant token-usda-name "USDA")
(define-constant token-ayusda-name "ayUSDA")

(define-constant insufficient-flash-loan-balance-err (err u3003))
(define-constant invalid-post-loan-balance-err (err u3004))
(define-constant user-execute-err (err u3005))
(define-constant transfer-one-by-one-err (err u3006))
(define-constant transfer-failed-err (err u3000))
(define-constant none-token-err (err u3007))
(define-constant get-token-fail (err u3008))

(define-data-var fee-amount uint u0)

;; This Vault should note all the transferred token balance 
(define-data-var balances (list 2000 {token: (string-ascii 32), balance: uint}) (list))

(define-map new-balances 
  { vault-owner: principal }
  {
    token-1: (string-ascii 32),
    balances: uint
    ;; Token and balances are keep inserted using map-insert 
  }
)


(define-map tokens-balances {token: (string-ascii 32) } { balance: uint})


;; Initialize the tokens-balances map with all the three tokens' balance from 0
;;(define-map tokens-balances {token: (string-ascii 32) } { balance: uint})
(map-set tokens-balances {token: token-galex-name} { balance: u0})
(map-set tokens-balances {token: token-usda-name} { balance: u0})
(map-set tokens-balances {token: token-ayusda-name} { balance: u0})

;; Initialize the pre-loan-balances-map map with all the three tokens' balance from 0
(define-map pre-loan-balances-map {token: (string-ascii 32) } { balance: uint})
(map-set pre-loan-balances-map {token: token-galex-name} { balance: u0})
(map-set pre-loan-balances-map {token: token-usda-name} { balance: u0})
(map-set pre-loan-balances-map {token: token-ayusda-name} { balance: u0})



(define-public (get-balance (token <ft-trait>))
  ;;use https://docs.stacks.co/references/language-functions#ft-get-balance
  ;; 
  (ok (unwrap! (contract-call? token get-balance tx-sender) get-token-fail))
)

;; (define-map names-map { name: (string-ascii 10) } { id: int })
;; (map-set names-map { name: "blockstack" } { id: 1337 })

;; returns list of {token, balance}
(define-read-only (get-balances)
  ;;Clarity doesn't support loop, so we need to maintain a list of tokens to apply map to get-balance
  ;;See get-pool-contracts and get-pools in fixed-weight-pool
  (let
    (
      ;; (tb-1 (map-get? tokens-balances { token: token-galex-name }))
      (tb-1 (default-to u0 (get balance (map-get? tokens-balances { token: token-galex-name }))))
      (tb-2 (default-to u0 (get balance (map-get? tokens-balances { token: token-usda-name }))))
      (tb-3 (default-to u0 (get balance (map-get? tokens-balances { token: token-ayusda-name }))))
      (result (list {token: token-galex-name, balance: tb-1} 
                    {token: token-usda-name, balance: tb-2} 
                    {token: token-ayusda-name, balance: tb-3}))
    )
    (ok result)
  )
)

(define-public (update-token-balance
                (token-trait <ft-trait>))
  (let
    (
      (token-name (unwrap-panic (contract-call? token-trait get-name)))
      (balance (unwrap-panic (get-balance token-trait)))
    )
    (map-set tokens-balances { token: token-name } { balance: balance })
    (ok true)
  )
)
 
(define-public (transfer-to-vault
      (amount uint)  
      (sender principal) 
      (recipient principal) 
      (token-trait <ft-trait>) 
      (memo (optional (buff 34))))
      (let 
        (
          (token-symbol (unwrap-panic (contract-call? token-trait get-symbol)))
          (token-name (unwrap-panic (contract-call? token-trait get-name)))
          (vault-balances (var-get balances)) ;; list 
        )
        
        ;; Transfering
        ;; Initially my idea was to implement transferring function here, but that implicits violating sip010 standard. 
        (asserts! (is-ok (contract-call? token-trait transfer amount tx-sender recipient none)) transfer-failed-err)
        (asserts! (is-ok (update-token-balance token-trait)) transfer-failed-err)
        
        (ok true)
      )
)

;; flash loan to flash loan user up to 3 tokens of amounts specified
(define-public (flash-loan 
                (flash-loan-user <flash-loan-user-trait>) 
                (token1 <ft-trait>) 
                (token2 <ft-trait>) 
                (token3  (optional <ft-trait>)) 
                (amount1 uint) 
                (amount2 uint) 
                (amount3 (optional uint)))
  
  (begin 
      ;; TODO: step 1 transfer tokens to user one by one
      (asserts! (is-ok (transfer-to-user flash-loan-user token1 amount1)) transfer-one-by-one-err)  
      (asserts! (is-ok (transfer-to-user flash-loan-user token2 amount2)) transfer-one-by-one-err)
      ;; At least It wouldn't been called when the token3 is none
      (if (and 
            (is-some token3)
            (is-some amount3)
          ) 
        (asserts! (is-ok (transfer-to-user flash-loan-user (unwrap! token3 none-token-err) (unwrap-panic amount3))) transfer-one-by-one-err)
        false
       )
    ;; TODO: step 2 call user.execute. the one could do anything then pay the tokens back ,see test-flash-loan-user
      (asserts! (is-ok (contract-call? flash-loan-user execute token1 token2 token3 amount1 amount2 amount3 tx-sender)) user-execute-err)
    ;; TODO: step 3 check if the balance is incorrect
      (asserts! (is-ok (after-pay-back-check token1)) transfer-one-by-one-err)
      (asserts! (is-ok (after-pay-back-check token2)) transfer-one-by-one-err)
      (if (is-some token3) 
        (asserts! (is-ok (after-pay-back-check (unwrap! token3 none-token-err) u2)) transfer-one-by-one-err)
        false
       )
      (ok true)
  )
)


(define-private (transfer-to-user (flash-loan-user <flash-loan-user-trait>) (token <ft-trait>) (amount uint)) 
  (begin
    (let 
      (
        (pre-b (unwrap-panic (contract-call? token get-balance tx-sender)))
        (token-name (unwrap-panic (contract-call? token get-name)))
      )
      (map-set pre-loan-balances-map { token: token-name } { balance: pre-b })
      (asserts! (>= pre-b amount) insufficient-flash-loan-balance-err)
    )
    ;; (let 
    ;;   (
    ;;     (token-name (unwrap-panic (contract-call? token get-name)))
    ;;     (tb-1 (default-to u0 (get balance (map-get? pre-loan-balances-map { token: token-name }))))
    ;;   )
    ;;   (print token-name)
    ;;   (print tb-1)
    ;; )
    ;; ;; TODO: calculate this fee later
    ;; ;; (var-set fee-amount (calculateFlashLoanFeeAmount amount))
    
    (asserts! (is-ok (contract-call? token transfer amount tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
    ;; (let 
    ;;   (
    ;;     (pre-b (unwrap-panic (contract-call? token get-balance tx-sender)))
    ;;     (token-name (unwrap-panic (contract-call? token get-name)))
    ;;   )
    ;;   (print u"**********************************************")
    ;;   (print pre-b)
    ;; )  
    (ok true)
  )
)

(define-private (after-pay-back-check (token <ft-trait>))
  (begin 
    (let 
      (
        (post-b (unwrap-panic (contract-call? token get-balance tx-sender)))
        (token-name (unwrap-panic (contract-call? token get-name)))
        (pre-b (default-to u0 (get balance (map-get? pre-loan-balances-map { token: token-name }))))
      )
      (asserts! (>= post-b pre-b) invalid-post-loan-balance-err)
    )
    (ok true)
  )
)


(define-private (calculateFlashLoanFeeAmount (amount uint))
;;TODO: need to implement Flash loan fee amount, now just leave it 1%
    (/ amount u100)
)