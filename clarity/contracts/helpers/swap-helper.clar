(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint) (min-dy (optional uint)))
    (ok
        (if (or 
                (is-eq (contract-of token-x-trait) .token-wstx)
                (is-eq (contract-of token-y-trait) .token-wstx)
                (and
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-x-trait) weight-y weight-x))
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-y-trait) weight-x weight-y))
                )
            )
            (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait token-y-trait weight-x weight-y dx min-dy))
            (if (or 
                    (is-eq (contract-of token-x-trait) .age000-governance-token) 
                    (is-eq (contract-of token-y-trait) .age000-governance-token)
                    (and
                        (is-some (contract-call? .fixed-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-x-trait) weight-y weight-x))
                        (is-some (contract-call? .fixed-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-y-trait) weight-x weight-y))
                    )                    
                )
                (try! (contract-call? .fixed-weight-pool-alex swap-helper token-x-trait token-y-trait weight-x weight-y dx min-dy))
                (if (and 
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx (contract-of token-x-trait) weight-y weight-x))
                        (is-some (contract-call? .fixed-weight-pool-alex get-pool-exists .age000-governance-token (contract-of token-y-trait) weight-x weight-y))
                    )
                    (get dy (try! (contract-call? .fixed-weight-pool-alex swap-alex-for-y token-y-trait weight-y
                        (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait .age000-governance-token weight-x weight-y dx none)) min-dy))) 
                    (try! (contract-call? .fixed-weight-pool swap-helper .age000-governance-token token-y-trait weight-x weight-y 
                        (get dx (try! (contract-call? .fixed-weight-pool-alex swap-y-for-alex token-x-trait weight-x dx none))) min-dy))
                )
            )
        )
    )
)
