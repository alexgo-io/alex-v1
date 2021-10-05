(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; collateral-rebalancing-pool
;; <add a description here>
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

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
(define-constant ERR-MATH-CALL (err u4003))
(define-constant ERR-INTERNAL-FUNCTION-CALL (err u1001))
(define-constant ERR-GET-WEIGHT-FAIL (err u2012))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))
(define-constant ERR-GET-PRICE-FAIL (err u2015))
(define-constant ERR-GET-SYMBOL-FAIL (err u6000))
(define-constant ERR-GET-ORACLE-PRICE-FAIL (err u7000))
(define-constant ERR-EXPIRY (err u2017))
(define-constant ERR-GET-BALANCE-FAIL (err u6001))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-LTV-GREATER-THAN-ONE (err u2019))


(define-constant a1 u27839300)
(define-constant a2 u23038900)
(define-constant a3 u97200)
(define-constant a4 u7810800)

;; TODO: need to be defined properly
(define-data-var contract-owner principal tx-sender)
(define-data-var oracle-src (string-ascii 32) "coingecko")
;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal, ;; collateral
    token-y: principal, ;; token
    expiry: uint    
  }
)

(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal,
    expiry: uint
  }
  {
    yield-supply: uint,
    key-supply: uint,
    balance-x: uint,
    balance-y: uint,
    fee-balance-x: uint,
    fee-balance-y: uint,
    fee-to-address: principal,
    yield-token: principal,
    key-token: principal,
    strike: uint,
    bs-vol: uint,
    ltv-0: uint,
    fee-rate-x: uint,
    fee-rate-y: uint,
    weight-x: uint,
    weight-y: uint,
    token-symbol: (string-ascii 32),
    collateral-symbol: (string-ascii 32),
    moving-average: uint,
    conversion-ltv: uint
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;

;; Approximation of Error Function using Abramowitz and Stegun
;; https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
;; Please note erf(x) equals -erf(-x)
(define-private (erf (x uint))
    (let
        (
            (a1x (unwrap! (mul-down a1 x) ERR-MATH-CALL))
            (x2 (unwrap! (pow-down x u200000000) ERR-MATH-CALL))
            (a2x (unwrap! (mul-down a2 x2) ERR-MATH-CALL))
            (x3 (unwrap! (pow-down x u300000000) ERR-MATH-CALL))
            (a3x (unwrap! (mul-down a3 x3) ERR-MATH-CALL))
            (x4 (unwrap! (pow-down x u400000000) ERR-MATH-CALL))
            (a4x (unwrap! (mul-down a4 x4) ERR-MATH-CALL))
            (denom (unwrap! (add-fixed ONE_8 a1x) ERR-MATH-CALL))
            (denom1 (unwrap! (add-fixed denom a2x) ERR-MATH-CALL))
            (denom2 (unwrap! (add-fixed denom1 a3x) ERR-MATH-CALL))
            (denom3 (unwrap! (add-fixed denom2 a4x) ERR-MATH-CALL))
            (denom4 (unwrap! (pow-down denom3 u400000000) ERR-MATH-CALL))
            (base (unwrap! (div-down ONE_8 denom4) ERR-MATH-CALL))
        )
        (if (<= ONE_8 base) (ok u0) (sub-fixed ONE_8 base))
    )
)

;; public functions
;;

(define-read-only (get-oracle-src)
  (ok (var-get oracle-src))
)

(define-public (set-oracle-src (new-oracle-src (string-ascii 32)))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set oracle-src new-oracle-src))
  )
)

;; implement trait-pool
(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) ERR-INVALID-POOL-ERR))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; additional functions
(define-read-only (get-pool-details (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
        )
        (ok (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
    )
)

;; token / collateral
(define-read-only (get-spot (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))                        
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) token-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) collateral-symbol) ERR-GET-ORACLE-PRICE-FAIL))            
        )
        (ok (unwrap-panic (div-down token-price collateral-price)))
    )
)


(define-read-only (get-pool-value-in-token (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))            
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))   
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) token-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) collateral-symbol) ERR-GET-ORACLE-PRICE-FAIL))  
            (token-value (unwrap! (mul-down balance-x collateral-price) ERR-MATH-CALL))
            (balance-x-in-y (unwrap! (div-down token-value token-price) ERR-MATH-CALL))
        )
        (add-fixed balance-x-in-y balance-y)
    )
)

(define-read-only (get-pool-value-in-collateral (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))            
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))   
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) token-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) collateral-symbol) ERR-GET-ORACLE-PRICE-FAIL))  
            (collateral-value (unwrap! (mul-down balance-y token-price) ERR-MATH-CALL))
            (balance-y-in-x (unwrap! (div-down collateral-value collateral-price) ERR-MATH-CALL))
        )
        (add-fixed balance-y-in-x balance-x)
    )
)

(define-read-only (get-ltv (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))            
            (yield-supply (get yield-supply pool)) ;; in token
            (pool-value (try! (get-pool-value-in-token token collateral expiry))) ;; also in token
        )
        ;; if no liquidity in the pool, return ltv-0
        (if (is-eq yield-supply u0)
            (ok (get ltv-0 pool))
            (div-down yield-supply pool-value)
        )
    )
)

(define-read-only (get-weight-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (strike uint) (bs-vol uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (weight-y (get weight-y pool))
            (moving-average (get moving-average pool))
            (conversion-ltv (get conversion-ltv pool))
            (ma-comp (unwrap! (sub-fixed ONE_8 moving-average) ERR-MATH-CALL))

            ;; determine spot using open oracle
            ;; token / collateral
            (spot (unwrap! (get-spot token collateral expiry) ERR-GET-ORACLE-PRICE-FAIL))
            (now (* block-height ONE_8))
            (ltv (try! (get-ltv token collateral expiry)))
        )
        (if (or (> ltv conversion-ltv) (>= now expiry))
            (ok u99900000)   
            (let 
                (
                    ;; assume 15secs per block 
                    (t (unwrap! (div-down 
                    (unwrap! (sub-fixed expiry now) ERR-MATH-CALL) (* u2102400 ONE_8)) ERR-MATH-CALL))

                    ;; we calculate d1 first
                    (spot-term (unwrap! (div-up spot strike) ERR-MATH-CALL))
                    (pow-bs-vol (unwrap! (div-up 
                                    (unwrap! (pow-down bs-vol u200000000) ERR-MATH-CALL) u200000000) ERR-MATH-CALL))
                    (vol-term (unwrap! (mul-up t pow-bs-vol) ERR-MATH-CALL))                       
                    (sqrt-t (unwrap! (pow-down t u50000000) ERR-MATH-CALL))
                    (sqrt-2 (unwrap! (pow-down u200000000 u50000000) ERR-MATH-CALL))
            
                    (denominator (unwrap! (mul-down bs-vol sqrt-t) ERR-MATH-CALL))
                    (numerator (unwrap! (add-fixed vol-term (unwrap! (sub-fixed (if (> spot-term ONE_8) spot-term ONE_8) (if (> spot-term ONE_8) ONE_8 spot-term)) ERR-MATH-CALL)) ERR-MATH-CALL))
                    (d1 (unwrap! (div-up numerator denominator) ERR-MATH-CALL))
                    (erf-term (unwrap! (erf (unwrap! (div-up d1 sqrt-2) ERR-MATH-CALL)) ERR-MATH-CALL))
                    (complement (if (> spot-term ONE_8) (unwrap! (add-fixed ONE_8 erf-term) ERR-MATH-CALL) (if (<= ONE_8 erf-term) u0 (unwrap! (sub-fixed ONE_8 erf-term) ERR-MATH-CALL))))
                    (weight-t (unwrap! (div-up complement u200000000) ERR-MATH-CALL))
                    (weighted (unwrap! (add-fixed (unwrap! (mul-down moving-average weight-y) ERR-MATH-CALL) (unwrap! (mul-down ma-comp weight-t) ERR-MATH-CALL)) ERR-MATH-CALL))                    
                )
                ;; make sure weight-x > 0 so it works with weighted-equation
                (ok (if (> weighted u100000) weighted u100000))
            )    
        )
    )
)

;; single sided liquidity
(define-public (create-pool (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (multisig-vote <multisig-trait>) (ltv-0 uint) (conversion-ltv uint) (bs-vol uint) (moving-average uint) (dx uint)) 
    (begin
        (asserts! 
            (is-none (map-get? pools-data-map { token-x: (contract-of collateral), token-y: (contract-of token), expiry: (unwrap! (contract-call? the-yield-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR) }))
            ERR-POOL-ALREADY-EXISTS
        )    
        (let
            (
                (pool-id (+ (var-get pool-count) u1))

                (token-x (contract-of collateral))
                (token-y (contract-of token))            
                (expiry (unwrap! (contract-call? the-yield-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR))

                (now (* block-height ONE_8))
                ;; TODO: assume 10mins per block - something to be reviewed
                (t (unwrap! (div-down 
                    (unwrap! (sub-fixed expiry now) ERR-MATH-CALL) (* u52560 ONE_8)) ERR-MATH-CALL))

                (token-symbol (try! (contract-call? token get-symbol)))
                (collateral-symbol (try! (contract-call? collateral get-symbol)))
                (token-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) token-symbol) ERR-GET-ORACLE-PRICE-FAIL))
                (collateral-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) collateral-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            
                (strike (unwrap-panic (div-down token-price collateral-price)))

                ;; we calculate d1 first
                ;; because we support 'at-the-money' only, we can simplify formula
                (sqrt-t (unwrap! (pow-down t u50000000) ERR-MATH-CALL))
                (sqrt-2 (unwrap! (pow-down u200000000 u50000000) ERR-MATH-CALL))            
                (pow-bs-vol (unwrap! (div-up 
                                (unwrap! (pow-down bs-vol u200000000) ERR-MATH-CALL) u200000000) ERR-MATH-CALL))
                (numerator (unwrap! (mul-up t pow-bs-vol) ERR-MATH-CALL))                       
                (denominator (unwrap! (mul-down bs-vol sqrt-t) ERR-MATH-CALL))        
                (d1 (unwrap! (div-up numerator denominator) ERR-MATH-CALL))
                (erf-term (unwrap! (erf (unwrap! (div-up d1 sqrt-2) ERR-MATH-CALL)) ERR-MATH-CALL))
                (complement (if (<= ONE_8 erf-term) u0 (unwrap! (sub-fixed ONE_8 erf-term) ERR-MATH-CALL)))
                (weighted (unwrap! (div-up complement u200000000) ERR-MATH-CALL))                
                (weight-y (if (> weighted u100000) weighted u100000))

                (weight-x (unwrap! (sub-fixed ONE_8 weight-y) ERR-MATH-CALL))

                (pool-data {
                    yield-supply: u0,
                    key-supply: u0,
                    balance-x: u0,
                    balance-y: u0,
                    fee-balance-x: u0,
                    fee-balance-y: u0,
                    fee-to-address: (contract-of multisig-vote),
                    yield-token: (contract-of the-yield-token),
                    key-token: (contract-of the-key-token),
                    strike: strike,
                    bs-vol: bs-vol,
                    fee-rate-x: u0,
                    fee-rate-y: u0,
                    ltv-0: ltv-0,
                    weight-x: weight-x,
                    weight-y: weight-y,
                    token-symbol: (unwrap! (contract-call? token get-symbol) ERR-GET-SYMBOL-FAIL),
                    collateral-symbol: (unwrap! (contract-call? collateral get-symbol) ERR-GET-SYMBOL-FAIL),
                    moving-average: moving-average,
                    conversion-ltv: conversion-ltv
                })
            )

            (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, expiry: expiry })
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)
        
            (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) ERR-TOO-MANY-POOLS))
            (var-set pool-count pool-id)
            (try! (add-to-position token collateral the-yield-token the-key-token dx))
            (print { object: "pool", action: "created", data: pool-data })
            (ok true)
        )
    )
)

(define-public (add-to-position-and-switch (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (dx uint))
    (let
        (
            (minted-yield-token (get yield-token (try! (add-to-position token collateral the-yield-token the-key-token dx))))
        )
        (contract-call? .yield-token-pool swap-y-for-x the-yield-token token minted-yield-token)
    )
)

;; note single-sided liquidity
(define-public (add-to-position (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (dx uint))    
    (let
        (   
            (token-x (contract-of collateral))
            (token-y (contract-of token))             
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR))                   
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))            
            (conversion-ltv (get conversion-ltv pool))
            (ltv (try! (get-ltv token collateral expiry)))
        )
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        ;; mint is possible only if ltv < 1
        (asserts! (>= conversion-ltv ltv) ERR-LTV-GREATER-THAN-ONE)
        (print ltv)
        (let
            (
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))   
                (key-supply (get key-supply pool))
                (weight-x (get weight-x pool))

                (new-supply (try! (get-token-given-position token collateral expiry dx)))
                (yield-new-supply (get yield-token new-supply))
                (key-new-supply (get key-token new-supply))

                (dx-weighted (unwrap! (mul-down weight-x dx) ERR-MATH-CALL))
                (dx-to-dy (if (<= dx dx-weighted) u0 (unwrap! (sub-fixed dx dx-weighted) ERR-MATH-CALL)))

                (dy-weighted (if (is-eq token-x token-y)
                                dx-to-dy
                                (if (is-some (contract-call? .fixed-weight-pool get-pool-exists token collateral u50000000 u50000000))
                                    (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 dx-to-dy)))
                                    (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y collateral token u50000000 u50000000 dx-to-dy)))
                                )                                 
                             )
                )

                (pool-updated (merge pool {
                    yield-supply: (unwrap! (add-fixed yield-new-supply yield-supply) ERR-MATH-CALL),
                    key-supply: (unwrap! (add-fixed key-new-supply key-supply) ERR-MATH-CALL),
                    balance-x: (unwrap! (add-fixed balance-x dx-weighted) ERR-MATH-CALL),
                    balance-y: (unwrap! (add-fixed balance-y dy-weighted) ERR-MATH-CALL)
                }))
            )     

            (unwrap! (contract-call? collateral transfer dx-weighted tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
            (unwrap! (contract-call? token transfer dy-weighted tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            ;; mint pool token and send to tx-sender
            (try! (contract-call? the-yield-token mint tx-sender yield-new-supply))
            (try! (contract-call? the-key-token mint tx-sender key-new-supply))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {yield-token: yield-new-supply, key-token: key-new-supply})
        )
    )
)    

;; note single sided liquidity
(define-public (reduce-position-yield (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT_GREATER_THAN_ONE)
        ;; burn supported only at maturity
        (asserts! (> (* block-height ONE_8) (unwrap! (contract-call? the-yield-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR)) ERR-EXPIRY)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (expiry (unwrap! (contract-call? the-yield-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))
                (total-shares (unwrap! (contract-call? the-yield-token get-balance tx-sender) ERR-GET-BALANCE-FAIL))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) ERR-MATH-CALL)))
                (shares-to-yield (unwrap! (div-down shares yield-supply) ERR-MATH-CALL))        

                ;; if there are any residual collateral, convert to token
                (bal-x-to-y (if (is-eq balance-x u0) 
                                u0 
                                (if (is-eq token-x token-y)
                                    balance-x
                                    (begin
                                        (as-contract (try! (contract-call? .alex-vault transfer-ft collateral balance-x tx-sender tx-sender)))
                                        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists collateral token u50000000 u50000000))
                                            (get dy (as-contract (try! (contract-call? .fixed-weight-pool swap-x-for-y collateral token u50000000 u50000000 balance-x))))
                                            (get dx (as-contract (try! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 balance-x))))
                                        )                                                                                
                                    )                                    
                                )
                            )
                )
                (new-bal-y (unwrap! (add-fixed balance-y bal-x-to-y) ERR-MATH-CALL))
                (dy (unwrap! (mul-down new-bal-y shares-to-yield) ERR-MATH-CALL))

                (pool-updated (merge pool {
                    yield-supply: (if (<= yield-supply shares) u0 (unwrap! (sub-fixed yield-supply shares) ERR-MATH-CALL)),
                    balance-x: u0,
                    balance-y: (if (<= new-bal-y dy) u0 (unwrap! (sub-fixed new-bal-y dy) ERR-MATH-CALL))
                    })
                )
            )

            ;; if any conversion happened at contract level, transfer back to vault
            (and 
                (> bal-x-to-y u0) 
                (not (is-eq token-x token-y)) 
                (as-contract (unwrap! (contract-call? token transfer bal-x-to-y tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED))
            )

            ;; if shares > dy, then transfer the shortfall from reserve.
            ;; TODO: this goes through swapping, so the amount received is actually slightly less than the shortfall
            (and (< dy shares) 
                (let
                    (
                        (amount (unwrap! (sub-fixed shares dy) ERR-MATH-CALL))                    
                    )                
                    (if (is-eq token-y .token-usda)
                        (as-contract (try! (contract-call? .alex-reserve-pool transfer-ft .token-usda amount tx-sender tx-sender)))
                        (let
                            (
                                (amount-to-swap 
                                    (if (is-eq token-y .token-usda)
                                        amount
                                        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists token .token-usda u50000000 u50000000))
                                            (as-contract (try! (contract-call? .fixed-weight-pool get-y-given-x token .token-usda u50000000 u50000000 amount)))
                                            (as-contract (try! (contract-call? .fixed-weight-pool get-x-given-y .token-usda token u50000000 u50000000 amount)))
                                        )                                         
                                        
                                    )
                                )
                            )
                            (as-contract (try! (contract-call? .alex-reserve-pool transfer-ft .token-usda amount-to-swap tx-sender tx-sender)))
                            (as-contract (unwrap! (contract-call? token transfer (if (is-eq token-y .token-usda)
                                                                        amount-to-swap
                                                                        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists token .token-usda u50000000 u50000000))
                                                                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x token .token-usda u50000000 u50000000 amount-to-swap)))
                                                                            (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda token u50000000 u50000000 amount-to-swap)))
                                                                        )                                                                        
                                                                    ) tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED))
                        )
                    )                
                )
            )       
        
            ;; transfer shares of token to tx-sender, ensuring convertability of yield-token
            (try! (contract-call? .alex-vault transfer-ft token shares (as-contract tx-sender) tx-sender))

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? the-yield-token burn tx-sender shares))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: u0, dy: shares})            
        )
    )
)

(define-public (reduce-position-key (token <ft-trait>) (collateral <ft-trait>) (the-key-token <yield-token-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT_GREATER_THAN_ONE)
        ;; burn supported only at maturity
        (asserts! (> (* block-height ONE_8) (unwrap! (contract-call? the-key-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR)) ERR-EXPIRY)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (expiry (unwrap! (contract-call? the-key-token get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))            
                (key-supply (get key-supply pool))            
                (total-shares (unwrap! (contract-call? the-key-token get-balance tx-sender) ERR-GET-BALANCE-FAIL))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) ERR-MATH-CALL)))
                (reduce-data (try! (get-position-given-burn-key token collateral expiry shares)))
                (dx-weighted (get dx reduce-data))
                (dy-weighted (get dy reduce-data))

                (pool-updated (merge pool {
                    key-supply: (if (<= key-supply shares) u0 (unwrap! (sub-fixed key-supply shares) ERR-MATH-CALL)),
                    balance-x: (if (<= balance-x dx-weighted) u0 (unwrap! (sub-fixed balance-x dx-weighted) ERR-MATH-CALL)),
                    balance-y: (if (<= balance-y dy-weighted) u0 (unwrap! (sub-fixed balance-y dy-weighted) ERR-MATH-CALL))
                    })
                )            
            )

            (and (> dx-weighted u0) (try! (contract-call? .alex-vault transfer-ft collateral dx-weighted (as-contract tx-sender) tx-sender)))
            (and (> dy-weighted u0) (try! (contract-call? .alex-vault transfer-ft token dy-weighted (as-contract tx-sender) tx-sender)))
        
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? the-key-token burn tx-sender shares))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx-weighted, dy: dy-weighted})
        )        
    )
)

;; split of balance to yield and key is transparent to traders
(define-public (swap-x-for-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (begin
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY) 
        ;; (asserts! (<= (* block-height ONE_8) expiry) ERR-EXPIRY)    
        
        ;; swap is supported only if token /= collateral
        (asserts! (not (is-eq (contract-of token) (contract-of collateral))) ERR-INVALID-POOL-ERR)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (strike (get strike pool))
                (bs-vol (get bs-vol pool)) 
                (fee-rate-x (get fee-rate-x pool))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-y (unwrap! (get-weight-y token collateral expiry strike bs-vol) ERR-GET-WEIGHT-FAIL))
                (weight-x (unwrap! (sub-fixed ONE_8 weight-y) ERR-MATH-CALL))            
            
                ;; fee = dx * fee-rate-x
                (fee (unwrap! (mul-up dx fee-rate-x) ERR-MATH-CALL))
                (dx-net-fees (if (<= dx fee) u0 (unwrap! (sub-fixed dx fee) ERR-MATH-CALL)))
                (dy (try! (get-y-given-x token collateral expiry dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (add-fixed balance-x dx-net-fees) ERR-MATH-CALL),
                            balance-y: (if (<= balance-y dy) u0 (unwrap! (sub-fixed balance-y dy) ERR-MATH-CALL)),
                            fee-balance-x: (unwrap! (add-fixed (get fee-balance-x pool) fee) ERR-MATH-CALL),
                            weight-x: weight-x,
                            weight-y: weight-y                    
                        }
                    )
                )
            )

            (unwrap! (contract-call? collateral transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
            (try! (contract-call? .alex-vault transfer-ft token dy (as-contract tx-sender) tx-sender))

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

(define-public (swap-y-for-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (begin
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)    
        ;; (asserts! (<= (* block-height ONE_8) expiry) ERR-EXPIRY)   
        ;; swap is supported only if token /= collateral
        (asserts! (not (is-eq (contract-of token) (contract-of collateral))) ERR-INVALID-POOL-ERR)   
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (strike (get strike pool))
                (bs-vol (get bs-vol pool)) 
                (fee-rate-y (get fee-rate-y pool))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-y (unwrap! (get-weight-y token collateral expiry strike bs-vol) ERR-GET-WEIGHT-FAIL))
                (weight-x (unwrap! (sub-fixed ONE_8 weight-y) ERR-MATH-CALL))   

                ;; fee = dy * fee-rate-y
                (fee (unwrap! (mul-up dy fee-rate-y) ERR-MATH-CALL))
                (dy-net-fees (if (<= dy fee) u0 (unwrap! (sub-fixed dy fee) ERR-MATH-CALL)))
                (dx (try! (get-x-given-y token collateral expiry dy-net-fees)))        

                (pool-updated
                    (merge pool
                        {
                            balance-x: (if (<= balance-x dx) u0 (unwrap! (sub-fixed balance-x dx) ERR-MATH-CALL)),
                            balance-y: (unwrap! (add-fixed balance-y dy-net-fees) ERR-MATH-CALL),                      
                            fee-balance-y: (unwrap! (add-fixed (get fee-balance-y pool) fee) ERR-MATH-CALL),
                            weight-x: weight-x,
                            weight-y: weight-y                        
                        }
                    )
                )
            )

            (try! (contract-call? .alex-vault transfer-ft collateral dx (as-contract tx-sender) tx-sender))
            (unwrap! (contract-call? token transfer dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

(define-read-only (get-fee-rate-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-x pool))
    )
)

(define-read-only (get-fee-rate-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-y pool))
    )
)

(define-public (set-fee-rate-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (fee-rate-x uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, expiry: expiry 
            }
            (merge pool { fee-rate-x: fee-rate-x })
        )
        (ok true)     
    )
)

(define-public (set-fee-rate-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (fee-rate-y uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, expiry: expiry
            }
            (merge pool { fee-rate-y: fee-rate-y })
        )
        (ok true)     
    )
)

(define-read-only (get-fee-to-address (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))                
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok {fee-balance-x: (get fee-balance-x pool), fee-balance-y: (get fee-balance-y pool)})
    )
)

(define-public (collect-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))       
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (try! (contract-call? .alex-vault transfer-ft collateral fee-x (as-contract tx-sender) tx-sender))
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-x .token-usda) 
                            fee-x 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda collateral u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda collateral u50000000 u50000000 fee-x)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y collateral .token-usda u50000000 u50000000 fee-x)))
                            )                            
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (try! (contract-call? .alex-vault transfer-ft token fee-y (as-contract tx-sender) tx-sender))
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-y .token-usda) 
                            fee-y 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda token u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token u50000000 u50000000 fee-y)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y token .token-usda u50000000 u50000000 fee-y)))
                            )                            
                        )
                    )
                )
            )
        )          

        (map-set pools-data-map
            { token-x: token-x, token-y: token-y, expiry: expiry}
            (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok {fee-x: fee-x, fee-y: fee-y})
    )
)

(define-read-only (get-y-given-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))         
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-y-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))         
        )
        (contract-call? .weighted-equation get-y-given-price balance-x balance-y weight-x weight-y price)
    )
)

;; single sided liquidity
(define-read-only (get-token-given-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (begin
        (asserts! (< (* block-height ONE_8) expiry) ERR-EXPIRY)
        (let 
            (
                (ltv (try! (get-ltv token collateral expiry)))
                (dy (if (is-eq (contract-of token) (contract-of collateral))
                        dx
                        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists token collateral u50000000 u50000000))
                            (try! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 dx))
                            (try! (contract-call? .fixed-weight-pool get-y-given-x collateral token u50000000 u50000000 dx))
                        )                    
                    )
                )
                (ltv-dy (unwrap! (mul-down ltv dy) ERR-MATH-CALL))
            )

            (ok {yield-token: ltv-dy, key-token: ltv-dy})
        )
    )
)

;; single sided liquidity
(define-read-only (get-position-given-mint (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (begin
        (asserts! (< (* block-height ONE_8) expiry) ERR-EXPIRY) ;; mint supported until, but excl., expiry
        (let 
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-supply (get yield-supply pool)) ;; prior to maturity, yield-supply == key-supply, so we use yield-supply
                (weight-x (get weight-x pool))
                (weight-y (get weight-y pool))
            
                (ltv (try! (get-ltv token collateral expiry)))

                (pos-data (unwrap! (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares) ERR-WEIGHTED-EQUATION-CALL))

                (dx-weighted (get dx pos-data))
                (dy-weighted (get dy pos-data))

                ;; always convert to collateral ccy
                (dy-to-dx (if (is-eq token-x token-y)
                            dy-weighted
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists token collateral u50000000 u50000000))
                                (try! (contract-call? .fixed-weight-pool get-y-given-x token collateral u50000000 u50000000 dy-weighted))
                                (try! (contract-call? .fixed-weight-pool get-x-given-y collateral token u50000000 u50000000 dy-weighted))
                            )                            
                        )
                )   
                (dx (unwrap! (add-fixed dx-weighted dy-to-dx) ERR-MATH-CALL))
            )
            (ok {dx: dx, dx-weighted: dx-weighted, dy-weighted: dy-weighted})
        )
    )
)

(define-read-only (get-position-given-burn-yield (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (begin
        (asserts! (> (* block-height ONE_8) expiry) ERR-EXPIRY)
        (ok shares)
    )
)

(define-read-only (get-position-given-burn-key (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (begin         
        (asserts! (> (* block-height ONE_8) expiry) ERR-EXPIRY)
        (let 
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))  
                (yield-supply (get yield-supply pool))                  
                (key-supply (get key-supply pool))
                (weight-x (get weight-x pool))
                (weight-y (get weight-y pool))
                (pool-value-unfloored (try! (get-pool-value-in-token token collateral expiry)))
                (pool-value-in-y (if (> yield-supply pool-value-unfloored) yield-supply pool-value-unfloored))
                (key-value-in-y (if (<= pool-value-in-y yield-supply) u0 (unwrap! (sub-fixed pool-value-in-y yield-supply) ERR-MATH-CALL)))
                (key-to-pool (unwrap! (div-down key-value-in-y pool-value-in-y) ERR-MATH-CALL))
                (shares-to-key (unwrap! (div-down shares key-supply) ERR-MATH-CALL))
                (shares-to-pool (unwrap! (mul-down key-to-pool shares-to-key) ERR-MATH-CALL))
                    
                (dx (unwrap! (mul-down shares-to-pool balance-x) ERR-MATH-CALL))
                (dy (unwrap! (mul-down shares-to-pool balance-y) ERR-MATH-CALL))
            )
            (ok {dx: dx, dy: dy})
        )
    )
)


;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; TODO: overflow causes runtime error, should handle before operation rather than after

;; constants
;;
(define-constant SCALE_UP_OVERFLOW (err u5001))
(define-constant SCALE_DOWN_OVERFLOW (err u5002))
(define-constant ADD_OVERFLOW (err u5003))
(define-constant SUB_OVERFLOW (err u5004))
(define-constant MUL_OVERFLOW (err u5005))
(define-constant DIV_OVERFLOW (err u5006))
(define-constant POW_OVERFLOW (err u5007))

;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 

;; public functions
;;

(define-read-only (get_one)
    (ok ONE_8)
)

(define-read-only (scale-up (a uint))
    (let
        (
            (r (* a ONE_8))
        )
        (asserts! (is-eq (/ r ONE_8) a) SCALE_UP_OVERFLOW)
        (ok r)
    )
)

(define-read-only (scale-down (a uint))
  (let
    ((r (/ a ONE_8)))
    (asserts! (is-eq (* r ONE_8) a) SCALE_DOWN_OVERFLOW)
    (ok r)
 )
)

(define-read-only (add-fixed (a uint) (b uint))
    (let
        (
            (c (+ a b))
        )
        (asserts! (>= c a) ADD_OVERFLOW)
        (ok c)
    )
)

(define-read-only (sub-fixed (a uint) (b uint))
    (let
        ()
        (asserts! (<= b a) SUB_OVERFLOW)
        (ok (- a b))
    )
)

(define-read-only (mul-down (a uint) (b uint))
    (let
        (
            (product (* a b))
        )
        (ok (/ product ONE_8))
    )
)


(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            (ok u0)
            (ok (+ u1 (/ (- product u1) ONE_8)))
       )
   )
)

(define-read-only (div-down (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_8))
       )
        (if (is-eq a u0)
            (ok u0)
            (ok (/ a-inflated b))
       )
   )
)

(define-read-only (div-up (a uint) (b uint))
    (let
        (
            (a-inflated (* a ONE_8))
       )
        (if (is-eq a u0)
            (ok u0)
            (ok (+ u1 (/ (- a-inflated u1) b)))
       )
   )
)

(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (unwrap-panic (mul-up raw MAX_POW_RELATIVE_ERROR))))
        )
        (if (< raw max-error)
            (ok u0)
            (sub-fixed raw max-error)
        )
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (unwrap-panic (mul-up raw MAX_POW_RELATIVE_ERROR))))
        )
        (add-fixed raw max-error)
    )
)

;; math-log-exp
;; Exponentiation and logarithm functions for 8 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 8 decimal fixed point numbers.
(define-constant iONE_8 (pow 10 8))
(define-constant ONE_10 (pow 10 10))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^8, 
;; which makes the largest exponent ln((2^127 - 1) / 10^8) = 69.6090111872.
;; The smallest possible result is 10^(-8), which makes largest negative argument ln(10^(-8)) = -18.420680744.
;; We use 69.0 and -18.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 69 iONE_8))
(define-constant MIN_NATURAL_EXPONENT (* -18 iONE_8))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint iONE_8)))

;; Because largest exponent is 69, we start from 64
;; The first several a_n are too large if stored as 8 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.
(define-constant x_a_list_no_deci (list 
{x_pre: 6400000000, a_pre: 6235149080811616882910000000, use_deci: false} ;; x1 = 2^6, a1 = e^(x1)
))
;; 8 decimal constants
(define-constant x_a_list (list 
{x_pre: 3200000000, a_pre: 7896296018268069516100, use_deci: true} ;; x2 = 2^5, a2 = e^(x2)
{x_pre: 1600000000, a_pre: 888611052050787, use_deci: true} ;; x3 = 2^4, a3 = e^(x3)
{x_pre: 800000000, a_pre: 298095798704, use_deci: true} ;; x4 = 2^3, a4 = e^(x4)
{x_pre: 400000000, a_pre: 5459815003, use_deci: true} ;; x5 = 2^2, a5 = e^(x5)
{x_pre: 200000000, a_pre: 738905610, use_deci: true} ;; x6 = 2^1, a6 = e^(x6)
{x_pre: 100000000, a_pre: 271828183, use_deci: true} ;; x7 = 2^0, a7 = e^(x7)
{x_pre: 50000000, a_pre: 164872127, use_deci: true} ;; x8 = 2^-1, a8 = e^(x8)
{x_pre: 25000000, a_pre: 128402542, use_deci: true} ;; x9 = 2^-2, a9 = e^(x9)
{x_pre: 12500000, a_pre: 113314845, use_deci: true} ;; x10 = 2^-3, a10 = e^(x10)
{x_pre: 6250000, a_pre: 106449446, use_deci: true} ;; x11 = 2^-4, a11 = e^x(11)
))

(define-constant X_OUT_OF_BOUNDS (err u5009))
(define-constant Y_OUT_OF_BOUNDS (err u5010))
(define-constant PRODUCT_OUT_OF_BOUNDS (err u5011))
(define-constant INVALID_EXPONENT (err u5012))
(define-constant OUT_OF_BOUNDS (err u5013))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-private (ln-priv (a int))
  (let
    (
      (a_sum_no_deci (fold accumulate_division x_a_list_no_deci {a: a, sum: 0}))
      (a_sum (fold accumulate_division x_a_list {a: (get a a_sum_no_deci), sum: (get sum a_sum_no_deci)}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a iONE_8) iONE_8) (+ out_a iONE_8)))
      (z_squared (/ (* z z) iONE_8))
      (div_list (list 3 5 7 9 11))
      (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
      (seriesSum (get seriesSum num_sum_zsq))
      (r (+ out_sum (* seriesSum 2)))
   )
    (ok r)
 )
)

(define-private (accumulate_division (x_a_pre (tuple (x_pre int) (a_pre int) (use_deci bool))) (rolling_a_sum (tuple (a int) (sum int))))
  (let
    (
      (a_pre (get a_pre x_a_pre))
      (x_pre (get x_pre x_a_pre))
      (use_deci (get use_deci x_a_pre))
      (rolling_a (get a rolling_a_sum))
      (rolling_sum (get sum rolling_a_sum))
   )
    (if (>= rolling_a (if use_deci a_pre (* a_pre iONE_8)))
      {a: (/ (* rolling_a (if use_deci iONE_8 1)) a_pre), sum: (+ rolling_sum x_pre)}
      {a: rolling_a, sum: rolling_sum}
   )
 )
)

(define-private (rolling_sum_div (n int) (rolling (tuple (num int) (seriesSum int) (z_squared int))))
  (let
    (
      (rolling_num (get num rolling))
      (rolling_sum (get seriesSum rolling))
      (z_squared (get z_squared rolling))
      (next_num (/ (* rolling_num z_squared) iONE_8))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
(define-private (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) iONE_8))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) PRODUCT_OUT_OF_BOUNDS)
    (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
  )
)

(define-private (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (let
      (
        ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
        (x_product_no_deci (fold accumulate_product x_a_list_no_deci {x: x, product: 1}))
        (x_adj (get x x_product_no_deci))
        (firstAN (get product x_product_no_deci))
        (x_product (fold accumulate_product x_a_list {x: x_adj, product: iONE_8}))
        (product_out (get product x_product))
        (x_out (get x x_product))
        (seriesSum (+ iONE_8 x_out))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
        (sum (get seriesSum term_sum_x))
     )
      (ok (* (/ (* product_out sum) iONE_8) firstAN))
   )
 )
)

(define-private (accumulate_product (x_a_pre (tuple (x_pre int) (a_pre int) (use_deci bool))) (rolling_x_p (tuple (x int) (product int))))
  (let
    (
      (x_pre (get x_pre x_a_pre))
      (a_pre (get a_pre x_a_pre))
      (use_deci (get use_deci x_a_pre))
      (rolling_x (get x rolling_x_p))
      (rolling_product (get product rolling_x_p))
   )
    (if (>= rolling_x x_pre)
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) (if use_deci iONE_8 1))}
      {x: rolling_x, product: rolling_product}
   )
 )
)

(define-private (rolling_div_sum (n int) (rolling (tuple (term int) (seriesSum int) (x int))))
  (let
    (
      (rolling_term (get term rolling))
      (rolling_sum (get seriesSum rolling))
      (x (get x rolling))
      (next_term (/ (/ (* rolling_term x) iONE_8) n))
      (next_sum (+ rolling_sum next_term))
   )
    {term: next_term, seriesSum: next_sum, x: x}
 )
)

;; public functions
;;

(define-read-only (get-exp-bound)
  (ok MILD_EXPONENT_BOUND)
)

;; Exponentiation (x^y) with unsigned 8 decimal fixed point base and exponent.
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) X_OUT_OF_BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD_EXPONENT_BOUND) Y_OUT_OF_BOUNDS)

    (if (is-eq y u0) 
      (ok (to-uint iONE_8))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 8 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (/ (* iONE_8 iONE_8) (unwrap-panic (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 8 decimal fixed point base and argument.
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (unwrap-panic (ln-priv base)) iONE_8))
      (logArg (* (unwrap-panic (ln-priv arg)) iONE_8))
   )
    (ok (/ (* logArg iONE_8) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) (err OUT_OF_BOUNDS))
    (if (< a iONE_8)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (- 0 (unwrap-panic (ln-priv (/ (* iONE_8 iONE_8) a)))))
      (ln-priv a)
   )
 )
)
