(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)

(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant insufficient-flash-loan-balance-err (err u3003))
(define-constant invalid-pool-err (err u2001))
(define-constant no-liquidity-err (err u2002))
(define-constant invalid-liquidity-err (err u2003))
(define-constant transfer-x-failed-err (err u3001))
(define-constant transfer-y-failed-err (err u3002))
(define-constant pool-already-exists-err (err u2000))
(define-constant too-many-pools-err (err u2004))
(define-constant percent-greater-than-one (err u5000))
(define-constant no-fee-x-err (err u2005))
(define-constant no-fee-y-err (err u2006))
(define-constant weighted-equation-call-err (err u2009))
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))
(define-constant get-weight-fail-err (err u2012))
(define-constant get-expiry-fail-err (err u2013))
(define-constant get-price-fail-err (err u2015))
(define-constant get-symbol-fail-err (err u6000))
(define-constant get-oracle-price-fail-err (err u7000))
(define-constant expiry-err (err u2017))
(define-constant get-balance-fail-err (err u6001))

(define-public (execute-margin-trade (token <ft-trait>) (collateral <ft-trait>) (yield-token <yield-token-trait>) (key-token <yield-token-trait>) (expiry uint) (dx uint))
    (let
        (
            (pool (try! (contract-call? .collateral-rebalancing-pool get-pool-details token collateral expiry)))
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv token collateral expiry)))
            (borrow (unwrap! (contract-call? .math-fixed-point mul-up dx ltv) math-call-err))
            (margin (unwrap! (contract-call? .math-fixed-point sub-fixed dx borrow) math-call-err))
            (pre-bal-borrow (try! (contract-call? collateral get-balance (as-contract .alex-vault))))
            (fee (unwrap-panic (contract-call? .alex-vault get-flash-loan-fee-rate)))
            (fee-with-principal (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 fee) math-call-err))
            (borrow-with-fee (unwrap! (contract-call? .math-fixed-point mul-up borrow fee-with-principal) math-call-err))
        )

        (asserts! (> pre-bal-borrow borrow) insufficient-flash-loan-balance-err)
        (try! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 margin))
        (try! (contract-call? collateral transfer borrow (as-contract .alex-vault) tx-sender none))
        (let
            (
                (minted (try! (contract-call? .collateral-rebalancing-pool add-to-position token collateral yield-token key-token dx)))
                (minted-yield-token (get yield-token minted))
                (minted-key-token (get key-token minted))
                (swapped (unwrap! (contract-call? .yield-token-pool swap-y-for-x yield-token token minted-yield-token) no-liquidity-err))
                (swapped-token (get dx swapped))
            )
            
            (try! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 swapped-token))
            (contract-call? collateral transfer borrow-with-fee tx-sender (as-contract .alex-vault) none)
        )
    )
)

