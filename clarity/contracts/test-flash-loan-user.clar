(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
;; (use-trait vault-trait .trait-vault.vault-trait)

(define-constant none-token-err (err u3007))
(define-constant transfer-failed-err (err u3000))
(define-constant user-execute-err (err u3005))

;; (define-public (execute 
;;                     (token1 <ft-trait>) 
;;                     (token2 <ft-trait>) 
;;                     (token3 (optional <ft-trait>)) 
;;                     (amount1 uint) 
;;                     (amount2 uint) 
;;                     (amount3 (optional uint)) 
;;                     (the-vault principal))
;;     (let 
;;         (
;;             (weight1 u50000000)
;;             (weight2 u50000000)
;;         )

;;         ;; do whatever you want to do with the loan you have
;;         ;; TODO: something is wrong on calling this swap-x-for-y , So I just commentted it by now.
;;         ;; (asserts! (is-ok (contract-call? fixed-weight-pool swap-x-for-y token1 token2 weight1 weight2 the-vault amount1)))

;;         ;; once you are done, return the loan
;;         (asserts! (is-ok (contract-call? token1 transfer amount1 (as-contract tx-sender) the-vault none)) transfer-failed-err)  
;;         (asserts! (is-ok (contract-call? token2 transfer amount2 (as-contract tx-sender) the-vault none)) transfer-failed-err)  
;;          (if (and 
;;                 (is-some token3)
;;                 (is-some amount3)
;;             ) 
;;             (asserts! (is-ok (transfer-to-user (unwrap! token3 none-token-err) (unwrap-panic amount3) the-vault)) transfer-failed-err)
;;             false
;;         )
;;         (ok true)
;;     )
;; )
;; (define-private (transfer-to-user (token <ft-trait>) (amount uint) (to principal))
;;   (begin
;;     (asserts! (is-ok (contract-call? token transfer amount (as-contract tx-sender) to none)) transfer-failed-err)  
;;     (ok true)
;;   )
;; )

(define-public (execute-1 
                    (token <ft-trait>) 
                    (amount uint) 
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
        (asserts! (is-ok (contract-call? token transfer amount (as-contract tx-sender) the-vault none)) transfer-failed-err)
        (ok true)
    )
)

(define-public (execute-2 
                    (token1 <ft-trait>) 
                    (token2 <ft-trait>) 
                    (amount1 uint) 
                    (amount2 uint)  
                    (the-vault principal))
    (let 
        (
            (weight1 u50000000)
            (weight2 u50000000)
        )
        ;; TODO: If I want to do someting with <vault-trait> I need to add it to trait-flash-loan-user's depends_on in Clarinet.toml
        ;; Because vault-trait already used trait-flash-loan-user in trait-vault, 
        ;; so if I add trait-vault to trait-flash-loan-user's depends_on, there will be a Error: cycling dependencies:
        ;; Thus, I can't make a call below. <by Tiger>
        
        ;; (asserts! (is-ok (contract-call? 
        ;;                     .fixed-weight-pool 
        ;;                     swap-x-for-y 
        ;;                     token1 
        ;;                     token2 
        ;;                     weight1 
        ;;                     weight2 
        ;;                     .alex-vault
        ;;                     (* u200 u1000000))) user-execute-err)
        ;; (asserts! (is-ok (contract-call? 
        ;;                     .fixed-weight-pool 
        ;;                     test)) user-execute-err)
        ;; once you are done, return the loan
        (asserts! (is-ok (contract-call? token1 transfer amount1 (as-contract tx-sender) the-vault none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 (as-contract tx-sender) the-vault none)) transfer-failed-err)
        (ok true)
    )
)

(define-public (execute-3 
                    (token1 <ft-trait>) 
                    (token2 <ft-trait>)
                    (token3 <ft-trait>) 
                    (amount1 uint) 
                    (amount2 uint)
                    (amount3 uint)  
                    (the-vault principal))
    (let 
        (
            (weight1 u50000000)
            (weight2 u50000000)
        )

        
        ;; once you are done, return the loan
        (asserts! (is-ok (contract-call? token1 transfer amount1 (as-contract tx-sender) the-vault none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token2 transfer amount2 (as-contract tx-sender) the-vault none)) transfer-failed-err)
        (asserts! (is-ok (contract-call? token3 transfer amount3 (as-contract tx-sender) the-vault none)) transfer-failed-err)
        
        ;; way 1 works
        ;; (asserts! (is-ok (test token1)) transfer-failed-err)
        ;; way 2 works
        ;; (asserts! (is-ok (test token1 token2)) transfer-failed-err)
        ;; way 3 works
        ;; (asserts! (is-ok (test token1 (some token2))) transfer-failed-err)
        
        (ok true)
    )
)
(define-public (test 
                (token1 <ft-trait>) 
                (token2 (optional <ft-trait>))  
                ) 
    (if (is-some token2)
        (test2 token1 (unwrap-panic token2))
        (test1 token1)
    )
)
(define-private (test1 (token1 <ft-trait>))
    (ok true)
)
(define-private (test2 (token1 <ft-trait>) (token2 <ft-trait>))
    (ok true)
)