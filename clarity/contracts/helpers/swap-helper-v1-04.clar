(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (swap-helper-a (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (factor-x uint) (factor-y uint) (dx uint) (min-dz (optional uint)))
    (swap-helper token-y-trait token-z-trait factor-y (try! (swap-helper token-x-trait token-y-trait factor-x dx none)) min-dz)
)

(define-public (swap-helper-b 
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) 
    (factor-x uint) (factor-y uint) (factor-z uint)
    (dx uint) (min-dw (optional uint)))
    (swap-helper token-z-trait token-w-trait factor-z 
        (try! (swap-helper-a token-x-trait token-y-trait token-z-trait factor-x factor-y dx none)) none)
)

(define-public (swap-helper-c
    (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (token-z-trait <ft-trait>) (token-w-trait <ft-trait>) (token-v-trait <ft-trait>)
    (factor-x uint) (factor-y uint) (factor-z uint) (factor-w uint)
    (dx uint) (min-dv (optional uint)))
    (swap-helper-a token-z-trait token-w-trait token-v-trait factor-z factor-w
        (try! (swap-helper-a token-x-trait token-y-trait token-z-trait factor-x factor-y dx none)) min-dv)
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


