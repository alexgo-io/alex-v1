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
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
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
                    total-supply: (unwrap! (add-fixed new-supply total-supply) ERR-MATH-CALL),
                    balance-x: (unwrap! (add-fixed balance-x dx) ERR-MATH-CALL),
                    balance-y: (unwrap! (add-fixed balance-y new-dy) ERR-MATH-CALL)
                }))
            )
            (asserts! (> new-dy u0) ERR-INVALID-LIQUIDITY)
            (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
            (unwrap! (contract-call? token-y-trait transfer new-dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)
        
            ;; mint pool token-x and send to tx-sender
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? the-pool-token mint tx-sender new-supply))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok true)
        )
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
    (begin
        (asserts! (< (* block-height ONE_8) expiry) already-ERR-EXPIRY)
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

                ;; weight-t = weight-x-0 - (block-height - listed) * (weight-x-0 - weight-x-1) / (expiry - listed)
                (now-to-listed (unwrap! (sub-fixed (* block-height ONE_8) listed) ERR-MATH-CALL))
                (expiry-to-listed (unwrap! (sub-fixed expiry listed) ERR-MATH-CALL))
                (weight-diff (unwrap! (sub-fixed weight-x-0 weight-x-1) ERR-MATH-CALL))
                (time-ratio (unwrap! (div-down now-to-listed expiry-to-listed) ERR-MATH-CALL))
                (weight-change (unwrap! (mul-down weight-diff time-ratio) ERR-MATH-CALL))
                (weight-t (unwrap! (sub-fixed weight-x-0 weight-change) ERR-MATH-CALL))     
            )

            (ok weight-t)
        )
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
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of multisig-vote),
                pool-token: (contract-of the-pool-token),
                listed: (* block-height ONE_8),
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
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT_GREATER_THAN_ONE)        
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) ERR-MATH-CALL)))
                (total-supply (get total-supply pool))     
                (reduce-data (try! (get-position-given-burn token-x-trait token-y-trait expiry shares)))
                (dx (get dx reduce-data))
                (dy (get dy reduce-data))
                (pool-updated (merge pool {
                    total-supply: (if (<= total-supply shares) u0 (unwrap! (sub-fixed total-supply shares) ERR-MATH-CALL)),
                    balance-x: (if (<= balance-x dx) u0 (unwrap! (sub-fixed balance-x dx) ERR-MATH-CALL)),
                    balance-y: (if (<= balance-y dx) u0 (unwrap! (sub-fixed balance-y dy) ERR-MATH-CALL))
                    })
                )
            )
            (try! (contract-call? .alex-vault transfer-ft token-x-trait dx (as-contract tx-sender) tx-sender))
            (try! (contract-call? .alex-vault transfer-ft token-y-trait dy (as-contract tx-sender) tx-sender))

            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? the-pool-token burn tx-sender shares))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint))
    (begin
        ;; swap is allowed only until expiry
        (asserts! (< (* block-height ONE_8) expiry) already-ERR-EXPIRY)
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)    
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))       
                (fee-rate-x (get fee-rate-x pool))

                ;; fee = dx * fee-rate-x
                (fee (unwrap! (mul-up dx fee-rate-x) ERR-MATH-CALL))
                (dx-net-fees (if (<= dx fee) u0 (unwrap! (sub-fixed dx fee) ERR-MATH-CALL)))

                ;; swap triggers update of weight
                (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
                (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
                (dy (try! (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx-net-fees)))                    

                (pool-updated
                    (merge pool
                        {
                            balance-x: (unwrap! (add-fixed balance-x dx-net-fees) ERR-MATH-CALL),
                            balance-y: (if (<= balance-y dy) u0 (unwrap! (sub-fixed balance-y dy) ERR-MATH-CALL)),
                            fee-balance-x: (unwrap! (add-fixed fee (get fee-balance-x pool)) ERR-MATH-CALL),
                            weight-x-t: weight-x
                        }
                    )
                )
            )
            (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
            (try! (contract-call? .alex-vault transfer-ft token-y-trait dy (as-contract tx-sender) tx-sender))
            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint))
    (begin
        ;; swap is allowed only until expiry
        (asserts! (< (* block-height ONE_8) expiry) already-ERR-EXPIRY)

        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)        
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (fee-rate-y (get fee-rate-y pool))  

                ;; fee = dy * fee-rate-y
                (fee (unwrap! (mul-up dy fee-rate-y) ERR-MATH-CALL))
                (dy-net-fees (if (<= dy fee) u0 (unwrap! (sub-fixed dy fee) ERR-MATH-CALL)))

                ;; swap triggers update of weight
                (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
                (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))            
                (dx (try! (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-x: (if (<= balance-x dx) u0 (unwrap! (sub-fixed balance-x dx) ERR-MATH-CALL)),
                            balance-y: (unwrap! (add-fixed balance-y dy-net-fees) ERR-MATH-CALL),
                            fee-balance-y: (unwrap! (add-fixed fee (get fee-balance-y pool)) ERR-MATH-CALL),
                            weight-x-t: weight-x
                        }
                    )
                )
            )
            (try! (contract-call? .alex-vault transfer-ft token-x-trait dx (as-contract tx-sender) tx-sender))
            (unwrap! (contract-call? token-y-trait transfer dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED)
            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
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
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (try! (contract-call? .alex-vault transfer-ft token-x-trait fee-x (as-contract tx-sender) tx-sender))
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-x .token-usda) 
                            fee-x 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda token-x-trait u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token-x-trait u50000000 u50000000 fee-x)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y token-x-trait .token-usda u50000000 u50000000 fee-x)))
                            )                            
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                ;; (unwrap! (contract-call? token-y-trait transfer fee-y .alex-vault tx-sender none) ERR-TRANSFER-Y-FAILED)
                (try! (contract-call? .alex-vault transfer-ft token-y-trait fee-y (as-contract tx-sender) tx-sender))
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-y .token-usda) 
                            fee-y 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda token-y-trait u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda token-y-trait u50000000 u50000000 fee-y)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y token-y-trait .token-usda u50000000 u50000000 fee-y)))
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

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL-ERR))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
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
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))
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
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))            
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
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))          
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
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))                         
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
            (weight-y (unwrap! (sub-fixed ONE_8 weight-x) ERR-MATH-CALL))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
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
