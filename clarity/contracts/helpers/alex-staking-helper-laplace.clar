


(define-read-only (get-staking-stats-coinbase (token principal) (reward-cycle uint))
    { 
        staking-stats: (contract-call? .alex-reserve-pool get-staking-stats-at-cycle-or-default token reward-cycle), 
        coinbase-amount: (contract-call? .alex-reserve-pool get-coinbase-amount-or-default token reward-cycle)
    }
)

(define-read-only (get-staking-stats-coinbase-as-list (token principal) (reward-cycles (list 32 uint)))
    (let
        (
            (token-list (list token token token token token token token token token token token token token token token token token token token token token token token token token token token token token token token token))
        )
        (map get-staking-stats-coinbase token-list reward-cycles)
    )    
)