(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
        )        
        (if (is-eq token-x .token-wstx) (is-eq token-y .token-wstx))

            (is-ok (contract-call? .fixed-weight-pool get-helper token-x token-y u50000000 u50000000 dx))
            (contract-call? .fixed-weight-pool swap-helper token-x-trait token-y-trait u50000000 u50000000 dx min-dy)
            (if (is-ok (contract-call? .simple-weight-pool-alex get-helper token-x token-y dx))
                (contract-call? .simple-weight-pool-alex swap-helper token-x-trait token-y-trait dx min-dy)
                (if (is-ok (contract-call? .simple-weight-pool get-helper token-x token-y dx))
                    (contract-call? .simple-weight-pool swap-helper token-x-trait token-y-trait dx min-dy)
                    (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                        (if (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                            (ok (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                                                (try! (contract-call? .fixed-weight-pool swap-helper token-x-trait .age000-governance-token u50000000 u50000000 dx none)) min-dy))))
                            (ok (get dy (try! (contract-call? .simple-weight-pool swap-wstx-for-y token-y-trait 
                                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-wstx token-x-trait u50000000 dx none))) min-dy))))
                        )
                        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                            (if (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                                (contract-call? .fixed-weight-pool swap-helper .age000-governance-token token-y-trait u50000000 u50000000
                                    (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) min-dy)
                                (ok (get dy (try! (contract-call? .fixed-weight-pool swap-wstx-for-y token-y-trait u50000000 
                                                    (get dx (try! (contract-call? .simple-weight-pool swap-y-for-wstx token-x-trait dx none))) min-dy))))
                            )
                            (if (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                                (ok (get dy (try! (contract-call? .simple-weight-pool swap-wstx-for-y token-y-trait 
                                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-wstx .age000-governance-token u50000000 
                                                    (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) none))) min-dy))))
                                (ok (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                                                (get dy (try! (contract-call? .fixed-weight-pool swap-wstx-for-y .age000-governance-token u50000000 
                                                    (get dx (try! (contract-call? .simple-weight-pool swap-y-for-wstx token-x-trait dx none))) none))) min-dy))))
                            )
                        )
                    )
                )
            )
        )
    )
)

(define-read-only (get-helper (token-x principal) (token-y principal) (dx uint))
    (ok
        (if (or 
                (is-eq token-x .token-wstx)
                (is-eq token-y .token-wstx)
                (and
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
                    (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-y u50000000 u50000000))
                )
            )
            (try! (contract-call? .fixed-weight-pool get-helper token-x token-y u50000000 u50000000 dx))
            (if (or 
                    (is-eq token-x .age000-governance-token) 
                    (is-eq token-y .age000-governance-token)
                    (and
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                    )                    
                )
                (try! (contract-call? .simple-weight-pool-alex get-helper token-x token-y dx))
                (if (and 
                        (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx token-x u50000000 u50000000))
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

