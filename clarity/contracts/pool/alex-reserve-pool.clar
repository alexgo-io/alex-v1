;; alex-reserve-pool

(define-constant ERR-INVALID-POOL-ERR (err u2001))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-X-FAILED (err u3001))
(define-constant ERR-TRANSFER-Y-FAILED (err u3002))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT_GREATER_THAN_ONE (err u5000))
(define-constant ERR-NO-FEE (err u2005))
(define-constant ERR-NO-FEE-Y (err u2006))
(define-constant ERR-WEIGHTED-EQUATION-CALL (err u2009))
(define-constant ERR-MATH-CALL (err u2010))
(define-constant ERR-INTERNAL-FUNCTION-CALL (err u1001))
(define-constant ERR-GET-WEIGHT-FAIL (err u2012))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))
(define-constant ERR-GET-PRICE-FAIL (err u2015))
(define-constant ERR-GET-SYMBOL-FAIL (err u6000))
(define-constant ERR-GET-ORACLE-PRICE-FAIL (err u7000))
(define-constant ERR-EXPIRY (err u2017))
(define-constant ERR-GET-BALANCE-FAIL (err u6001))
(define-constant ERR-NOT-AUTHORIZED (err u1000))

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
            (amount-to-rebate (unwrap! (contract-call? .math-fixed-point mul-down usda-amount (var-get rebate-rate)) ERR-MATH-CALL))
            (usda-symbol (unwrap! (contract-call? .token-usda get-symbol) ERR-GET-SYMBOL-FAIL))
            (alex-symbol (unwrap! (contract-call? .token-alex get-symbol) ERR-GET-SYMBOL-FAIL))
            (usda-price (unwrap! (contract-call? .open-oracle get-price oracle-src usda-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (alex-price (unwrap! (contract-call? .open-oracle get-price oracle-src alex-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (usda-to-alex (unwrap! (contract-call? .math-fixed-point div-down usda-price alex-price) ERR-MATH-CALL))
            (alex-to-rebate (unwrap! (contract-call? .math-fixed-point mul-down amount-to-rebate usda-to-alex) ERR-MATH-CALL))
        )
        (asserts! (> usda-amount u0) ERR-INVALID-LIQUIDITY)

        ;; all usdc amount is transferred
        (try! (contract-call? .token-usda transfer usda-amount tx-sender (as-contract tx-sender) none))
        ;; portion of that (by rebate-rate) is minted as alex and transferred        
        (try! (contract-call? .token-alex mint tx-sender alex-to-rebate))
    
        (print { object: "reserve-pool", action: "transfer-to-mint", data: alex-to-rebate })
        (ok true)        
    )
)