;; (use-trait equation-trait)

(define-trait pool-trait
  ( 
    
    ;; get-token-x () (response string-ascii uint)
    (get-token-x () (response (string-ascii 32) uint))

    ;; get-token-y () (response string-ascii uint)
    (get-token-y () (response (string-ascii 32) uint))

    ;; get-equation () (response principal uint)
    (get-equation () (response principal uint))

    ;; get-shares-total () (response uint uint)
    (get-shares-total () (response uint uint))

    ;; get-balance-x () (response uint uint)
    (get-balance-x () (response uint uint))

    ;; get-balance-y () (response uint uint)
    (get-balance-y () (response uint uint))

    ;; get-fee-balance-x () (response uint uint)
    (get-fee-balance-x () (response uint uint))

    ;; get-fee-balance-y () (response uint uint)
    (get-fee-balance-y () (response uint uint))

    ;; get-fee-to-address () (response principal uint)
    (get-fee-to-address () (response principal uint))

    ;; get-pool-token () (response principal uint)
    (get-pool-token () (response principal uint))

    ;; get-name () (response string-ascii uint)
    (get-name () (response (string-ascii 32) uint))

    )
)
