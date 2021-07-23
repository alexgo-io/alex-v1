(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant none-token-err (err u103))
(define-constant transfer-failed-err (err u3000))

(define-public (execute 
                    (token1 <ft-trait>) 
                    (token2 <ft-trait>) 
                    (token3 (optional <ft-trait>)) 
                    (amount1 uint) 
                    (amount2 uint) 
                    (amount3 (optional uint)) 
                    (the-vault principal))
    (let 
        (
            (weight1 u50000000)
            (weight2 u50000000)
        )

        ;; do whatever you want to do with the loan you have
        ;; TODO: something is wrong on calling this swap-x-for-y , So I just commentted it by now.
        ;; (asserts! (is-ok (contract-call? fixed-weight-pool swap-x-for-y token1 token2 weight1 weight2 the-vault amount1)))

        ;; once you are done, return the loan
        (asserts! (is-ok (contract-call? token1 transfer amount1 (as-contract tx-sender) the-vault none)) transfer-failed-err)  
        (asserts! (is-ok (contract-call? token2 transfer amount2 (as-contract tx-sender) the-vault none)) transfer-failed-err)  
         (if (and 
                (is-some token3)
                (is-some amount3)
            ) 
            (asserts! (is-ok (transfer-to-user (unwrap! token3 none-token-err) (unwrap-panic amount3) the-vault)) transfer-failed-err)
            false
        )
        ;; (match token3
        ;;     (contract-call? token3 transfer amount3 (as-contract tx-sender) the-vault none)
        ;;     err transfer-failed-err
        ;; )
        (ok true)
    )
)
(define-private (transfer-to-user (token <ft-trait>) (amount uint) (to principal))
  (begin
    (asserts! (is-ok (contract-call? token transfer amount (as-contract tx-sender) to none)) transfer-failed-err)  
    (ok true)
  )
)