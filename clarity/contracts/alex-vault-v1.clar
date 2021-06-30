(use-trait vault-trait .trait-vault-v1.vault-trait)
(use-trait ft-trait .sip-010-trait-ft-standard.sip-010-trait)



(define-constant ERR-NOT-AUTHORIZED u20401)
(define-constant INVALID-PAIR-ERR (err u201))
(define-constant ERR-INVALID-LIQUIDITY u202)


(define-map pairs-map
  { pair-id: uint }
  {
    token-x: <ft-trait>,
    token-y: <ft-trait>,
  }
)
