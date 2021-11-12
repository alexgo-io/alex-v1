(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible-token.semi-fungible-token-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-constant ONE_8 (pow u10 u8))

(define-public (roll-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (the-key-token <sft-trait>) (flash-loan-user <flash-loan-user-trait>) (expiry-to-roll uint))
    (let
        (
            (reduce-data (try! (contract-call? .collateral-rebalancing-pool reduce-position-key token collateral expiry the-key-token ONE_8)))
            (collateral-amount (get dx reduce-data))
            (token-amount (get dy reduce-data))
            (token-to-collateral 
                                (if (is-eq token-amount u0) 
                                    u0 
                                    (try! (contract-call? .fixed-weight-pool swap collateral token u50000000 u50000000 token-amount none)) 
                                )
            )
        )
        (contract-call? .alex-vault flash-loan flash-loan-user collateral (+ collateral-amount token-to-collateral) (some expiry))
    )
)