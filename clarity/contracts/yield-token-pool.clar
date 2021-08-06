(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)

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
(define-constant internal-function-call-err (err u1001))
(define-constant math-call-err (err u2010))
(define-constant get-expiry-fail-err (err u2013))
(define-constant aytoken-equation-call-err (err u2014))

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
    fee-rate-aytoken: uint
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
            (now (unwrap! (contract-call? .math-fixed-point mul-down block-height ONE_8) math-call-err)) ;; convert current block-height to fixed point integer
        )
        (asserts! (> (var-get max-expiry) expiry) invalid-expiry-err)
        (asserts! (> (var-get max-expiry) now) invalid-expiry-err)

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
(define-read-only (get-pool-details (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))            
            (pool (map-get? pools-data-map { aytoken: aytoken }))
       )
        (if (is-some pool)
            (ok pool)
            invalid-pool-err
       )
   )
)

;; note yield is not annualised
;; b_y = balance-aytoken
;; b_x = balance-token
;; yield = ln(b_y/b_x)
(define-public (get-yield (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (balance-token (get balance-token pool))            
            (balance-aytoken (get balance-aytoken pool))
            (base (unwrap! (contract-call? .math-fixed-point div-down balance-aytoken balance-token) math-call-err))
        )

        (asserts! (> balance-aytoken balance-token) invalid-balance-err)

        (ok (to-uint (unwrap! (contract-call? .math-log-exp ln-fixed (to-int base)) math-call-err)))
    )
)

;; get-price
;; b_y = balance-aytoken
;; b_x = balance-token
;; price = (b_y / b_x) ^ t
(define-public (get-price (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            ;;(exp (get expiry pool)) I think it is safer to use below function.
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (balance-token (get balance-token pool))            
            (balance-aytoken (get balance-aytoken pool))

            (base (unwrap! (contract-call? .math-fixed-point div-down balance-aytoken balance-token) math-call-err))
            (t-value (unwrap! (get-t expiry) internal-function-call-err))
    
            (price (unwrap! (contract-call? .math-fixed-point pow-up base t-value) math-call-err))
        )

        (asserts! (> balance-aytoken balance-token) invalid-balance-err)

        (ok price)
    )
)

(define-public (create-pool (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (dx uint) (dy uint)) 
    (let
        (
            (aytoken (contract-of the-aytoken))            
            (pool-id (+ (var-get pool-count) u1))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (pool-data {
                total-supply: u0,
                balance-token: u0,                
                balance-aytoken: u0,
                balance-virtual: u0,
                fee-balance-aytoken: u0,
                fee-balance-token: u0,
                fee-to-address: (contract-of the-pool-token),
                pool-token: (contract-of the-pool-token),
                fee-rate-aytoken: u0,
                fee-rate-token: u0                
            })
        )
        (asserts! (is-none (map-get? pools-data-map { aytoken: aytoken })) pool-already-exists-err)
        
        (map-set pools-map { pool-id: pool-id } { aytoken: aytoken })
        (map-set pools-data-map { aytoken: aytoken } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)

        ;; if ayToken added has a longer expiry than current max-expiry, update max-expiry.
        (var-set max-expiry (if (< (var-get max-expiry) expiry) expiry (var-get max-expiry)))

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
            (new-dy (get dy add-data))
            (percent-act (unwrap! (contract-call? .math-fixed-point div-up balance-aytoken 
                            (unwrap! (contract-call? .math-fixed-point add-fixed balance-aytoken balance-virtual) math-call-err)) math-call-err))
            (new-dy-act (unwrap! (contract-call? .math-fixed-point mul-up new-dy percent-act) math-call-err))
            (new-dy-vir (unwrap! (contract-call? .math-fixed-point sub-fixed new-dy new-dy-act) math-call-err))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed balance-token dx) math-call-err),
                balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed balance-aytoken new-dy-act) math-call-err),
                balance-virtual: (unwrap! (contract-call? .math-fixed-point add-fixed balance-virtual new-dy-vir) math-call-err)                
            }))
        )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? the-token transfer dx tx-sender .alex-vault none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? the-aytoken transfer new-dy-act tx-sender .alex-vault none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
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
                (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent) math-call-err))
                (reduce-data (unwrap! (get-position-given-burn the-aytoken shares) internal-function-call-err))
                (dx (get dx reduce-data))
                (dy (get dy reduce-data))
                (percent-act (unwrap! (contract-call? .math-fixed-point div-up balance-aytoken 
                            (unwrap! (contract-call? .math-fixed-point add-fixed balance-aytoken balance-virtual) math-call-err)) math-call-err))
                (dy-act (unwrap! (contract-call? .math-fixed-point mul-up dy percent-act) math-call-err))
                (dy-vir (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-act) math-call-err))  
                (pool-updated (merge pool {
                    total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                    balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-token dx) math-call-err),
                    balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-aytoken dy-act) math-call-err),                    
                    balance-virtual: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-virtual dy-vir) math-call-err),                    
                    })
                )
            )

            (asserts! (is-ok (contract-call? the-token transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
            (asserts! (is-ok (contract-call? the-aytoken transfer dy-act .alex-vault tx-sender none)) transfer-y-failed-err)

            (map-set pools-data-map { aytoken: aytoken } pool-updated)
            (try! (contract-call? the-pool-token burn tx-sender shares))

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
            (yield (unwrap! (get-yield the-aytoken) internal-function-call-err))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-aytoken) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 fee-yield) math-call-err))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dx lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dx dx-net-fees) math-call-err))

            (dy (unwrap! (get-y-given-x the-aytoken dx-net-fees) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-token pool) dx-net-fees) math-call-err),
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) dy) math-call-err),
                        fee-balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-token pool)) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (asserts! (is-ok (contract-call? the-token transfer dx-net-fees tx-sender .alex-vault none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? the-aytoken transfer dy .alex-vault tx-sender none)) transfer-y-failed-err)

        ;; post setting
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
        (ok (list dx-net-fees dy))
    )
)

(define-public (swap-y-for-x (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dy uint))

    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (fee-rate-token (get fee-rate-token pool))

            ;; lambda ~= 1 - fee-rate-token * yield
            (yield (unwrap! (get-yield the-aytoken) internal-function-call-err))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-token) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 fee-yield) math-call-err))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dy lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-net-fees) math-call-err))

            (dx (unwrap! (get-x-given-y the-aytoken dy-net-fees) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-token pool) dx) math-call-err),                        
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-aytoken pool) dy-net-fees) math-call-err),
                        fee-balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-aytoken pool)) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        (asserts! (is-ok (contract-call? the-token transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? the-aytoken transfer dy-net-fees tx-sender .alex-vault none)) transfer-y-failed-err)

        ;; post setting
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
        (ok (list dx dy-net-fees))
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

        (map-set pools-data-map { aytoken: aytoken } (merge pool { fee-rate-token: fee-rate-token }))
        (ok true) 
    )
)

(define-public (set-fee-to-address (the-aytoken <yield-token-trait>) (address principal))
    (let 
        (
            (aytoken (contract-of the-aytoken))    
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        )

        (map-set pools-data-map 
            { 
                aytoken: aytoken 
            }
            (merge pool { fee-to-address: address })
        )
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
        (ok (list (get fee-balance-aytoken pool) (get fee-balance-token pool)))
    )
)

;; Returns the fee of current x and y and make balance to 0.
(define-public (collect-fees (the-aytoken <yield-token-trait>) (the-token <ft-trait>))
    
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (address (get fee-to-address pool))
            (fee-x (get fee-balance-aytoken pool))
            (fee-y (get fee-balance-token pool))
        )

        (asserts! (is-eq fee-x u0) no-fee-x-err)
        (asserts! (is-ok (contract-call? the-aytoken transfer fee-x (as-contract tx-sender) address none)) transfer-x-failed-err)
        (asserts! (is-eq fee-y u0) no-fee-y-err)
        (asserts! (is-ok (contract-call? the-token transfer fee-y (as-contract tx-sender) address none)) transfer-y-failed-err)

        (map-set pools-data-map
        { aytoken: aytoken}
        (merge pool { fee-balance-aytoken: u0, fee-balance-token: u0 })
        )
        (ok (list fee-x fee-y)
        )
  )
)

(define-public (get-y-given-x (the-aytoken <yield-token-trait>) (dx uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-y-given-x balance-token balance-aytoken expiry dx)
    )
)

(define-public (get-x-given-y (the-aytoken <yield-token-trait>) (dy uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-y balance-token balance-aytoken expiry dy)
    )
)

(define-public (get-x-given-price (the-aytoken <yield-token-trait>) (price uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-price balance-token balance-aytoken expiry price)
    )
)

(define-public (get-x-given-yield (the-aytoken <yield-token-trait>) (yield uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        )
        (contract-call? .yield-token-equation get-x-given-yield balance-token balance-aytoken expiry yield)
    )
)

(define-public (get-token-given-position (the-aytoken <yield-token-trait>) (dx uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .yield-token-equation get-token-given-position balance-token balance-aytoken expiry total-supply dx)
    )

)

(define-public (get-position-given-mint (the-aytoken <yield-token-trait>) (token uint))

    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))        
        )
        (contract-call? .yield-token-equation get-position-given-mint balance-token balance-aytoken expiry total-supply token)
    )
)

(define-public (get-position-given-burn (the-aytoken <yield-token-trait>) (token uint))
    
    (let 
        (
        (aytoken (contract-of the-aytoken))
        (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
        (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
        (balance-aytoken (get balance-aytoken pool))
        (balance-token (get balance-token pool))
        (total-supply (get total-supply pool))
        )
        (contract-call? .yield-token-equation get-position-given-burn balance-token balance-aytoken expiry total-supply token)
    )
)