(define-trait flash-loan-user-trait
  (
    ;; no need for params, as whoever implements this trait should know what he/she is doing
    ;; see test-flash-loan-user
    (execute () (response bool uint))
  )
)