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

;; execute margin trade based on margin notional (in token) provided
(define-public (execute-trade-on-margin (token <ft-trait>) (collateral <ft-trait>) (yield-token <yield-token-trait>) (key-token <yield-token-trait>) (expiry uint) (margin uint))
    (let 
        (
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv token collateral expiry)))
            (ltv-comp (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 ltv) math-call-err))
            (margin-in-collateral (try! (contract-call? .fixed-weight-pool get-y-given-x token collateral u5000000 u5000000 margin)))
            (dy (unwrap! (contract-call? .math-fixed-point div-down margin-in-collateral ltv-comp) math-call-err))
        )
        (execute-margin-trade token collateral yield-token key-token expiry dy)
    )
)

;; execute margin trade based on gross notional (in collateral) provided
(define-public (execute-margin-trade (token <ft-trait>) (collateral <ft-trait>) (yield-token <yield-token-trait>) (key-token <yield-token-trait>) (expiry uint) (dy uint))
    (let
        (
            ;; calculate the prevailing LTV of the relevant CRP
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv token collateral expiry)))
            ;; calculate the amount to borrow
            (borrow (unwrap! (contract-call? .math-fixed-point mul-up dy ltv) math-call-err))
            ;; calculate the margin amount in token
            (margin-in-collateral (unwrap! (contract-call? .math-fixed-point sub-fixed dy borrow) math-call-err))
            (margin-in-token (try! (contract-call? .fixed-weight-pool get-x-given-y token collateral u5000000 u5000000 margin-in-collateral)))
            ;; calculate the vault balance pre-flash loan
            (pre-bal-borrow (try! (contract-call? collateral get-balance (as-contract .alex-vault))))
            ;; calculate the total amount to borrow with flash loan fee            
            (fee (unwrap-panic (contract-call? .alex-vault get-flash-loan-fee-rate)))
            (fee-with-principal (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 fee) math-call-err))
            (borrow-with-fee (unwrap! (contract-call? .math-fixed-point mul-up borrow fee-with-principal) math-call-err))
            ;; swap margin into collateral
            (swapped-margin (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 margin-in-token))))
            ;; calculate new dy based on swapped margin and flash loan
            (new-dy (unwrap! (contract-call? .math-fixed-point add-fixed swapped-margin borrow) math-call-err))
        )

        (asserts! (> pre-bal-borrow borrow) insufficient-flash-loan-balance-err)
        
        ;; make flash loan
        ;; can this be called without authorisation from .alex-vault?
        (try! (contract-call? collateral transfer borrow (as-contract .alex-vault) tx-sender none))

        (let
            (
                ;; mint yield-token and key-token using new-dy
                (minted (try! (contract-call? .collateral-rebalancing-pool add-to-position token collateral yield-token key-token new-dy)))
                (minted-yield-token (get yield-token minted))
                (minted-key-token (get key-token minted))
                ;; swap minted yield-token for token
                (swapped (unwrap! (contract-call? .yield-token-pool swap-y-for-x yield-token token minted-yield-token) no-liquidity-err))
                (swapped-token (get dx swapped))
            )
            
            ;; swap swapped-token into collateral ccy
            (try! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 swapped-token))
            ;; return flash loan together with fee
            (contract-call? collateral transfer borrow-with-fee tx-sender (as-contract .alex-vault) none)
        )
    )
)

