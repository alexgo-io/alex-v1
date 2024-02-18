(define-trait transfer-fixed-trait
  (
    (transfer-fixed (uint principal principal (optional (buff 34))) (response bool uint))   
    (get-balance-fixed (principal) (response uint uint))
  )
)