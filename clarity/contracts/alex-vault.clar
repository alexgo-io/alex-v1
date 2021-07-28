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

(define-data-var fee-amount uint u0)

;; List of tokens passed vault in history
(define-data-var vault-owned-token (list 2000 (string-ascii 32)) (list))

;; token balances map owned by vault
(define-map tokens-balances {token: (string-ascii 32) } { balance: uint})


;; return balance of token held by vault
(define-public (get-balance (token <ft-trait>))
  (let
    (
      (token-name (unwrap! (contract-call? token get-name) token-type-err))
      (target-balance (default-to u0 (get balance (map-get? tokens-balances { token: token-name }))))
    )
    (ok target-balance)
  )
)

;; For Debugging
(define-read-only (get-tokenlist)
    (var-get vault-owned-token)
)
;; returns list of {token, balance}
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
    (ok result)
  )    
)

;; bug: add-token-balance also pass the amount of tokens being added to balance
;; bug: add-token-balance should first add token-name to the vault-owned-token if needed, 
;;      before looking at the current balance held of that token by vault.
;; Ans : Seems not required because amount of tokens being added can be retreived through line 81 ??
(define-private (add-token-balance
                (token-trait <ft-trait>) (sender principal))
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
      ;; Yes, It is but I think it makes confusion so I'll change the name
      (added-balance (unwrap! (contract-call? token-trait get-balance sender) invalid-balance)) 
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
    ;; If Token- Name does not exist, its going to pass the 'map-insert' above which sets balance 0.
    (if (is-eq current-balance u0)
      (begin

        (var-set vault-owned-token (unwrap-panic (as-max-len? (append vault-token-list token-name) u2000)))
        (map-set tokens-balances { token: token-name} updated-token-map )
        (ok (map-set tokens-balances { token: token-name } updated-token-map ))
      )
      (begin
      (ok (map-set tokens-balances { token: token-name } updated-token-map ))
      )
  )

    )
  )
)

(define-private (remove-token-balance
                (token-trait <ft-trait>) (sender principal))
  (let
    (
      (token-name (unwrap! (contract-call? token-trait get-name) none-token-err))
      ;;(balance (unwrap! (get-balance token-trait) none-token-err))
      (updated-balance (unwrap! (contract-call? token-trait get-balance sender) invalid-balance)) 
      ;; (current-token-map (unwrap! (map-get? tokens-balances { token: token-name }) get-token-fail))
      ;; (current-balance (get balance current-token-map))

      ;; (updated-token-map (merge current-token-map {
      ;;   balance: (unwrap! (contract-call? .math-fixed-point sub-fixed current-balance balance) math-call-err)
      ;; }))
    )
    (map-set tokens-balances { token: token-name} { balance : updated-balance});;updated-token-map )
    ;; (print balance)
    ;; (print current-token-map)
    (ok true)
  )
)

;; bug: transfer-to-vault implies the tokens are sent from sender to vault. Therefore param should not include recipient.
(define-public (transfer-to-vault
      (amount uint)  
      (sender principal) 
      (recipient principal) ;; (as-contract tx-sender) 
      (token-trait <ft-trait>) 
      (memo (optional (buff 34))))
      (let 
        (
          (token-symbol (unwrap! (contract-call? token-trait get-symbol) get-token-fail))
          (token-name (unwrap! (contract-call? token-trait get-name) get-token-fail))
        )
        
        ;; Transfering
        ;; Initially my idea was to implement transferring function here, but that implicits violating sip010 standard. 
        
        ;; bug: why are we not hard-coding recipient to be vault?
        (asserts! (is-ok (contract-call? token-trait transfer amount sender recipient memo)) transfer-failed-err)
        (asserts! (is-ok (add-token-balance token-trait recipient)) internal-function-call-err)
        
        (ok true)
      )
)

;; bug: same as transfer-to-vault
(define-public (transfer-from-vault
      (amount uint)  
      (sender principal) ;; Vault
      (recipient principal) 
      (token-trait <ft-trait>) 
      (memo (optional (buff 34))))
      (let 
        (
          (token-symbol (unwrap! (contract-call? token-trait get-symbol) none-token-err))
          (token-name (unwrap! (contract-call? token-trait get-name) none-token-err))
          ;;(vault-balances (var-get balances)) ;; list 
        )
        
        ;; Transfering
        ;; Initially my idea was to implement transferring function here, but that implicits violating sip010 standard. 
        (asserts! (is-ok (contract-call? token-trait transfer amount sender recipient none)) transfer-failed-err)
        (asserts! (is-ok (remove-token-balance token-trait sender)) internal-function-call-err)
        
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
      (let 
        (
          (pre-b-1 (unwrap-panic (contract-call? token1 get-balance tx-sender)))
          (pre-b-2 (unwrap-panic (contract-call? token2 get-balance tx-sender)))
          
        )
        (asserts! (> pre-b-1 amount1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-2 amount2) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token1 transfer amount1 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute token1 token2 token3 amount1 amount2 amount3 tx-sender)) user-execute-err)
        (let 
          (
            (post-b-1 (unwrap! (contract-call? token1 get-balance tx-sender) unwrap-err))
            (post-b-2 (unwrap! (contract-call? token2 get-balance tx-sender) unwrap-err))
          )
          (asserts! (>= post-b-1 pre-b-1) invalid-post-loan-balance-err)
          (asserts! (>= post-b-2 pre-b-2) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)

(define-public (flash-loan-1 
                (flash-loan-user <flash-loan-user-trait>) 
                (token <ft-trait>) 
                (amount uint))
  
  (begin 
      (let 
        (
          ;; bug: why are we getting the balance of tx-sender, rather than that of vault?
          (pre-b (unwrap-panic (contract-call? token get-balance tx-sender)))
        )
        (asserts! (> pre-b amount) insufficient-flash-loan-balance-err)
        ;; bug: why are we sending amount of token from tx-sender to flash-loan-user, rather than from vault to flash-loan-user?
        (asserts! (is-ok (contract-call? token transfer amount tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-1 token amount tx-sender)) user-execute-err)
        (let 
          (
            ;; bug: same as above.
            (post-b (unwrap! (contract-call? token get-balance tx-sender) unwrap-err))
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
          (pre-b-1 (unwrap-panic (contract-call? token1 get-balance tx-sender)))
          (pre-b-2 (unwrap-panic (contract-call? token2 get-balance tx-sender)))
          
        )
        (asserts! (> pre-b-1 amount1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-2 amount2) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token1 transfer amount1 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-2 token1 token2 amount1 amount2 tx-sender)) user-execute-err)
        (let 
          (
            (post-b-1 (unwrap! (contract-call? token1 get-balance tx-sender) unwrap-err))
            (post-b-2 (unwrap! (contract-call? token2 get-balance tx-sender) unwrap-err))
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
          (pre-b-1 (unwrap-panic (contract-call? token1 get-balance tx-sender)))
          (pre-b-2 (unwrap-panic (contract-call? token2 get-balance tx-sender)))
          (pre-b-3 (unwrap-panic (contract-call? token3 get-balance tx-sender)))
        )
        (asserts! (> pre-b-1 amount1) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-2 amount2) insufficient-flash-loan-balance-err)
        (asserts! (> pre-b-3 amount3) insufficient-flash-loan-balance-err)
        (asserts! (is-ok (contract-call? token1 transfer amount1 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token3 transfer amount3 tx-sender (contract-of flash-loan-user) none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? flash-loan-user execute-3 token1 token2 token3 amount1 amount2 amount3 tx-sender)) user-execute-err)
        (let 
          (
            (post-b-1 (unwrap! (contract-call? token1 get-balance tx-sender) unwrap-err))
            (post-b-2 (unwrap! (contract-call? token2 get-balance tx-sender) unwrap-err))
            (post-b-3 (unwrap! (contract-call? token2 get-balance tx-sender) unwrap-err))
          )
          (asserts! (>= post-b-1 pre-b-1) invalid-post-loan-balance-err)
          (asserts! (>= post-b-2 pre-b-2) invalid-post-loan-balance-err)
          (asserts! (>= post-b-3 pre-b-3) invalid-post-loan-balance-err)
        )
      )  
      (ok true)
  )
)
