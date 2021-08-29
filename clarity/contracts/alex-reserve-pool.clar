(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; alex-reserve-pool
;; <add a description here>

;; constants
;;

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;

(define-public (transfer-in (token <ft-trait>) (amount uint))
    (begin
        (try! (contract-call? token transfer .alex-vault (as-contract tx-sender) amount))
        (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-wbtc token u50000000 u50000000 amount))
    )
)

(define-public (transfer-out (token <ft-trait>) (amount uint))
    (let
        (
            (amount-to-wbtc (try! (contract-call? .fixed-weight-pool get-x-given-y .token-wbtc token u50000000 u50000000 amount)))
            (swapped-amount (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-wbtc token u50000000 u50000000 amount-to-wbtc)))
            (dy (get dy swapped-amount))
        )
        
        (try! (contract-call? token transfer (as-contract tx-sender) .alex-vault dy))
    )
)
