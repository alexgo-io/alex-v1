(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; fixed-weight-pool
;; Fixed Weight Pool is an uniswap-like on-chain AMM based on Balancer
;;

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant not-authorized-err (err u1000))
(define-constant invalid-pool-err (err u2001))
(define-constant no-liquidity-err (err u2002))
(define-constant invalid-liquidity-err (err u2003))
(define-constant transfer-x-failed-err (err u3001))
(define-constant transfer-y-failed-err (err u3002))
(define-constant pool-already-exists-err (err u2000))
(define-constant too-many-pools-err (err u2004))
(define-constant percent-greater-than-one (err u5000))
(define-constant invalid-balance-err (err u2008))
(define-constant invalid-token-err (err u2007))
(define-constant no-fee-x-err (err u2005))
(define-constant no-fee-y-err (err u2006))
(define-constant weighted-equation-call-err (err u2009))
(define-constant math-call-err (err u2010))
(define-constant internal-function-call-err (err u1001))
(define-constant get-oracle-price-fail-err (err u7000))

(define-constant alex-symbol "alex")
(define-constant reserve-usdc-symbol "usdc")
(define-constant oracle-src "nothing")

;; data maps and vars
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal,
    token-y: principal,
    weight-x: uint,
    weight-y: uint
  }
)

(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal,
    weight-x: uint,
    weight-y: uint
  }
  {
    total-supply: uint,
    balance-x: uint,
    balance-y: uint,
    fee-balance-x: uint,
    fee-balance-y: uint,
    fee-to-address: principal,
    pool-token: principal,
    fee-rate-x: uint,
    fee-rate-y: uint,
    token-x-symbol: (string-ascii 32),
    token-y-symbol: (string-ascii 32)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; implement trait-pool
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

;; additional functions
(define-read-only (get-pool-details (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (ok pool)
   )
)

;; get overall balances for the pair
(define-read-only (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
  (let
    (
      (token-x (contract-of token-x-trait))
      (token-y (contract-of token-y-trait))
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y  }) invalid-pool-err))
    )
    (ok {balance-x: (get balance-x pool), balance-y: (get balance-y pool)})
  )
)

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (multisig-vote <multisig-trait>) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool-id (+ (var-get pool-count) u1))
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of multisig-vote),
                pool-token: (contract-of the-pool-token),
                fee-rate-x: u0,
                fee-rate-y: u0,
                token-x-symbol: (try! (contract-call? token-x-trait get-symbol)),
                token-y-symbol: (try! (contract-call? token-y-trait get-symbol))
            })
       )
        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, weight-x: weight-y, weight-y: weight-x }))
           )
            pool-already-exists-err
       )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)
        ;; Deployer should inject the initial coins to the pool
        (try! (add-to-position token-x-trait token-y-trait weight-x weight-y the-pool-token dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (dx uint) (dy uint))
    (begin
        (asserts! (and (> dx u0) (> dy u0)) invalid-liquidity-err)

        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-supply (get total-supply pool))
                (add-data (unwrap! (get-token-given-position token-x-trait token-y-trait weight-x weight-y dx dy) internal-function-call-err))
                (new-supply (get token add-data))
                (new-dy (get dy add-data))
                (pool-updated (merge pool {
                    total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                    balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed balance-x dx) math-call-err),
                    balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed balance-y new-dy) math-call-err)
                }))
            )

            (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
            (unwrap! (contract-call? token-y-trait transfer new-dy tx-sender .alex-vault none) transfer-y-failed-err)

            ;; mint pool token and send to tx-sender
            (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
            (try! (contract-call? the-pool-token mint tx-sender new-supply))
            
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {supply: new-supply, dx: dx, dy: new-dy})
        )
    )
)    

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (percent uint))
    (if (<= percent ONE_8)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) math-call-err)))
                (total-supply (get total-supply pool))
                (reduce-data (unwrap! (get-position-given-burn token-x-trait token-y-trait weight-x weight-y shares) internal-function-call-err))
                (dx (get dx reduce-data))
                (dy (get dy reduce-data))
                (pool-updated (merge pool {
                    total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                    balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx) math-call-err),
                    balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy) math-call-err)
                    })
                )
            )

            (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
            (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

            (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)

            (try! (contract-call? the-pool-token burn tx-sender shares))
            ;;(try! (contract-call? .alex-multisig-registry burn-token new-supply tx-sender))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
        percent-greater-than-one
    )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint))    
    (begin
        (asserts! (> dx u0) invalid-liquidity-err) 
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)        
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (fee-rate-x (get fee-rate-x pool))

                ;; fee = dx * fee-rate-x
                (fee (unwrap! (contract-call? .math-fixed-point mul-up dx fee-rate-x) math-call-err))
                (dx-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dx fee) math-call-err))
    
                (dy (try! (get-y-given-x token-x-trait token-y-trait weight-x weight-y dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                        balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-x pool) dx-net-fees) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy) math-call-err),
                        fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)) math-call-err)
                        }
                    )
                )
            )
        
            (unwrap! (contract-call? token-x-trait transfer dx tx-sender .alex-vault none) transfer-x-failed-err)
            (unwrap! (contract-call? token-y-trait transfer dy .alex-vault tx-sender none) transfer-y-failed-err)

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dy uint))
    (begin
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (asserts! (> dy u0) invalid-liquidity-err)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (fee-rate-y (get fee-rate-y pool))

                ;; fee = dy * fee-rate-y
                (fee (unwrap! (contract-call? .math-fixed-point mul-up dy fee-rate-y) math-call-err))
                (dy-net-fees (unwrap! (contract-call? .math-fixed-point sub-fixed dy fee) math-call-err))

                (dx (try! (get-x-given-y token-x-trait token-y-trait weight-x weight-y dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                        balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx) math-call-err),
                        balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-y pool) dy-net-fees) math-call-err),
                        fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)) math-call-err)
                        }
                    )
                )
            )
        
            (unwrap! (contract-call? token-x-trait transfer dx .alex-vault tx-sender none) transfer-x-failed-err)
            (unwrap! (contract-call? token-y-trait transfer dy tx-sender .alex-vault none) transfer-y-failed-err)

            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

(define-read-only (get-fee-rate-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (ok (get fee-rate-x pool))
    )
)

(define-read-only (get-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (ok (get fee-rate-y pool))
    )
)

(define-public (set-fee-rate-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (fee-rate-x uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y 
            }
            (merge pool { fee-rate-x: fee-rate-x })
        )
        (ok true)     
    )
)

(define-public (set-fee-rate-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (fee-rate-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y 
            }
            (merge pool { fee-rate-y: fee-rate-y })
        )
        (ok true)     
    )
)

;; return principal
(define-read-only (get-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))                
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))              
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        )        
        (ok {fee-balance-x: (get fee-balance-x pool), fee-balance-y: (get fee-balance-y pool)})
    )
)

;; Returns the fee of current x and y and make balance to 0.
(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))
            (fee-x-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-x rebate-rate) math-call-err))
            (fee-y-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-y rebate-rate) math-call-err))
            (fee-x-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-x fee-x-rebate) math-call-err))
            (fee-y-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-y fee-y-rebate) math-call-err))
        )

        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (unwrap! (contract-call? token-x-trait transfer fee-x .alex-vault tx-sender none) transfer-x-failed-err)
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-x .token-usda) 
                            fee-x 
                            (get dx (try! (swap-y-for-x .token-usda token-x-trait u50000000 u50000000 fee-x)))
                        )
                    )
                )
            )
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (unwrap! (contract-call? token-y-trait transfer fee-y .alex-vault tx-sender none) transfer-y-failed-err)
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token-y .token-usda) 
                            fee-y 
                            (get dx (try! (swap-y-for-x .token-usda token-y-trait u50000000 u50000000 fee-y)))
                        )
                    )
                )
            )
        )    

        (map-set pools-data-map
        { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y}
        (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok {fee-x: fee-x, fee-y: fee-y})
    )
)

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dy uint)) 
    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (price uint))

    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint) (dy uint))
    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )

)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (token uint))

    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))        
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply token)
    )
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (token uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply token)
    )
)