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

        ;; swap one token for another
        (swap-x-for-y (<ft-trait> <ft-trait> uint) (response uint uint))

        ;; flash loan to flash loan user up to 3 tokens of amounts specified
        (flash-loan (flash-loan-user-trait (list 3 <ft-trait>) (list 3 uint)) (response bool uint))
    )
)
