
(use-trait ft-trait .trait-sip-010.sip-010-trait)


(define-trait flash-loan-user-trait
  (
    ;; (execute ((list 3 <ft-trait>) (list 3 uint)) (response bool uint))
    (execute (<ft-trait> <ft-trait> (optional <ft-trait>) uint uint (optional uint) principal) (response bool uint))
  )
)