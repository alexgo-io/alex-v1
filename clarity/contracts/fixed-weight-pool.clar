;;(impl-trait .trait-pool.pool-trait)

(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)

;; fixed-weight-pool
;; Fixed Weight Pool is an reference pool for which can be used as a template on future works. 
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant invalid-pool-err (err u201))
(define-constant no-liquidity-err (err u61))
(define-constant invalid-liquidity-err (err u202))
(define-constant transfer-x-failed-err (err u72))
(define-constant transfer-y-failed-err (err u73))
(define-constant pool-already-exists-err (err u69))
(define-constant too-many-pools-err (err u68))
(define-constant percent-greater-than-one (err u5))
(define-constant invalid-balance-err (err u6))
(define-constant invalid-token-err (err u7))
(define-constant no-fee-x-err (err u8))
(define-constant no-fee-y-err (err u9))

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
    pool-token: principal
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

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
            invalid-pool-err
       )
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
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }))
       )
        (if (is-some pool)
            (ok pool)
            invalid-pool-err
       )
   )
)

;; get overall balances for the pair
(define-public (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
  (let
    (
      (token-x (contract-of token-x-trait))
      (token-y (contract-of token-y-trait))
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y  }) (err invalid-pool-err)))
    )
    (ok (list (get balance-x pool) (get balance-y pool)))
  )
)

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
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
                fee-to-address: (contract-of the-pool-token),
                pool-token: (contract-of the-pool-token),
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
        (try! (add-to-position token-x-trait token-y-trait weight-x weight-y the-pool-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            ;;(pool-token (get pool-token pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap-panic (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point add-fixed new-supply (get total-supply pool))),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-y new-dy))
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? token-y-trait transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap-panic (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent)))
            (total-supply (get total-supply pool))
            (reduce-data (unwrap-panic (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point sub-fixed total-supply shares)),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy))
                })
           )
       )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-vault <vault-trait>) (dx uint))
    
    (let
    (
    (token-x (contract-of token-x-trait))
    (token-y (contract-of token-y-trait))
    (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
    (balance-x (get balance-x pool))
    (balance-y (get balance-y pool))


    ;; TODO : Platform Fee imposing logic required.
    ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
    ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
    (fee u0)
    
    (dy (unwrap-panic (get-y-given-x token-x-trait token-y-trait weight-x weight-y dx)))

    (pool-updated
      (merge pool
        {
          balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed (get balance-x pool) dx)),
          balance-y: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy)),
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


    (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
    (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

    ;; TODO : Burning STX at future if required. 

    ;; post setting
    (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
    (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
    (ok (list dx dy))
  )
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-vault <vault-trait>) (dy uint))

    (let
    (
    (token-x (contract-of token-x-trait))
    (token-y (contract-of token-y-trait))
    (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
    (balance-x (get balance-x pool))
    (balance-y (get balance-y pool))

    ;; TODO : Platform Fee imposing logic required.
    ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
    ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
    (fee u0)
    (dx (unwrap-panic (get-x-given-y token-x-trait token-y-trait weight-x weight-y dy)))

    (pool-updated
      (merge pool
        {
          balance-x: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx)),
          balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed (get balance-y pool) dy)),
          fee-balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)))
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


    (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
    (asserts! (is-ok (contract-call? token-y-trait transfer dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)

    ;; TODO : Burning STX at future if required. 

    ;; post setting
    (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
    (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
    (ok (list dx dy))
  )
)

(define-public (set-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (address principal))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
        )

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y 
            }
            (merge pool { fee-to-address: address })
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
        (ok (list (get fee-balance-x pool) (get fee-balance-y pool)))
    )
)

;; Returns the fee of current x and y and make balance to 0.
(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
        )

        (asserts! (is-eq fee-x u0) no-fee-x-err)
        (asserts! (is-ok (contract-call? token-x-trait transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
        (asserts! (is-eq fee-y u0) no-fee-y-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

        (map-set pools-data-map
        { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y}
        (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok (list fee-x fee-y)
        )
  )
)

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (token-y (contract-of token-y-trait))
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
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
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
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
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
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
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
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
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
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
        (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply token)
    )
)