;;(impl-trait .trait-pool.pool-trait)

(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)

;; collateral-rebalancing-pool
;; <add a description here>
;; delta update happens every time contract is called
;; currently it does not support single asset liquidity provision

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
(define-constant internal-function-call-err (err u2011))
(define-constant internal-get-weight-err (err u2012))

(define-constant a1 u27839300)
(define-constant a2 u23038900)
(define-constant a3 u97200)
(define-constant a4 u7810800)
(define-constant oracle-src "nothing")

;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal, ;; token
    token-y: principal, ;; collateral
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
    total-supply: uint,
    balance-x: uint,
    balance-y: uint,
    fee-balance-x: uint,
    fee-balance-y: uint,
    fee-to-address: principal,
    yield-token: principal,
    strike: uint,
    bs-vol: uint    
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
    (let
        (
            (pool (map-get? pools-map {pool-id: pool-id}))
       )
        (if (is-some pool)
            (ok pool)
            (err invalid-pool-err)
       )
   )
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; additional functions
(define-read-only (get-pool-details (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }))
       )
        (if (is-some pool)
            (ok pool)
            (err invalid-pool-err)
       )
   )
)

(define-read-only (get-weight-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))                  
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (strike (get strike pool))
            (bs-vol (get bs-vol pool))

            ;; TODO use yield-token-pool as the price oracle
            ;; BUT wouldn't this be circular at inception?
            (spot ONE_8)            
            (now (unwrap! (contract-call? .math-fixed-point mul-down block-height ONE_8) math-call-err))

            ;; assume 10mins per block - something to be reviewed
            (t (unwrap! (contract-call? .math-fixed-point div-down 
                (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) math-call-err)  
                (unwrap! (contract-call? .math-fixed-point mul-down u52560 ONE_8) math-call-err)) math-call-err))            

            ;; TODO APYs need to be calculated from the prevailing yield token price.
            ;; TODO ln(S/K) approximated as (S/K - 1)

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
                (contract-call? .math-fixed-point div-up complement u200000000)
            )
            (let
                (
                    (numerator (unwrap! (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 spot-term) math-call-err)) math-call-err))
                    (d1 (unwrap! (contract-call? .math-fixed-point div-up numerator denominator) math-call-err))
                    (erf-term (unwrap! (erf (unwrap! (contract-call? .math-fixed-point div-up d1 sqrt-2) math-call-err)) math-call-err))
                    (complement (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 erf-term) math-call-err))
                )
                (contract-call? .math-fixed-point div-up complement u200000000)              
            )
        )
        
    )
)

;; get overall balances for the pair
(define-public (get-balances (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
  (let
    (
      (token-x (contract-of token))
      (token-y (contract-of collateral))
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
    )
    (ok (list (get balance-x pool) (get balance-y pool)))
  )
)

(define-public (create-pool (token <ft-trait>) (collateral <ft-trait>) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))

            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (expiry (unwrap-panic (contract-call? the-yield-token get-expiry)))

            ;; determine strike using yield-token-pool as price oracle
            (strike ONE_8)
            ;; historical volatility oracle?
            (bs-vol ONE_8)

            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of the-yield-token),
                yield-token: (contract-of the-yield-token),
                strike: strike,
                bs-vol: bs-vol
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
        (try! (add-to-position token collateral expiry the-yield-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

;; TODO: support single-sided liquidity
(define-public (add-to-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))            
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
            (add-data (unwrap! (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy) weighted-equation-call-err))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx) math-call-err),
                balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y new-dy) math-call-err)
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? token transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? collateral transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)

        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-yield-token mint new-supply tx-sender))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-yield-token get-balance tx-sender)) percent) math-call-err))
            (total-supply (get total-supply pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))        
            (reduce-data (unwrap! (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares) weighted-equation-call-err))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) math-call-err),
                balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) math-call-err)
                })
           )
       )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        (asserts! (is-ok (contract-call? token transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? collateral transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-yield-token burn shares tx-sender))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (the-vault <vault-trait>) (dx uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))       

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
    
            (dy (unwrap! (get-y-given-x token collateral expiry dx) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) math-call-err),
                        fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)) math-call-err)                      
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dx u0) invalid-liquidity-err) 
        ;; TODO : Implement case by case logic of token here bt branching with if statement

        (asserts! (is-ok (contract-call? token transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? collateral transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok (list dx dy))
    )
)

(define-public (swap-y-for-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (the-vault <vault-trait>) (dy uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
            (dx (unwrap! (get-x-given-y token collateral expiry dy) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y dy) math-call-err),
                        fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)) math-call-err),
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dy u0) invalid-liquidity-err)
        ;; TODO : Implement case by case logic of token here bt branching with if statement

        (asserts! (is-ok (contract-call? token transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? collateral transfer dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok (list dx dy))
  )
)

(define-public (set-fee-to-address (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (address principal))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

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
            (token-x (contract-of token))
            (token-y (contract-of collateral))                
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
        )
        (ok (list (get fee-balance-x pool) (get fee-balance-y pool)))
    )
)

(define-public (collect-fees (token <ft-trait>) (collateral <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
        )

        (asserts! (is-eq fee-x u0) no-fee-x-err)
        (asserts! (is-ok (contract-call? token transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
        (asserts! (is-eq fee-y u0) no-fee-y-err)
        (asserts! (is-ok (contract-call? collateral transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

        (map-set pools-data-map
            { token-x: token-x, token-y: token-y, expiry: expiry}
            (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok (list fee-x fee-y))
    )
)

(define-read-only (get-y-given-x (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))            
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint) (dy uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))          
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )
)

(define-read-only (get-position-given-mint (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))                         
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

(define-read-only (get-position-given-burn (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap! (get-weight-x token collateral expiry) internal-get-weight-err))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)