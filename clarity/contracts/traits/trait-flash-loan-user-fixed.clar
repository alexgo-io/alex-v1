(use-trait ft-trait .trait-transfer-fixed.transfer-fixed-trait)

(define-trait flash-loan-user-fixed-trait
  (
    (execute (<ft-trait> uint (optional (buff 16))) (response bool uint))
  )
)