(define-trait stacking-pool-trait
  (
    (delegate-stx (uint principal (optional uint) (optional (tuple (hashbytes (buff 20)) (version (buff 1)))) (tuple (hashbytes (buff 20)) (version (buff 1))) uint) (response bool uint))
    
    (get-delegate-to () (response principal uint))

    (get-pool-pox-address () (response (optional (tuple (hashbytes (buff 20)) (version (buff 1)))) uint))
  )
)