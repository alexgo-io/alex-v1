(define-read-only (get-total-value-locked)
    (list 
      {
        token: .fwp-wstx-alex-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-alex-50-50-v1-01 get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-alex-50-50-v1-01),
        balances: (contract-call? .fixed-weight-pool-v1-01 get-balances .token-wstx .age000-governance-token 50000000 50000000)
      }
      {
        token: .fwp-wstx-wbtc-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wbtc-50-50-v1-01 get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wbtc-50-50-v1-01),
        balances: (contract-call? .fixed-weight-pool-v1-01 get-balances .token-wstx .token-wbtc 50000000 50000000)
      }
      {
        token: .fwp-alex-usda,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-usda get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-alex-usda),
        balances: (contract-call? .simple-weight-pool-alex get-balances .age000-governance-token .token-usda)
      }
      {
        token: .fwp-alex-wslm,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-wslm get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-alex-wslm)
        balances: (contract-call? .simple-weight-pool-alex get-balances .age000-governance-token .token-wslm)
      }
      {
        token: .fwp-wstx-wxusd-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wxusd-50-50-v1-01 get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wxusd-50-50-v1-01)
        balances: (contract-call? .fixed-weight-pool-v1-01 get-balances .token-wstx .token-wxusd)
      }
      {
        token: .fwp-wstx-wnycc-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wnycc-50-50-v1-01 get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wnycc-50-50-v1-01)
        balances: (contract-call? .fixed-weight-pool-v1-01 get-balances .token-wstx .token-wnycc)
      }
      {
        token: .ytp-alex-v1,
        total_supply: (unwrap-panic (contract-call? .ytp-alex-v1 get-overall-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .ytp-alex-v1)
      }
      {
        token: .fwp-alex-wban,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-wban get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-alex-wban)
        balances: (contract-call? .simple-weight-pool-alex get-balances .age000-governance-token .token-wban)
      }
      {
        token: .fwp-alex-autoalex,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-autoalex get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-alex-autoalex)
        balances: (contract-call? .simple-weight-pool-alex get-balances .age000-governance-token .auto-alex)
      }
      {
        token: .fwp-wstx-wmia-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wmia-50-50-v1-01 get-total-supply-fixed)),
        reserved_balance: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wmia-50-50-v1-01)
        balances: (contract-call? .fixed-weight-pool-v1-01 get-balances .token-wstx .token-wmia)
      }                                                
    )
)