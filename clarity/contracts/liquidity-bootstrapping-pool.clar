(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)

;; liquidity-bootstrapping-pool
;; <add a description here>

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
(define-constant already-expiry-err (err u2010))

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
    weight-x-1: uint       
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;
(define-private (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))            
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
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
        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? token-y-trait transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)
        ;; mint pool token-x and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
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
(define-read-only (get-pool-details (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }))
       )
        (if (is-some pool)
            (ok pool)
            (err invalid-pool-err)
       )
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
        )

        (asserts! (< block-height expiry) already-expiry-err)

        ;; weight-x-0 - (block-height - listed) * (weight-x-0 - weight-x-1) / expiry
        (ok (unwrap-panic (contract-call? .math-fixed-point sub-fixed 
                            weight-x-0 
                            (unwrap-panic (contract-call? .math-fixed-point div-down 
                                (unwrap-panic (contract-call? .math-fixed-point mul-down 
                                    (unwrap-panic (contract-call? .math-fixed-point sub-fixed block-height listed)) 
                                    (unwrap-panic (contract-call? .math-fixed-point sub-fixed weight-x-0 weight-x-1)))) 
                                expiry)))))
    )
)

;; get overall balances for the pair
(define-public (get-balances (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
  (let
    (
      (token-x (contract-of token-x-trait))
      (token-y (contract-of token-y-trait))
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) (err invalid-pool-err)))
    )
    (ok (list (get balance-x pool) (get balance-y pool)))
  )
)

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x-0 uint) (weight-x-1 uint) (expiry uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
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
                fee-to-address: (contract-of the-pool-token),
                pool-token: (contract-of the-pool-token),
                listed: block-height,
                weight-x-0: weight-x-0,
                weight-x-1: weight-x-1 
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
        (try! (add-to-position token-x-trait token-y-trait expiry the-pool-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)   

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap-panic (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent)))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
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
        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-vault <vault-trait>) (dx uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))       

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
    
            (dy (unwrap-panic (get-y-given-x token-x-trait token-y-trait expiry dx)))

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

        ;; TODO : Implement case by case logic of token-x here bt branching with if statement

        ;; Transfer 
        ;; when received token-x , token-x -> vault
        ;; when received token-y , token-y : vault  -> tx-sender

        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok (list dx dy))
    )
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (the-vault <vault-trait>) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))

            ;; TODO : Platform Fee imposing logic required.
            ;; (dx-with-fees (/ (* u997 dx) u1000)) ;; 0.3% fee for LPs 
            ;; (fee (/ (* u5 dx) u10000)) ;; 0.05% fee for protocol
            (fee u0)
            (dx (unwrap-panic (get-x-given-y token-x-trait token-y-trait expiry dy)))

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

        ;; TODO : Implement case by case logic of token-x here bt branching with if statement

        ;; Transfer 
        ;; when received token-x , token-x -> vault
        ;; when received token-y , token-y : vault  -> tx-sender

        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

        ;; post setting
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok (list dx dy))
  )
)

(define-public (set-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (address principal))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))            
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
        (ok (list (get fee-balance-x pool) (get fee-balance-y pool)))
    )
)

(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-x pool))
            (fee-y (get fee-balance-y pool))
        )

        (asserts! (is-eq fee-x u0) no-fee-x-err)
        (asserts! (is-ok (contract-call? token-x-trait transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
        (asserts! (is-eq fee-y u0) no-fee-y-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

        (map-set pools-data-map
            { token-x: token-x, token-y: token-y, expiry: expiry}
            (merge pool { fee-balance-x: u0, fee-balance-y: u0 })
        )
        (ok (list fee-x fee-y))
    )
)

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))
        )
        (contract-call? .weighted-equation get-y-given-x balance-x balance-y weight-x weight-y dx)        
    )
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))
        )
        (contract-call? .weighted-equation get-x-given-y balance-x balance-y weight-x weight-y dy)
    )
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (price uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))            
        )
        (contract-call? .weighted-equation get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint) (dy uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))          
        )
        (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)
    )
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))                         
        )
        (contract-call? .weighted-equation get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (shares uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait expiry)))
            (weight-y (unwrap-panic (contract-call? .math-fixed-point sub-fixed ONE_8 weight-x)))                  
        )
        (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)