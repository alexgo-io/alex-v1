(use-trait ft-trait .trait-sip-010.sip-010-trait)
;;(use-trait pool-token-trait #FILEPATH )
(use-trait trait-equation .trait-equation.trait-equation)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

;; Fungible Token SIP-010
;; TODO : Define all the error types in implementation file

(define-trait vault-trait
    (   
        ;; get-name(token-x:sip-010-token, token-y:sip-010-token):string-ascii
        (get-name (<ft-trait> <ft-trait>) (response (string-ascii 32) uint))

        ;; get-symbol(token-x:sip-010-token, token-y:sip-010-token):string-ascii
        (get-symbol (<ft-trait> <ft-trait>) (response (string-ascii 32) uint))

        ;; get-total-supply(token-x:sip-010-token, token-y:sip-010-token):uint
        (get-total-supply (<ft-trait> <ft-trait>) (response uint uint))

        ;; get-balances(token-x:sip-010-token, token-y:sip-010-token):list(uint, uint) 
        (get-balances (<ft-trait> <ft-trait>) (response (list 2 uint) uint)) ;; Tuple ? -> keyname

        ;; create-pool(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, equation:trait-equation, pair-name:string-ascii):bool
        ;;(create-pool (<ft-trait> <ft-trait> <pool-token-trait> <equation-trait> (string-ascii 32)) (response bool uint))    
    
        ;; flash-loan (loan-user trait-flash-loan-user) (list 3 trait-fungible-token) (list 3 uint) (response bool uint))
        (flash-loan (<flash-loan-user-trait> (list 3 <ft-trait>) (list 3 uint)) (response bool uint))

        ;; add-to-position(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, x uint, y uint):bool
        ;; (add-to-position (<ft-trait> <ft-trait> <pool-token-trait> uint uint) (response bool uint))

        ;; reduce-position(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, token uint):list(uint, uint)
        ;; (reduce-position (<ft-trait> <ft-trait> <pool-token-trait> uint) (response (list 2 uint) uint))

        ;; swap-x-for-y(token-x:sip-010-token, token-y:sip-010-token, dx uint):uint
        ;; (swap-x-for-y (<ft-trait> <ft-trait> uint) (response uint uint))

        ;; +swap-y-for-x(token-:sip-010-token, token-y:sip-10-token, dy uint):uint
        ;; (swap-y-for-x (<ft-trait> <ft-trait> uint) (response uint uint))

        ;; set-fee-to-address(token-x:sip-010-token, token-y:sip-010-token, address:principal):bool
        ;; (set-fee-to-address (<ft-trait> <ft-trait> principal) (response bool uint))

        ;; get-fee-to-address(token-x:sip-010-token, token-y:sip-010-token):principal
        ;; (get-fee-to-address (<ft-trait> <ft-trait>) (response principal uint))  ;; IS THIS RIGHT?? 

        ;; get-fees(token-x:sip-010-token, token-y:sip-010-token):list(uint, uint)
        ;; (get-fees (<ft-trait> <ft-trait>) (response (list 2 uint) uint))   

        ;; collect-fees(token-x:sip-010-token, token-y:sip-010-token):list(uint, uint)
        ;; (collect-fees (<ft-trait> <ft-trait>) (response (list 2 uint) uint)) 

        ;; flashSwap()
        ;;(flashSwap () (response uint uint))

        ;; flashLoan()
        ;;(flashLoan () (response uint uint))
    
        ;; get-y-given-x(token-x:sip-010-token, token-y:sip-010-token, dx uint):uint
        ;; (get-y-given-x (<ft-trait> <ft-trait> uint) (response uint uint))

        ;; get-x-given-y(token-x:sip-010-token, token-y:sip-010-token, dy uint):uint
        ;; (get-x-given-y (<ft-trait> <ft-trait> uint) (response uint uint))

        ;; get-x-given-price(token-x:sip-010-token, token-y:sip-010-token, price uint):uint
        ;; (get-x-given-price (<ft-trait> <ft-trait> uint) (response uint uint))
    
        ;; get-token-given-position(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, x uint, y uint):uint
        ;; (get-token-given-position (<ft-trait> <ft-trait> <pool-token-trait> uint uint) (response uint uint))

        ;; get-position-given-mint(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, token uint):list(uint, uint)
        ;; (get-position-given-mint (<ft-trait> <ft-trait> <pool-token-trait> uint) (response (list 2 uint) uint))

        ;; get-position-given-burn(token-x:sip-010-token, token-y:sip-010-token, pool-token:trait-pool-token, token uint):list(uint, uint)
        ;; (get-position-given-burn (<ft-trait> <ft-trait> <pool-token-trait> uint) (response (list 2 uint) uint))

    )
)
