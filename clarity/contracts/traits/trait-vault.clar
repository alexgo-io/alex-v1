(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

;; TODO: can flash-loan support a list of tokens of arbitrary size?
(define-trait vault-trait
    (   
        ;; returns the balance of token
        (get-balance (<ft-trait>) (response uint uint))

        ;; flash loan currently supports single token loan
        (flash-loan (<flash-loan-user-trait> <ft-trait> uint) (response bool uint))
    
    )
)
