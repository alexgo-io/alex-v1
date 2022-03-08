(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-private (is-fixed-weight-pool-v1-01 (token-x principal) (token-y principal))
    (or 
        (and
            (is-eq token-x .token-wstx)
            (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
        )
        (and
            (is-eq token-y .token-wstx)
            (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
        )
        (and
            (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
            (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
        )
    )
)

(define-private (is-simple-weight-pool-alex (token-x principal) (token-y principal))
    (or
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
)

(define-private (is-from-fixed-to-simple-alex (token-x principal) (token-y principal))
    (and 
        (or 
            (is-eq token-x .token-wstx)
            (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
        )
        (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
    )
)

(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
        )        
        (ok 
            (if (is-fixed-weight-pool-v1-01 token-x token-y) 
                (try! (contract-call? .fixed-weight-pool-v1-01 swap-helper token-x-trait token-y-trait u50000000 u50000000 dx min-dy))                        
                (if (is-simple-weight-pool-alex token-x token-y)
                    (try! (contract-call? .simple-weight-pool-alex swap-helper token-x-trait token-y-trait dx min-dy))        
                    (if (is-from-fixed-to-simple-alex token-x token-y)
                        (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                            (try! (contract-call? .fixed-weight-pool-v1-01 swap-helper token-x-trait .age000-governance-token u50000000 u50000000 dx none)) min-dy))) 
                        (try! (contract-call? .fixed-weight-pool-v1-01 swap-helper .age000-governance-token token-y-trait u50000000 u50000000 
                            (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) min-dy))
                    )
                )
            )
        )
    )
)

(define-read-only (get-helper (token-x principal) (token-y principal) (dx uint))
    (ok
        (if (is-fixed-weight-pool-v1-01 token-x token-y)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-helper token-x token-y u50000000 u50000000 dx))
            (if (is-simple-weight-pool-alex token-x token-y)
                (try! (contract-call? .simple-weight-pool-alex get-helper token-x token-y dx))
                (if (is-from-fixed-to-simple-alex token-x token-y)
                    (try! (contract-call? .simple-weight-pool-alex get-y-given-alex token-y 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-helper token-x .age000-governance-token u50000000 u50000000 dx)))) 
                    (try! (contract-call? .fixed-weight-pool-v1-01 get-helper .age000-governance-token token-y u50000000 u50000000 
                        (try! (contract-call? .simple-weight-pool-alex get-alex-given-y token-x dx))))
                )
            )
        )
    )
)

;; @desc oracle-instant-helper returns price of token-x in token-y
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-read-only (oracle-instant-helper (token-x principal) (token-y principal))
    (ok
        (if (is-fixed-weight-pool-v1-01 token-x token-y)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant token-x token-y u50000000 u50000000))
            (if (is-simple-weight-pool-alex token-x token-y)
                (try! (contract-call? .simple-weight-pool-alex get-oracle-instant token-x token-y))
                (if (is-from-fixed-to-simple-alex token-x token-y)
                    (div-down 
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-instant .age000-governance-token token-y))
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant .age000-governance-token token-x u50000000 u50000000))
                    )
                    (div-down 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant .age000-governance-token token-y u50000000 u50000000))
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-instant .age000-governance-token token-x))                        
                    )                                        
                )
            )
        )
    )
)

;; @desc oracle-resilient-helper returns moving average price of token-x in token-y
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-read-only (oracle-resilient-helper (token-x principal) (token-y principal))
    (ok
        (if (is-fixed-weight-pool-v1-01 token-x token-y)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient token-x token-y u50000000 u50000000))
            (if (is-simple-weight-pool-alex token-x token-y)
                (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient token-x token-y))
                (if (is-from-fixed-to-simple-alex token-x token-y)
                    (div-down 
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient .age000-governance-token token-y))
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient .age000-governance-token token-x u50000000 u50000000))
                    )
                    (div-down 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient .age000-governance-token token-y u50000000 u50000000))
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient .age000-governance-token token-x))                        
                    )                                        
                )
            )
        )
    )
)

(define-constant ONE_8 u100000000)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)


