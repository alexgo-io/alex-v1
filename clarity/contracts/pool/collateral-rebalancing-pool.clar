(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; collateral-rebalancing-pool
;; <add a description here>
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant invalid-pool-err (err u2001))
(define-constant no-liquidity-err (err u2002))
(define-constant invalid-liquidity-err (err u2003))
(define-constant transfer-x-failed-err (err u3001))
(define-constant transfer-y-failed-err (err u3002))
(define-constant pool-already-exists-err (err u2000))
(define-constant too-many-pools-err (err u2004))
(define-constant percent-greater-than-one-err (err u5000))
(define-constant no-fee-x-err (err u2005))
(define-constant no-fee-y-err (err u2006))
(define-constant weighted-equation-call-err (err u2009))
(define-constant ERR-MATH-CALL (err u4003))
(define-constant internal-function-call-err (err u1001))
(define-constant get-weight-fail-err (err u2012))
(define-constant get-expiry-fail-err (err u2013))
(define-constant get-price-fail-err (err u2015))
(define-constant get-symbol-fail-err (err u6000))
(define-constant get-oracle-price-fail-err (err u7000))
(define-constant expiry-err (err u2017))
(define-constant get-balance-fail-err (err u6001))
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant a1 u27839300)
(define-constant a2 u23038900)
(define-constant a3 u97200)
(define-constant a4 u7810800)

;; TODO: need to be defined properly
(define-constant oracle-src "nothing")

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
            (a1x (unwrap! (contract-call? .math-fixed-point mul-down a1 x) ERR-MATH-CALL))
            (x2 (unwrap! (contract-call? .math-fixed-point pow-down x u200000000) ERR-MATH-CALL))
            (a2x (unwrap! (contract-call? .math-fixed-point mul-down a2 x2) ERR-MATH-CALL))
            (x3 (unwrap! (contract-call? .math-fixed-point pow-down x u300000000) ERR-MATH-CALL))
            (a3x (unwrap! (contract-call? .math-fixed-point mul-down a3 x3) ERR-MATH-CALL))
            (x4 (unwrap! (contract-call? .math-fixed-point pow-down x u400000000) ERR-MATH-CALL))
            (a4x (unwrap! (contract-call? .math-fixed-point mul-down a4 x4) ERR-MATH-CALL))
            (denom (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 a1x) ERR-MATH-CALL))
            (denom1 (unwrap! (contract-call? .math-fixed-point add-fixed denom a2x) ERR-MATH-CALL))
            (denom2 (unwrap! (contract-call? .math-fixed-point add-fixed denom1 a3x) ERR-MATH-CALL))
            (denom3 (unwrap! (contract-call? .math-fixed-point add-fixed denom2 a4x) ERR-MATH-CALL))
            (denom4 (unwrap! (contract-call? .math-fixed-point pow-down denom3 u400000000) ERR-MATH-CALL))
            (base (unwrap! (contract-call? .math-fixed-point div-down ONE_8 denom4) ERR-MATH-CALL))
        )
        (contract-call? .math-fixed-point sub-fixed ONE_8 base)
    )
)

;; public functions
;;

;; implement trait-pool
(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) invalid-pool-err))
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
        (ok (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
    )
)

;; token / collateral
(define-read-only (get-spot (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))                        
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))            
        )
        (ok (unwrap-panic (contract-call? .math-fixed-point div-down token-price collateral-price)))
    )
)


(define-read-only (get-pool-value-in-token (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))            
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))   
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))  
            (token-value (unwrap! (contract-call? .math-fixed-point mul-down balance-x collateral-price) ERR-MATH-CALL))
            (balance-x-in-y (unwrap! (contract-call? .math-fixed-point div-down token-value token-price) ERR-MATH-CALL))
        )
        (contract-call? .math-fixed-point add-fixed balance-x-in-y balance-y)
    )
)

(define-read-only (get-pool-value-in-collateral (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))            
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))   
            (token-symbol (get token-symbol pool))
            (collateral-symbol (get collateral-symbol pool))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))  
            (collateral-value (unwrap! (contract-call? .math-fixed-point mul-down balance-y token-price) ERR-MATH-CALL))
            (balance-y-in-x (unwrap! (contract-call? .math-fixed-point div-down collateral-value collateral-price) ERR-MATH-CALL))
        )
        (contract-call? .math-fixed-point add-fixed balance-y-in-x balance-x)
    )
)

(define-read-only (get-ltv (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))            
            (yield-supply (get yield-supply pool)) ;; in token
            (pool-value (try! (get-pool-value-in-token token collateral expiry))) ;; also in token
        )
        ;; if no liquidity in the pool, return ltv-0
        (if (is-eq yield-supply u0)
            (ok (get ltv-0 pool))
            (contract-call? .math-fixed-point div-down yield-supply pool-value)
        )
    )
)

(define-read-only (get-weight-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (strike uint) (bs-vol uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (weight-y (get weight-y pool))
            (moving-average (get moving-average pool))
            (conversion-ltv (get conversion-ltv pool))
            (ma-comp (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 moving-average) ERR-MATH-CALL))

            ;; determine spot using open oracle
            ;; token / collateral
            (spot (unwrap! (get-spot token collateral expiry) get-oracle-price-fail-err))
            (now (* block-height ONE_8))
            
            ;; TODO: assume 10mins per block - something to be reviewed            
            (t (unwrap! (contract-call? .math-fixed-point div-down 
                (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) ERR-MATH-CALL) (* u52560 ONE_8)) ERR-MATH-CALL))
            ;; TODO: APYs need to be calculated from the prevailing yield token price.
            ;; TODO: ln(S/K) approximated as (S/K - 1)

            ;; we calculate d1 first
            (spot-term (unwrap! (contract-call? .math-fixed-point div-up spot strike) ERR-MATH-CALL))
            (pow-bs-vol (unwrap! (contract-call? .math-fixed-point div-up 
                            (unwrap! (contract-call? .math-fixed-point pow-down bs-vol u200000000) ERR-MATH-CALL) u200000000) ERR-MATH-CALL))
            (vol-term (unwrap! (contract-call? .math-fixed-point mul-up t pow-bs-vol) ERR-MATH-CALL))                       
            (sqrt-t (unwrap! (contract-call? .math-fixed-point pow-down t u50000000) ERR-MATH-CALL))
            (sqrt-2 (unwrap! (contract-call? .math-fixed-point pow-down u200000000 u50000000) ERR-MATH-CALL))
            
            (denominator (unwrap! (contract-call? .math-fixed-point mul-down bs-vol sqrt-t) ERR-MATH-CALL))

            (ltv (try! (get-ltv token collateral expiry)))
        )

        ;; if current ltv > conversion-ltv, then pool converts to (almost) 100% token (i.e. weight-x = 0)
        (if (or (> ltv conversion-ltv) (is-eq now expiry))
            (ok u99900000)                    
            (let
                (
                    (numerator (unwrap! (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap! (contract-call? .math-fixed-point sub-fixed 
                                        (if (> spot-term ONE_8) spot-term ONE_8) (if (> spot-term ONE_8) ONE_8 spot-term)) ERR-MATH-CALL)) ERR-MATH-CALL))
                    (d1 (unwrap! (contract-call? .math-fixed-point div-up numerator denominator) ERR-MATH-CALL))
                    (erf-term (unwrap! (erf (unwrap! (contract-call? .math-fixed-point div-up d1 sqrt-2) ERR-MATH-CALL)) ERR-MATH-CALL))
                    (complement (if (> spot-term ONE_8) (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 erf-term) ERR-MATH-CALL) (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 erf-term) ERR-MATH-CALL)))
                    (weight-t (unwrap! (contract-call? .math-fixed-point div-up complement u200000000) ERR-MATH-CALL))
                    (weighted (unwrap! (contract-call? .math-fixed-point add-fixed 
                                (unwrap! (contract-call? .math-fixed-point mul-down moving-average weight-y) ERR-MATH-CALL) 
                                (unwrap! (contract-call? .math-fixed-point mul-down ma-comp weight-t) ERR-MATH-CALL)) ERR-MATH-CALL))
                    
                )
                ;; make sure weight-x > 0 so it works with weighted-equation
                (ok (if (> weighted u100000) weighted u100000))
            )     
        )
    )
)

;; single sided liquidity
(define-public (create-pool (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (multisig-vote <multisig-trait>) (ltv-0 uint) (conversion-ltv uint) (bs-vol uint) (moving-average uint) (dx uint)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))

            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))

            (now (* block-height ONE_8))
            ;; TODO: assume 10mins per block - something to be reviewed
            (t (unwrap! (contract-call? .math-fixed-point div-down 
                (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) ERR-MATH-CALL) (* u52560 ONE_8)) ERR-MATH-CALL))

            (token-symbol (try! (contract-call? token get-symbol)))
            (collateral-symbol (try! (contract-call? collateral get-symbol)))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))
            
            (strike (unwrap-panic (contract-call? .math-fixed-point div-down token-price collateral-price)))

            ;; TODO: APYs need to be calculated from the prevailing yield token price.
            ;; we calculate d1 first
            ;; because we support 'at-the-money' only, we can simplify formula
            (sqrt-t (unwrap! (contract-call? .math-fixed-point pow-down t u50000000) ERR-MATH-CALL))
            (sqrt-2 (unwrap! (contract-call? .math-fixed-point pow-down u200000000 u50000000) ERR-MATH-CALL))            
            (pow-bs-vol (unwrap! (contract-call? .math-fixed-point div-up 
                            (unwrap! (contract-call? .math-fixed-point pow-down bs-vol u200000000) ERR-MATH-CALL) u200000000) ERR-MATH-CALL))
            (numerator (unwrap! (contract-call? .math-fixed-point mul-up t pow-bs-vol) ERR-MATH-CALL))                       
            (denominator (unwrap! (contract-call? .math-fixed-point mul-down bs-vol sqrt-t) ERR-MATH-CALL))        
            (d1 (unwrap! (contract-call? .math-fixed-point div-up numerator denominator) ERR-MATH-CALL))
            (erf-term (unwrap! (erf (unwrap! (contract-call? .math-fixed-point div-up d1 sqrt-2) ERR-MATH-CALL)) ERR-MATH-CALL))
            (complement (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 erf-term) ERR-MATH-CALL))
            (weighted (unwrap! (contract-call? .math-fixed-point div-up complement u200000000) ERR-MATH-CALL))                
            (weight-y (if (> weighted u100000) weighted u100000))

            (weight-x (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-y) ERR-MATH-CALL))

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
                token-symbol: (unwrap! (contract-call? token get-symbol) get-symbol-fail-err),
                collateral-symbol: (unwrap! (contract-call? collateral get-symbol) get-symbol-fail-err),
                moving-average: moving-average,
                conversion-ltv: conversion-ltv
            })
        )

        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, expiry: expiry }))
            )
            pool-already-exists-err
        )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, expiry: expiry })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)
        (try! (add-to-position token collateral the-yield-token the-key-token dx))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
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
        ;; Just for Validation of initial parameters
        (   
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))
            (ltv (try! (get-ltv token collateral expiry)))
        )
        (asserts! (> dx u0) invalid-liquidity-err)
        ;; mint is possible only if ltv < 1
        (asserts! (> ONE_8 ltv) invalid-pool-err)
        (print ltv)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))                    
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))   
                (key-supply (get key-supply pool))
                (weight-x (get weight-x pool))

                (new-supply (try! (get-token-given-position token collateral expiry dx)))
                (yield-new-supply (get yield-token new-supply))
                (key-new-supply (get key-token new-supply))

                (dx-weighted (unwrap! (contract-call? .math-fixed-point mul-down weight-x dx) ERR-MATH-CALL))
                (dx-to-dy (unwrap! (contract-call? .math-fixed-point sub-fixed dx dx-weighted) ERR-MATH-CALL))

                (dy-weighted (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 dx-to-dy) no-liquidity-err)))

                (pool-updated (merge pool {
                    yield-supply: (unwrap! (contract-call? .math-fixed-point add-fixed yield-new-supply yield-supply) ERR-MATH-CALL),
                    key-supply: (unwrap! (contract-call? .math-fixed-point add-fixed key-new-supply key-supply) ERR-MATH-CALL),
                    balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx-weighted) ERR-MATH-CALL),
                    balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y dy-weighted) ERR-MATH-CALL)
                }))
            )     

            (unwrap! (contract-call? collateral transfer dx-weighted tx-sender .alex-vault none) transfer-x-failed-err)
            (unwrap! (contract-call? token transfer dy-weighted tx-sender .alex-vault none) transfer-y-failed-err)

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
;; TODO: currently the position returned is not guaranteed 
(define-public (reduce-position-yield (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) percent-greater-than-one-err)
        ;; burn supported only at maturity
        (asserts! (> (* block-height ONE_8) (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err)) expiry-err)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))
                (total-shares (unwrap! (contract-call? the-yield-token get-balance tx-sender) get-balance-fail-err))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) ERR-MATH-CALL)))
                (shares-to-yield (unwrap! (contract-call? .math-fixed-point div-down shares yield-supply) ERR-MATH-CALL))        

                ;; if there are any residual collateral, convert to token
                (bal-x-to-y (if (is-eq balance-x u0) 
                                u0 
                                (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 balance-x) no-liquidity-err))))
                (new-bal-y (unwrap! (contract-call? .math-fixed-point add-fixed balance-y bal-x-to-y) ERR-MATH-CALL))
                (dy (unwrap! (contract-call? .math-fixed-point mul-down new-bal-y shares-to-yield) ERR-MATH-CALL))


                (pool-updated (merge pool {
                    yield-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-supply shares) ERR-MATH-CALL),
                    balance-x: u0,
                    balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed new-bal-y dy) ERR-MATH-CALL)
                    })
                )
            )

            ;; if shares > dy, then transfer the shortfall from reserve.
            ;; TODO: this goes through swapping, so the amount received is actually slightly less than the shortfall
            (and (< dy shares) 
                (let
                    (
                        (amount (unwrap! (contract-call? .math-fixed-point sub-fixed shares dy) ERR-MATH-CALL))                    
                    )                
                    (if (is-eq token-y .token-usda)
                        (unwrap! (contract-call? .token-usda transfer amount .alex-reserve-pool tx-sender none) transfer-y-failed-err)
                        (let
                            (
                                (amount-to-swap (try! (contract-call? .fixed-weight-pool get-y-given-x token .token-usda u50000000 u50000000 amount)))
                            )
                            (unwrap! (contract-call? .token-usda transfer amount-to-swap .alex-reserve-pool tx-sender none) transfer-y-failed-err)
                            (unwrap! (contract-call? token transfer (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x token .token-usda u50000000 u50000000 amount-to-swap))) tx-sender .alex-vault none) transfer-y-failed-err)
                        )
                    )                
                )
            )       
        
            ;; transfer shares of token to tx-sender, ensuring convertability of yield-token
            (unwrap! (contract-call? token transfer shares .alex-vault tx-sender none) transfer-y-failed-err)

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? the-yield-token burn tx-sender shares))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: u0, dy: shares})            
        )
    )
)

(define-public (reduce-position-key (token <ft-trait>) (collateral <ft-trait>) (the-key-token <yield-token-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) percent-greater-than-one-err)
        ;; burn supported only at maturity
        (asserts! (> (* block-height ONE_8) (unwrap! (contract-call? the-key-token get-expiry) get-expiry-fail-err)) expiry-err)
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (expiry (unwrap! (contract-call? the-key-token get-expiry) get-expiry-fail-err))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))            
                (key-supply (get key-supply pool))            
                (total-shares (unwrap! (contract-call? the-key-token get-balance tx-sender) get-balance-fail-err))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) ERR-MATH-CALL)))
                (reduce-data (try! (get-position-given-burn-key token collateral expiry shares)))
                (dx-weighted (get dx reduce-data))
                (dy-weighted (get dy reduce-data))

                (pool-updated (merge pool {
                    key-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed key-supply shares) ERR-MATH-CALL),
                    balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx-weighted) ERR-MATH-CALL),
                    balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy-weighted) ERR-MATH-CALL)
                    })
                )            
            )

            (and (> dx-weighted u0) (unwrap! (contract-call? collateral transfer dx-weighted .alex-vault tx-sender none) transfer-x-failed-err))
            (and (> dy-weighted u0) (unwrap! (contract-call? token transfer dy-weighted .alex-vault tx-sender none) transfer-y-failed-err))
        
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
        (asserts! (> dx u0) invalid-liquidity-err) 
        (asserts! (<= (* block-height ONE_8) expiry) expiry-err)    
    
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (strike (get strike pool))
                (bs-vol (get bs-vol pool)) 
                (fee-rate-x (get fee-rate-x pool))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-y (unwrap! (get-weight-y token collateral expiry strike bs-vol) get-weight-fail-err))
                (weight-x (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-y) ERR-MATH-CALL))            
            
                ;; fee = dx * fee-rate-x
                (fee (unwrap! (contract-call? .math-fixed-point mul-up dx fee-rate-x) ERR-MATH-CALL))
                (dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx fee) ERR-MATH-CALL))    
                (dy (try! (get-y-given-x token collateral expiry dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx-net-fees) ERR-MATH-CALL),
                            balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) ERR-MATH-CALL),
                            fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-x pool) fee) ERR-MATH-CALL),
                            weight-x: weight-x,
                            weight-y: weight-y                    
                        }
                    )
                )
            )

            (unwrap! (contract-call? collateral transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
            (unwrap! (contract-call? token transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

;; split of balance to yield and key is transparent to traders
(define-public (swap-y-for-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (begin
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dy u0) invalid-liquidity-err)    
        (asserts! (<= (* block-height ONE_8) expiry) expiry-err)      
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (strike (get strike pool))
                (bs-vol (get bs-vol pool)) 
                (fee-rate-y (get fee-rate-y pool))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-y (unwrap! (get-weight-y token collateral expiry strike bs-vol) get-weight-fail-err))
                (weight-x (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-y) ERR-MATH-CALL))   

                ;; fee = dy * fee-rate-y
                (fee (unwrap! (contract-call? .math-fixed-point mul-up dy fee-rate-y) ERR-MATH-CALL))
                (dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy fee) ERR-MATH-CALL))
                (dx (try! (get-x-given-y token collateral expiry dy-net-fees)))        

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) ERR-MATH-CALL),
                            balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y dy-net-fees) ERR-MATH-CALL),                      
                            fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-y pool) fee) ERR-MATH-CALL),
                            weight-x: weight-x,
                            weight-y: weight-y                        
                        }
                    )
                )
            )

            (unwrap! (contract-call? collateral transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
            (unwrap! (contract-call? token transfer dy tx-sender .alex-vault none) transfer-y-failed-err)

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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok (get fee-rate-x pool))
    )
)

(define-read-only (get-fee-rate-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok (get fee-rate-y pool))
    )
)

(define-public (set-fee-rate-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (fee-rate-x uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok {fee-balance-x: (get fee-balance-x pool), fee-balance-y: (get fee-balance-y pool)})
    )
)

(define-public (collect-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))
            (fee-x-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-x rebate-rate) ERR-MATH-CALL))
            (fee-y-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-y rebate-rate) ERR-MATH-CALL))
            (fee-x-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-x fee-x-rebate) ERR-MATH-CALL))
            (fee-y-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-y fee-y-rebate) ERR-MATH-CALL))            
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (unwrap! (contract-call? collateral transfer fee-x .alex-vault tx-sender none) transfer-x-failed-err)
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-x .token-usda) 
                            fee-x 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda collateral u50000000 u50000000 fee-x)))
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (unwrap! (contract-call? token transfer fee-y .alex-vault tx-sender none) transfer-y-failed-err)
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-y .token-usda) 
                            fee-y 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token u50000000 u50000000 fee-y)))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))         
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

;; single sided liquidity
(define-read-only (get-token-given-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (< now expiry) ;; mint supported until, but excl., expiry
            (let 
                (
                    (ltv (try! (get-ltv token collateral expiry)))
                    (dy (unwrap! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 dx) no-liquidity-err))
                    (ltv-dy (unwrap! (contract-call? .math-fixed-point mul-down ltv dy) ERR-MATH-CALL))
                )

                (ok {yield-token: ltv-dy, key-token: ltv-dy})
            )
            expiry-err
        )
    )
)

;; single sided liquidity
(define-read-only (get-position-given-mint (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (< now expiry) ;; mint supported until, but excl., expiry
            (let 
                (
                    (token-x (contract-of collateral))
                    (token-y (contract-of token))
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                    (balance-x (get balance-x pool))
                    (balance-y (get balance-y pool))
                    (total-supply (get yield-supply pool)) ;; prior to maturity, yield-supply == key-supply, so we use yield-supply
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))
            
                    (ltv (try! (get-ltv token collateral expiry)))

                    (pos-data (unwrap! (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares) weighted-equation-call-err))

                    (dx-weighted (get dx pos-data))
                    (dy-weighted (get dy pos-data))

                    ;; always convert to collateral ccy
                    (dy-to-dx (unwrap! (contract-call? .fixed-weight-pool get-y-given-x token collateral u50000000 u50000000 dy-weighted) no-liquidity-err))
                    
                    (dx (unwrap! (contract-call? .math-fixed-point add-fixed dx-weighted dy-to-dx) ERR-MATH-CALL))
                )
                (ok {dx: dx, dx-weighted: dx-weighted, dy-weighted: dy-weighted})
            )
            expiry-err
        )
    )
)

(define-read-only (get-position-given-burn-yield (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (> now expiry)
            (ok shares)
            expiry-err
        )
    )
)

(define-read-only (get-position-given-burn-key (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (> now expiry)
            (let 
                (
                    (token-x (contract-of collateral))
                    (token-y (contract-of token))
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                    (balance-x (get balance-x pool))
                    (balance-y (get balance-y pool))  
                    (yield-supply (get yield-supply pool))                  
                    (key-supply (get key-supply pool))
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))
                    (pool-value-unfloored (try! (get-pool-value-in-token token collateral expiry)))
                    (pool-value-in-y (if (> yield-supply pool-value-unfloored) yield-supply pool-value-unfloored))
                    (key-value-in-y (unwrap! (contract-call? .math-fixed-point sub-fixed pool-value-in-y yield-supply) ERR-MATH-CALL))
                    (key-to-pool (unwrap! (contract-call? .math-fixed-point div-down key-value-in-y pool-value-in-y) ERR-MATH-CALL))
                    (shares-to-key (unwrap! (contract-call? .math-fixed-point div-down shares key-supply) ERR-MATH-CALL))
                    (shares-to-pool (unwrap! (contract-call? .math-fixed-point mul-down key-to-pool shares-to-key) ERR-MATH-CALL))
                    
                    (dx (unwrap! (contract-call? .math-fixed-point mul-down shares-to-pool balance-x) ERR-MATH-CALL))
                    (dy (unwrap! (contract-call? .math-fixed-point mul-down shares-to-pool balance-y) ERR-MATH-CALL))
                )
                (ok {dx: dx, dy: dy})
            )
            expiry-err
        )
    )
)