(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-public (execute (token <ft-trait>) (amount uint) (memo (optional (buff 16))))
  (ok true)
)