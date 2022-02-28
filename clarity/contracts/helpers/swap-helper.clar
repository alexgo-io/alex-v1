(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (swap-helper-simple (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (ok
        (if (or 
                (is-eq (contract-of token-x-trait) .token-wstx)
                (is-eq (contract-of token-y-trait) .token-wstx)
                (and
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-x-trait) u50000000 u50000000))
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-y-trait) u50000000 u50000000))
                )
            )
            (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait token-y-trait u50000000 u50000000 dx min-dy))
            (if (or 
                    (is-eq (contract-of token-x-trait) .age000-governance-token) 
                    (is-eq (contract-of token-y-trait) .age000-governance-token)
                    (and
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-x-trait)))
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-y-trait)))
                    )                    
                )
                (try! (contract-call? .simple-weight-pool-alex swap-helper token-x-trait token-y-trait dx min-dy))
                (if (and 
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-x-trait) u50000000 u50000000))
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-y-trait)))
                    )
                    (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                        (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait .age000-governance-token u50000000 u50000000 dx none)) min-dy))) 
                    (try! (contract-call? .fixed-weight-pool swap-helper .age000-governance-token token-y-trait u50000000 u50000000 
                        (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) min-dy))
                )
            )
        )
    )
)
