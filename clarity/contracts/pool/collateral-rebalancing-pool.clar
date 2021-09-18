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
(define-constant percent-greater-than-one (err u5000))
(define-constant no-fee-x-err (err u2005))
(define-constant no-fee-y-err (err u2006))
(define-constant weighted-equation-call-err (err u2009))
(define-constant math-call-err (err u4003))
(define-constant internal-function-call-err (err u1001))
(define-constant get-weight-fail-err (err u2012))
(define-constant get-expiry-fail-err (err u2013))
(define-constant get-price-fail-err (err u2015))
(define-constant get-symbol-fail-err (err u6000))
(define-constant get-oracle-price-fail-err (err u7000))
(define-constant expiry-err (err u2017))
(define-constant get-balance-fail-err (err u6001))
(define-constant not-authorized-err (err u1000))
(define-constant ltv-greater-than-one-err (err u2019))

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
            (a1x (unwrap! (mul-down a1 x) math-call-err))
            (x2 (unwrap! (pow-down x u200000000) math-call-err))
            (a2x (unwrap! (mul-down a2 x2) math-call-err))
            (x3 (unwrap! (pow-down x u300000000) math-call-err))
            (a3x (unwrap! (mul-down a3 x3) math-call-err))
            (x4 (unwrap! (pow-down x u400000000) math-call-err))
            (a4x (unwrap! (mul-down a4 x4) math-call-err))
            (denom (unwrap! (add-fixed ONE_8 a1x) math-call-err))
            (denom1 (unwrap! (add-fixed denom a2x) math-call-err))
            (denom2 (unwrap! (add-fixed denom1 a3x) math-call-err))
            (denom3 (unwrap! (add-fixed denom2 a4x) math-call-err))
            (denom4 (unwrap! (pow-down denom3 u400000000) math-call-err))
            (base (unwrap! (div-down ONE_8 denom4) math-call-err))
        )
        (sub-fixed ONE_8 base)
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
        (ok (unwrap-panic (div-down token-price collateral-price)))
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
            (token-value (unwrap! (mul-down balance-x collateral-price) math-call-err))
            (balance-x-in-y (unwrap! (div-down token-value token-price) math-call-err))
        )
        (add-fixed balance-x-in-y balance-y)
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
            (collateral-value (unwrap! (mul-down balance-y token-price) math-call-err))
            (balance-y-in-x (unwrap! (div-down collateral-value collateral-price) math-call-err))
        )
        (add-fixed balance-y-in-x balance-x)
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
            (div-down yield-supply pool-value)
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
            (ma-comp (unwrap! (sub-fixed ONE_8 moving-average) math-call-err))

            ;; determine spot using open oracle
            ;; token / collateral
            (spot (unwrap! (get-spot token collateral expiry) get-oracle-price-fail-err))
            (now (* block-height ONE_8))
            
            ;; TODO: assume 10mins per block - something to be reviewed            
            (t (unwrap! (div-down 
                (unwrap! (sub-fixed expiry now) math-call-err) (* u52560 ONE_8)) math-call-err))
            ;; TODO: APYs need to be calculated from the prevailing yield token price.
            ;; TODO: ln(S/K) approximated as (S/K - 1)

            ;; we calculate d1 first
            (spot-term (unwrap! (div-up spot strike) math-call-err))
            (pow-bs-vol (unwrap! (div-up 
                            (unwrap! (pow-down bs-vol u200000000) math-call-err) u200000000) math-call-err))
            (vol-term (unwrap! (mul-up t pow-bs-vol) math-call-err))                       
            (sqrt-t (unwrap! (pow-down t u50000000) math-call-err))
            (sqrt-2 (unwrap! (pow-down u200000000 u50000000) math-call-err))
            
            (denominator (unwrap! (mul-down bs-vol sqrt-t) math-call-err))

            (ltv (try! (get-ltv token collateral expiry)))
        )

        ;; if current ltv > conversion-ltv, then pool converts to (almost) 100% token (i.e. weight-x = 0)
        (if (or (> ltv conversion-ltv) (is-eq now expiry))
            (ok u99900000)                    
            (let
                (
                    (numerator (unwrap! (add-fixed vol-term 
                                    (unwrap! (sub-fixed 
                                        (if (> spot-term ONE_8) spot-term ONE_8) (if (> spot-term ONE_8) ONE_8 spot-term)) math-call-err)) math-call-err))
                    (d1 (unwrap! (div-up numerator denominator) math-call-err))
                    (erf-term (unwrap! (erf (unwrap! (div-up d1 sqrt-2) math-call-err)) math-call-err))
                    (complement (if (> spot-term ONE_8) (unwrap! (add-fixed ONE_8 erf-term) math-call-err) (unwrap! (sub-fixed ONE_8 erf-term) math-call-err)))
                    (weight-t (unwrap! (div-up complement u200000000) math-call-err))
                    (weighted (unwrap! (add-fixed 
                                (unwrap! (mul-down moving-average weight-y) math-call-err) 
                                (unwrap! (mul-down ma-comp weight-t) math-call-err)) math-call-err))
                    
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
            (t (unwrap! (div-down 
                (unwrap! (sub-fixed expiry now) math-call-err) (* u52560 ONE_8)) math-call-err))

            (token-symbol (try! (contract-call? token get-symbol)))
            (collateral-symbol (try! (contract-call? collateral get-symbol)))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))
            
            (strike (unwrap-panic (div-down token-price collateral-price)))

            ;; TODO: APYs need to be calculated from the prevailing yield token price.
            ;; we calculate d1 first
            ;; because we support 'at-the-money' only, we can simplify formula
            (sqrt-t (unwrap! (pow-down t u50000000) math-call-err))
            (sqrt-2 (unwrap! (pow-down u200000000 u50000000) math-call-err))            
            (pow-bs-vol (unwrap! (div-up 
                            (unwrap! (pow-down bs-vol u200000000) math-call-err) u200000000) math-call-err))
            (numerator (unwrap! (mul-up t pow-bs-vol) math-call-err))                       
            (denominator (unwrap! (mul-down bs-vol sqrt-t) math-call-err))        
            (d1 (unwrap! (div-up numerator denominator) math-call-err))
            (erf-term (unwrap! (erf (unwrap! (div-up d1 sqrt-2) math-call-err)) math-call-err))
            (complement (unwrap! (sub-fixed ONE_8 erf-term) math-call-err))
            (weighted (unwrap! (div-up complement u200000000) math-call-err))                
            (weight-y (if (> weighted u100000) weighted u100000))

            (weight-x (unwrap! (sub-fixed ONE_8 weight-y) math-call-err))

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
        (asserts! (> ONE_8 ltv) ltv-greater-than-one-err)
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

                (dx-weighted (unwrap! (mul-down weight-x dx) math-call-err))
                (dx-to-dy (unwrap! (sub-fixed dx dx-weighted) math-call-err))

                (dy-weighted (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 dx-to-dy) no-liquidity-err)))

                (pool-updated (merge pool {
                    yield-supply: (unwrap! (add-fixed yield-new-supply yield-supply) math-call-err),
                    key-supply: (unwrap! (add-fixed key-new-supply key-supply) math-call-err),
                    balance-x: (unwrap! (add-fixed balance-x dx-weighted) math-call-err),
                    balance-y: (unwrap! (add-fixed balance-y dy-weighted) math-call-err)
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
        (asserts! (<= percent ONE_8) percent-greater-than-one)
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
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) math-call-err)))
                (shares-to-yield (unwrap! (div-down shares yield-supply) math-call-err))        

                ;; if there are any residual collateral, convert to token
                (bal-x-to-y (if (is-eq balance-x u0) 
                                u0 
                                (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 balance-x) no-liquidity-err))))
                (new-bal-y (unwrap! (add-fixed balance-y bal-x-to-y) math-call-err))
                (dy (unwrap! (mul-down new-bal-y shares-to-yield) math-call-err))


                (pool-updated (merge pool {
                    yield-supply: (unwrap! (sub-fixed yield-supply shares) math-call-err),
                    balance-x: u0,
                    balance-y: (unwrap! (sub-fixed new-bal-y dy) math-call-err)
                    })
                )
            )

            ;; if shares > dy, then transfer the shortfall from reserve.
            ;; TODO: this goes through swapping, so the amount received is actually slightly less than the shortfall
            (and (< dy shares) 
                (let
                    (
                        (amount (unwrap! (sub-fixed shares dy) math-call-err))                    
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
        (asserts! (<= percent ONE_8) percent-greater-than-one)
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
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) math-call-err)))
                (reduce-data (try! (get-position-given-burn-key token collateral expiry shares)))
                (dx-weighted (get dx reduce-data))
                (dy-weighted (get dy reduce-data))

                (pool-updated (merge pool {
                    key-supply: (unwrap! (sub-fixed key-supply shares) math-call-err),
                    balance-x: (unwrap! (sub-fixed balance-x dx-weighted) math-call-err),
                    balance-y: (unwrap! (sub-fixed balance-y dy-weighted) math-call-err)
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
                (weight-x (unwrap! (sub-fixed ONE_8 weight-y) math-call-err))            
            
                ;; fee = dx * fee-rate-x
                (fee (unwrap! (mul-up dx fee-rate-x) math-call-err))
                (dx-net-fees (unwrap! (sub-fixed dx fee) math-call-err))    
                (dy (try! (get-y-given-x token collateral expiry dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (add-fixed balance-x dx-net-fees) math-call-err),
                            balance-y: (unwrap! (sub-fixed balance-y dy) math-call-err),
                            fee-balance-x: (unwrap! (add-fixed (get fee-balance-x pool) fee) math-call-err),
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
                (weight-x (unwrap! (sub-fixed ONE_8 weight-y) math-call-err))   

                ;; fee = dy * fee-rate-y
                (fee (unwrap! (mul-up dy fee-rate-y) math-call-err))
                (dy-net-fees (unwrap! (sub-fixed dy fee) math-call-err))
                (dx (try! (get-x-given-y token collateral expiry dy-net-fees)))        

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (sub-fixed balance-x dx) math-call-err),
                            balance-y: (unwrap! (add-fixed balance-y dy-net-fees) math-call-err),                      
                            fee-balance-y: (unwrap! (add-fixed (get fee-balance-y pool) fee) math-call-err),
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
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

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
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

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
            (fee-x-rebate (unwrap! (mul-down fee-x rebate-rate) math-call-err))
            (fee-y-rebate (unwrap! (mul-down fee-y rebate-rate) math-call-err))
            (fee-x-net (unwrap! (sub-fixed fee-x fee-x-rebate) math-call-err))
            (fee-y-net (unwrap! (sub-fixed fee-y fee-y-rebate) math-call-err))            
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)
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

(define-read-only (get-y-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
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
        (contract-call? .weighted-equation get-y-given-price balance-x balance-y weight-x weight-y price)
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
                    (ltv-dy (unwrap! (mul-down ltv dy) math-call-err))
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
                    
                    (dx (unwrap! (add-fixed dx-weighted dy-to-dx) math-call-err))
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
                    (key-value-in-y (unwrap! (sub-fixed pool-value-in-y yield-supply) math-call-err))
                    (key-to-pool (unwrap! (div-down key-value-in-y pool-value-in-y) math-call-err))
                    (shares-to-key (unwrap! (div-down shares key-supply) math-call-err))
                    (shares-to-pool (unwrap! (mul-down key-to-pool shares-to-key) math-call-err))
                    
                    (dx (unwrap! (mul-down shares-to-pool balance-x) math-call-err))
                    (dy (unwrap! (mul-down shares-to-pool balance-y) math-call-err))
                )
                (ok {dx: dx, dy: dy})
            )
            expiry-err
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
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
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
            (raw (unwrap-panic (contract-call? .math-log-exp pow-fixed a b)))
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

(define-read-only (test)
  (let
    (
      (x (* u7 (pow u10 u6)))
      (y (* u233 (pow u10 u6)))
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) iONE_8))
      ;;(r (exp-pos (* -1 logx-times-y)))

      ;;(arg (* 69 iONE_8))
      ;;(r (exp-pos arg))
      ;;(x_product (fold accumulate_product x_a_list {x: arg, product: iONE_8}))
  )
  ;;(ok logx-times-y)
  ;;x_product
  (ok (pow-fixed x y))
 )
)
