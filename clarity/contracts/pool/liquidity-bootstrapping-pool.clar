(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; liquidity-bootstrapping-pool

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
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
(define-constant already-ERR-EXPIRY (err u2010))
(define-constant ERR-WEIGHTED-EQUATION-CALL (err u2009))
(define-constant ERR-MATH-CALL (err u2010))
(define-constant ERR-INTERNAL-FUNCTION-CALL (err u1001))
(define-constant internal-get-weight-err (err u2012))


;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal,
    token-y: principal,
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
    pool-token: principal,
    listed: uint,
    weight-x-0: uint,
    weight-x-1: uint,
    weight-x-t: uint,
    fee-rate-x: uint,
    fee-rate-y: uint       
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;

;; liquidity injection is allowed at the pool creation only
(define-private (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-pool-token <pool-token-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (add-data (try! (get-token-given-position token-x-trait token-y-trait expiry dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) ERR-MATH-CALL),
                balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx) ERR-MATH-CALL),
                balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y new-dy) ERR-MATH-CALL)
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) ERR-INVALID-LIQUIDITY)

        (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
        (unwrap! (contract-call? token-y-trait transfer new-dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)
        
        ;; mint pool token-x and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
) 

;; public functions
;;

(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (let
        (
            (pool (map-get? pools-map {pool-id: pool-id}))
        )
        (asserts! (is-some pool) ERR-INVALID-POOL-ERR)
        (ok pool)
    )
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

(define-read-only (get-pool-details (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }))
        )
        (asserts! (is-some pool) ERR-INVALID-POOL-ERR)
        (ok pool)
    )
)

(define-read-only (get-weight-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))                  
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x-0 (get weight-x-0 pool))
            (weight-x-1 (get weight-x-1 pool))
            (listed (get listed pool))
            (now (* block-height ONE_8))

            ;; weight-t = weight-x-0 - (block-height - listed) * (weight-x-0 - weight-x-1) / (expiry - listed)
            (now-to-listed (unwrap! (contract-call? .math-fixed-point sub-fixed now listed) ERR-MATH-CALL))
            (expiry-to-listed (unwrap! (contract-call? .math-fixed-point sub-fixed expiry listed) ERR-MATH-CALL))
            (weight-diff (unwrap! (contract-call? .math-fixed-point sub-fixed weight-x-0 weight-x-1) ERR-MATH-CALL))
            (time-ratio (unwrap! (contract-call? .math-fixed-point div-down now-to-listed expiry-to-listed) ERR-MATH-CALL))
            (weight-change (unwrap! (contract-call? .math-fixed-point mul-down weight-diff time-ratio) ERR-MATH-CALL))
            (weight-t (unwrap! (contract-call? .math-fixed-point sub-fixed weight-x-0 weight-change) ERR-MATH-CALL))     
        )

        (asserts! (< now expiry) already-ERR-EXPIRY)

        (ok weight-t)
    )
)

;; get overall balances for the pair
(define-read-only (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err ERR-INVALID-POOL-ERR)))
        )
        (ok {balance-x: (get balance-x pool), balance-y: (get balance-y pool)})
    )
)

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x-0 uint) (weight-x-1 uint) (expiry uint) (the-pool-token <pool-token-trait>) (multisig-vote <multisig-trait>) (dx uint) (dy uint)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))

            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (now (* block-height ONE_8))
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of multisig-vote),
                pool-token: (contract-of the-pool-token),
                listed: now,
                weight-x-0: weight-x-0,
                weight-x-1: weight-x-1,
                weight-x-t: weight-x-0,
                fee-rate-x: u0,
                fee-rate-y: u0
            })
        )
        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, expiry: expiry }))
            )
            ERR-POOL-ALREADY-EXISTS
        )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, expiry: expiry })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)
        (try! (add-to-position token-x-trait token-y-trait expiry the-pool-token dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)   

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-pool-token <pool-token-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
            (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) ERR-MATH-CALL)))
            (total-supply (get total-supply pool))     
            (reduce-data (try! (get-position-given-burn token-x-trait token-y-trait expiry shares)))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) ERR-MATH-CALL),
                balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) ERR-MATH-CALL),
                balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) ERR-MATH-CALL)
                })
           )
        )

        (asserts! (<= percent ONE_8) ERR-PERCENT_GREATER_THAN_ONE)
        (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) ERR-TRANSFER-X-FAILED)
        (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) ERR-TRANSFER-Y-FAILED)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))
        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
    )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))       
            (fee-rate-x (get fee-rate-x pool))
            (now (* block-height ONE_8))

            ;; fee = dx * fee-rate-x
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dx fee-rate-x) ERR-MATH-CALL))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx fee) ERR-MATH-CALL))

            ;; swap triggers update of weight
            (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
            (dy (try! (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx-net-fees)))                    

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx-net-fees) ERR-MATH-CALL),
                        balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) ERR-MATH-CALL),
                        fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)) ERR-MATH-CALL),
                        weight-x-t: weight-x
                    }
                )
            )
        )

        ;; swap is allowed only until expiry
        (asserts! (< now expiry) already-ERR-EXPIRY)
        
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
        (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) ERR-TRANSFER-Y-FAILED)

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok {dx: dx-net-fees, dy: dy})
    )
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (fee-rate-y (get fee-rate-y pool))  
            (now (* block-height ONE_8))

            ;; fee = dy * fee-rate-y
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dy fee-rate-y) ERR-MATH-CALL))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy fee) ERR-MATH-CALL))

            ;; swap triggers update of weight
            (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))            
            (dx (try! (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy-net-fees)))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) ERR-MATH-CALL),
                        balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y dy-net-fees) ERR-MATH-CALL),
                        fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)) ERR-MATH-CALL),
                        weight-x-t: weight-x
                    }
                )
            )
        )

        ;; swap is allowed only until expiry
        (asserts! (< now expiry) already-ERR-EXPIRY)

        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) ERR-TRANSFER-X-FAILED)
        (unwrap! (contract-call? token-y-trait transfer dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok {dx: dx, dy: dy-net-fees})
  )
)


(define-read-only (get-fee-rate-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-x pool))
    )
)

(define-read-only (get-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-y pool))
    )
)

(define-public (set-fee-rate-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (fee-rate-x uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
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

(define-public (set-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (fee-rate-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
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

(define-read-only (get-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))                
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err ERR-INVALID-POOL-ERR)))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err ERR-INVALID-POOL-ERR)))
        )
        (ok {fee-balance-x: (get fee-balance-x pool), fee-balance-y: (get fee-balance-y pool)})
    )
)

;; TODO: implement reserve pool logic
(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
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
                (unwrap! (contract-call? token-x-trait transfer fee-x .alex-vault tx-sender none) ERR-TRANSFER-X-FAILED)
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-x .token-usda) 
                            fee-x 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token-x-trait u50000000 u50000000 fee-x)))
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (unwrap! (contract-call? token-y-trait transfer fee-y .alex-vault tx-sender none) ERR-TRANSFER-Y-FAILED)
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-y .token-usda) 
                            fee-y 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token-y-trait u50000000 u50000000 fee-y)))
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

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))            
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))          
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))                         
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) ERR-MATH-CALL))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)