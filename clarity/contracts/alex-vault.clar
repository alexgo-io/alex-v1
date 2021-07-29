(impl-trait .trait-vault.vault-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

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
(define-constant internal-function-call-err (err u2011))

;; Fee
(define-data-var fee-amount uint u0)

;; Vault Address hardcoded
(define-data-var vault-address principal 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault)

;; List of tokens passed vault in history
(define-data-var vault-owned-token (list 2000 (string-ascii 32)) (list))

;; token balances map owned by vault
(define-map tokens-balances {token: (string-ascii 32) } { balance: uint})


;; Return balance of token held by vault
(define-public (get-balance (token <ft-trait>))
  (let
    (
      (token-name (unwrap! (contract-call? token get-name) token-type-err))
      (target-balance (default-to u0 (get balance (map-get? tokens-balances { token: token-name }))))
    )
    (ok target-balance)
  )
)

;; Returns list of {token, balance}
(define-read-only (get-balances)
  (ok (map get-tuple (var-get vault-owned-token)))
)

;; Preprocessing function to make map value to tuple
(define-private (get-tuple (token-name (string-ascii 32)))
  (let
    (
      (token-balance (default-to u0 (get balance (map-get? tokens-balances { token: token-name }))))
      (result {token: token-name, balance: token-balance})
    )
    result  ;; Let's keep this for now. Internal function 'map' cannot crack if its wrapped.
  )    
)

;; bug: add-token-balance also pass the amount of tokens being added to balance
;; bug: add-token-balance should first add token-name to the vault-owned-token if needed, 
;;      before looking at the current balance held of that token by vault.
;; Ans : Bug Fixed passed added-balance is added to current vault balance.
(define-private (add-token-balance
                (token-trait <ft-trait>) (added-balance uint))
  (begin
    (let
      (
        (token-name (unwrap! (contract-call? token-trait get-name) get-token-fail))          
      )

      ;; bug: what if token-name already exists? wouldn't this reset balance to zero?
      ;; Answer : It's Okay since map-insert only exerts when the token-name does not exist. Or else, its going to return false.
      (map-insert tokens-balances { token: token-name } { balance: u0 })
    )
  
  (let
    (
      (token-name (unwrap! (contract-call? token-trait get-name) get-token-fail))
      ;; bug: balance = amount of tokens being added to current balance, not all the balance the sender holds in token.
      ;; Answer : Fixed 
      (current-token-map (unwrap! (map-get? tokens-balances { token: token-name }) get-token-fail)) 
      (current-balance (get balance current-token-map))
      (vault-token-list (var-get vault-owned-token))
      (updated-token-map (merge current-token-map {
        balance: (unwrap! (contract-call? .math-fixed-point add-fixed current-balance added-balance) math-call-err)
      }))
    )
    ;; bug: this doesn't make sense. if token-name doesn't exist in vault-owned-token, it also shouldn't exist in token-balances. 
    ;;      Therefore Line 77 should have already thrown get-token-fail.
    ;; Ans : It seems okay since token-name is just getting the name of token from token trait.
    (if (is-none (index-of vault-token-list token-name))
      (begin
          (var-set vault-owned-token (unwrap-panic (as-max-len? (append vault-token-list token-name) u2000)))
          (ok (map-set tokens-balances { token: token-name } updated-token-map ))
        )
      (begin
      (ok (map-set tokens-balances { token: token-name } updated-token-map ))
      )
  )

    )
  )
)

;; Refresh Token Balance
(define-private (refresh-token-balance
                (token-trait <ft-trait>))
  (let
    (
      (token-name (unwrap! (contract-call? token-trait get-name) none-token-err))
      (vault (as-contract tx-sender));;(var-get vault-address))
      ;; Refresh the map with current vault balance
      (updated-balance (unwrap! (contract-call? token-trait get-balance vault) invalid-balance)) 
    )
    (map-set tokens-balances { token: token-name} { balance : updated-balance})

    (ok true)
  )
)

;; bug: transfer-to-vault implies the tokens are sent from sender to vault. Therefore param should not include recipient.
;; Answer : Fixed with hardcoded vault address
(define-public (transfer-to-vault
      (amount uint)  
      (sender principal) 
      (token-trait <ft-trait>) 
      (memo (optional (buff 34))))
      (let 
        (
          (token-symbol (unwrap! (contract-call? token-trait get-symbol) get-token-fail))
          (token-name (unwrap! (contract-call? token-trait get-name) get-token-fail))
          (vault (as-contract tx-sender));;(var-get vault-address))
        )
        
        ;; Transfering
        ;; bug: why are we not hard-coding recipient to be vault?
        ;; Answer : Fixed 
        (asserts! (is-ok (contract-call? token-trait transfer amount sender vault memo)) transfer-failed-err)
        (asserts! (is-ok (add-token-balance token-trait amount)) internal-function-call-err)
        
        (ok true)
      )
)

;; bug: same as transfer-to-vault
;; Answer : Fixed
(define-public (transfer-from-vault
      (amount uint)  
      (recipient principal) 
      (token-trait <ft-trait>) 
      (memo (optional (buff 34))))
      (let 
        (
          (token-symbol (unwrap! (contract-call? token-trait get-symbol) none-token-err))
          (token-name (unwrap! (contract-call? token-trait get-name) none-token-err))
          (vault (as-contract tx-sender));;(var-get vault-address))
        )
        
        ;; Transfering
        (asserts! (is-ok (contract-call? token-trait transfer amount vault recipient none)) transfer-failed-err)
        (asserts! (is-ok (refresh-token-balance token-trait)) internal-function-call-err)
        
        (ok true)
      )
)


;; (define-public (flash-loan 
;;                 (flash-loan-user <flash-loan-user-trait>) 
;;                 (token-1 <ft-trait>)
;;                 (token-2 <ft-trait>) 
;;                 (token-3 (optional <ft-trait>)) 
;;                 (amount1 uint)
;;                 (amount2 (optional uint)))

    
;;     (if (is-some token-3)
;;       (ok (flash-loan-3 flash-loan-user token-1 token-2 (unwrap-panic token-3) amount1 (unwrap-panic amount2)))
;;       (ok (flash-loan-2 flash-loan-user token-1 token-2 amount1))
;;     )
   
;; )

(define-public (flash-loan-1 
                (flash-loan-user <flash-loan-user-trait>) 
                (token <ft-trait>) 
                (amount uint))
  
  (begin 
      (let 
        (
          (pre-b (unwrap! (get-balance token) invalid-balance))
        )
        (asserts! (> pre-b amount) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token transfer amount .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-1 token amount .alex-vault)) user-execute-err)
        (let 
          (
            ;; bug: same as above.
            (post-b (unwrap! (get-balance token) invalid-balance))
          )
          (asserts! (>= post-b pre-b) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)

(define-public (flash-loan-2 
                (flash-loan-user <flash-loan-user-trait>) 
                (token1 <ft-trait>) 
                (token2 <ft-trait>) 
                (amount1 uint) 
                (amount2 uint))
  
  (begin 
      (let 
        (
          (pre-b-1 (unwrap! (get-balance token1) invalid-balance))
          (pre-b-2 (unwrap! (get-balance token1) invalid-balance))
        )
        (asserts! (> pre-b-1 amount1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-2 amount2) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token1 transfer amount1 .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-2 token1 token2 amount1 amount2 .alex-vault)) user-execute-err)
        (let 
          (
            (post-b-1 (unwrap! (get-balance token1) invalid-balance))
            (post-b-2 (unwrap! (get-balance token1) invalid-balance))
          )
          (asserts! (>= post-b-1 pre-b-1) invalid-post-loan-balance-err)
          (asserts! (>= post-b-2 pre-b-2) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)

(define-public (flash-loan-3 
                (flash-loan-user <flash-loan-user-trait>) 
                (token1 <ft-trait>) 
                (token2 <ft-trait>)
                (token3 <ft-trait>) 
                (amount1 uint) 
                (amount2 uint)
                (amount3 uint))
  
  (begin 
      (let 
        (
          (pre-b-1 (unwrap! (get-balance token1) invalid-balance))
          (pre-b-2 (unwrap! (get-balance token1) invalid-balance))
          (pre-b-3 (unwrap! (get-balance token3) invalid-balance))
        )
        (asserts! (> pre-b-1 amount1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-2 amount2) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-3 amount3) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token1 transfer amount1 .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token3 transfer amount3 .alex-vault (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-3 token1 token2 token3 amount1 amount2 amount3 .alex-vault)) user-execute-err)
        (let 
          (
            (post-b-1 (unwrap! (get-balance token1) invalid-balance))
            (post-b-2 (unwrap! (get-balance token1) invalid-balance))
            (post-b-3 (unwrap! (get-balance token3) invalid-balance))
          )
          (asserts! (>= post-b-1 pre-b-1) invalid-post-loan-balance-err)
          (asserts! (>= post-b-2 pre-b-2) invalid-post-loan-balance-err)
          (asserts! (>= post-b-3 pre-b-3) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)

;; (define-public (flash-loan 
;;                 (flash-loan-user <flash-loan-user-trait>) 
;;                 (token1 <ft-trait>) 
;;                 (token2 <ft-trait>)
;;                 (token3 (optional <ft-trait>)) 
;;                 (amount1 uint) 
;;                 (amount2 uint)
;;                 (amount3 uint))
  
;;   (begin 
;;       () 
;;       (ok true)
;;   )
;; )
