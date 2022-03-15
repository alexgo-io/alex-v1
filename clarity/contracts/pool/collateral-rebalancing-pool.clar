(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)

;; collateral-rebalancing-pool
;;

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-WEIGHTED-EQUATION-CALL (err u2009))
(define-constant ERR-GET-WEIGHT-FAIL (err u2012))
(define-constant ERR-EXPIRY (err u2017))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-LTV-GREATER-THAN-ONE (err u2019))
(define-constant ERR-EXCEEDS-MAX-SLIPPAGE (err u2020))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-POOL-AT-CAPACITY (err u2027))

(define-constant a1 u27839300)
(define-constant a2 u23038900)
(define-constant a3 u97200)
(define-constant a4 u7810800)

(define-data-var contract-owner principal tx-sender)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-private (check-is-owner)
    (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-data-var shortfall-coverage uint u101000000) ;; 1.01x

(define-read-only (get-shortfall-coverage)
  (ok (var-get shortfall-coverage))
)

(define-public (set-shortfall-coverage (new-shortfall-coverage uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set shortfall-coverage new-shortfall-coverage))
  )
)

;; data maps and vars
;;
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
    fee-to-address: principal,
    yield-token: principal,
    key-token: principal,
    strike: uint,
    bs-vol: uint,
    ltv-0: uint,
    fee-rate-x: uint,
    fee-rate-y: uint,
    fee-rebate: uint,
    weight-x: uint,
    weight-y: uint,
    moving-average: uint,
    conversion-ltv: uint,
    token-to-maturity: uint
  }
)

;; private functions
;;

;; Approximation of Error Function using Abramowitz and Stegun
;; https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
;; Please note erf(x) equals -erf(-x)
(define-private (erf (x uint))
    (let
        (
            (denom3 (+ (+ (+ (+ ONE_8 (mul-down a1 x)) (mul-down a2 (mul-down x x))) (mul-down a3 (mul-down x (mul-down x x)))) (mul-down a4 (mul-down x (mul-down x (mul-down x x))))))
            (base (mul-down denom3 (mul-down denom3 (mul-down denom3 denom3))))
        )
        (div-down (- base ONE_8) base)
    )
)

;; public functions
;;

;; @desc get-pool-details
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @returns (response (tuple) uint)
(define-read-only (get-pool-details (token principal) (collateral principal) (expiry uint))
    (ok (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
)

;; @desc get-spot
;; @desc price of collateral in token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @returns (response uint uint)
(define-read-only (get-spot (token principal) (collateral principal))
    (ok (try! (contract-call? .swap-helper oracle-resilient-helper collateral token)))
)

(define-read-only (get-pool-value-in-token (token principal) (collateral principal) (expiry uint))
    (get-pool-value-in-token-with-spot token collateral expiry (try! (get-spot token collateral)))
)

;; @desc get-pool-value-in-token-with-spot
;; @desc value of pool in units of borrow token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @returns (response uint uint)
(define-private (get-pool-value-in-token-with-spot (token principal) (collateral principal) (expiry uint) (spot uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))            
        )
        (ok (+ (mul-down (get balance-x pool) spot) (get balance-y pool)))
    )
)

(define-read-only (get-pool-value-in-collateral (token principal) (collateral principal) (expiry uint))
    (get-pool-value-in-collateral-with-spot token collateral expiry (try! (get-spot token collateral)))
)

;; @desc get-pool-value-in-collateral-with-spot
;; @desc value of pool in units of collateral token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @returns (response uint uint)
(define-private (get-pool-value-in-collateral-with-spot (token principal) (collateral principal) (expiry uint) (spot uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))   
        )
        (ok (+ (div-down (get balance-y pool) spot) (get balance-x pool)))
    )
)

(define-read-only (get-ltv (token principal) (collateral principal) (expiry uint))
    (get-ltv-with-spot token collateral expiry (try! (get-spot token collateral)))
)

;; @desc get-ltv-with-spot
;; @desc value of yield-token as % of pool value (i.e. loan-to-value)
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @returns (response uint uint)
(define-private (get-ltv-with-spot (token principal) (collateral principal) (expiry uint) (spot uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
        )
        ;; if no liquidity in the pool, return ltv-0
        (if (is-eq (get yield-supply pool) u0)
            (ok (get ltv-0 pool))
            (ok (div-down (get yield-supply pool) (+ (mul-down (get balance-x pool) spot) (get balance-y pool))))
        )
    )
)

(define-read-only (get-weight-x (token principal) (collateral principal) (expiry uint))
    (get-weight-x-with-spot token collateral expiry (try! (get-spot token collateral)))
)

;; @desc get-weight-x-with-spot
;; @desc call delta of collateral token (risky asset) based on reference black-scholes option with expiry/strike/bs-vol
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; expiry block-height
;; @param strike; reference strike price
;; @param bs-vol; reference black-scholes vol
;; @returns (response uint uint)
(define-private (get-weight-x-with-spot (token principal) (collateral principal) (expiry uint) (spot uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
            (bs-vol (get bs-vol pool))
            (ltv (try! (get-ltv-with-spot token collateral expiry spot)))
        )
        (if (>= ltv (get conversion-ltv pool))
            (ok u100000) ;; move everything to risk-free asset
            (let 
                (
                    ;; assume 10mins per block 
                    (t (div-down (* (- expiry block-height) ONE_8) (* u52560 ONE_8)))
                    (t-2 (div-down (* (- expiry block-height) ONE_8) (get token-to-maturity pool)))

                    ;; we calculate d1 first
                    (spot-term (div-down spot (get strike pool)))
                    (d1 
                        (div-down 
                            (+ 
                                (mul-down t (div-down (mul-down bs-vol bs-vol) u200000000)) 
                                (if (> spot-term ONE_8) (- spot-term ONE_8) (- ONE_8 spot-term))
                            )
                            (mul-down bs-vol (pow-down t u50000000))
                        )
                    )
                    (erf-term (erf (div-down d1 (pow-down u200000000 u50000000))))
                    (weight-t (div-down (if (> spot-term ONE_8) (+ ONE_8 erf-term) (if (<= ONE_8 erf-term) u0 (- ONE_8 erf-term))) u200000000))
                    (weighted 
                        (+ 
                            (mul-down (get moving-average pool) (get weight-y pool)) 
                            (mul-down 
                                (- ONE_8 (get moving-average pool)) 
                                (if (> t-2 ONE_8) weight-t (+ (mul-down t-2 weight-t) (mul-down (- ONE_8 t-2) (- ONE_8 ltv))))
                            )
                        )
                    )                    
                )
                ;; make sure weight-x <= 0.9 so it works with weighted-equation-v1-01
                (ok (if (< weighted u95000000) weighted u95000000))
            )    
        )
    )
)

;; @desc create-pool with single sided liquidity
;; @restricted contract-owner
;; @param token; borrow token
;; @param collateral; collateral token
;; @param yield-token-trait; yield-token to be minted
;; @param key-token-trait; key-token to be minted
;; @param multisig-vote; multisig to govern the pool being created
;; @param ltv-0; initial loan-to-value
;; @param conversion-ltv; loan-to-value at which conversion into borrow token happens
;; @param bs-vol; reference black-scholes vol to use 
;; @param moving-average; weighting smoothing factor
;; @param dx; amount of collateral token being added
;; @returns (response bool uint)
(define-public (create-pool (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (multisig-vote principal) (ltv-0 uint) (conversion-ltv uint) (bs-vol uint) (moving-average uint) (token-to-maturity uint) (dx uint)) 
    (begin
        (try! (check-is-owner))
        (asserts! 
            (is-none (map-get? pools-data-map { token-x: (contract-of collateral-trait), token-y: (contract-of token-trait), expiry: expiry }))
            ERR-POOL-ALREADY-EXISTS
        )
        (asserts! 
            (and 
                (< conversion-ltv ONE_8) 
                (< ltv-0 conversion-ltv) 
                (< moving-average ONE_8) 
                (< token-to-maturity (* (- expiry block-height) ONE_8))
                (not (is-eq (contract-of collateral-trait) (contract-of token-trait)))
            ) 
            ERR-INVALID-POOL
        )            
        (let
            (
                (token-x (contract-of collateral-trait))
                (token-y (contract-of token-trait))
                    
                ;; assume 10mins per block 
                (t (div-down (* (- expiry block-height) ONE_8) (* u52560 ONE_8)))                
                ;; we calculate d1 first (of call on collateral at strike) first                
                (d1 (div-down (+ (mul-down t (div-down (mul-down bs-vol bs-vol) u200000000)) (- ONE_8 ltv-0)) (mul-down bs-vol (pow-down t u50000000))))
                (erf-term (erf (div-down d1 (pow-down u200000000 u50000000))))
                (weighted (div-down (+ ONE_8 erf-term) u200000000))
                (weight-x (if (< weighted u95000000) weighted u95000000))
                (weight-y (- ONE_8 weight-x))

                (pool-data {
                    yield-supply: u0,
                    key-supply: u0,
                    balance-x: u0,
                    balance-y: u0,
                    fee-to-address: multisig-vote,
                    yield-token: (contract-of yield-token-trait),
                    key-token: (contract-of key-token-trait),
                    strike: (mul-down (try! (get-spot token-y token-x)) ltv-0),
                    bs-vol: bs-vol,
                    fee-rate-x: u0,
                    fee-rate-y: u0,
                    fee-rebate: u0,
                    ltv-0: ltv-0,
                    weight-x: weight-x,
                    weight-y: weight-y,
                    moving-average: moving-average,
                    conversion-ltv: conversion-ltv,
                    token-to-maturity: token-to-maturity
                })                             
            )
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)

            (try! (contract-call? .alex-vault add-approved-token token-x))
            (try! (contract-call? .alex-vault add-approved-token token-y))
            (try! (contract-call? .alex-vault add-approved-token (contract-of yield-token-trait)))
            (try! (contract-call? .alex-vault add-approved-token (contract-of key-token-trait)))

            (try! (add-to-position token-trait collateral-trait expiry yield-token-trait key-token-trait dx))
            (print { object: "pool", action: "created", data: pool-data })
            (ok true)
        )
    )
)

;; @desc mint yield-token and key-token, swap minted yield-token with token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param yield-token-trait; yield-token to be minted
;; @param key-token-trait; key-token to be minted
;; @param dx; amount of collateral added
;; @post collateral; sender transfer exactly dx to alex-vault
;; @post yield-token; sender transfers > 0 to alex-vault
;; @post token; alex-vault transfers >0 to sender
;; @returns (response (tuple uint uint) uint)
(define-public (add-to-position-and-switch (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (dx uint))
    (contract-call? 
        .yield-token-pool swap-y-for-x expiry yield-token-trait token-trait (get yield-token (try! (add-to-position token-trait collateral-trait expiry yield-token-trait key-token-trait dx))) none
    )
)

;; @desc mint yield-token and key-token, with single-sided liquidity
;; @param token; borrow token
;; @param collateral; collateral token
;; @param yield-token-trait; yield-token to be minted
;; @param key-token-trait; key-token to be minted
;; @param dx; amount of collateral added
;; @post collateral; sender transfer exactly dx to alex-vault
;; @returns (response (tuple uint uint) uint)
(define-public (add-to-position (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (dx uint))    
    (add-to-position-with-spot token-trait collateral-trait expiry yield-token-trait key-token-trait (try! (get-spot (contract-of token-trait) (contract-of collateral-trait))) dx)
)    

;; @desc mint yield-token and key-token, with single-sided liquidity
;; @param token; borrow token
;; @param collateral; collateral token
;; @param yield-token-trait; yield-token to be minted
;; @param key-token-trait; key-token to be minted
;; @param dx; amount of collateral added
;; @post collateral; sender transfer exactly dx to alex-vault
;; @returns (response (tuple uint uint) uint)
(define-private (add-to-position-with-spot (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (spot uint) (dx uint))    
    (let
        (   
            (token-x (contract-of collateral-trait))
            (token-y (contract-of token-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
        )
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        ;; mint is possible only if ltv < conversion-ltv
        (asserts! (>= (get conversion-ltv pool) (try! (get-ltv-with-spot token-y token-x expiry spot))) ERR-LTV-GREATER-THAN-ONE)
        (asserts! (and (is-eq (get yield-token pool) (contract-of yield-token-trait)) (is-eq (get key-token pool) (contract-of key-token-trait))) ERR-INVALID-TOKEN)
        (let
            (
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))   
                (key-supply (get key-supply pool))
                (weight-x (get weight-x pool))

                (new-supply (try! (get-token-given-position-with-spot token-y token-x expiry spot dx)))
                (yield-new-supply (get yield-token new-supply))
                (key-new-supply (get key-token new-supply))

                (dx-weighted (mul-down weight-x dx))
                (dx-to-dy (if (<= dx dx-weighted) u0 (- dx dx-weighted)))

                (dy-weighted (try! (contract-call? .swap-helper swap-helper collateral-trait token-trait dx-to-dy none)))

                (pool-updated (merge pool {
                    yield-supply: (+ yield-new-supply yield-supply),                    
                    key-supply: (+ key-new-supply key-supply),
                    balance-x: (+ balance-x dx-weighted),
                    balance-y: (+ balance-y dy-weighted)
                }))
                (sender tx-sender)
            ) 

            (unwrap! (contract-call? .swap-helper get-helper token-x token-y (+ dx balance-x (div-down balance-y spot))) ERR-POOL-AT-CAPACITY)

            (unwrap! (contract-call? collateral-trait transfer-fixed dx-weighted sender .alex-vault none) ERR-TRANSFER-FAILED)
            (unwrap! (contract-call? token-trait transfer-fixed dy-weighted sender .alex-vault none) ERR-TRANSFER-FAILED)

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            ;; mint pool token and send to tx-sender
            (as-contract (try! (contract-call? yield-token-trait mint-fixed expiry yield-new-supply sender)))
            (as-contract (try! (contract-call? key-token-trait mint-fixed expiry key-new-supply sender)))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {yield-token: yield-new-supply, key-token: key-new-supply})
        )
    )
)    

;; @desc burn yield-token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param yield-token-trait; yield-token to be burnt
;; @param percent; % of yield-token held to be burnt
;; @post yield-token; alex-vault transfer exactly uints of token equal to (percent * yield-token held) to sender
;; @returns (response (tuple uint uint) uint)
(define-public (reduce-position-yield (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        ;; burn supported only at maturity
        (asserts! (> block-height expiry) ERR-EXPIRY)
        
        (let
            (
                (token-x (contract-of collateral-trait))
                (token-y (contract-of token-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (yield-supply (get yield-supply pool))
                (total-shares (unwrap! (contract-call? yield-token-trait get-balance-fixed expiry tx-sender) ERR-GET-BALANCE-FIXED-FAIL))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
                (sender tx-sender)

                ;; if balance-y does not cover yield-supply, swap some balance-x to meet the requirement.
                (bal-y-short (if (<= yield-supply balance-y) u0 (mul-down (- yield-supply balance-y) (var-get shortfall-coverage))))
                (bal-x-to-sell 
                    (if (is-eq bal-y-short u0)
                        u0
                        (try! (contract-call? .swap-helper get-helper token-y token-x bal-y-short))
                    )
                )
                (bal-y-short-act 
                    (if (is-eq bal-x-to-sell u0)
                        u0
                        (begin
                            (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait bal-x-to-sell tx-sender)))
                            (as-contract (try! (contract-call? .swap-helper swap-helper collateral-trait token-trait bal-x-to-sell none)))
                        )
                    )
                )                
                (bal-x-short (if (<= bal-x-to-sell balance-x) u0 (- bal-x-to-sell balance-x)))

                (pool-updated (merge pool {
                    yield-supply: (if (<= yield-supply shares) u0 (- yield-supply shares)),
                    balance-x: (- (+ balance-x bal-x-short) bal-x-to-sell),
                    balance-y: (if (<= (+ balance-y bal-y-short-act) shares) u0 (- (+ balance-y bal-y-short-act) shares))
                    })
                )
            )
            (asserts! (is-eq (get yield-token pool) (contract-of yield-token-trait)) ERR-INVALID-TOKEN)

            ;; if any conversion happened at contract level, transfer back to vault
            (and (> bal-y-short-act u0) (as-contract (try! (contract-call? token-trait transfer-fixed bal-y-short-act tx-sender .alex-vault none))))
            
            ;; if bal-x-short > 0, then transfer the shortfall from reserve (accounting only).
            ;; TODO: what if token is exhausted but reserve have others?
            (and (> bal-x-short u0) (as-contract (try! (contract-call? .alex-reserve-pool remove-from-balance token-x bal-x-short))))
        
            ;; transfer shares of token to tx-sender, ensuring convertability of yield-token
            (and (> shares u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-trait shares sender))))

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (and (> shares u0) (as-contract (try! (contract-call? yield-token-trait burn-fixed expiry shares sender))))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: u0, dy: shares})            
        )
    )
)

;; @desc burn key-token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param key-token-trait; key-token to be burnt
;; @param percent; % of key-token held to be burnt
;; @post token; alex-vault transfers > 0 token to sender
;; @post collateral; alex-vault transfers > 0 collateral to sender
;; @returns (response (tuple uint uint) uint)
(define-public (reduce-position-key (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (key-token-trait <sft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        ;; burn supported only at maturity
        (asserts! (> block-height expiry) ERR-EXPIRY)        
        (let
            (
                (token-x (contract-of collateral-trait))
                (token-y (contract-of token-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))            
                (key-supply (get key-supply pool))    
                (yield-supply (get yield-supply pool))        
                (total-shares (unwrap! (contract-call? key-token-trait get-balance-fixed expiry tx-sender) ERR-GET-BALANCE-FIXED-FAIL))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
                (sender tx-sender)

                ;; if balance-y does not cover yield-supply, swap some balance-x to meet the requirement.
                (bal-y-short (if (<= yield-supply balance-y) u0 (mul-down (- yield-supply balance-y) (var-get shortfall-coverage))))
                (bal-x-to-sell 
                    (if (is-eq bal-y-short u0)
                        u0
                        (try! (contract-call? .swap-helper get-helper token-y token-x bal-y-short))
                    )
                )
                (bal-y-short-act 
                    (if (is-eq bal-x-to-sell u0)
                        u0
                        (begin
                            (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait bal-x-to-sell tx-sender)))
                            (as-contract (try! (contract-call? .swap-helper swap-helper collateral-trait token-trait bal-x-to-sell none)))
                        )
                    )
                )                                 
                (bal-x-short (if (<= bal-x-to-sell balance-x) u0 (- bal-x-to-sell balance-x)))
                
                (bal-y-key (if (<= (+ balance-y bal-y-short-act) yield-supply) u0 (- (+ balance-y bal-y-short-act) yield-supply)))
                (shares-to-key (div-down shares key-supply))
                (bal-y-to-reduce (mul-down bal-y-key shares-to-key))
                (bal-x-to-reduce (mul-down (- (+ balance-x bal-x-short) bal-x-to-sell) shares-to-key))

                (pool-updated (merge pool {
                    key-supply: (if (<= key-supply shares) u0 (- key-supply shares)),
                    balance-x: (- (- (+ balance-x bal-x-short) bal-x-to-sell) bal-x-to-reduce),
                    balance-y: (- (+ balance-y bal-y-short-act) bal-y-to-reduce)
                    })
                )            
            )

            (asserts! (is-eq (get key-token pool) (contract-of key-token-trait)) ERR-INVALID-TOKEN)

            ;; if any conversion happened at contract level, transfer back to vault
            (and (> bal-y-short-act u0) (as-contract (try! (contract-call? token-trait transfer-fixed bal-y-short-act tx-sender .alex-vault none))))
            
            ;; if bal-x-short > 0, then transfer the shortfall from reserve (accounting only).
            ;; TODO: what if token is exhausted but reserve have others?
            (and (> bal-x-short u0) (as-contract (try! (contract-call? .alex-reserve-pool remove-from-balance token-x bal-x-short))))

            (and (> bal-x-to-reduce u0) (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait bal-x-to-reduce sender))))
            (and (> bal-y-to-reduce u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-trait bal-y-to-reduce sender))))
        
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (and (> shares u0) (as-contract (try! (contract-call? key-token-trait burn-fixed expiry shares sender))))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: bal-x-to-reduce, dy: bal-y-to-reduce})
        )        
    )
)

;; @desc swap collateral with token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param dx; amount of collateral to be swapped
;; @param min-dy; max slippage
;; @post collateral; sender transfers exactly dx collateral to alex-vault
;; @returns (response (tuple uint uint) uint)
(define-public (swap-x-for-y (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (dx uint) (min-dy (optional uint)))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        ;; CR-03
        (asserts! (<= block-height expiry) ERR-EXPIRY)            
        (let
            (
                (token-x (contract-of collateral-trait))
                (token-y (contract-of token-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-x (unwrap! (get-weight-x-with-spot token-y token-x expiry (try! (get-spot token-y token-x))) ERR-GET-WEIGHT-FAIL))
                (weight-y (- ONE_8 weight-x))            
            
                ;; fee = dx * fee-rate-x
                (fee (mul-up dx (get fee-rate-x pool)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))
                (dx-net-fees (if (<= dx fee) u0 (- dx fee)))
                (dy (try! (get-y-given-x token-y token-x expiry dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-x: (+ balance-x dx-net-fees fee-rebate),
                            balance-y: (if (<= balance-y dy) u0 (- balance-y dy)),
                            weight-x: weight-x,
                            weight-y: weight-y                    
                        }
                    )
                )
                (sender tx-sender)
            )

            (asserts! (< (default-to u0 min-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)

            (unwrap! (contract-call? collateral-trait transfer-fixed dx tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
            (and (> dy u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-trait dy sender))))
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance token-x (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

;; @desc swap token with collateral
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param dy; amount of token to be swapped
;; @param min-dx; max slippage
;; @post token; sender transfers exactly dy token to alex-vault
;; @returns (response (tuple uint uint) uint)
(define-public (swap-y-for-x (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (dy uint) (min-dx (optional uint)))
    (begin
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)    
        ;; CR-03
        (asserts! (<= block-height expiry) ERR-EXPIRY)              
        (let
            (
                (token-x (contract-of collateral-trait))
                (token-y (contract-of token-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; every swap call updates the weights
                (weight-x (unwrap! (get-weight-x-with-spot token-y token-x expiry (try! (get-spot token-y token-x))) ERR-GET-WEIGHT-FAIL))
                (weight-y (- ONE_8 weight-x))   

                ;; fee = dy * fee-rate-y
                (fee (mul-up dy (get fee-rate-y pool)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))
                (dy-net-fees (if (<= dy fee) u0 (- dy fee)))
                (dx (try! (get-x-given-y token-y token-x expiry dy-net-fees)))        

                (pool-updated
                    (merge pool
                        {
                            balance-x: (if (<= balance-x dx) u0 (- balance-x dx)),
                            balance-y: (+ balance-y dy-net-fees fee-rebate),
                            weight-x: weight-x,
                            weight-y: weight-y                        
                        }
                    )
                )
                (sender tx-sender)
            )

            (asserts! (< (default-to u0 min-dx) dx) ERR-EXCEEDS-MAX-SLIPPAGE)

            (and (> dx u0) (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait dx sender))))
            (unwrap! (contract-call? token-trait transfer-fixed dy tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance token-y (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

;; @desc get-fee-rebate
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @returns (response uint uint)
(define-read-only (get-fee-rebate (token principal) (collateral principal) (expiry uint)) 
   (ok (get fee-rebate (try! (get-pool-details token collateral expiry))))  
)

;; @desc set-fee-rebate
;; @restricted contract-owner
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param fee-rebate; new fee-rebate
;; @returns (response bool uint)
(define-public (set-fee-rebate (token principal) (collateral principal) (expiry uint) (fee-rebate uint))
    (begin 
        (try! (check-is-owner))
        (map-set pools-data-map 
            { 
                token-x: collateral, token-y: token, expiry: expiry 
            }
            (merge (try! (get-pool-details token collateral expiry)) { fee-rebate: fee-rebate })
        )
        (ok true)     
    )
)

;; @desc get-fee-rate-x
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @returns (response uint uint)
(define-read-only (get-fee-rate-x (token principal) (collateral principal) (expiry uint)) 
   (ok (get fee-rate-x (try! (get-pool-details token collateral expiry))))  
)

;; @desc get-fee-rate-y
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @returns (response uint uint)
(define-read-only (get-fee-rate-y (token principal) (collateral principal) (expiry uint)) 
   (ok (get fee-rate-y (try! (get-pool-details token collateral expiry))))  
)

;; @desc set-fee-rate-x
;; @restricted fee-to-address
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param fee-rate-x; new fee-rate-x
;; @returns (response bool uint)
(define-public (set-fee-rate-x (token principal) (collateral principal) (expiry uint) (fee-rate-x uint))
    (let
        (
            (pool (try! (get-pool-details token collateral expiry)))
        )
        (asserts! (is-eq tx-sender (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        (map-set pools-data-map 
            { 
                token-x: collateral, token-y: token, expiry: expiry 
            }
            (merge pool { fee-rate-x: fee-rate-x })
        )
        (ok true)     
    )
)

;; @desc set-fee-rate-y
;; @restricted fee-to-address
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param fee-rate-y; new fee-rate-y
;; @returns (response bool uint)
(define-public (set-fee-rate-y (token principal) (collateral principal) (expiry uint) (fee-rate-y uint))
    (let
        (
            (pool (try! (get-pool-details token collateral expiry)))
        )
        (asserts! (is-eq tx-sender (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        (map-set pools-data-map 
            { 
                token-x: collateral, token-y: token, expiry: expiry
            }
            (merge (try! (get-pool-details token collateral expiry)) { fee-rate-y: fee-rate-y })
        )
        (ok true)     
    )
)

;; @desc get-fee-to-address (multisig of the pool)
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @returns (response principal uint)
(define-read-only (get-fee-to-address (token principal) (collateral principal) (expiry uint))
    (ok (get fee-to-address (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL)))
)

(define-public (set-fee-to-address (token principal) (collateral principal) (expiry uint) (fee-to-address principal))
    (begin
        (try! (check-is-owner))
        (map-set pools-data-map 
            { 
                token-x: collateral, token-y: token, expiry: expiry 
            }
            (merge (try! (get-pool-details token collateral expiry)) { fee-to-address: fee-to-address })
        )
        (ok true)     
    )
)

;; @desc units of token given units of collateral
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param dx; amount of collateral being added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (token principal) (collateral principal) (expiry uint) (dx uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (contract-call? .weighted-equation-v1-01 get-y-given-x (get balance-x pool) (get balance-y pool) (get weight-x pool) (get weight-y pool) dx)
    )
)

;; @desc units of collateral given units of token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param dy; amount of token being added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (token principal) (collateral principal) (expiry uint) (dy uint))
	(let
		(
			(pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
		)
		(contract-call? .weighted-equation-v1-01 get-x-given-y (get balance-x pool) (get balance-y pool) (get weight-x pool) (get weight-y pool) dy)
	)
)

;; @desc units of collateral required for a target price
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (token principal) (collateral principal) (expiry uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (contract-call? .weighted-equation-v1-01 get-x-given-price (get balance-x pool) (get balance-y pool) (get weight-x pool) (get weight-y pool) price)
    )
)

;; @desc units of token required for a target price
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (token principal) (collateral principal) (expiry uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (contract-call? .weighted-equation-v1-01 get-y-given-price (get balance-x pool) (get balance-y pool) (get weight-x pool) (get weight-y pool) price)
    )
)

(define-read-only (get-token-given-position (token principal) (collateral principal) (expiry uint) (dx uint))
    (get-token-given-position-with-spot token collateral expiry (try! (get-spot token collateral)) dx)
)

;; @desc units of yield-/key-token to be minted given amount of collateral being added (single sided liquidity)
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param dx; amount of collateral being added
;; @returns (response (tuple uint uint) uint)
(define-private (get-token-given-position-with-spot (token principal) (collateral principal) (expiry uint) (spot uint) (dx uint))
    (let 
        (
            (ltv-dy (mul-down (try! (get-ltv-with-spot token collateral expiry spot)) (try! (contract-call? .swap-helper get-helper collateral token dx))))
        )
        (asserts! (< block-height expiry) ERR-EXPIRY)
        (ok {yield-token: ltv-dy, key-token: ltv-dy})
    )
)

(define-read-only (get-position-given-mint (token principal) (collateral principal) (expiry uint) (shares uint))
    (get-position-given-mint-with-spot token collateral expiry (try! (get-spot token collateral)) shares)
)

;; @desc units of token/collateral required to mint given units of yield-/key-token
;; @desc returns dx (single liquidity) based on dx-weighted and dy-weighted
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param shares; units of yield-/key-token to be minted
;; @returns (response (tuple uint uint uint) uint)
(define-private (get-position-given-mint-with-spot (token principal) (collateral principal) (expiry uint) (spot uint) (shares uint))
    (begin
        (asserts! (< block-height expiry) ERR-EXPIRY) ;; mint supported until, but excl., expiry
        (let 
            (                
                (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-supply (get yield-supply pool)) ;; prior to maturity, yield-supply == key-supply, so we use yield-supply
                (weight-x (get weight-x pool))
                (weight-y (get weight-y pool))
            
                (ltv (try! (get-ltv-with-spot token collateral expiry spot)))

                (pos-data (unwrap! (contract-call? .weighted-equation-v1-01 get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares) ERR-WEIGHTED-EQUATION-CALL))

                (dx-weighted (get dx pos-data))
                (dy-weighted (get dy pos-data))

                ;; always convert to collateral ccy
                (dy-to-dx (try! (contract-call? .swap-helper get-helper collateral token dy-weighted)))   
                (dx (+ dx-weighted dy-to-dx))
            )
            (ok {dx: dx, dx-weighted: dx-weighted, dy-weighted: dy-weighted})
        )
    )
)

(define-read-only (get-position-given-burn-key (token principal) (collateral principal) (expiry uint) (shares uint))
    (get-position-given-burn-key-with-spot token collateral expiry (try! (get-spot token collateral)) shares)
)

;; @desc units of token/collateral to be returned after burning given units of yield-/key-token
;; @param token; borrow token
;; @param collateral; collateral token
;; @param expiry; borrow expiry
;; @param shares; units of yield-/key-token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-private (get-position-given-burn-key-with-spot (token principal) (collateral principal) (expiry uint) (spot uint) (shares uint))
    (begin         
        (let 
            (
                (pool (unwrap! (map-get? pools-data-map { token-x: collateral, token-y: token, expiry: expiry }) ERR-INVALID-POOL))
                (pool-value-in-y (try! (get-pool-value-in-token-with-spot token collateral expiry spot)))
                (key-value-in-y (if (<= pool-value-in-y (get yield-supply pool)) u0 (- pool-value-in-y (get yield-supply pool))))
                (shares-to-pool (mul-down (div-down key-value-in-y pool-value-in-y) (div-down shares (get key-supply pool))))
            )
            (ok {dx: (mul-down shares-to-pool (get balance-x pool)), dy: (mul-down shares-to-pool (get balance-y pool))})
        )
    )
)

(define-private (div-down (a uint) (b uint))
  (contract-call? .math-fixed-point div-down a b)
)

(define-private (div-up (a uint) (b uint))
  (contract-call? .math-fixed-point div-up a b)
)

(define-private (mul-down (a uint) (b uint))
  (contract-call? .math-fixed-point mul-down a b)
)

(define-private (mul-up (a uint) (b uint))
  (contract-call? .math-fixed-point mul-up a b)
)

(define-private (pow-down (a uint) (b uint))
  (contract-call? .math-fixed-point pow-down a b)
)

(define-private (pow-up (a uint) (b uint))
  (contract-call? .math-fixed-point pow-up a b)
)