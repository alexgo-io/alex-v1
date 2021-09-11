(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait multisig-trait .trait-multisig-vote.multisig-vote-trait)

;; yield-token-pool
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places
(define-constant MAX_T u85000000) ;; to avoid numerical error

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
(define-constant internal-function-call-err (err u1001))
(define-constant math-call-err (err u4003))
(define-constant get-expiry-fail-err (err u2013))
(define-constant aytoken-equation-call-err (err u2014))
(define-constant dy-bigger-than-available-err (err u2016))
(define-constant not-authorized-err (err u1000))
(define-constant get-oracle-price-fail-err (err u7000))
(define-constant get-symbol-fail-err (err u6000))

;; TODO: need to be defined properly
(define-constant oracle-src "nothing")

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

(define-data-var max-expiry uint u0)

(define-read-only (get-max-expiry)
    (ok (var-get max-expiry))
)

(define-read-only (get-t (expiry uint) (listed uint))
    (let
        (
            (now (* block-height ONE_8)) ;; convert current block-height to fixed point integer
            (t (unwrap! (contract-call? .math-fixed-point div-down
                (unwrap! (contract-call? .math-fixed-point sub-fixed expiry now) math-call-err) 
                (unwrap! (contract-call? .math-fixed-point sub-fixed (var-get max-expiry) listed) math-call-err)) math-call-err))
            (t-maxed (if (< t MAX_T) t MAX_T))
        )
        (asserts! (> (var-get max-expiry) expiry) invalid-expiry-err)
        (asserts! (> (var-get max-expiry) now) invalid-expiry-err)

        (ok t-maxed)
    )
)

(define-read-only (get-pool-count)
    (ok (var-get pool-count))
)

(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) invalid-pool-err))
)

(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; additional functions
(define-read-only (get-pool-details (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))            
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
       )
        (ok pool)
    )
)

(define-read-only (get-pool-value-in-token (the-aytoken <yield-token-trait>) (the-token <ft-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (balance-token (get balance-token pool))
            (balance-aytoken (get balance-aytoken pool))
            (token-symbol (get token-symbol pool))         
            (token-price (unwrap! (contract-call? .open-oracle get-price oracle-src token-symbol) get-oracle-price-fail-err))
            (balance (unwrap! (contract-call? .math-fixed-point add-fixed balance-token balance-aytoken) math-call-err))
        )

        (contract-call? .math-fixed-point mul-up balance token-price)
    )
)

;; note yield is not annualised
;; b_y = balance-aytoken
;; b_x = balance-token
;; yield = ln(b_y/b_x)
(define-read-only (get-yield (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (get expiry pool))
            (balance-token (get balance-token pool))            
            (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))
            (base (unwrap! (contract-call? .math-fixed-point div-down balance-aytoken balance-token) math-call-err))
        )

        (asserts! (>= balance-aytoken balance-token) invalid-balance-err)

        (ok (to-uint (unwrap! (contract-call? .math-log-exp ln-fixed (to-int base)) math-call-err)))
    )
)

;; get-price
;; b_y = balance-aytoken
;; b_x = balance-token
;; price = (b_y / b_x) ^ t
(define-read-only (get-price (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (get expiry pool))
            (listed (get listed pool))
            (balance-token (get balance-token pool)) 
            (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))
            (base (unwrap! (contract-call? .math-fixed-point div-down balance-aytoken balance-token) math-call-err))
            (t-value (try! (get-t expiry listed)))
        )
        (asserts! (> balance-aytoken balance-token) invalid-balance-err)
        (contract-call? .math-fixed-point pow-up base t-value)        
    )
)

(define-public (create-pool (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (multisig-vote <multisig-trait>) (dx uint) (dy uint)) 
    (let
        (
            (aytoken (contract-of the-aytoken))            
            (pool-id (+ (var-get pool-count) u1))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (now (* block-height ONE_8))
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
                token-symbol: (unwrap! (contract-call? the-token get-symbol) get-symbol-fail-err),
                expiry: (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err),
                listed: now          
            })
        )
        ;; create pool only if the correct pair
        (asserts! (is-eq (try! (contract-call? the-aytoken get-token)) (contract-of the-token)) invalid-pool-err)
        (asserts! (is-none (map-get? pools-data-map { aytoken: aytoken })) pool-already-exists-err)
        
        (map-set pools-map { pool-id: pool-id } { aytoken: aytoken })
        (map-set pools-data-map { aytoken: aytoken } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)

        ;; if ayToken added has a longer expiry than current max-expiry, update max-expiry (to expiry + one block).
        (var-set max-expiry (if (< (var-get max-expiry) expiry) (unwrap! (contract-call? .math-fixed-point add-fixed expiry ONE_8) math-call-err) (var-get max-expiry)))
        (try! (add-to-position the-aytoken the-token the-pool-token dx))

        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (dx uint))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (balance-token (get balance-token pool))            
            (balance-aytoken (get balance-aytoken pool))
            (balance-virtual (get balance-virtual pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap! (get-token-given-position the-aytoken dx) internal-function-call-err))
            (new-supply (get token add-data))
            (new-dy-act (get dy-act add-data))
            (new-dy-vir (get dy-vir add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed balance-token dx) math-call-err),
                balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed balance-aytoken new-dy-act) math-call-err),
                balance-virtual: (unwrap! (contract-call? .math-fixed-point add-fixed balance-virtual new-dy-vir) math-call-err)   
            }))
        )

        ;; dx must be greater than zero
        ;; at least one of dy must be greater than zero
        (asserts! (and (> dx u0) (or (> new-dy-act u0) (> new-dy-vir u0))) invalid-liquidity-err)

        ;; send x to vault
        ;;(asserts! (is-ok (contract-call? the-token transfer dx tx-sender .alex-vault none)) transfer-x-failed-err)
        (and (> dx u0) (unwrap! (contract-call? the-token transfer dx tx-sender .alex-vault none) transfer-x-failed-err))

        ;; send y to vault
        ;;(asserts! (is-ok (contract-call? the-aytoken transfer new-dy-act tx-sender .alex-vault none)) transfer-y-failed-err)
        (and (> new-dy-act u0) (unwrap! (contract-call? the-aytoken transfer new-dy-act tx-sender .alex-vault none) transfer-y-failed-err))
        
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        ;; Failure. 
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        ;;(try! (contract-call? .alex-multisig-registry mint-token the-pool-token new-supply tx-sender))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok {supply: new-supply, balance-token: dx, balance-aytoken: new-dy-act, balance-virtual: new-dy-vir})
   )
)    

(define-public (reduce-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (percent uint))
    (if (<= percent ONE_8)
        (let
            (
                (aytoken (contract-of the-aytoken))
                (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
                (balance-token (get balance-token pool))
                (balance-aytoken (get balance-aytoken pool))
                (balance-virtual (get balance-virtual pool))                
                (total-supply (get total-supply pool))
                (total-shares (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (unwrap! (contract-call? .math-fixed-point mul-down total-shares percent) math-call-err)))
                (reduce-data (unwrap! (get-position-given-burn the-aytoken shares) internal-function-call-err))
                (dx (get dx reduce-data))
                (dy-act (get dy-act reduce-data))
                (dy-vir (get dy-vir reduce-data))
                (pool-updated (merge pool {
                    total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                    balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-token dx) math-call-err),
                    balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-aytoken dy-act) math-call-err),                    
                    balance-virtual: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-virtual dy-vir) math-call-err),                    
                    })
                )
            )
            ;;(asserts! (is-ok (contract-call? the-token transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
            ;;(asserts! (is-ok (contract-call? the-aytoken transfer dy-act .alex-vault tx-sender none)) transfer-y-failed-err)
            (and (> dx u0) (unwrap! (contract-call? the-token transfer dx .alex-vault tx-sender none) transfer-x-failed-err))
            (and (> dy-act u0) (unwrap! (contract-call? the-aytoken transfer dy-act .alex-vault tx-sender none) transfer-y-failed-err))

            (map-set pools-data-map { aytoken: aytoken } pool-updated)
            (try! (contract-call? the-pool-token burn tx-sender shares))
            ;;(try! (contract-call? .alex-multisig-registry burn-token the-pool-token new-supply tx-sender))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy-act})
        )    
        percent-greater-than-one
    )    
)

(define-public (swap-x-for-y (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dx uint))
    
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (fee-rate-aytoken (get fee-rate-aytoken pool))

            ;; lambda ~= 1 - fee-rate-aytoken * yield
            (yield (try! (get-yield the-aytoken)))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-aytoken) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 fee-yield) math-call-err))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dx lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dx dx-net-fees) math-call-err))

            (dy (try! (get-y-given-x the-aytoken dx-net-fees)))

            (pool-updated
                (merge pool
                    {
                        balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-token pool) dx-net-fees) math-call-err),
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-aytoken pool) dy) math-call-err),
                        fee-balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-token pool) fee) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        (and (> dx u0) (unwrap! (contract-call? the-token transfer dx tx-sender .alex-vault none) transfer-x-failed-err))
        (and (> dy u0) (unwrap! (contract-call? the-aytoken transfer dy .alex-vault tx-sender none) transfer-y-failed-err))

        ;; post setting
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok {dx: dx-net-fees, dy: dy})
    )
)

(define-public (swap-y-for-x (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dy uint))

    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (fee-rate-token (get fee-rate-token pool))

            ;; lambda ~= 1 - fee-rate-token * yield
            (yield (try! (get-yield the-aytoken)))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-token) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 fee-yield) math-call-err))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dy lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-net-fees) math-call-err))

            ;;(dx (unwrap! (get-x-given-y the-aytoken dy-net-fees) internal-function-call-err))
            (dx (try! (get-x-given-y the-aytoken dy-net-fees)))

            (pool-updated
                (merge pool
                    {
                        balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-token pool) dx) math-call-err),                        
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) dy-net-fees) math-call-err),
                        fee-balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed (get fee-balance-aytoken pool) fee) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)
        ;;(asserts! (is-ok (contract-call? the-token transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
        ;;(asserts! (is-ok (contract-call? the-aytoken transfer dy tx-sender .alex-vault none)) transfer-y-failed-err)
        (and (> dx u0) (unwrap! (contract-call? the-token transfer dx .alex-vault tx-sender none) transfer-x-failed-err))
        (and (> dy u0) (unwrap! (contract-call? the-aytoken transfer dy tx-sender .alex-vault none) transfer-y-failed-err))

        (print dy)
        ;; post setting
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok {dx: dx, dy: dy-net-fees})
    )
)

(define-read-only (get-fee-rate-aytoken (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )
        (ok (get fee-rate-aytoken pool))
    )
)

(define-read-only (get-fee-rate-token (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )
        (ok (get fee-rate-token pool))
    )
)

(define-public (set-fee-rate-aytoken (the-aytoken <yield-token-trait>) (fee-rate-aytoken uint))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (map-set pools-data-map { aytoken: aytoken } (merge pool { fee-rate-aytoken: fee-rate-aytoken }))
        (ok true)
    
    )
)

(define-public (set-fee-rate-token (the-aytoken <yield-token-trait>) (fee-rate-token uint))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (map-set pools-data-map { aytoken: aytoken } (merge pool { fee-rate-token: fee-rate-token }))
        (ok true) 
    )
)

;; return principal
(define-read-only (get-fee-to-address (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))       
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )
        (ok (get fee-to-address pool))
    )
)

(define-read-only (get-fees (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))   
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
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
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-aytoken pool))
            (fee-y (get fee-balance-token pool))
            (rebate-rate (unwrap-panic (contract-call? .alex-reserve-pool get-rebate-rate)))
            (fee-x-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-x rebate-rate) math-call-err))
            (fee-y-rebate (unwrap! (contract-call? .math-fixed-point mul-down fee-y rebate-rate) math-call-err))
            (fee-x-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-x fee-x-rebate) math-call-err))
            (fee-y-net (unwrap! (contract-call? .math-fixed-point sub-fixed fee-y fee-y-rebate) math-call-err))            
        )
        
        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)

        (asserts! (is-eq contract-caller (get fee-to-address pool)) not-authorized-err)
        
        (and (> fee-x u0) 
            (and 
                ;; first transfer fee-x to tx-sender
                (unwrap! (contract-call? the-aytoken transfer fee-x .alex-vault tx-sender none) transfer-x-failed-err)
                ;; send fee-x to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq aytoken .token-usda) 
                            fee-x 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda the-aytoken u50000000 u50000000 fee-x)))
                        )
                    )
                )
            )
        )

        (and (> fee-y u0) 
            (and 
                ;; first transfer fee-y to tx-sender
                (unwrap! (contract-call? the-token transfer fee-y .alex-vault tx-sender none) transfer-y-failed-err)
                ;; send fee-y to reserve-pool to mint alex    
                (try! 
                    (contract-call? .alex-reserve-pool transfer-to-mint 
                        (if (is-eq token .token-usda) 
                            fee-y 
                            (get dx (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-usda the-token u50000000 u50000000 fee-y)))
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
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))    
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
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-y balance-token balance-aytoken normalized-expiry dy)
    )
)

(define-read-only (get-x-given-price (the-aytoken <yield-token-trait>) (price uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-price balance-token balance-aytoken normalized-expiry price)
    )
)

(define-read-only (get-x-given-yield (the-aytoken <yield-token-trait>) (yield uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) (get balance-virtual pool)) math-call-err))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-yield balance-token balance-aytoken normalized-expiry yield)
    )
)

(define-read-only (get-token-given-position (the-aytoken <yield-token-trait>) (dx uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed balance-actual balance-virtual) math-call-err))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (unwrap! (contract-call? .yield-token-equation get-token-given-position balance-token balance-aytoken normalized-expiry total-supply dx) aytoken-equation-call-err))
        (token (get token data))
        (dy (get dy data))
        (percent-act (unwrap! (contract-call? .math-fixed-point div-up balance-actual balance-aytoken) math-call-err))
        (dy-act (unwrap! (contract-call? .math-fixed-point mul-up dy percent-act) math-call-err))
        (dy-vir (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-act) math-call-err))
        )        
        (ok {token: token, dy-act: dy-act, dy-vir: dy-vir})
    )

)

(define-read-only (get-position-given-mint (the-aytoken <yield-token-trait>) (token uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed balance-actual balance-virtual) math-call-err))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (unwrap! (contract-call? .yield-token-equation get-position-given-mint balance-token balance-aytoken normalized-expiry total-supply token) aytoken-equation-call-err))   
        (dx (get dx data))
        (dy (get dy data))
        (percent-act (unwrap! (contract-call? .math-fixed-point div-up balance-actual balance-aytoken) math-call-err))
        (dy-act (unwrap! (contract-call? .math-fixed-point mul-up dy percent-act) math-call-err))
        (dy-vir (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-act) math-call-err))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: dy-vir})
    )
)

(define-read-only (get-position-given-burn (the-aytoken <yield-token-trait>) (token uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (get expiry pool))
        (listed (get listed pool))
        (normalized-expiry (try! (get-t expiry listed)))
        (balance-actual (get balance-aytoken pool))
        (balance-virtual (get balance-virtual pool))
        (balance-aytoken (unwrap! (contract-call? .math-fixed-point add-fixed balance-actual balance-virtual) math-call-err))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        (data (unwrap! (contract-call? .yield-token-equation get-position-given-burn balance-token balance-aytoken normalized-expiry total-supply token) aytoken-equation-call-err))   
        (dx (get dx data))
        (dy (get dy data))
        (percent-act (unwrap! (contract-call? .math-fixed-point div-up balance-actual balance-aytoken) math-call-err))
        (dy-act (unwrap! (contract-call? .math-fixed-point mul-up dy percent-act) math-call-err))
        (dy-vir (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-act) math-call-err))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: dy-vir})
    )
)