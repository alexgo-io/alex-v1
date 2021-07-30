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
(define-constant internal-function-call-err (err u2011))
(define-constant math-call-err (err u2010))
(define-constant get-expiry-fail-err (err u2013))
(define-constant aytoken-equation-call-err (err u2014))

;; data maps and vars
(define-map pools-map
  { pool-id: uint }
  {
    aytoken: principal, ;; aytoken
  }
)

(define-map pools-data-map
  {
    aytoken: principal    
  }
  {
    total-supply: uint,
    balance-aytoken: uint,
    balance-token: uint,
    fee-balance-aytoken: uint,
    fee-balance-token: uint,
    fee-to-address: principal,
    pool-token: principal,
    fee-rate-aytoken: uint,
    fee-rate-token: uint    
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
(define-public (get-yield (the-aytoken <yield-token-trait>))
    (let 
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (balance-aytoken (get balance-aytoken pool))
            (balance-token (get balance-token pool))
            (base (unwrap! (contract-call? .math-fixed-point div-down balance-token balance-aytoken) math-call-err))
        )

        (asserts! (> balance-aytoken balance-token) invalid-balance-err)

        (ok (to-uint (unwrap! (contract-call? .math-log-exp ln-fixed (to-int base)) math-call-err)))
    )
)

;; get-price - input: token trait, expiry / output : price
(define-public (get-price (the-aytoken <yield-token-trait>))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            ;;(exp (get expiry pool)) I think it is safer to use below function.
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (balance-aytoken (get balance-aytoken pool))
            (balance-token (get balance-token pool))

            (base (unwrap! (contract-call? .math-fixed-point div-down balance-token balance-aytoken) math-call-err))
            (t-value (unwrap! (get-t expiry) internal-function-call-err))
    
            (price (unwrap! (contract-call? .math-fixed-point pow-up base t-value) math-call-err))
            (aytoken-price (unwrap! (contract-call? .math-fixed-point div-down ONE_8 price) math-call-err))
        )

        (asserts! (> balance-aytoken balance-token) invalid-balance-err)

        (ok aytoken-price)
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
                balance-aytoken: u0,
                balance-token: u0,
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

        (try! (add-to-position the-aytoken the-token the-pool-token dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (dx uint))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (balance-aytoken (get balance-aytoken pool))
            (balance-token (get balance-token pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap! (get-token-given-position the-aytoken dx) internal-function-call-err))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point add-fixed new-supply total-supply) math-call-err),
                balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed balance-aytoken dx) math-call-err),
                balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed balance-token new-dy) math-call-err)
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? the-aytoken transfer dx tx-sender .alex-vault none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? the-token transfer new-dy tx-sender .alex-vault none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (the-pool-token <pool-token-trait>) (percent uint))
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (balance-aytoken (get balance-aytoken pool))
            (balance-token (get balance-token pool))
            (total-supply (get total-supply pool))
            (shares (unwrap! (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent) math-call-err))
            (reduce-data (unwrap! (get-position-given-burn the-aytoken shares) internal-function-call-err))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap! (contract-call? .math-fixed-point sub-fixed total-supply shares) math-call-err),
                balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-aytoken dx) math-call-err),
                balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed balance-token dy) math-call-err)
                })
           )
       )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        (asserts! (is-ok (contract-call? the-aytoken transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? the-token transfer dy .alex-vault tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { aytoken: aytoken } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (the-aytoken <yield-token-trait>) (the-token <ft-trait>) (dx uint))
    
    (let
        (
            (aytoken (contract-of the-aytoken))
            (pool (unwrap! (map-get? pools-data-map { aytoken: aytoken }) invalid-pool-err))
            (expiry (unwrap! (contract-call? the-aytoken get-expiry) get-expiry-fail-err))
            (balance-aytoken (get balance-aytoken pool))
            (fee-rate-aytoken (get fee-rate-aytoken pool))

            ;; lambda = (dx + balance-aytoken * (1 - exp(yield * fee-rate-aytoken))) / dx / exp(yield * fee-rate-aytoken)
            (yield (unwrap! (get-yield the-aytoken) internal-function-call-err))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-aytoken) math-call-err))
            (exp-fee-yield (to-uint (unwrap! (contract-call? .math-log-exp exp-fixed (to-int fee-yield)) math-call-err)))
            (lambda-numer (unwrap! (contract-call? .math-fixed-point add-fixed dx 
                            (unwrap! (contract-call? .math-fixed-point mul-up balance-aytoken 
                                (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 exp-fee-yield) math-call-err)) math-call-err)) math-call-err))
            (lambda-denom (unwrap! (contract-call? .math-fixed-point mul-down dx exp-fee-yield) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point div-up lambda-numer lambda-denom) math-call-err))
            (dx-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dx lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dx dx-net-fees) math-call-err))

            (dy (unwrap! (get-y-given-x the-aytoken dx-net-fees) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-aytoken pool) dx-net-fees) math-call-err),
                        balance-token: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-token pool) dy) math-call-err),
                        fee-balance-aytoken: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-aytoken pool)) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        ;; TODO : Implement case by case logic of token here bt branching with if statement

        (asserts! (is-ok (contract-call? the-aytoken transfer dx-net-fees tx-sender .alex-vault none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? the-token transfer dy .alex-vault tx-sender none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

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
            (balance-token (get balance-token pool))
            (fee-rate-token (get fee-rate-token pool))

            ;; lambda = (dy + balance-token * (1 - exp(yield * fee-rate-token))) / dy / exp(yield * fee-rate-aytoken)
            (yield (unwrap! (get-yield the-aytoken) internal-function-call-err))
            (fee-yield (unwrap! (contract-call? .math-fixed-point mul-down yield fee-rate-token) math-call-err))
            (exp-fee-yield (to-uint (unwrap! (contract-call? .math-log-exp exp-fixed (to-int fee-yield)) math-call-err)))
            (lambda-numer (unwrap! (contract-call? .math-fixed-point add-fixed dy 
                            (unwrap! (contract-call? .math-fixed-point mul-up balance-token 
                                (unwrap! (contract-call? .math-fixed-point sub-fixed ONE_8 exp-fee-yield) math-call-err)) math-call-err)) math-call-err))
            (lambda-denom (unwrap! (contract-call? .math-fixed-point mul-down dy exp-fee-yield) math-call-err))
            (lambda (unwrap! (contract-call? .math-fixed-point div-up lambda-numer lambda-denom) math-call-err))
            (dy-net-fees (unwrap! (contract-call? .math-fixed-point mul-down dy lambda) math-call-err))
            (fee (unwrap! (contract-call? .math-fixed-point sub-fixed dy dy-net-fees) math-call-err))

            (dx (unwrap! (get-x-given-y the-aytoken dy-net-fees) internal-function-call-err))

            (pool-updated
                (merge pool
                    {
                        balance-aytoken: (unwrap! (contract-call? .math-fixed-point sub-fixed (get balance-aytoken pool) dx) math-call-err),
                        balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed (get balance-token pool) dy-net-fees) math-call-err),
                        fee-balance-token: (unwrap! (contract-call? .math-fixed-point add-fixed fee (get fee-balance-token pool)) math-call-err)
                    }
                )
            )
        )
        ;; TODO : Check whether dy or dx value is valid  
        ;; (asserts! (< min-dy dy) too-much-slippage-err)

        ;; TODO : Implement case by case logic of token here bt branching with if statement

        (asserts! (is-ok (contract-call? the-aytoken transfer dx .alex-vault tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? the-token transfer dy-net-fees tx-sender .alex-vault none)) transfer-y-failed-err)

        ;; TODO : Burning STX at future if required. 

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

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

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

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

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

        ;; TODO : Assertion for checking the right to set the platform fee.
        ;; (asserts! (is-eq tx-sender .arkadiko-dao) (err ERR-NOT-AUTHORIZED))

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
        (contract-call? .yield-token-equation get-y-given-x balance-aytoken balance-token expiry dx)
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
        (contract-call? .yield-token-equation get-x-given-y balance-aytoken balance-token expiry dy)
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
        (contract-call? .yield-token-equation get-x-given-price balance-aytoken balance-token expiry price)
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
        (contract-call? .yield-token-equation get-token-given-position balance-aytoken balance-token expiry total-supply dx)
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
        (contract-call? .yield-token-equation get-position-given-mint balance-aytoken balance-token expiry total-supply token)
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
        (contract-call? .yield-token-equation get-position-given-burn balance-aytoken balance-token expiry total-supply token)
    )
)