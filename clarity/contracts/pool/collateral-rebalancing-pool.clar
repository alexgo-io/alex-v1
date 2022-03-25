(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)

;; collateral-rebalancing-pool
;;

;; constants
;;

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
(define-constant ERR-ROLL-FLASH-LOAN-FEE (err u2028))

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

(define-private (check-is-self)
  (ok (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR-NOT-AUTHORIZED))
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
    (ok (try! (oracle-resilient-helper collateral token)))
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
    (create-pool-with-spot token-trait collateral-trait expiry yield-token-trait key-token-trait multisig-vote ltv-0 conversion-ltv bs-vol moving-average token-to-maturity (try! (get-spot (contract-of token-trait) (contract-of collateral-trait))) dx)
)

(define-private (create-pool-with-spot (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (multisig-vote principal) (ltv-0 uint) (conversion-ltv uint) (bs-vol uint) (moving-average uint) (token-to-maturity uint) (spot uint) (dx uint)) 
    (begin
        (asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-self))) ERR-NOT-AUTHORIZED)
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
                    strike: (mul-down spot ltv-0),
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

            ;; (try! (contract-call? .alex-vault add-approved-token token-x))
            ;; (try! (contract-call? .alex-vault add-approved-token token-y))
            ;; (try! (contract-call? .alex-vault add-approved-token (contract-of yield-token-trait)))
            ;; (try! (contract-call? .alex-vault add-approved-token (contract-of key-token-trait)))

            (print { object: "pool", action: "created", data: pool-data })
            (add-to-position-with-spot token-trait collateral-trait expiry yield-token-trait key-token-trait spot dx)
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
(define-public (add-to-position-and-switch (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (dx uint) (min-dy (optional uint)))
    (contract-call? 
        .yield-token-pool swap-y-for-x expiry yield-token-trait token-trait (get yield-token (try! (add-to-position token-trait collateral-trait expiry yield-token-trait key-token-trait dx))) min-dy
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

                (dy-weighted (try! (swap-helper collateral-trait token-trait dx-to-dy none)))

                (pool-updated (merge pool {
                    yield-supply: (+ yield-new-supply yield-supply),                    
                    key-supply: (+ key-new-supply key-supply),
                    balance-x: (+ balance-x dx-weighted),
                    balance-y: (+ balance-y dy-weighted)
                }))
                (sender tx-sender)
            ) 

            (unwrap! (get-helper token-x token-y (+ dx balance-x (div-down balance-y spot))) ERR-POOL-AT-CAPACITY)

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
                        (try! (get-helper token-y token-x bal-y-short))
                    )
                )
                (bal-y-short-act 
                    (if (is-eq bal-x-to-sell u0)
                        u0
                        (begin
                            (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait bal-x-to-sell tx-sender)))
                            (as-contract (try! (swap-helper collateral-trait token-trait bal-x-to-sell none)))
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
                        (try! (get-helper token-y token-x bal-y-short))
                    )
                )
                (bal-y-short-act 
                    (if (is-eq bal-x-to-sell u0)
                        u0
                        (begin
                            (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait bal-x-to-sell tx-sender)))
                            (as-contract (try! (swap-helper collateral-trait token-trait bal-x-to-sell none)))
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
            (ltv-dy (mul-down (try! (get-ltv-with-spot token collateral expiry spot)) (try! (get-helper collateral token dx))))
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
                (dy-to-dx (try! (get-helper collateral token dy-weighted)))   
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



;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

;; TODO: this needs to be reviewed/updated
;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 

;; public functions
;;

;; @desc scale-up
;; @params a 
;; @returns uint
(define-read-only (scale-up (a uint))
    (* a ONE_8)
)

;; @desc scale-down
;; @params a 
;; @returns uint
(define-read-only (scale-down (a uint))
    (/ a ONE_8)
)

;; @desc mul-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc mul-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)

;; @desc div-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_8) b)
   )
)

;; @desc div-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-up (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (+ u1 (/ (- (* a ONE_8) u1) b))
    )
)

;; @desc pow-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (if (< raw max-error)
            u0
            (- raw max-error)
        )
    )
)

;; @desc pow-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (+ raw max-error)
    )
)

;; math-log-exp
;; Exponentiation and logarithm functions for 8 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 8 decimal fixed point numbers.
(define-constant UNSIGNED_ONE_8 (pow 10 8))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^8, 
;; which makes the largest exponent ln((2^127 - 1) / 10^8) = 69.6090111872.
;; The smallest possible result is 10^(-8), which makes largest negative argument ln(10^(-8)) = -18.420680744.
;; We use 69.0 and -18.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 69 UNSIGNED_ONE_8))
(define-constant MIN_NATURAL_EXPONENT (* -18 UNSIGNED_ONE_8))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint UNSIGNED_ONE_8)))

;; Because largest exponent is 69, we start from 64
;; The first several a_n are too large if stored as 8 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.

(define-constant x_a_list_no_deci (list 
{x_pre: 6400000000, a_pre: 62351490808116168829, use_deci: false} ;; x1 = 2^6, a1 = e^(x1)
))

;; 8 decimal constants
(define-constant x_a_list (list 
{x_pre: 3200000000, a_pre: 78962960182680695161, use_deci: true} ;; x2 = 2^5, a2 = e^(x2)
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


(define-constant ERR-X-OUT-OF-BOUNDS (err u5009))
(define-constant ERR-Y-OUT-OF-BOUNDS (err u5010))
(define-constant ERR-PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant ERR-INVALID-EXPONENT (err u5012))
(define-constant ERR-OUT-OF-BOUNDS (err u5013))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 8 decimal fixed point argument.

;; @desc ln-priv
;; @params a
;; @ returns (response uint)
(define-private (ln-priv (a int))
  (let
    (
      (a_sum_no_deci (fold accumulate_division x_a_list_no_deci {a: a, sum: 0}))
      (a_sum (fold accumulate_division x_a_list {a: (get a a_sum_no_deci), sum: (get sum a_sum_no_deci)}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a UNSIGNED_ONE_8) UNSIGNED_ONE_8) (+ out_a UNSIGNED_ONE_8)))
      (z_squared (/ (* z z) UNSIGNED_ONE_8))
      (div_list (list 3 5 7 9 11))
      (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
      (seriesSum (get seriesSum num_sum_zsq))
    )
    (+ out_sum (* seriesSum 2))
  )
)

;; @desc accumulate_division
;; @params x_a_pre ; tuple(x_pre a_pre use_deci)
;; @params rolling_a_sum ; tuple (a sum)
;; @returns uint
(define-private (accumulate_division (x_a_pre (tuple (x_pre int) (a_pre int) (use_deci bool))) (rolling_a_sum (tuple (a int) (sum int))))
  (let
    (
      (a_pre (get a_pre x_a_pre))
      (x_pre (get x_pre x_a_pre))
      (use_deci (get use_deci x_a_pre))
      (rolling_a (get a rolling_a_sum))
      (rolling_sum (get sum rolling_a_sum))
   )
    (if (>= rolling_a (if use_deci a_pre (* a_pre UNSIGNED_ONE_8)))
      {a: (/ (* rolling_a (if use_deci UNSIGNED_ONE_8 1)) a_pre), sum: (+ rolling_sum x_pre)}
      {a: rolling_a, sum: rolling_sum}
   )
 )
)

;; @desc rolling_sum_div
;; @params n
;; @params rolling ; tuple (num seriesSum z_squared)
;; @Sreturns tuple
(define-private (rolling_sum_div (n int) (rolling (tuple (num int) (seriesSum int) (z_squared int))))
  (let
    (
      (rolling_num (get num rolling))
      (rolling_sum (get seriesSum rolling))
      (z_squared (get z_squared rolling))
      (next_num (/ (* rolling_num z_squared) UNSIGNED_ONE_8))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.

;; @desc pow-priv
;; @params x
;; @params y
;; @returns (response uint)
(define-read-only (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (ln-priv x-int))
      (logx-times-y (/ (* lnx y-int) UNSIGNED_ONE_8))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) ERR-PRODUCT-OUT-OF-BOUNDS)
    (ok (to-uint (try! (exp-fixed logx-times-y))))
  )
)

;; @desc exp-pos
;; @params x
;; @returns (response uint)
(define-read-only (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (let
      (
        ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
        (x_product_no_deci (fold accumulate_product x_a_list_no_deci {x: x, product: 1}))
        (x_adj (get x x_product_no_deci))
        (firstAN (get product x_product_no_deci))
        (x_product (fold accumulate_product x_a_list {x: x_adj, product: UNSIGNED_ONE_8}))
        (product_out (get product x_product))
        (x_out (get x x_product))
        (seriesSum (+ UNSIGNED_ONE_8 x_out))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
        (sum (get seriesSum term_sum_x))
     )
      (ok (* (/ (* product_out sum) UNSIGNED_ONE_8) firstAN))
   )
 )
)

;; @desc accumulate_product
;; @params x_a_pre ; tuple (x_pre a_pre use_deci)
;; @params rolling_x_p ; tuple (x product)
;; @returns tuple
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
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) (if use_deci UNSIGNED_ONE_8 1))}
      {x: rolling_x, product: rolling_product}
   )
 )
)

;; @desc rolling_div_sum
;; @params n
;; @params rolling ; tuple (term seriesSum x)
;; @returns tuple
(define-private (rolling_div_sum (n int) (rolling (tuple (term int) (seriesSum int) (x int))))
  (let
    (
      (rolling_term (get term rolling))
      (rolling_sum (get seriesSum rolling))
      (x (get x rolling))
      (next_term (/ (/ (* rolling_term x) UNSIGNED_ONE_8) n))
      (next_sum (+ rolling_sum next_term))
   )
    {term: next_term, seriesSum: next_sum, x: x}
 )
)

;; public functions
;;

;; Exponentiation (x^y) with unsigned 8 decimal fixed point base and exponent.
;; @desc pow-fixed
;; @params x
;; @params y
;; @returns (response uint)
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) ERR-X-OUT-OF-BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD_EXPONENT_BOUND) ERR-Y-OUT-OF-BOUNDS)

    (if (is-eq y u0) 
      (ok (to-uint UNSIGNED_ONE_8))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 8 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.

;; @desc exp-fixed
;; @params x
;; @returns (response uint)
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by UNSIGNED_ONE_8.
      (ok (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) (try! (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 8 decimal fixed point base and argument.
;; @desc log-fixed
;; @params arg
;; @params base
;; @returns (response uint)
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (ln-priv base) UNSIGNED_ONE_8))
      (logArg (* (ln-priv arg) UNSIGNED_ONE_8))
   )
    (ok (/ (* logArg UNSIGNED_ONE_8) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 8 decimal fixed point argument.

;; @desc ln-fixed
;; @params a
;; @returns (response uint)
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) ERR-OUT-OF-BOUNDS)
    (if (< a UNSIGNED_ONE_8)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by UNSIGNED_ONE_8.
      (ok (- 0 (ln-priv (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) a))))
      (ok (ln-priv a))
   )
 )
)

(define-private (is-fixed-weight-pool-v1-01 (token-x principal) (token-y principal))
    (if 
        (or  
            (and
                (is-eq token-x .token-wstx)
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
            )
            (and
                (is-eq token-y .token-wstx)
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
            )
        )
        u1
        (if 
            (and
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
            )
            u2
            u0
        )    
    )
)

(define-private (is-simple-weight-pool-alex (token-x principal) (token-y principal))
    (if 
        (or
            (and
                (is-eq token-x .age000-governance-token)
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
            )
            (and 
                (is-eq token-y .age000-governance-token)
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
            )
        )
        u1
        (if 
            (and 
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
            )
            u2
            u0
        )
    )
)

(define-private (is-from-fixed-to-simple-alex (token-x principal) (token-y principal))
    (if
        (and
            (is-eq token-x .token-wstx) 
            (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
        )
        u2
        (if
            (and
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-x u50000000 u50000000))
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-y))
            )
            u3
            u0
        )
    )
)

(define-private (is-from-simple-alex-to-fixed (token-x principal) (token-y principal))
    (if
        (or
            (and
                (is-eq token-x .age000-governance-token) 
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
            )
            (and 
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
                (is-eq token-y .token-wstx)
            )
        )
        u2
        (if
            (and
                (is-some (contract-call? .fixed-weight-pool-v1-01 get-pool-exists .token-wstx token-y u50000000 u50000000))
                (is-some (contract-call? .simple-weight-pool-alex get-pool-exists .age000-governance-token token-x))
            )
            u3
            u0
        )
    )
)

;; @desc swap-helper swaps dx of token-x-trait for at least min-dy of token-y-trait (else, it fails)
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
        )        
        (ok 
            (if (> (is-fixed-weight-pool-v1-01 token-x token-y) u0)
                (if (is-eq token-x .token-wstx)
                    (get dy (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y token-y-trait u50000000 dx min-dy)))
                    (if (is-eq token-y .token-wstx)
                        (get dx (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx token-x-trait u50000000 dx min-dy)))
                        (get dy (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y token-y-trait u50000000 
                            (get dx (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx token-x-trait u50000000 dx none))) min-dy)))
                    )
                )
                (if (> (is-simple-weight-pool-alex token-x token-y) u0)
                    (get dy (try! (contract-call? .simple-weight-pool-alex swap-x-for-y token-x-trait token-y-trait dx min-dy)))
                    (if (> (is-from-fixed-to-simple-alex token-x token-y) u0)
                        (if (is-eq token-x .token-wstx)
                            (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                                (get dy (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y .age000-governance-token u50000000 dx none))) min-dy))) 
                            (get dy (try! (contract-call? .simple-weight-pool-alex swap-alex-for-y token-y-trait 
                                (get dy (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y .age000-governance-token u50000000 
                                    (get dx (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx token-x-trait u50000000 dx none))) none))) min-dy)))
                        )
                        (if (is-eq token-y .token-wstx)
                            (get dx (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx .age000-governance-token u50000000 
                                (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) min-dy)))                        
                            (get dy (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y token-y-trait u50000000 
                                (get dx (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx .age000-governance-token u50000000 
                                    (get dx (try! (contract-call? .simple-weight-pool-alex swap-y-for-alex token-x-trait dx none))) none))) min-dy)))
                        )
                    )
                )
            )
        )
    )
)

;; @desc get-helper returns estimated dy when swapping token-x for token-y
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-read-only (get-helper (token-x principal) (token-y principal) (dx uint))
    (ok
        (if (> (is-fixed-weight-pool-v1-01 token-x token-y) u0)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-helper token-x token-y u50000000 u50000000 dx))
            (if (> (is-simple-weight-pool-alex token-x token-y) u0)
                (try! (contract-call? .simple-weight-pool-alex get-helper token-x token-y dx))
                (if (> (is-from-fixed-to-simple-alex token-x token-y) u0)
                    (try! (contract-call? .simple-weight-pool-alex get-y-given-alex token-y 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-helper token-x .age000-governance-token u50000000 u50000000 dx)))) 
                    (try! (contract-call? .fixed-weight-pool-v1-01 get-helper .age000-governance-token token-y u50000000 u50000000 
                        (try! (contract-call? .simple-weight-pool-alex get-alex-given-y token-x dx))))
                )
            )
        )
    )
)

;; @desc oracle-instant-helper returns price of token-x in token-y
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-read-only (oracle-instant-helper (token-x principal) (token-y principal))
    (ok
        (if (> (is-fixed-weight-pool-v1-01 token-x token-y) u0)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant token-x token-y u50000000 u50000000))
            (if (> (is-simple-weight-pool-alex token-x token-y) u0)
                (try! (contract-call? .simple-weight-pool-alex get-oracle-instant token-x token-y))
                (if (> (is-from-fixed-to-simple-alex token-x token-y) u0)
                    (div-down 
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-instant .age000-governance-token token-y))
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant .age000-governance-token token-x u50000000 u50000000))
                    )
                    (div-down 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-instant .age000-governance-token token-y u50000000 u50000000))
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-instant .age000-governance-token token-x))                        
                    )                                        
                )
            )
        )
    )
)

;; @desc oracle-resilient-helper returns moving average price of token-x in token-y
;; @param token-x
;; @param token-y
;; @returns (response uint uint)
(define-read-only (oracle-resilient-helper (token-x principal) (token-y principal))
    (ok
        (if (> (is-fixed-weight-pool-v1-01 token-x token-y) u0)
            (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient token-x token-y u50000000 u50000000))
            (if (> (is-simple-weight-pool-alex token-x token-y) u0)
                (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient token-x token-y))
                (if (> (is-from-fixed-to-simple-alex token-x token-y) u0)
                    (div-down 
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient .age000-governance-token token-y))
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient .age000-governance-token token-x u50000000 u50000000))
                    )
                    (div-down 
                        (try! (contract-call? .fixed-weight-pool-v1-01 get-oracle-resilient .age000-governance-token token-y u50000000 u50000000))
                        (try! (contract-call? .simple-weight-pool-alex get-oracle-resilient .age000-governance-token token-x))                        
                    )                                        
                )
            )
        )
    )
)


(define-public (create-margin-position (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (dx uint))
    (let
        (
            (sender tx-sender)
            (spot (try! (get-spot (contract-of token-trait) (contract-of collateral-trait))))
            (dx-with-fee (mul-up dx (+ ONE_8 (unwrap-panic (contract-call? .alex-vault get-flash-loan-fee-rate)))))
            (loaned (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait dx sender))))
            (gross-dx
                (div-down  
                    (mul-up 
                        dx 
                        (try! (contract-call? .yield-token-pool get-price expiry (contract-of yield-token-trait))) 
                    )
                    (try! (get-ltv-with-spot (contract-of token-trait) (contract-of collateral-trait) expiry spot))
                )
            )
            (minted-yield-token (get yield-token (try! (add-to-position-with-spot token-trait collateral-trait expiry yield-token-trait key-token-trait spot gross-dx))))
            (swapped-token (get dx (try! (contract-call? .yield-token-pool swap-y-for-x expiry yield-token-trait token-trait minted-yield-token none))))
        )
        (try! (swap-helper token-trait collateral-trait swapped-token none))
        ;; return the loan + fee
        (try! (contract-call? collateral-trait transfer-fixed dx-with-fee sender .alex-vault none))
        (ok dx-with-fee)
    )
)

(define-public (roll-margin-position (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (expiry-to-roll uint))
    (let
        (
            (sender tx-sender)
            (spot (try! (get-spot (contract-of token-trait) (contract-of collateral-trait))))
            (reduce-data (try! (reduce-position-key token-trait collateral-trait expiry key-token-trait ONE_8)))
            (dx 
                (+ 
                    (get dx reduce-data) 
                    (if (is-eq (get dy reduce-data) u0) u0 (try! (swap-helper token-trait collateral-trait (get dy reduce-data) none)))
                )               
            )
            (dx-with-fee (mul-up dx (+ ONE_8 (unwrap-panic (contract-call? .alex-vault get-flash-loan-fee-rate)))))
            (loaned (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait dx sender))))
            (gross-dx
                (div-down  
                    (mul-up 
                        dx 
                        (try! (contract-call? .yield-token-pool get-price expiry-to-roll (contract-of yield-token-trait))) 
                    )
                    (try! (get-ltv-with-spot (contract-of token-trait) (contract-of collateral-trait) expiry-to-roll spot))
                )
            )
            (minted-yield-token (get yield-token (try! (add-to-position-with-spot token-trait collateral-trait expiry-to-roll yield-token-trait key-token-trait spot gross-dx))))
            (swapped-token (get dx (try! (contract-call? .yield-token-pool swap-y-for-x expiry-to-roll yield-token-trait token-trait minted-yield-token none))))
        )
        (try! (swap-helper token-trait collateral-trait swapped-token none))
        ;; return the loan + fee
        (try! (contract-call? collateral-trait transfer-fixed dx-with-fee sender .alex-vault none))
        (ok dx-with-fee)
    )    
)

;; test
(define-public (test-depth (token-trait <ft-trait>) (collateral-trait <ft-trait>) (expiry uint) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (expiry-to-roll uint))
    (roll-margin-position token-trait collateral-trait expiry yield-token-trait key-token-trait expiry-to-roll)
)

(define-map approved-pair principal principal) ;; auto-token => pool token
(define-map auto-total-supply principal uint) ;; auto-token => supply
(define-map pool-total-supply principal uint) ;; pool token => supply
(define-map pool-underlying principal principal) ;; pool token => token with staking schedule
(define-map pool-expiry principal uint) ;; pool token => expiry
(define-map bounty-in-fixed principal uint) ;; bounty as % of amount
(define-map bounty-max-in-fixed principal uint) ;; bounty cap

(define-read-only (get-approved-pair (auto-token principal))
    (map-get? approved-pair auto-token)
)
(define-public (set-approved-pair (auto-token principal) (pool-token principal))
    (begin 
        (try! (check-is-owner))
        (ok (map-set approved-pair auto-token pool-token))
    )
)

(define-read-only (get-pool-underlying (pool-token principal))
    (map-get? pool-underlying pool-token)
)
(define-public (set-pool-underlying (pool-token principal) (token principal))
    (begin 
        (try! (check-is-owner))
        (map-set pool-expiry pool-token (try! (get-expiry-with-underlying pool-token token)))        
        (ok (map-set pool-underlying pool-token token))
    )
)

(define-read-only (get-auto-total-supply (auto-token principal))
    (map-get? auto-total-supply auto-token)
)
(define-read-only (get-pool-total-supply (pool-token principal))
    (map-get? pool-total-supply pool-token)
)

(define-read-only (get-expiry (pool-token principal))
    (get-expiry-with-underlying pool-token (unwrap! (map-get? pool-underlying pool-token) ERR-NOT-AUTHORIZED))
)

(define-private (get-expiry-with-underlying (pool-token principal) (token principal))
    (let
        (
            (current-cycle (unwrap! (contract-call? .alex-reserve-pool get-reward-cycle token block-height) ERR-NOT-AUTHORIZED))
        )        
        (ok (- (contract-call? .alex-reserve-pool get-first-stacks-block-in-reward-cycle token (+ current-cycle u1)) u1))
    )
)

(define-private (set-expiry (pool-token principal))
    (let 
        (
            (last-height (try! (get-expiry pool-token)))
        )
        (map-set pool-expiry pool-token last-height)        
        (ok last-height)
    )
)

(define-read-only (get-auto-supply-or-default (pool-token principal))
    (default-to u0 (map-get? auto-total-supply pool-token))
)
(define-read-only (get-pool-supply-or-default (pool-token principal))
    (default-to u0 (map-get? pool-total-supply pool-token))
)

(define-public (mint-auto (pool-token-trait <sft-trait>) (auto-token-trait <ft-trait>) (dx uint))
    (let
        (
            (pool-token (contract-of pool-token-trait))
            (auto-token (contract-of auto-token-trait))
            (auto-to-add 
                (match (map-get? pool-total-supply pool-token) 
                    value (div-down (mul-down dx (get-auto-supply-or-default pool-token)) value) ;; dx * auto-total-supply / pool-total-supply
                    dx
                )
            )
            (pool-to-add (+ dx (get-pool-supply-or-default pool-token)))
            (expiry (unwrap! (map-get? pool-expiry pool-token) ERR-NOT-AUTHORIZED))
            (sender tx-sender)
        )
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (asserts! (is-eq (unwrap! (map-get? approved-pair auto-token) ERR-NOT-AUTHORIZED) pool-token) ERR-NOT-AUTHORIZED)
        
        (try! (contract-call? pool-token-trait transfer-fixed expiry dx sender .alex-vault))
        (map-set auto-total-supply pool-token (+ (get-auto-supply-or-default pool-token) auto-to-add))
        (map-set pool-total-supply pool-token (+ (get-pool-supply-or-default pool-token) dx))
        (as-contract (try! (contract-call? auto-token-trait mint-fixed auto-to-add sender)))
        (print { object: "pool", action: "pool-added", data: auto-to-add })
        (ok true)
    )
)

(define-public (redeem-auto (pool-token-trait <sft-trait>) (auto-token-trait <ft-trait>) (percent uint))
    (let 
        (
            (pool-token (contract-of pool-token-trait))
            (auto-token (contract-of auto-token-trait))
            (total-shares (unwrap! (contract-call? auto-token-trait get-balance-fixed tx-sender) ERR-GET-BALANCE-FIXED-FAIL))
            (auto-to-reduce (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
            (pool-to-reduce (div-down (mul-down (get-pool-supply-or-default pool-token) auto-to-reduce) (get-auto-supply-or-default pool-token)))
            (expiry (unwrap! (map-get? pool-expiry pool-token) ERR-NOT-AUTHORIZED))
            (sender tx-sender)
        )
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        (asserts! (is-eq (unwrap! (map-get? approved-pair auto-token) ERR-NOT-AUTHORIZED) pool-token) ERR-NOT-AUTHORIZED)

        (as-contract (try! (contract-call? .alex-vault transfer-sft pool-token-trait expiry pool-to-reduce sender)))
        (map-set auto-total-supply pool-token (- (get-auto-supply-or-default pool-token) auto-to-reduce))
        (map-set pool-total-supply pool-token (- (get-pool-supply-or-default pool-token) pool-to-reduce))
        (as-contract (try! (contract-call? auto-token-trait burn-fixed auto-to-reduce sender)))
        (print { object: "pool", action: "pool-removed", data: auto-to-reduce })
        (ok true)
    )     
)

;; roll-auto-pool
(define-public (roll-auto-pool (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (collateral-trait <ft-trait>) (pool-token-trait <sft-trait>) (auto-token-trait <ft-trait>))
    (let 
        (
            (token (contract-of token-trait))
            (collateral (contract-of collateral-trait))
            (yield-token (contract-of yield-token-trait))
            (pool-token (contract-of pool-token-trait))
            (auto-token (contract-of auto-token-trait))
            (expiry (unwrap! (map-get? pool-expiry pool-token) ERR-NOT-AUTHORIZED))
            (expiry-to-roll (try! (set-expiry pool-token)))
        )
        (asserts! (is-eq (unwrap! (map-get? approved-pair auto-token) ERR-NOT-AUTHORIZED) pool-token) ERR-NOT-AUTHORIZED)
        (asserts! (> expiry-to-roll expiry) ERR-EXPIRY)

        (as-contract (try! (contract-call? .alex-vault transfer-sft pool-token-trait expiry (get-pool-supply-or-default pool-token) tx-sender)))

        (let
            (
                (reduce-data (as-contract (try! (contract-call? .yield-token-pool reduce-position expiry yield-token-trait token-trait pool-token-trait ONE_8))))
                (dy-to-dx (get dy (as-contract (try! (reduce-position-yield token-trait collateral-trait expiry yield-token-trait ONE_8)))))
                (pool (try! (contract-call? .yield-token-pool get-pool-details expiry yield-token)))
                (new-pool-supply 
                    (if (is-err (contract-call? .yield-token-pool get-pool-details expiry-to-roll yield-token))
                        (get supply (as-contract (try! (contract-call? .yield-token-pool create-pool expiry-to-roll yield-token-trait token-trait pool-token-trait (get fee-to-address pool) (+ (get dx reduce-data) dy-to-dx) u0))))
                        (get supply (as-contract (try! (contract-call? .yield-token-pool buy-and-add-to-position expiry-to-roll yield-token-trait token-trait pool-token-trait (+ (get dx reduce-data) dy-to-dx) none))))
                    )                
                )
            )

            (as-contract (try! (contract-call? pool-token-trait transfer-fixed expiry-to-roll new-pool-supply tx-sender .alex-vault)))
            (map-set pool-total-supply pool-token new-pool-supply)

            ;; TODO: pay bounty

            (ok true)
        )
    )    
)

;; roll-auto-key
(define-public (roll-auto-key (token-trait <ft-trait>) (collateral-trait <ft-trait>) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (auto-token-trait <ft-trait>))
    (let 
        (
            (token (contract-of token-trait))
            (collateral (contract-of collateral-trait))
            (yield-token (contract-of yield-token-trait))
            (key-token (contract-of key-token-trait))
            (auto-token (contract-of auto-token-trait))
            (expiry (unwrap! (map-get? pool-expiry key-token) ERR-NOT-AUTHORIZED))
            (expiry-to-roll (try! (set-expiry key-token)))
        )
        (asserts! (is-eq (unwrap! (map-get? approved-pair auto-token) ERR-NOT-AUTHORIZED) key-token) ERR-NOT-AUTHORIZED)
        (asserts! (> expiry-to-roll expiry) ERR-EXPIRY)
        (asserts! (is-ok (contract-call? .yield-token-pool get-pool-details expiry-to-roll yield-token)) ERR-NOT-AUTHORIZED)
        (as-contract (try! (contract-call? .alex-vault transfer-sft key-token-trait expiry (get-pool-supply-or-default key-token) tx-sender)))

        (let
            (
                (sender tx-sender)
                (pool (try! (get-pool-details token collateral expiry)))
                (spot (try! (get-spot token collateral)))
                (reduce-data (as-contract (try! (reduce-position-key token-trait collateral-trait expiry key-token-trait ONE_8))))
                (dx 
                    (+ 
                        (get dx reduce-data) 
                        (if (is-eq (get dy reduce-data) u0) u0 (as-contract (try! (swap-helper token-trait collateral-trait (get dy reduce-data) none))))
                    )               
                )
                (ltv 
                    (if (is-err (get-pool-details token collateral expiry-to-roll)) 
                        (get ltv-0 pool) 
                        (try! (get-ltv-with-spot token collateral expiry-to-roll spot))
                    )
                )
                (gross-dx (div-down dx ltv))                                
                (yield-amount (mul-down (try! (get-helper collateral token gross-dx)) ltv))
                (swapped-amount (try! (contract-call? .yield-token-pool get-x-given-y expiry-to-roll yield-token yield-amount)))
                (out-amount (try! (get-helper token collateral swapped-amount)))
                (dx-act (- dx (- (- gross-dx dx) out-amount)))
                (gross-dx-act (div-down dx-act ltv))
                (loan-amount (- gross-dx-act dx-act))
                (loaned (as-contract (try! (contract-call? .alex-vault transfer-ft collateral-trait loan-amount tx-sender))))                
                (minted
                    (if (is-err (get-pool-details token collateral expiry-to-roll))
                        (as-contract (try! (create-pool-with-spot token-trait collateral-trait expiry-to-roll yield-token-trait key-token-trait (get fee-to-address pool) (get ltv-0 pool) (get conversion-ltv pool) (get bs-vol pool) (get moving-average pool) (get token-to-maturity pool) spot gross-dx-act)))
                        (as-contract (try! (add-to-position-with-spot token-trait collateral-trait expiry-to-roll yield-token-trait key-token-trait spot gross-dx-act)))
                    )
                )                 
                (swapped-token 
                    (as-contract 
                        (try! (swap-helper token-trait collateral-trait
                            (get dx (try! (contract-call? .yield-token-pool swap-y-for-x expiry-to-roll yield-token-trait token-trait (get yield-token minted) none))) none)
                        )
                    )
                )
                (swapped-token-with-fee (+ swapped-token (- dx dx-act)))
            )

            ;; return the loan + fee
            (as-contract (try! (contract-call? collateral-trait transfer-fixed swapped-token-with-fee tx-sender .alex-vault none)))

            (as-contract (try! (contract-call? key-token-trait transfer-fixed expiry-to-roll (get key-token minted) tx-sender .alex-vault)))
            (map-set pool-total-supply key-token (get key-token minted))            

            ;; TODO: pay bounty

            (ok (- swapped-token-with-fee loan-amount))
        )
    )    
)

;; roll-auto-yield
(define-public (roll-auto-yield (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (collateral-trait <ft-trait>) (auto-token-trait <ft-trait>))
    (let 
        (
            (token (contract-of token-trait))
            (collateral (contract-of collateral-trait))
            (yield-token (contract-of yield-token-trait))
            (auto-token (contract-of auto-token-trait))
            (expiry (unwrap! (map-get? pool-expiry yield-token) ERR-NOT-AUTHORIZED))
            (expiry-to-roll (try! (set-expiry yield-token)))
        )
        (asserts! (is-eq (unwrap! (map-get? approved-pair auto-token) ERR-NOT-AUTHORIZED) yield-token) ERR-NOT-AUTHORIZED)
        (asserts! (> expiry-to-roll expiry) ERR-EXPIRY)
        (asserts! (is-ok (contract-call? .yield-token-pool get-pool-details expiry-to-roll yield-token)) ERR-NOT-AUTHORIZED)
        (asserts! (is-ok (get-pool-details token collateral expiry-to-roll)) ERR-NOT-AUTHORIZED)

        (as-contract (try! (contract-call? .alex-vault transfer-sft yield-token-trait expiry (get-pool-supply-or-default yield-token) tx-sender)))

        (let
            (
                (dx (get dy (as-contract (try! (reduce-position-yield token-trait collateral-trait expiry yield-token-trait ONE_8)))))
                (new-supply (get dy (as-contract (try! (contract-call? .yield-token-pool swap-x-for-y expiry-to-roll yield-token-trait token-trait dx none)))))
            )            

            (as-contract (try! (contract-call? yield-token-trait transfer-fixed expiry-to-roll new-supply tx-sender .alex-vault)))
            (map-set pool-total-supply yield-token new-supply)

            ;; TODO: pay bounty

            (ok true)
        )
    )    
)