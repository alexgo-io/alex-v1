(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-trait pool-token-trait
  (
    ;;mint(principal uint):bool
    (mint (principal uint) (response bool uint))
    
    ;;burn(principal uint):bool
    (burn (principal uint) (response bool uint))
  )
)