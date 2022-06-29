(define-read-only (get-total-value-locked)
    (list 
      {
        token: .fwp-wstx-alex-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-alex-50-50-v1-01 get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-alex-50-50-v1-01)
      }
      {
        token: .fwp-wstx-wbtc-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wbtc-50-50-v1-01 get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wbtc-50-50-v1-01)
      }
      {
        token: .fwp-alex-usda,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-usda get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-alex-usda)
      }
      {
        token: .fwp-alex-wslm,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-wslm get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-alex-wslm)
      }
      {
        token: .fwp-wstx-wxusd-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wxusd-50-50-v1-01 get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wxusd-50-50-v1-01)
      }
      {
        token: .fwp-wstx-wnycc-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wnycc-50-50-v1-01 get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wnycc-50-50-v1-01)
      }
      {
        token: .ytp-alex-v1,
        total_supply: (unwrap-panic (contract-call? .ytp-alex-v1 get-overall-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .ytp-alex-v1)
      }
      {
        token: .fwp-alex-wban,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-wban get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-alex-wban)
      }
      {
        token: .fwp-alex-autoalex,
        total_supply: (unwrap-panic (contract-call? .fwp-alex-autoalex get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-alex-autoalex)
      }
      {
        token: .fwp-wstx-wmia-50-50-v1-01,
        total_supply: (unwrap-panic (contract-call? .fwp-wstx-wmia-50-50-v1-01 get-total-supply-fixed)),
        reserved_balnce: (contract-call? .alex-reserve-pool get-balance .fwp-wstx-wmia-50-50-v1-01)
      }                                                
    )
)