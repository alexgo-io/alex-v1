(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)

;; yield-token-pool
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

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
(define-constant invalid-expiry-err (err u2009))
(define-constant fixed-point-err (err 5014))
(define-constant internal-function-call-err (err u2011))
(define-constant math-call-err (err u2010))
(define-constant get-expiry-fail-err (err u2013))
(define-constant yield-token-equation-call-err (err u2014))
;; data maps and vars
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal, ;; yield-token
  }
)

(define-map pools-data-map
  {
    token-x: principal    
  }
  {
    expiry: uint,
    token-y: principal,  
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

(define-data-var max-expiry uint u0)

(define-read-only (get-max-expiry)
    (ok (var-get max-expiry))
)

(define-read-only (get-t (expiry uint))
    (let
        (
            ;;(now (unwrap! (contract-call? .math-fixed-point mul-down block-height ONE_8) fixed-point-err)) ;; convert current block-height to fixed point integer
            (now (unwrap! (contract-call? .math-fixed-point mul-down block-height ONE_8) math-call-err)) ;; convert current block-height to fixed point integer
        )
        (asserts! (> (var-get max-expiry) expiry) invalid-expiry-err)
        (asserts! (> (var-get max-expiry) now) invalid-expiry-err)

        ;;(ok (unwrap! (contract-call? .math-fixed-point div-down 
        ;;        (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) fixed-point-err) 
        ;;        (unwrap! (contract-call? .math-fixed-point sub-fixed (var-get max-expiry) now) fixed-point-err)) fixed-point-err))
        (ok (unwrap! (contract-call? .math-fixed-point div-down 
                (unwrap-panic (contract-call? .math-fixed-point sub-fixed expiry now)) 
                (unwrap-panic (contract-call? .math-fixed-point sub-fixed (var-get max-expiry) now))) math-call-err))                
    )
)

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
            invalid-pool-err
       )
   )
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; additional functions
(define-read-only (get-pool-details (token-x-trait <yield-token-trait>))
    (let 
        (
            (token-x (contract-of token-x-trait))            
            (pool (map-get? pools-data-map { token-x: token-x }))
       )
        (if (is-some pool)
            (ok pool)
            invalid-pool-err
       )
   )
)

;; get-price - input: token trait, expiry / output : price
(define-public (get-price (token-x-trait <yield-token-trait>) (expiry uint))
    
    (let
    (
    (token-x (contract-of token-x-trait))
    (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
    ;;(exp (get expiry pool)) I think it is safer to use below function.
    (exp (unwrap! (contract-call? token-x-trait get-expiry) get-expiry-fail-err))
    (balance-x (get balance-x pool))
    (balance-y (get balance-y pool))

    (base (unwrap! (contract-call? .math-fixed-point div-down balance-y balance-x) math-call-err))
    (t-value (unwrap! (get-t exp) internal-function-call-err))
    
    (price (unwrap! (contract-call? .math-fixed-point pow-up base t-value) math-call-err))
    (inverse-price (unwrap! (contract-call? .math-fixed-point div-down ONE_8 price) math-call-err))
    )
  
    (ok inverse-price)
    )
  
)

;; TODO: shouldn't the pool token be created as part of create-pool?
(define-public (create-pool (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))            
            (pool-id (+ (var-get pool-count) u1))
            (expiry (unwrap! (contract-call? token-x-trait get-expiry) get-expiry-fail-err))
            (pool-data {
                expiry: expiry,
                token-y: (unwrap! (contract-call? token-x-trait get-token) invalid-token-err),
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of the-pool-token),
                pool-token: (contract-of the-pool-token),
            })
        )
        (asserts! (is-none (map-get? pools-data-map { token-x: token-x })) pool-already-exists-err)

        (map-set pools-map { pool-id: pool-id } { token-x: token-x })
        (map-set pools-data-map { token-x: token-x } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)

        ;; if ayToken added has a longer expiry than current max-expiry, update max-expiry.
        (var-set max-expiry (if (< (var-get max-expiry) expiry) expiry (var-get max-expiry)))

        (try! (add-to-position token-x-trait token-y-trait the-pool-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
            (expiry (get expiry pool))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap! (contract-call? .yield-token-equation get-token-given-position balance-x balance-y expiry total-supply dx) yield-token-equation-call-err))
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
        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? token-y-trait transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { token-x: token-x } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
            (expiry (get expiry pool))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent) math-call-err))
            (total-supply (get total-supply pool))
            (reduce-data (unwrap! (contract-call? .yield-token-equation get-position-given-burn balance-x balance-y expiry total-supply shares) yield-token-equation-call-err))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx) math-call-err),
                balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy) math-call-err)
                })
           )
       )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>) (the-vault <vault-trait>) (dx uint))
    
    (let
    (
    (token-x (contract-of token-x-trait))
    (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
    (expiry (get expiry pool))
    (balance-x (get balance-x pool))
    (balance-y (get balance-y pool))

    ;; TODO : Platform Fee imposing logic required.
    ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
    ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
    (fee u0)
    
    (dy (unwrap! (get-y-given-x token-x-trait dx) internal-function-call-err))

    (pool-updated
      (merge pool
        {
          balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-x pool) dx) math-call-err),
          balance-y: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy) math-call-err),
          fee-balance-x: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-x pool)) math-call-err)
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
    (map-set pools-data-map { token-x: token-x } pool-updated)
    (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
    (ok (list dx dy))
  )
)

(define-public (swap-y-for-x (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>) (the-vault <vault-trait>) (dy uint))

    (let
    (
    (token-x (contract-of token-x-trait))
    (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
    (balance-x (get balance-x pool))
    (balance-y (get balance-y pool))

    ;; TODO : Platform Fee imposing logic required.
    ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
    ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
    (fee u0)
    (dx (unwrap! (get-x-given-y token-x-trait dy) internal-function-call-err))

    (pool-updated
      (merge pool
        {
          balance-x: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx) math-call-err),
          balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-y pool) dy) math-call-err),
          fee-balance-y: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-y pool)) math-call-err)
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
    (map-set pools-data-map { token-x: token-x } pool-updated)
    (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
    (ok (list dx dy))
  )
)

(define-public (set-fee-to-address (token-x-trait <yield-token-trait>) (address principal))
    (let 
        (
            (token-x (contract-of token-x-trait))    
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        )

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

        (map-set pools-data-map 
            { 
                token-x: token-x 
            }
            (merge pool { fee-to-address: address })
        )
        (ok true)     
    )
)

;; return principal
(define-read-only (get-fee-to-address (token-x-trait <yield-token-trait>))
    (let 
        (
            (token-x (contract-of token-x-trait))       
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (token-x-trait <yield-token-trait>))
    (let
        (
            (token-x (contract-of token-x-trait))   
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        )
        (ok (list (get fee-balance-x pool) (get fee-balance-y pool)))
    )
)

;; Returns the fee of current x and y and make balance to 0.
(define-public (collect-fees (token-x-trait <yield-token-trait>) (token-y-trait <ft-trait>))
    
    (let
        (
            (token-x (contract-of token-x-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
        )

        (asserts! (is-eq fee-x u0) no-fee-x-err)
        (asserts! (is-ok (contract-call? token-x-trait transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
        (asserts! (is-eq fee-y u0) no-fee-y-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

        (map-set pools-data-map
        { token-x: token-x}
        (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok (list fee-x fee-y)
        )
  )
)

(define-read-only (get-y-given-x (token-x-trait <yield-token-trait>) (dx uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .yield-token-equation get-y-given-x balance-x balance-y expiry dx)
    )
)

(define-read-only (get-x-given-y (token-x-trait <yield-token-trait>) (dy uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .yield-token-equation get-x-given-y balance-x balance-y expiry dy)
    )
)

(define-read-only (get-x-given-price (token-x-trait <yield-token-trait>) (price uint))

    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        )
        (contract-call? .yield-token-equation get-x-given-price balance-x balance-y expiry price)
    )
)

(define-read-only (get-token-given-position (token-x-trait <yield-token-trait>) (dx uint))

    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .yield-token-equation get-token-given-position balance-x balance-y expiry total-supply dx)
    )

)

(define-read-only (get-position-given-mint (token-x-trait <yield-token-trait>) (token uint))

    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))        
        )
        (contract-call? .yield-token-equation get-position-given-mint balance-x balance-y expiry total-supply token)
    )
)

(define-read-only (get-position-given-burn (token-x-trait <yield-token-trait>) (token uint))
    
    (let 
        (
        (token-x (contract-of token-x-trait))
        (pool (unwrap! (map-get? pools-data-map { token-x: token-x }) invalid-pool-err))
        (expiry (unwrap! (get-t (get expiry pool)) internal-function-call-err))
        (balance-x (get balance-x pool))
        (balance-y (get balance-y pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .yield-token-equation get-position-given-burn balance-x balance-y expiry total-supply token)
    )
)