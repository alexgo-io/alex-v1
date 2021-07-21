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

(define-constant invalid-pool-err (err u201))
(define-constant no-liquidity-err (err u61))
(define-constant invalid-liquidity-err (err u202))
(define-constant transfer-x-failed-err (err u72))
(define-constant transfer-y-failed-err (err u73))
(define-constant pool-already-exists-err (err u69))
(define-constant too-many-pools-err (err u68))
(define-constant percent-greater-than-one (err u5))
(define-constant no-fee-x-err (err u8))
(define-constant no-fee-y-err (err u9))

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
            (a1x (unwrap-panic (contract-call? .math-fixed-point mul-down a1 x)))
            (x2 (unwrap-panic (contract-call? .math-fixed-point pow-down x u200000000)))
            (a2x (unwrap-panic (contract-call? .math-fixed-point mul-down a2 x2)))
            (x3 (unwrap-panic (contract-call? .math-fixed-point pow-down x u300000000)))
            (a3x (unwrap-panic (contract-call? .math-fixed-point mul-down a3 x3)))
            (x4 (unwrap-panic (contract-call? .math-fixed-point pow-down x u400000000)))
            (a4x (unwrap-panic (contract-call? .math-fixed-point mul-down a4 x4)))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8 a1x)))
            (denom1 (unwrap-panic (contract-call? .math-fixed-point add-fixed denom a2x)))
            (denom2 (unwrap-panic (contract-call? .math-fixed-point add-fixed denom1 a3x)))
            (denom3 (unwrap-panic (contract-call? .math-fixed-point add-fixed denom2 a4x)))
            (denom4 (unwrap-panic (contract-call? .math-fixed-point pow-down denom3 u400000000)))
            (base (unwrap-panic (contract-call? .math-fixed-point div-down ONE_8 denom4)))
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
;;    (unwrap-panic (map-get? pools-map { pool-id: pool-id }))
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
            ;; TODO t needs to normalised relative to the current block height
            (t ONE_8)

            ;; TODO APYs need to be calculated from the prevailing yield token price.
            ;; TODO ln(S/K) approximated as (S/K - 1)

            ;; we calculate d1 first
            (spot-term (unwrap-panic (contract-call? .math-fixed-point div-up spot strike)))
            (pow-bs-vol (unwrap-panic (contract-call? .math-fixed-point div-up 
                            (unwrap-panic (contract-call? .math-fixed-point pow-down bs-vol u200000000)) u200000000)))
            (vol-term (unwrap-panic (contract-call? .math-fixed-point mul-up t pow-bs-vol)))                       
            (sqrt-t (unwrap-panic (contract-call? .math-fixed-point pow-down t u50000000)))
            (sqrt-2 (unwrap-panic (contract-call? .math-fixed-point pow-down u200000000 u50000000)))
            
            (denominator (unwrap-panic (contract-call? .math-fixed-point mul-down bs-vol sqrt-t)))
        )
        
        (if (> spot-term ONE_8)
            (let
                (
                    (numerator (unwrap-panic (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap-panic (contract-call? .math-fixed-point sub-fixed spot-term ONE_8)))))
                    (d1 (unwrap-panic (contract-call? .math-fixed-point div-up numerator denominator)))
                    (erf-term (unwrap-panic (erf (unwrap-panic (contract-call? .math-fixed-point div-up d1 sqrt-2)))))
                    (complement (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8 erf-term)))
                )
                (contract-call? .math-fixed-point div-up complement u200000000)
            )
            (let
                (
                    (numerator (unwrap-panic (contract-call? .math-fixed-point add-fixed vol-term 
                                    (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 spot-term)))))
                    (d1 (unwrap-panic (contract-call? .math-fixed-point div-up numerator denominator)))
                    (erf-term (unwrap-panic (erf (unwrap-panic (contract-call? .math-fixed-point div-up d1 sqrt-2)))))
                    (complement (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 erf-term)))
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
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))
            (add-data (unwrap-panic (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point add-fixed new-supply total-supply)),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-y new-dy))
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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap-panic (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-yield-token get-balance tx-sender)) percent)))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))        
            (reduce-data (unwrap-panic (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point sub-fixed total-supply shares)),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-x dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-y dy))
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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))       

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
    
            (dy (unwrap-panic (get-y-given-x token collateral expiry dx)))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)),
                        balance-y: (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-y dy)),
                        fee-balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)))                      
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        ;; TODO : Implement case by case logic of token here bt branching with if statement

        ;; Transfer 
        ;; when received token-x , token-x -> vault
        ;; when received token-y , token-y : vault  -> tx-sender

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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
            (dx (unwrap-panic (get-x-given-y token collateral expiry dy)))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap-panic (contract-call? .math-fixed-point sub-fixed balance-x dx)),
                        balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-y dy)),
                        fee-balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool))),
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        ;; TODO : Implement case by case logic of token here bt branching with if statement

        ;; Transfer 
        ;; when received token-x , token-x -> vault
        ;; when received token-y , token-y : vault  -> tx-sender

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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
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
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))            
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (dx uint) (dy uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))          
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )
)

(define-read-only (get-position-given-mint (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))                         
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

(define-read-only (get-position-given-burn (token <ft-trait>) (collateral <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token))
            (token-y (contract-of collateral))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token collateral expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)