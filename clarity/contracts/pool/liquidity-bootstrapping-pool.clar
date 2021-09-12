(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; liquidity-bootstrapping-pool

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant not-authorized-err (err u1000))
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
(define-constant already-expiry-err (err u2010))
(define-constant weighted-equation-call-err (err u2009))
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (add-data (try! (get-token-given-position token-x-trait token-y-trait expiry dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx) math-call-err),
                balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y new-dy) math-call-err)
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
        (unwrap! (contract-call? token-y-trait transfer new-dy tx-sender .alex-vault none) transfer-y-failed-err)
        
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
        (asserts! (is-some pool) invalid-pool-err)
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
        (asserts! (is-some pool) invalid-pool-err)
        (ok pool)
    )
)

(define-read-only (get-weight-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))                  
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x-0 (get weight-x-0 pool))
            (weight-x-1 (get weight-x-1 pool))
            (listed (get listed pool))
            (now (* block-height ONE_8))

            ;; weight-t = weight-x-0 - (block-height - listed) * (weight-x-0 - weight-x-1) / (expiry - listed)
            (now-to-listed (unwrap! (contract-call? .math-fixed-point sub-fixed now listed) math-call-err))
            (expiry-to-listed (unwrap! (contract-call? .math-fixed-point sub-fixed expiry listed) math-call-err))
            (weight-diff (unwrap! (contract-call? .math-fixed-point sub-fixed weight-x-0 weight-x-1) math-call-err))
            (time-ratio (unwrap! (contract-call? .math-fixed-point div-down now-to-listed expiry-to-listed) math-call-err))
            (weight-change (unwrap! (contract-call? .math-fixed-point mul-down weight-diff time-ratio) math-call-err))
            (weight-t (unwrap! (contract-call? .math-fixed-point sub-fixed weight-x-0 weight-change) math-call-err))     
        )

        (asserts! (< now expiry) already-expiry-err)

        (ok weight-t)
    )
)

;; get overall balances for the pair
(define-read-only (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
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
            pool-already-exists-err
        )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, expiry: expiry })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
            (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) math-call-err)))
            (total-supply (get total-supply pool))     
            (reduce-data (try! (get-position-given-burn token-x-trait token-y-trait expiry shares)))
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
        (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
        (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))       
            (fee-rate-x (get fee-rate-x pool))
            (now (* block-height ONE_8))

            ;; fee = dx * fee-rate-x
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dx fee-rate-x) math-call-err))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx fee) math-call-err))

            ;; swap triggers update of weight
            (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
            (dy (try! (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx-net-fees)))                    

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx-net-fees) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-y dy) math-call-err),
                        fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)) math-call-err),
                        weight-x-t: weight-x
                    }
                )
            )
        )

        ;; swap is allowed only until expiry
        (asserts! (< now expiry) already-expiry-err)
        
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
        (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (fee-rate-y (get fee-rate-y pool))  
            (now (* block-height ONE_8))

            ;; fee = dy * fee-rate-y
            (fee (unwrap! (contract-call? .math-fixed-point mul-up dy fee-rate-y) math-call-err))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy fee) math-call-err))

            ;; swap triggers update of weight
            (weight-x (try! (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))            
            (dx (try! (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy-net-fees)))

            (pool-updated
                (merge pool
                    {
                        balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-x dx) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y dy-net-fees) math-call-err),
                        fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)) math-call-err),
                        weight-x-t: weight-x
                    }
                )
            )
        )

        ;; swap is allowed only until expiry
        (asserts! (< now expiry) already-expiry-err)

        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
        (unwrap! (contract-call? token-y-trait transfer dy tx-sender .alex-vault none) transfer-y-failed-err)

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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok (get fee-rate-x pool))
    )
)

(define-read-only (get-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
        )
        (ok (get fee-rate-y pool))
    )
)

(define-public (set-fee-rate-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (fee-rate-x uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
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

(define-public (set-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (fee-rate-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
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

(define-read-only (get-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))                
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))
            (fee-x-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-x rebate-rate) math-call-err))
            (fee-y-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-y rebate-rate) math-call-err))
            (fee-x-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-x fee-x-rebate) math-call-err))
            (fee-y-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-y fee-y-rebate) math-call-err))                 
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (unwrap! (contract-call? token-x-trait transfer fee-x .alex-vault tx-sender none) transfer-x-failed-err)
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
                (unwrap! (contract-call? token-y-trait transfer fee-y .alex-vault tx-sender none) transfer-y-failed-err)
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
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))            
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))          
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))                         
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x) math-call-err))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)