
(use-trait ft-trait .trait-sip-010.sip-010-trait)


(define-trait flash-loan-user-trait
  (
    (execute (<ft-trait> <ft-trait> (optional <ft-trait>) uint uint (optional uint) principal) (response bool uint))
    (execute-2 (<ft-trait> <ft-trait> uint uint principal) (response bool uint))
    (execute-3 (<ft-trait> <ft-trait> <ft-trait> uint uint uint principal) (response bool uint))
  )
)