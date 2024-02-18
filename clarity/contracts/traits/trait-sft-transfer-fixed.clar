(define-trait sft-transfer-fixed-trait
  (
    (transfer-fixed (uint uint principal principal) (response bool uint))
    (get-balance-fixed (uint principal) (response uint uint))
  )
)