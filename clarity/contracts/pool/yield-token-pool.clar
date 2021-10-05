(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; yield-token-pool
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places
(define-constant MAX_T u85000000)

(define-constant ERR-INVALID-POOL-ERR (err u2001))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-X-FAILED (err u3001))
(define-constant ERR-TRANSFER-Y-FAILED (err u3002))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT_GREATER_THAN_ONE (err u5000))
(define-constant invalid-token-err (err u2007))
(define-constant ERR-NO-FEE (err u2005))
(define-constant ERR-NO-FEE-Y (err u2006))
(define-constant invalid-ERR-EXPIRY (err u2009))
(define-constant fixed-point-err (err 5014))
(define-constant ERR-MATH-CALL (err u4003))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))
(define-constant dy-bigger-than-available-err (err u2016))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-GET-ORACLE-PRICE-FAIL (err u7000))
(define-constant ERR-GET-SYMBOL-FAIL (err u6000))

;; TODO: need to be defined properly
(define-data-var contract-owner principal tx-sender)
(define-data-var oracle-src (string-ascii 32) "coingecko")

;; data maps and vars
(define-map pools-map
  { pool-id: uint }
  {
    aytoken: principal, ;; aytoken, dy
  }
)

(define-map pools-data-map
  {
    aytoken: principal    
  }
  {
    total-supply: uint,    
    balance-token: uint, ;; dx    
    balance-aytoken: uint, ;; dy_actual
    balance-virtual: uint, ;; dy_virtual
    fee-balance-token: uint,    
    fee-balance-aytoken: uint,
    fee-to-address: principal,
    pool-token: principal,
    fee-rate-token: uint,    
    fee-rate-aytoken: uint,
    token-symbol: (string-ascii 32),
    expiry: uint,
    listed: uint
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; 4 years based on 2102400 blocks per year (i.e. 15 secs per block)
(define-data-var max-expiry uint (unwrap-panic (scale-up u8409600))) 

(define-read-only (get-max-expiry)
    (ok (var-get max-expiry))
)

(define-public (set-max-expiry (new-max-expiry uint))
    (begin
       (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set max-expiry new-max-expiry)) 
    )
)

(define-read-only (get-oracle-src)
  (ok (var-get oracle-src))
)

(define-public (set-oracle-src (new-oracle-src (string-ascii 32)))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set oracle-src new-oracle-src))
  )
)

(define-read-only (get-t (expiry uint) (listed uint))
    (begin
        (asserts! (> (var-get max-expiry) expiry) invalid-ERR-EXPIRY)
        (asserts! (> (var-get max-expiry) (* block-height ONE_8)) invalid-ERR-EXPIRY)        
        (let
            (
                (t (unwrap! (div-down
                    (unwrap! (sub-fixed expiry (* block-height ONE_8)) ERR-MATH-CALL) 
                    (unwrap! (sub-fixed (var-get max-expiry) listed) ERR-MATH-CALL)) ERR-MATH-CALL))
            )
            (ok (if (< t MAX_T) t MAX_T)) ;; to avoid numerical error
        )
    )
)

(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) ERR-INVALID-POOL-ERR))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; additional functions
(define-read-only (get-pool-details (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))            
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
       )
        (ok pool)
    )
)

(define-read-only (get-pool-value-in-token (the-aytoken <yield-token-trait>) (the-token <ft-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
            (balance-token (get balance-token pool))
            (balance-aytoken (get balance-aytoken pool))
            (token-symbol (get token-symbol pool))         
            (token-price (unwrap! (contract-call? .open-oracle get-price (var-get oracle-src) token-symbol) ERR-GET-ORACLE-PRICE-FAIL))
            (balance (unwrap! (add-fixed balance-token balance-aytoken) ERR-MATH-CALL))
        )
        (mul-up balance token-price)
    )
)

;; note yield is not annualised
(define-read-only (get-yield (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
            (expiry (get expiry pool))
            (listed (get listed pool))
            (balance-token (get balance-token pool)) 
            (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
            (t-value (try! (get-t expiry listed)))
        )
        (contract-call? .yield-token-equation get-yield balance-token balance-aytoken t-value)
    )
)

(define-read-only (get-price (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
            (expiry (get expiry pool))
            (listed (get listed pool))
            (balance-token (get balance-token pool)) 
            (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
            (t-value (try! (get-t expiry listed)))
        )
        (contract-call? .yield-token-equation get-price balance-token balance-aytoken t-value)
    )
)

(define-public (create-pool (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (multisig-vote <multisig-trait>) (dx uint) (dy uint)) 
    (begin
        ;; create pool only if the correct pair
        (asserts! (is-eq (try! (contract-call? the-aytoken get-token)) (contract-of the-token)) ERR-INVALID-POOL-ERR)
        (asserts! (is-none (map-get? pools-data-map { aytoken: (contract-of the-aytoken) })) ERR-POOL-ALREADY-EXISTS)    
        (let
            (
                (aytoken (contract-of the-aytoken))            
                (pool-id (+ (var-get pool-count) u1))
                (expiry (unwrap! (contract-call? the-aytoken get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
                (pool-data {
                    total-supply: u0,
                    balance-token: u0,                
                    balance-aytoken: u0,
                    balance-virtual: u0,
                    fee-balance-aytoken: u0,
                    fee-balance-token: u0,
                    fee-to-address: (contract-of multisig-vote),
                    pool-token: (contract-of the-pool-token),
                    fee-rate-aytoken: u0,
                    fee-rate-token: u0,
                    token-symbol: (unwrap! (contract-call? the-token get-symbol) ERR-GET-SYMBOL-FAIL),
                    expiry: (unwrap! (contract-call? the-aytoken get-expiry) ERR-GET-EXPIRY-FAIL-ERR),
                    listed: (* block-height ONE_8)          
                })
            )
        
            (map-set pools-map { pool-id: pool-id } { aytoken: aytoken })
            (map-set pools-data-map { aytoken: aytoken } pool-data)
        
            (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) ERR-TOO-MANY-POOLS))
            (var-set pool-count pool-id)

            ;; ;; if ayToken added has a longer expiry than current max-expiry, update max-expiry (to expiry + one block).
            ;; (var-set max-expiry (if (< (var-get max-expiry) expiry) (unwrap! (add-fixed expiry ONE_8) ERR-MATH-CALL) (var-get max-expiry)))
            (try! (add-to-position the-aytoken the-token the-pool-token dx))

            (print { object: "pool", action: "created", data: pool-data })
            (ok true)
        )
    )
)

(define-public (add-to-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (dx uint))
    (begin
        ;; dx must be greater than zero
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)    
        (let
            (
                (aytoken (contract-of the-aytoken))
                (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
                (balance-token (get balance-token pool))            
                (balance-aytoken (get balance-aytoken pool))
                (balance-virtual (get balance-virtual pool))
                (total-supply (get total-supply pool))
                (add-data (try! (get-token-given-position the-aytoken dx)))
                (new-supply (get token add-data))
                (new-dy-act (get dy-act add-data))
                (new-dy-vir (get dy-vir add-data))
                (pool-updated (merge pool {
                    total-supply: (unwrap! (add-fixed new-supply total-supply) ERR-MATH-CALL),
                    balance-token: (unwrap! (add-fixed balance-token dx) ERR-MATH-CALL),
                    balance-aytoken: (unwrap! (add-fixed balance-aytoken new-dy-act) ERR-MATH-CALL),
                    balance-virtual: (unwrap! (add-fixed balance-virtual new-dy-vir) ERR-MATH-CALL)   
                }))
            )
            ;; at least one of dy must be greater than zero            
            (asserts! (or (> new-dy-act u0) (> new-dy-vir u0)) ERR-INVALID-LIQUIDITY)
            ;; send x to vault
            (unwrap! (contract-call? the-token transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)
            ;; send y to vault
            (and (> new-dy-act u0) (unwrap! (contract-call? the-aytoken transfer new-dy-act tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED))
        
            ;; mint pool token and send to tx-sender
            (map-set pools-data-map { aytoken: aytoken } pool-updated)    
            (try! (contract-call? the-pool-token mint tx-sender new-supply))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {supply: new-supply, balance-token: dx, balance-aytoken: new-dy-act, balance-virtual: new-dy-vir})
        )
    )
)    

(define-public (reduce-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT_GREATER_THAN_ONE)
        (let
            (
                (aytoken (contract-of the-aytoken))
                (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
                (balance-token (get balance-token pool))
                (balance-aytoken (get balance-aytoken pool))
                (balance-virtual (get balance-virtual pool))                
                (total-supply (get total-supply pool))
                (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (mul-down total-shares percent) ERR-MATH-CALL)))
                (reduce-data (try! (get-position-given-burn the-aytoken shares)))
                (dx (get dx reduce-data))
                (dy-act (get dy-act reduce-data))
                (dy-vir (get dy-vir reduce-data))
                (pool-updated (merge pool {
                    total-supply: (if (<= total-supply shares) u0 (unwrap! (sub-fixed total-supply shares) ERR-MATH-CALL)),
                    balance-token: (if (<= balance-token dx) u0 (unwrap! (sub-fixed balance-token dx) ERR-MATH-CALL)),
                    balance-aytoken: (if (<= balance-aytoken dy-act) u0 (unwrap! (sub-fixed balance-aytoken dy-act) ERR-MATH-CALL)),
                    balance-virtual: (if (<= balance-virtual dy-vir) u0 (unwrap! (sub-fixed balance-virtual dy-vir) ERR-MATH-CALL))
                    })
                )
            )

            (and (> dx u0) (try! (contract-call? .alex-vault transfer-ft the-token dx (as-contract tx-sender) tx-sender)))
            (and (> dy-act u0) (try! (contract-call? .alex-vault transfer-yield the-aytoken dy-act (as-contract tx-sender) tx-sender)))

            (map-set pools-data-map { aytoken: aytoken } pool-updated)
            (try! (contract-call? the-pool-token burn tx-sender shares))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy-act})
        )    
    )    
)

(define-public (swap-x-for-y (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dx uint))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (aytoken (contract-of the-aytoken))
                (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
                (expiry (unwrap! (contract-call? the-aytoken get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
                (fee-rate-aytoken (get fee-rate-aytoken pool))
                (balance-token (get balance-token pool))
                (balance-aytoken (get balance-aytoken pool))
                (fee-balance-token (get fee-balance-token pool))

                ;; lambda ~= 1 - fee-rate-aytoken * yield
                (yield (try! (get-yield the-aytoken)))
                (fee-yield (unwrap! (mul-down yield fee-rate-aytoken) ERR-MATH-CALL))
                (lambda (if (<= ONE_8 fee-yield) u0 (unwrap! (sub-fixed ONE_8 fee-yield) ERR-MATH-CALL)))
                (dx-net-fees (unwrap! (mul-down dx lambda) ERR-MATH-CALL))
                (fee (if (<= dx dx-net-fees) u0 (unwrap! (sub-fixed dx dx-net-fees) ERR-MATH-CALL)))

                (dy (try! (get-y-given-x the-aytoken dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-token: (unwrap! (add-fixed balance-token dx-net-fees) ERR-MATH-CALL),
                            balance-aytoken: (if (<= balance-aytoken dy) u0 (unwrap! (sub-fixed balance-aytoken dy) ERR-MATH-CALL)),
                            fee-balance-token: (unwrap! (add-fixed fee-balance-token fee) ERR-MATH-CALL)
                        }
                    )
                )
            )
            ;; TODO : Check whether dy or dx value is valid  
            ;; (asserts! (< min-dy dy) too-much-slippage-err)
            (and (> dx u0) (unwrap! (contract-call? the-token transfer dx tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED))
            (and (> dy u0) (try! (contract-call? .alex-vault transfer-yield the-aytoken dy (as-contract tx-sender) tx-sender)))

            ;; post setting
            (map-set pools-data-map { aytoken: aytoken } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

(define-public (swap-y-for-x (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dy uint))
    (begin
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (aytoken (contract-of the-aytoken))
                (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
                (fee-rate-token (get fee-rate-token pool))
                (balance-token (get balance-token pool))
                (balance-aytoken (get balance-aytoken pool))
                (fee-balance-aytoken (get fee-balance-aytoken pool))

                ;; lambda ~= 1 - fee-rate-token * yield
                (yield (try! (get-yield the-aytoken)))
                (fee-yield (unwrap! (mul-down yield fee-rate-token) ERR-MATH-CALL))
                (lambda (if (<= ONE_8 fee-yield) u0 (unwrap! (sub-fixed ONE_8 fee-yield) ERR-MATH-CALL)))
                (dy-net-fees (unwrap! (mul-down dy lambda) ERR-MATH-CALL))
                (fee (if (<= dy dy-net-fees) u0 (unwrap! (sub-fixed dy dy-net-fees) ERR-MATH-CALL)))
                (dx (try! (get-x-given-y the-aytoken dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-token: (if (<= balance-token dx) u0 (unwrap! (sub-fixed balance-token dx) ERR-MATH-CALL)),
                            balance-aytoken: (unwrap! (add-fixed balance-aytoken dy-net-fees) ERR-MATH-CALL),
                            fee-balance-aytoken: (unwrap! (add-fixed fee-balance-aytoken fee) ERR-MATH-CALL)
                        }
                    )
                )
            )
            ;; TODO : Check whether dy or dx value is valid  
            ;; (asserts! (< min-dy dy) too-much-slippage-err)

            (and (> dx u0) (try! (contract-call? .alex-vault transfer-ft the-token dx (as-contract tx-sender) tx-sender)))
            (and (> dy u0) (unwrap! (contract-call? the-aytoken transfer dy tx-sender .alex-vault none) ERR-TRANSFER-Y-FAILED))

            (print dy)
            ;; post setting
            (map-set pools-data-map { aytoken: aytoken } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

(define-read-only (get-fee-rate-aytoken (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-aytoken pool))
    )
)

(define-read-only (get-fee-rate-token (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-rate-token pool))
    )
)

(define-public (set-fee-rate-aytoken (the-aytoken <yield-token-trait>) (fee-rate-aytoken uint))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map { aytoken: aytoken } (merge pool { fee-rate-aytoken: fee-rate-aytoken }))
        (ok true)
    
    )
)

(define-public (set-fee-rate-token (the-aytoken <yield-token-trait>) (fee-rate-token uint))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map { aytoken: aytoken } (merge pool { fee-rate-token: fee-rate-token }))
        (ok true) 
    )
)

;; return principal
(define-read-only (get-fee-to-address (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))       
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))   
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        )
        (ok {fee-balance-aytoken: (get fee-balance-aytoken pool), fee-balance-token: (get fee-balance-token pool)})
    )
)

;; Returns the fee of current x and y and make balance to 0.
(define-public (collect-fees (the-aytoken <ft-trait>) (the-token <ft-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (token (contract-of the-token))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-aytoken pool))
            (fee-y (get fee-balance-token pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))        
        )
        
        (asserts! (is-eq contract-caller (get fee-to-address pool)) ERR-NOT-AUTHORIZED)
        
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (try! (contract-call? .alex-vault transfer-ft the-aytoken fee-x (as-contract tx-sender) tx-sender))
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq aytoken .token-usda) 
                            fee-x 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda the-aytoken u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda the-aytoken u50000000 u50000000 fee-x)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y the-aytoken .token-usda u50000000 u50000000 fee-x)))
                            )                            
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (try! (contract-call? .alex-vault transfer-ft the-token fee-y (as-contract tx-sender) tx-sender))
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token .token-usda) 
                            fee-y 
                            (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-usda the-token u50000000 u50000000))
                                (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda the-token u50000000 u50000000 fee-y)))
                                (get dy (try! (contract-call? .fixed-weight-pool swap-x-for-y the-token .token-usda u50000000 u50000000 fee-y)))
                            )
                        )
                    )
                )
            )
        )         

        (map-set pools-data-map
            { aytoken: aytoken}
            (merge pool { fee-balance-aytoken: u0, fee-balance-token: u0 })
        )
        (ok {fee-x: fee-x, fee-y: fee-y})
    )
)

(define-read-only (get-y-given-x (the-aytoken <yield-token-trait>) (dx uint))
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))    
        (balance-token (get balance-token pool))
        (dy (try! (contract-call? .yield-token-equation get-y-given-x balance-token balance-aytoken normalized-expiry dx)))
        )
        (asserts! (> (get balance-aytoken pool) dy) dy-bigger-than-available-err)
        (ok dy)        
    )
)

(define-read-only (get-x-given-y (the-aytoken <yield-token-trait>) (dy uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-y balance-token balance-aytoken normalized-expiry dy)
    )
)

(define-read-only (get-x-given-price (the-aytoken <yield-token-trait>) (price uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-price balance-token balance-aytoken normalized-expiry price)
    )
)

(define-read-only (get-y-given-price (the-aytoken <yield-token-trait>) (price uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-y-given-price balance-token balance-aytoken normalized-expiry price)
    )
)

(define-read-only (get-x-given-yield (the-aytoken <yield-token-trait>) (yield uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-yield balance-token balance-aytoken normalized-expiry yield)
    )
)

(define-read-only (get-y-given-yield (the-aytoken <yield-token-trait>) (yield uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (add-fixed (get balance-aytoken pool) (get balance-virtual pool)) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-y-given-yield balance-token balance-aytoken normalized-expiry yield)
    )
)

(define-read-only (get-token-given-position (the-aytoken <yield-token-trait>) (dx uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (add-fixed balance-actual balance-virtual) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (try! (contract-call? .yield-token-equation get-token-given-position balance-token balance-aytoken normalized-expiry total-supply dx)))
        (token (get token data))
        (dy (get dy data))
        (percent-act (if (is-eq balance-aytoken u0) u0 (unwrap! (div-up balance-actual balance-aytoken) ERR-MATH-CALL)))
        (dy-act (if (is-eq token dy) u0 (unwrap! (mul-down dy percent-act) ERR-MATH-CALL)))
        (dy-vir (if (is-eq token dy) token (if (<= dy dy-act) u0 (unwrap! (sub-fixed dy dy-act) ERR-MATH-CALL))))
        )        
        (ok {token: token, dy-act: dy-act, dy-vir: dy-vir})
    )

)

(define-read-only (get-position-given-mint (the-aytoken <yield-token-trait>) (token uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (add-fixed balance-actual balance-virtual) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (try! (contract-call? .yield-token-equation get-position-given-mint balance-token balance-aytoken normalized-expiry total-supply token)))   
        (dx (get dx data))
        (dy (get dy data))
        (percent-act (unwrap! (div-up balance-actual balance-aytoken) ERR-MATH-CALL))
        (dy-act (unwrap! (mul-up dy percent-act) ERR-MATH-CALL))
        (dy-vir (if (<= dy dy-act) u0 (unwrap! (sub-fixed dy dy-act) ERR-MATH-CALL)))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: dy-vir})
    )
)

(define-read-only (get-position-given-burn (the-aytoken <yield-token-trait>) (token uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) ERR-INVALID-POOL-ERR))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (add-fixed balance-actual balance-virtual) ERR-MATH-CALL))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (try! (contract-call? .yield-token-equation get-position-given-burn balance-token balance-aytoken normalized-expiry total-supply token)))   
        (dx (get dx data))
        (dy (get dy data))
        (percent-act (unwrap! (div-up balance-actual balance-aytoken) ERR-MATH-CALL))
        (dy-act (unwrap! (mul-up dy percent-act) ERR-MATH-CALL))
        (dy-vir (if (<= dy dy-act) u0 (unwrap! (sub-fixed dy dy-act) ERR-MATH-CALL)))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: dy-vir})
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
