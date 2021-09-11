;; alex-reserve-pool

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
(define-constant not-authorized-err (err u1000))

(define-constant oracle-src "nothing")

(define-data-var rebate-rate uint u50000000) ;;50%

(define-read-only (get-rebate-rate)
    (ok (var-get rebate-rate))
)

;; TODO: access control
(define-public (set-rebate-rate (rate uint))
    (ok (var-set rebate-rate rate))
)

(define-public (transfer-to-mint (usda-amount uint))
    (let
        (
            (amount-to-rebate (unwrap! (contract-call? .math-fixed-point mul-down usda-amount (var-get rebate-rate)) math-call-err))
            (usda-symbol (unwrap! (contract-call? .token-usda get-symbol) get-symbol-fail-err))
            (alex-symbol (unwrap! (contract-call? .token-alex get-symbol) get-symbol-fail-err))
            (usda-price (unwrap! (contract-call? .open-oracle get-price oracle-src usda-symbol) get-oracle-price-fail-err))
            (alex-price (unwrap! (contract-call? .open-oracle get-price oracle-src alex-symbol) get-oracle-price-fail-err))
            (usda-to-alex (unwrap! (contract-call? .math-fixed-point div-down usda-price alex-price) math-call-err))
            (alex-to-rebate (unwrap! (contract-call? .math-fixed-point mul-down amount-to-rebate usda-to-alex) math-call-err))
        )
        (asserts! (> usda-amount u0) invalid-liquidity-err)

        ;; all usdc amount is transferred
        (try! (contract-call? .token-usda transfer usda-amount tx-sender (as-contract tx-sender) none))
        ;; portion of that (by rebate-rate) is minted as alex and transferred        
        (try! (contract-call? .token-alex mint tx-sender alex-to-rebate))
    
        (print { object: "reserve-pool", action: "transfer-to-mint", data: alex-to-rebate })
        (ok true)        
    )
)