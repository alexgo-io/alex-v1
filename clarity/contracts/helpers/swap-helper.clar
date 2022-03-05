(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
        )        
        (ok
            (if (or 
                    (and
                        (is-eq token-x .token-wstx)
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                    )
                    (and
                        (is-eq token-y .token-wstx)
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                    )
                    (and
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                    )
                )
                (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait token-y-trait u50000000 u50000000 dx min-dy))                        
                (if (or
                        (and
                            (is-eq token-x .age000-governance-token)
                            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                        )
                        (and 
                            (is-eq token-y .age000-governance-token)
                            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                        )
                        (and 
                            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                        )
                    )
                    (try! (contract-call? .simple-weight-pool-alex swap-helper token-x-trait token-y-trait dx min-dy))        
                    (if (and 
                            (or 
                                (is-eq token-x .token-wstx)
                                (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                            )
                            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
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
)

(define-read-only (get-helper (token-x principal) (token-y principal) (dx uint))
    (ok
        (if (or 
                (and
                    (is-eq token-x .token-wstx)
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                )
                (and
                    (is-eq token-y .token-wstx)
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                )
                (and
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                )
            )
            (try! (contract-call? .fixed-weight-pool get-helper token-x token-y u50000000 u50000000 dx))
            (if (or
                    (and
                        (is-eq token-x .age000-governance-token)
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                    )
                    (and 
                        (is-eq token-y .age000-governance-token)
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                    )
                    (and 
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                    )
                )
                (try! (contract-call? .simple-weight-pool-alex get-helper token-x token-y dx))
                (if (and 
                        (or 
                            (is-eq token-x .token-wstx)
                            (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                        )
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                    )
                    (try! (contract-call? .simple-weight-pool-alex get-y-given-alex token-y 
                        (try! (contract-call? .fixed-weight-pool get-helper token-x .age000-governance-token u50000000 u50000000 dx)))) 
                    (try! (contract-call? .fixed-weight-pool get-helper .age000-governance-token token-y u50000000 u50000000 
                        (try! (contract-call? .simple-weight-pool-alex get-alex-given-y token-x dx))))
                )
            )
        )
    )
)

(define-read-only (oracle-instant-helper (token-x principal) (token-y principal))
    (ok
        (if (or 
                (and
                    (is-eq token-x .token-wstx)
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                )
                (and
                    (is-eq token-y .token-wstx)
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                )
                (and
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                )
            )
            (try! (contract-call? .fixed-weight-pool get-oracle-instant token-x token-y u50000000 u50000000))
            (if (or
                    (and
                        (is-eq token-x .age000-governance-token)
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                    )
                    (and 
                        (is-eq token-y .age000-governance-token)
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                    )
                    (and 
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                    )
                )
                (try! (contract-call? .simple-weight-pool-alex get-oracle-instant token-x token-y))
                (if (and 
                        (or 
                            (is-eq token-x .token-wstx)
                            (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                        )
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                    )
                    (try! (contract-call? .simple-weight-pool-alex get-y-given-alex token-y 
                        (try! (contract-call? .fixed-weight-pool get-helper token-x .age000-governance-token u50000000 u50000000 dx)))) 
                    (try! (contract-call? .fixed-weight-pool get-helper .age000-governance-token token-y u50000000 u50000000 
                        (try! (contract-call? .simple-weight-pool-alex get-alex-given-y token-x dx))))
                )
            )
        )
    )
)


