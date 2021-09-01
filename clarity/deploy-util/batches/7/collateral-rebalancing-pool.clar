(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)

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
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))
(define-constant get-weight-fail-err (err u2012))
(define-constant get-expiry-fail-err (err u2013))
(define-constant get-price-fail-err (err u2015))
(define-constant get-symbol-fail-err (err u6000))
(define-constant get-oracle-price-fail-err (err u7000))
(define-constant expiry-err (err u2017))
(define-constant get-balance-fail-err (err u6001))

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
    yield-bal-x: uint,
    yield-bal-y: uint,
    key-bal-x: uint,
    key-bal-y: uint,
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
    weight-y: uint  
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;

(define-private (min (x uint) (y uint))
    (if (< x y)
        (ok x)
        (ok y)
    )
)

(define-private (max (x uint) (y uint))
    (if (< x y)
        (ok y)
        (ok x)
    )
)

;; Approximation of Error Function using Abramowitz and Stegun
;; https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
;; Please note erf(x) equals -erf(-x)
(define-private (erf (x uint))
    (let
        (
            (a1x (unwrap! (contract-call? .math-fixed-point mul-down a1 x) math-call-err))
            (x2 (unwrap! (contract-call? .math-fixed-point pow-down x u200000000) math-call-err))
            (a2x (unwrap! (contract-call? .math-fixed-point mul-down a2 x2) math-call-err))
            (x3 (unwrap! (contract-call? .math-fixed-point pow-down x u300000000) math-call-err))
            (a3x (unwrap! (contract-call? .math-fixed-point mul-down a3 x3) math-call-err))
            (x4 (unwrap! (contract-call? .math-fixed-point pow-down x u400000000) math-call-err))
            (a4x (unwrap! (contract-call? .math-fixed-point mul-down a4 x4) math-call-err))
            (denom (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 a1x) math-call-err))
            (denom1 (unwrap! (contract-call? .math-fixed-point add-fixed denom a2x) math-call-err))
            (denom2 (unwrap! (contract-call? .math-fixed-point add-fixed denom1 a3x) math-call-err))
            (denom3 (unwrap! (contract-call? .math-fixed-point add-fixed denom2 a4x) math-call-err))
            (denom4 (unwrap! (contract-call? .math-fixed-point pow-down denom3 u400000000) math-call-err))
            (base (unwrap! (contract-call? .math-fixed-point div-down ONE_8 denom4) math-call-err))
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

(define-public (get-spot (token <ft-trait>) (collateral <ft-trait>))
    (let 
        (
            (token-symbol (unwrap-panic (contract-call? token get-symbol)))
            (collateral-symbol (unwrap-panic (contract-call? collateral get-symbol)))
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (collateral-price (unwrap! (contract-call? .open-oracle get-price oracle-src collateral-symbol) get-oracle-price-fail-err))            
            
            (spot (unwrap-panic (contract-call? .math-fixed-point div-down token-price collateral-price)))            
        )
        (ok spot)
    )
)

(define-public (get-pool-value-in-token (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))            
            (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
            (balance-x (get balance-x balances))
            (balance-y (get balance-y balances))            
            (spot (unwrap-panic (get-spot token collateral)))
            (balance-x-in-y (unwrap! (contract-call? .math-fixed-point div-down balance-x spot) math-call-err))
        )
        (contract-call? .math-fixed-point add-fixed balance-x-in-y balance-y)
    )
)

(define-public (get-ltv (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))            
            (yield-supply (get yield-supply pool)) ;; in token
            (pool-value (unwrap! (get-pool-value-in-token token collateral expiry) internal-function-call-err)) ;; also in token
        )
        ;; if no liquidity in the pool, return ltv-0
        (if (is-eq yield-supply u0)
            (ok (get ltv-0 pool))
            (contract-call? .math-fixed-point div-down yield-supply pool-value)
        )
    )
)

(define-public (get-weight-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (strike uint) (bs-vol uint))
    (let 
        (
            ;; determine spot using open oracle
            (spot (unwrap! (get-spot token collateral) get-oracle-price-fail-err))
            (now (* block-height ONE_8))
            ;; TODO: assume 10mins per block - something to be reviewed
            
            (t (unwrap! (contract-call? .math-fixed-point div-down 
                (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) math-call-err) (* u52560 ONE_8)) math-call-err))
            ;; TODO: APYs need to be calculated from the prevailing yield token price.
            ;; TODO: ln(S/K) approximated as (S/K - 1)

            ;; we calculate d1 first
            (spot-term (unwrap! (contract-call? .math-fixed-point div-up spot strike) math-call-err))
            (pow-bs-vol (unwrap! (contract-call? .math-fixed-point div-up 
                            (unwrap! (contract-call? .math-fixed-point pow-down bs-vol u200000000) math-call-err) u200000000) math-call-err))
            (vol-term (unwrap! (contract-call? .math-fixed-point mul-up t pow-bs-vol) math-call-err))                       
            (sqrt-t (unwrap! (contract-call? .math-fixed-point pow-down t u50000000) math-call-err))
            (sqrt-2 (unwrap! (contract-call? .math-fixed-point pow-down u200000000 u50000000) math-call-err))
            
            (denominator (unwrap! (contract-call? .math-fixed-point mul-down bs-vol sqrt-t) math-call-err))
        )
        
        (if (> spot-term ONE_8)
            (let
                (
                    (numerator (unwrap! (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap! (contract-call? .math-fixed-point sub-fixed spot-term ONE_8) math-call-err)) math-call-err))
                    (d1 (unwrap! (contract-call? .math-fixed-point div-up numerator denominator) math-call-err))
                    (erf-term (unwrap! (erf (unwrap! (contract-call? .math-fixed-point div-up d1 sqrt-2) math-call-err)) math-call-err))
                    (complement (unwrap! (contract-call? .math-fixed-point add-fixed ONE_8 erf-term) math-call-err))
                )
                ;; make sure weight-x > 0 so it works with weighted-equation
                (max (unwrap! (contract-call? .math-fixed-point div-up complement u200000000) math-call-err) u1)
            )
            (let
                (
                    (numerator (unwrap! (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 spot-term) math-call-err)) math-call-err))
                    (d1 (unwrap! (contract-call? .math-fixed-point div-up numerator denominator) math-call-err))
                    (erf-term (unwrap! (erf (unwrap! (contract-call? .math-fixed-point div-up d1 sqrt-2) math-call-err)) math-call-err))
                    (complement (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 erf-term) math-call-err))
                )
                ;; make sure weight-x > 0 so it works with weighted-equation
                (max (unwrap! (contract-call? .math-fixed-point div-up complement u200000000) math-call-err) u1)
            )
        )  
    )
)

;; get overall balances for the pair
(define-public (get-balances (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (yield-bal-x (get yield-bal-x pool))
            (yield-bal-y (get yield-bal-y pool))
            (key-bal-x (get key-bal-x pool))
            (key-bal-y (get key-bal-y pool))
            (balance-x (unwrap-panic (contract-call? .math-fixed-point add-fixed yield-bal-x key-bal-x)))
            (balance-y (unwrap-panic (contract-call? .math-fixed-point add-fixed yield-bal-y key-bal-y)))
        )
        (ok {balance-x: balance-x, balance-y: balance-y})
    )
)

;; single sided liquidity
(define-public (create-pool (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (dx uint)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))

            (token-x (contract-of collateral))
            (token-y (contract-of token))
            
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))

            ;; determine strike using open oracle
            (strike (unwrap! (get-spot token collateral) get-oracle-price-fail-err))
            
            ;; TODO: setter / getter of bs-vol / ltv-0
            ;; currently hard-coded at 50%
            (bs-vol u50000000)
            (ltv-0 u80000000)

            (weight-x (unwrap! (get-weight-x token collateral expiry strike bs-vol) get-weight-fail-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))

            (pool-data {
                yield-supply: u0,
                key-supply: u0,
                yield-bal-x: u0,
                yield-bal-y: u0,
                key-bal-x: u0,
                key-bal-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of the-key-token), ;; keytoken holder accrues fee
                yield-token: (contract-of the-yield-token),
                key-token: (contract-of the-key-token),
                strike: strike,
                bs-vol: bs-vol,
                fee-rate-x: u0,
                fee-rate-y: u0,
                ltv-0: ltv-0,
                weight-x: weight-x,
                weight-y: weight-y
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

;; note single-sided liquidity
(define-public (add-to-position (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-key-token <yield-token-trait>) (dx uint))    
    (let
        (
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))
            (ltv (unwrap! (get-ltv token collateral expiry) internal-function-call-err))
        )
        (asserts! (> dx u0) invalid-liquidity-err)
        ;; mint is possible only if ltv < 1
        (asserts! (> ONE_8 ltv) invalid-pool-err)
        
        (let
            (
                (token-x (contract-of collateral))
                (token-y (contract-of token))                    
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                (yield-bal-x (get yield-bal-x pool))
                (yield-bal-y (get yield-bal-y pool))
                (key-bal-x (get key-bal-x pool))
                (key-bal-y (get key-bal-y pool))
                (yield-supply (get yield-supply pool))   
                (key-supply (get key-supply pool))

                (yield-dx (unwrap! (contract-call? .math-fixed-point mul-down ltv dx) math-call-err))
                (key-dx (unwrap! (contract-call? .math-fixed-point sub-fixed dx yield-dx) math-call-err))                 

                (add-data (unwrap! (get-token-given-position token collateral expiry dx) internal-function-call-err))
                (add-yield-data (get yield-token add-data))
                (add-key-data (get key-token add-data))

                (yield-new-supply (get token add-yield-data))
                (yield-dx-weighted (get dx-weighted add-yield-data))                   
                (yield-dx-to-dy (unwrap! (contract-call? .math-fixed-point sub-fixed yield-dx yield-dx-weighted) math-call-err))     
            
                ;; TODO: a more efficient way to convert?
                (yield-dy-weighted (get dy (unwrap! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 yield-dx-to-dy) no-liquidity-err)))

                (key-new-supply (get token add-key-data))
                (key-dx-weighted (get dx-weighted add-key-data))    
                (key-dx-to-dy (unwrap! (contract-call? .math-fixed-point sub-fixed key-dx key-dx-weighted) math-call-err))    

                ;; TODO: a more efficient way to convert?      
                (key-dy-weighted (get dy (unwrap! (contract-call? .fixed-weight-pool swap-x-for-y token collateral u50000000 u50000000 key-dx-to-dy) no-liquidity-err)))

                (pool-updated (merge pool {
                    yield-supply: (unwrap! (contract-call? .math-fixed-point add-fixed yield-new-supply yield-supply) math-call-err),
                    key-supply: (unwrap! (contract-call? .math-fixed-point add-fixed key-new-supply key-supply) math-call-err),
                    yield-bal-x: (unwrap! (contract-call? .math-fixed-point add-fixed yield-bal-x yield-dx-weighted) math-call-err),
                    yield-bal-y: (unwrap! (contract-call? .math-fixed-point add-fixed yield-bal-y yield-dy-weighted) math-call-err),
                    key-bal-x: (unwrap! (contract-call? .math-fixed-point add-fixed key-bal-x key-dx-weighted) math-call-err),
                    key-bal-y: (unwrap! (contract-call? .math-fixed-point add-fixed key-bal-y key-dy-weighted) math-call-err)
                }))

                (dx-weighted (unwrap! (contract-call? .math-fixed-point add-fixed yield-dx-weighted key-dx-weighted) math-call-err))
                (dy-weighted (unwrap! (contract-call? .math-fixed-point add-fixed yield-dy-weighted key-dy-weighted) math-call-err))
            )     

            (unwrap! (contract-call? collateral transfer dx-weighted tx-sender .alex-vault none) transfer-x-failed-err)
            (unwrap! (contract-call? token transfer dy-weighted tx-sender .alex-vault none) transfer-y-failed-err)

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            ;; mint pool token and send to tx-sender
            (try! (contract-call? the-yield-token mint tx-sender yield-new-supply))
            (try! (contract-call? the-key-token mint tx-sender key-new-supply))
        
            ;; Registry using mint
            ;;(try! (contract-call? .alex-multisig-registry mint-token the-yield-token new-supply tx-sender))
            ;;(try! (contract-call? .alex-multisig-registry mint-token the-key-token new-supply tx-sender))

            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok true)
        )
    )
)    

;; note single sided liquidity
;; TODO: currently the position returned is not guaranteed 
(define-public (reduce-position-yield (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (percent uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (expiry (unwrap! (contract-call? the-yield-token get-expiry) get-expiry-fail-err))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (yield-bal-x (get yield-bal-x pool))
            (yield-bal-y (get yield-bal-y pool))
            (yield-supply (get yield-supply pool))   
            (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap! (contract-call? the-yield-token get-balance tx-sender) get-balance-fail-err) percent) math-call-err))
            (reduce-data (unwrap! (get-position-given-burn-yield token collateral expiry shares) internal-function-call-err))
            (dx-weighted (get dx-weighted reduce-data))
            (dy-weighted (get dy-weighted reduce-data))

            ;; TODO: a more efficient way to convert?
            (dy-to-dx (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 dy-weighted) no-liquidity-err)))
            (dx (unwrap! (contract-call? .math-fixed-point add-fixed dx-weighted dy-to-dx) math-call-err))
            (pool-updated (merge pool {
                yield-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-supply shares) math-call-err),
                yield-bal-x: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-bal-x dx-weighted) math-call-err),
                yield-bal-y: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-bal-y dy-weighted) math-call-err)
                })
            )  
            (now (* block-height ONE_8))
        )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        ;; burn supported only at maturity
        (asserts! (>= now expiry) expiry-err)
        
        ;; all dy converted into dx, so zero dy to transfer.
        (unwrap! (contract-call? collateral transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
        ;;(unwrap! (contract-call? token transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-yield-token burn tx-sender shares))
        ;;(try! (contract-call? .alex-multisig-registry burn-token the-yield-token new-supply tx-sender))


        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: u0})
        ;;  (print shares)
        ;;  (ok {dx: u0, dy: u0})
   )
)

;; note single-sided liquidity
;; TODO: currently the position returned is not floored
(define-public (reduce-position-key (token <ft-trait>) (collateral <ft-trait>) (the-key-token <yield-token-trait>) (percent uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (expiry (unwrap! (contract-call? the-key-token get-expiry) get-expiry-fail-err))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (key-bal-x (get key-bal-x pool))
            (key-bal-y (get key-bal-y pool))            
            (key-supply (get key-supply pool))            
            (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap! (contract-call? the-key-token get-balance tx-sender) get-balance-fail-err) percent) math-call-err))
            (reduce-data (unwrap! (get-position-given-burn-key token collateral expiry shares) internal-function-call-err))
            (dx-weighted (get dx-weighted reduce-data))
            (dy-weighted (get dy-weighted reduce-data))

            ;; TODO: a more efficient way to convert?
            (dy-to-dx (get dx (unwrap! (contract-call? .fixed-weight-pool swap-y-for-x token collateral u50000000 u50000000 dy-weighted) no-liquidity-err)))
            (dx (unwrap! (contract-call? .math-fixed-point add-fixed dx-weighted dy-to-dx) math-call-err))
            (pool-updated (merge pool {
                key-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed key-supply shares) math-call-err),
                key-bal-x: (unwrap! (contract-call? .math-fixed-point sub-fixed key-bal-x dx-weighted) math-call-err),
                key-bal-y: (unwrap! (contract-call? .math-fixed-point sub-fixed key-bal-y dy-weighted) math-call-err)
                })
            ) 
            (now (* block-height ONE_8))
        )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        ;; burn supported only at maturity
        (asserts! (>= now expiry) expiry-err)
        
        ;; all dy converted into dx, so zero dy to transfer.
        (unwrap! (contract-call? collateral transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
        ;;(unwrap! (contract-call? token transfer dy .alex-vault tx-sender none) transfer-y-failed-err)
        
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-key-token burn tx-sender shares))
        ;;(try! (contract-call? .alex-multisig-registry burn-token the-key-token new-supply tx-sender))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: u0})
   )
)

;; split of balance to yield and key is transparent to traders
(define-public (swap-x-for-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (strike (get strike pool))
            (bs-vol (get bs-vol pool)) 
            (fee-rate-x (get fee-rate-x pool))
            (yield-bal-x (get yield-bal-x pool))
            (yield-bal-y (get yield-bal-y pool))
            (key-bal-x (get key-bal-x pool))
            (key-bal-y (get key-bal-y pool))       

            ;; every swap call updates the weights
            (weight-x (unwrap! (get-weight-x token collateral expiry strike bs-vol) get-weight-fail-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))            
            
            ;; fee = dx * fee-rate-x
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dx fee-rate-x) math-call-err))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx fee) math-call-err))    
            (dy (unwrap! (get-y-given-x token collateral expiry dx-net-fees) internal-function-call-err))

            (ltv (unwrap! (get-ltv token collateral expiry) internal-function-call-err))
            (yield-dx-net-fees (unwrap! (contract-call? .math-fixed-point mul-up ltv dx-net-fees) math-call-err))
            (yield-dy (unwrap! (contract-call? .math-fixed-point mul-up ltv dy) math-call-err))
            (key-dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx-net-fees yield-dx-net-fees) math-call-err))
            (key-dy (unwrap! (contract-call? .math-fixed-point sub-fixed dy yield-dy) math-call-err))

            (pool-updated
                (merge pool
                    {
                        yield-bal-x: (unwrap! (contract-call? .math-fixed-point add-fixed yield-bal-x yield-dx-net-fees) math-call-err),
                        yield-bal-y: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-bal-y yield-dy) math-call-err),
                        key-bal-x: (unwrap! (contract-call? .math-fixed-point add-fixed key-bal-x key-dx-net-fees) math-call-err),
                        key-bal-y: (unwrap! (contract-call? .math-fixed-point sub-fixed key-bal-y key-dy) math-call-err),
                        fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-x pool) fee) math-call-err),
                        weight-x: weight-x,
                        weight-y: weight-y                    
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dx u0) invalid-liquidity-err) 

        (unwrap! (contract-call? collateral transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
        (unwrap! (contract-call? token transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok {dx: dx-net-fees, dy: dy})
    )
)

;; split of balance to yield and key is transparent to traders
(define-public (swap-y-for-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (let
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (strike (get strike pool))
            (bs-vol (get bs-vol pool)) 
            (fee-rate-y (get fee-rate-y pool))
            (yield-bal-x (get yield-bal-x pool))
            (yield-bal-y (get yield-bal-y pool))
            (key-bal-x (get key-bal-x pool))
            (key-bal-y (get key-bal-y pool))  

            ;; every swap call updates the weights
            (weight-x (unwrap! (get-weight-x token collateral expiry strike bs-vol) get-weight-fail-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))   

            ;; fee = dy * fee-rate-y
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dy fee-rate-y) math-call-err))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy fee) math-call-err))
            (dx (unwrap! (get-x-given-y token collateral expiry dy-net-fees) internal-function-call-err))

            (ltv (unwrap! (get-ltv token collateral expiry) internal-function-call-err))
            (yield-dy-net-fees (unwrap! (contract-call? .math-fixed-point mul-up ltv dy-net-fees) math-call-err))
            (yield-dx (unwrap! (contract-call? .math-fixed-point mul-up ltv dx) math-call-err))
            (key-dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy-net-fees yield-dy-net-fees) math-call-err))
            (key-dx (unwrap! (contract-call? .math-fixed-point sub-fixed dx yield-dx) math-call-err))            

            (pool-updated
                (merge pool
                    {
                        yield-bal-x: (unwrap! (contract-call? .math-fixed-point sub-fixed yield-bal-x yield-dx) math-call-err),
                        yield-bal-y: (unwrap! (contract-call? .math-fixed-point add-fixed yield-bal-y yield-dy-net-fees) math-call-err),
                        key-bal-x: (unwrap! (contract-call? .math-fixed-point sub-fixed key-bal-x key-dx) math-call-err),
                        key-bal-y: (unwrap! (contract-call? .math-fixed-point add-fixed key-bal-y key-dy-net-fees) math-call-err),                        
                        fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-y pool) fee) math-call-err),
                        weight-x: weight-x,
                        weight-y: weight-y                        
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dy u0) invalid-liquidity-err)

        (unwrap! (contract-call? collateral transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
        (unwrap! (contract-call? token transfer dy tx-sender .alex-vault none) transfer-y-failed-err)

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok {dx: dx, dy: dy-net-fees})
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

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, expiry: expiry
            }
            (merge pool { fee-rate-y: fee-rate-y })
        )
        (ok true)     
    )
)

(define-public (set-fee-to-address (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (address principal))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, expiry: expiry 
            }
            (merge pool { fee-to-address: address })
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
        )

        (and (> fee-x u0) (unwrap! (contract-call? token transfer fee-x .alex-vault address none) transfer-x-failed-err))
        (and (> fee-y u0) (unwrap! (contract-call? collateral transfer fee-y .alex-vault address none) transfer-y-failed-err))

        (map-set pools-data-map
            { token-x: token-x, token-y: token-y, expiry: expiry}
            (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok {fee-x: fee-x, fee-y: fee-y})
    )
)

(define-public (get-y-given-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
            (balance-x (get balance-x balances))
            (balance-y (get balance-y balances))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-public (get-x-given-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
            (balance-x (get balance-x balances))
            (balance-y (get balance-y balances))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-public (get-x-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of collateral))
            (token-y (contract-of token))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
            (balance-x (get balance-x balances))
            (balance-y (get balance-y balances))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))         
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

;; single sided liquidity
(define-public (get-token-given-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
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
                    (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
                    (balance-x (get balance-x balances))
                    (balance-y (get balance-y balances))
                    (total-supply (get yield-supply pool)) ;; prior to maturity, yield-supply == key-supply, so we use yield-supply
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))

                    (ltv (unwrap! (get-ltv token collateral expiry) internal-function-call-err))

                    ;; we split dx to dx-weighted and dy-weighted using on-chain AMM
                    (dx-weighted (unwrap! (contract-call? .math-fixed-point mul-up dx weight-x) math-call-err))
                    (dx-to-dy (unwrap! (contract-call? .math-fixed-point sub-fixed dx dx-weighted) math-call-err))
                    (dy-weighted (unwrap! (contract-call? .fixed-weight-pool get-y-given-x token collateral u50000000 u50000000 dx-to-dy) no-liquidity-err))            
                    
                    (add-data (unwrap! (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx-weighted dy-weighted) weighted-equation-call-err))
                    (dy-check (get dy add-data)) ;;must equal dy-weighted (see asserts below)
            
                    (ltv-dx (unwrap! (contract-call? .math-fixed-point mul-down ltv dx) math-call-err))

                    (yield-dx-weighted (unwrap! (contract-call? .math-fixed-point mul-down ltv dx-weighted) math-call-err))
                    (yield-dy-weighted (unwrap! (contract-call? .math-fixed-point mul-down ltv dy-weighted) math-call-err))
                    (key-dx-weighted (unwrap! (contract-call? .math-fixed-point sub-fixed dx-weighted yield-dx-weighted) math-call-err))
                    (key-dy-weighted (unwrap! (contract-call? .math-fixed-point sub-fixed dy-weighted yield-dy-weighted) math-call-err))
                )

                ;; (print "Debugging dy-weighted and dy-check mismatch")
                ;; (print dy-weighted)
                ;; (print dy-check)
                ;; (print dx-to-dy)
                ;;(asserts! (is-eq dy-weighted dy-check) invalid-liquidity-err)

                (ok {yield-token: {token: ltv-dx, dx-weighted: yield-dx-weighted, dy-weighted: yield-dy-weighted}, 
                     key-token: {token: ltv-dx, dx-weighted: key-dx-weighted, dy-weighted: key-dy-weighted}})
            )
            expiry-err
        )
    )
)

;; single sided liquidity
(define-private (get-position-given-mint (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
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
                    (balances (unwrap! (get-balances token collateral expiry) internal-function-call-err))
                    (balance-x (get balance-x balances))
                    (balance-y (get balance-y balances))         
                    (total-supply (get yield-supply pool)) ;; prior to maturity, yield-supply == key-supply, so we use yield-supply
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))
            
                    (ltv (unwrap! (get-ltv token collateral expiry) internal-function-call-err))

                    (pos-data (unwrap! (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares) weighted-equation-call-err))

                    (dx-weighted (get dx pos-data))
                    (dy-weighted (get dy pos-data))
                    (yield-dx-weighted (unwrap! (contract-call? .math-fixed-point mul-up ltv dx-weighted) math-call-err))
                    (yield-dy-weighted (unwrap! (contract-call? .math-fixed-point mul-up ltv dy-weighted) math-call-err))
                    (key-dx-weighted (unwrap! (contract-call? .math-fixed-point sub-fixed dx-weighted yield-dx-weighted) math-call-err))
                    (key-dy-weighted (unwrap! (contract-call? .math-fixed-point sub-fixed dy-weighted yield-dy-weighted) math-call-err))

                    ;; always convert to collateral ccy
                    (yield-dy-to-dx (unwrap! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 yield-dy-weighted) no-liquidity-err))
                    (key-dy-to-dx (unwrap! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 key-dy-weighted) no-liquidity-err))
                    
                    (yield-dx (unwrap! (contract-call? .math-fixed-point add-fixed yield-dx-weighted yield-dy-to-dx) math-call-err))
                    (key-dx (unwrap! (contract-call? .math-fixed-point add-fixed key-dx-weighted key-dy-to-dx) math-call-err))
                    
                )
                (ok {yield-token: {dx: yield-dx, dx-weighted: yield-dx-weighted, dy-weighted: yield-dy-weighted}, 
                    key-token: {dx: key-dx, dx-weighted: key-dx-weighted, dy-weighted: key-dy-weighted}})
            )
            expiry-err
        )
    )
)

(define-public (get-position-given-burn-yield (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (>= now expiry)
            (let 
                (
                    (token-x (contract-of collateral))
                    (token-y (contract-of token))
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                    (yield-bal-x (get yield-bal-x pool))
                    (yield-bal-y (get yield-bal-y pool))                    
                    (yield-supply (get yield-supply pool))
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))

                    (pos-data (unwrap! (contract-call? .weighted-equation get-position-given-burn yield-bal-x yield-bal-y weight-x weight-y yield-supply shares) weighted-equation-call-err))
                    
                    (dx-weighted (get dx pos-data))
                    (dy-weighted (get dy pos-data))                    

                    ;; always convert to collateral ccy
                    (dy-to-dx (unwrap! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 dy-weighted) no-liquidity-err))             
                    
                    (dx (unwrap! (contract-call? .math-fixed-point add-fixed dx-weighted dy-to-dx) math-call-err))
                    
                )
                (ok {dx: dx, dx-weighted: dx-weighted, dy-weighted: dy-weighted})
            )
            expiry-err
        )
    )
)

(define-public (get-position-given-burn-key (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (now (* block-height ONE_8))
        )
        (if (>= now expiry)
            (let 
                (
                    (token-x (contract-of collateral))
                    (token-y (contract-of token))
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
                    (key-bal-x (get yield-bal-x pool))
                    (key-bal-y (get yield-bal-y pool))                    
                    (key-supply (get yield-supply pool))
                    (weight-x (get weight-x pool))
                    (weight-y (get weight-y pool))

                    (pos-data (unwrap! (contract-call? .weighted-equation get-position-given-burn key-bal-x key-bal-y weight-x weight-y key-supply shares) weighted-equation-call-err))
                    
                    (dx-weighted (get dx pos-data))
                    (dy-weighted (get dy pos-data))                    

                    ;; always convert to collateral ccy
                    (dy-to-dx (unwrap! (contract-call? .fixed-weight-pool get-x-given-y token collateral u50000000 u50000000 dy-weighted) no-liquidity-err))
                    
                    (dx (unwrap! (contract-call? .math-fixed-point add-fixed dx-weighted dy-to-dx) math-call-err))   
                )
                (ok {dx: dx, dx-weighted: dx-weighted, dy-weighted: dy-weighted})
            )
            expiry-err
        )
    )
)
