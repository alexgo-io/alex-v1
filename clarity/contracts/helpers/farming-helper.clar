(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-private (stake-tokens (token-trait <ft-trait>) (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens token-trait amount-tokens lock-period)
)

(define-private (sum-claimed (claimed-response (response { entitled-token: uint, to-return: uint } uint)) (prior { entitled-token: uint, to-return: uint }))
  (match claimed-response
    claimed { entitled-token: (+ (get entitled-token prior) (get entitled-token claimed)), to-return: (+ (get to-return prior) (get to-return claimed)) }
    err prior
  )
)

(define-public (claim-and-stake (token-trait <ft-trait>) (reward-cycles (list 200 uint)) (lock-period uint))
  (let 
    (
      (claimed (unwrap-panic (contract-call? .staking-helper claim-staking-reward token-trait reward-cycles)))
      (total-claimed (fold sum-claimed claimed { entitled-token: u0, to-return: u0 }))
    )
    (and (> (get to-return total-claimed) u0) (try! (stake-tokens token-trait (get to-return total-claimed) lock-period)))
    (and (> (get entitled-token total-claimed) u0) (try! (stake-tokens .age000-governance-token (get entitled-token total-claimed) lock-period)))
    (ok claimed)
  )
)

(define-public (claim-and-mint (token-trait <ft-trait>) (reward-cycles (list 200 uint)) (lock-period uint))
  (let 
    (
      (claimed (unwrap-panic (contract-call? .staking-helper claim-staking-reward token-trait reward-cycles)))
      (total-claimed (fold sum-claimed claimed { entitled-token: u0, to-return: u0 }))
    )
    (and (> (get to-return total-claimed) u0) (try! (stake-tokens token-trait (get to-return total-claimed) lock-period)))
    (and (> (get entitled-token total-claimed) u0) (try! (contract-call? .auto-alex add-to-position (get entitled-token total-claimed))))
    (ok claimed)
  )
)

(define-public (claim-and-stake-many (token-traits (list 10 <ft-trait>)) (reward-cycles (list 200 uint)) (lock-period uint))
  (ok
    (map 
      claim-and-stake 
      token-traits
      (list 
        reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles
      )
      (list 
        lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period
      )
    )
  )
)

(define-public (claim-and-mint-many (token-traits (list 10 <ft-trait>)) (reward-cycles (list 200 uint)) (lock-period uint))
  (ok
    (map 
      claim-and-mint 
      token-traits
      (list 
        reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles	reward-cycles
      )
      (list 
        lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period	lock-period
      )
    )
  )
)
