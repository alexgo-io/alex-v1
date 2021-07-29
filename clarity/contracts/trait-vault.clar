(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

;; Fungible Token SIP-010
;; TODO : Define all the error types in implementation file

(define-trait vault-trait
    (   
        ;; returns the balance of token
        (get-balance (<ft-trait>) (response uint uint))
        
        ;; returns list of {token, balance}
        (get-balances () (response (list 2000 {token: (string-ascii 32), balance: uint}) uint))

        ;; flash loan to flash loan user up to 3 tokens of amounts specified
        ;; (flash-loan (<flash-loan-user-trait> <ft-trait> <ft-trait> (optional <ft-trait>) uint uint (optional uint)) (response bool uint))
        ;; Thought it is ugly to have three function with different numbers of parameters
        ;; Have no other choices 
        (flash-loan-1 (<flash-loan-user-trait> <ft-trait> uint) (response bool uint))

        (flash-loan-2 (<flash-loan-user-trait> <ft-trait> <ft-trait> uint uint) (response bool uint))

        (flash-loan-3 (<flash-loan-user-trait> <ft-trait> <ft-trait> <ft-trait> uint uint uint) (response bool uint))

;;        (update-token-balance (<ft-trait>) (response bool uint))

        (transfer-to-vault (uint principal <ft-trait> (optional (buff 34))) (response bool uint))

        (transfer-from-vault (uint principal <ft-trait> (optional (buff 34))) (response bool uint))
    
    )
)
