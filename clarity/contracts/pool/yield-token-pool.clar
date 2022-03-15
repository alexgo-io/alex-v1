(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)



;; yield-token-pool
(define-constant ONE_8 u100000000) ;; 8 decimal places
(define-constant MAX_T u85000000)

(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-NO-FEE (err u2005))
(define-constant ERR-NO-FEE-Y (err u2006))
(define-constant ERR-INVALID-EXPIRY (err u2009))
(define-constant ERR-MATH-CALL (err u4003))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))
(define-constant ERR-DY-BIGGER-THAN-AVAILABLE (err u2016))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-EXCEEDS-MAX-SLIPPAGE (err u2020))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-ORACLE-NOT-ENABLED (err u7002))
(define-constant ERR-ORACLE-ALREADY-ENABLED (err u7003))
(define-constant ERR-ORACLE-AVERAGE-BIGGER-THAN-ONE (err u7004))
(define-constant ERR-INVALID-BALANCE (err u1001))

(define-data-var contract-owner principal tx-sender)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-private (check-is-owner)
    (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

;; data maps and vars
(define-map pools-map
  { pool-id: uint }
  {
    yield-token: principal, ;; yield-token, dy
    expiry: uint
  }
)

(define-map pools-data-map
  {
    yield-token: principal, 
    expiry: uint
  }
  {
    total-supply: uint,    
    balance-token: uint, ;; dx    
    balance-yield-token: uint, ;; dy_actual
    balance-virtual: uint, ;; dy_virtual
    fee-to-address: principal,
    pool-token: principal,
    fee-rate-token: uint,    
    fee-rate-yield-token: uint,
    fee-rebate: uint,
    listed: uint,
    oracle-enabled: bool,
    oracle-average: uint,
    oracle-resilient: uint,
    token-trait: principal
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 500 uint) (list))

;; 4 years based on 52560 blocks per year (i.e. 10 mins per block)
(define-data-var max-expiry uint (* u210240 ONE_8))

;; @desc get-max-expiry
;; @returns uint
(define-read-only (get-max-expiry)
    (var-get max-expiry)
)

;; @desc set-max-expiry
;; @restricted contract-owner
;; @param new-max-expiry; new max-expiry
;; @returns (response bool uint)
(define-public (set-max-expiry (new-max-expiry uint))
    (begin
        (try! (check-is-owner))
        ;; MI-05
        (asserts! (> new-max-expiry (* block-height ONE_8)) ERR-INVALID-EXPIRY)
        (ok (var-set max-expiry new-max-expiry)) 
    )
)

;; @desc get-t
;; @desc get time-to-maturity as a function of max-expiry
;; @param expiry; when contract expiries
;; @param listed; when contract was listed
;; @returns (response uint uint)
(define-read-only (get-t (expiry uint) (listed uint))
    (begin
        (asserts! (and (> (var-get max-expiry) expiry) (> (var-get max-expiry) (* block-height ONE_8))) ERR-INVALID-EXPIRY)
        (let
            (
                (t (div-down
                    (if (< expiry (* block-height ONE_8)) u0 (- expiry (* block-height ONE_8)))
                    (- (var-get max-expiry) listed)))
            )
            (ok (if (< t MAX_T) t MAX_T)) ;; to avoid numerical error
        )
    )
)

;; @desc get-pool-count
;; @returns uint
(define-read-only (get-pool-count)
    (var-get pool-count)
)

;; @desc get-pool-contracts
;; @param pool-id; pool-id
;; @returns (response (tutple) uint)
(define-read-only (get-pool-contracts (pool-id uint))
    (ok (unwrap! (map-get? pools-map {pool-id: pool-id}) ERR-INVALID-POOL))
)

;; @desc get-pools
;; @returns map of get-pool-contracts
(define-read-only (get-pools)
    (ok (map get-pool-contracts (var-get pools-list)))
)

;; immunefi-4384
(define-read-only (get-pools-by-ids (pool-ids (list 26 uint)))
  (ok (map get-pool-contracts pool-ids))
)

;; @desc get-pool-details
;; @param yield-token-trait; yield-token
;; @returns (response (tuple) uint)
(define-read-only (get-pool-details (expiry uint) (yield-token principal))
    (ok (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
)

;; @desc get-yield
;; @desc note yield is not annualised
;; @param yield-token-trait; yield-token
;; @returns (response uint uint)
(define-read-only (get-yield (expiry uint) (yield-token principal))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry}) ERR-INVALID-POOL))
        )
        (get-yield-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))))
    )
)

;; @desc get-price
;; @param yield-token-trait; yield-token
;; @returns (response uint uint)
(define-read-only (get-price (expiry uint) (yield-token principal))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )      
        (get-price-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))))
    )
)

;; @desc get-oracle-enabled
;; @param yield-token-trait; yield-token
;; @returns (response bool uint)
(define-read-only (get-oracle-enabled (expiry uint) (yield-token principal))
    (ok (get oracle-enabled (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL)))
)

;; @desc set-oracle-enabled
;; @desc oracle can only be enabled
;; @restricted contract-owner
;; @param yield-token-trait; yield-token
;; @returns (response bool uint)
(define-public (set-oracle-enabled (expiry uint) (yield-token principal))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (asserts! (not (get oracle-enabled pool)) ERR-ORACLE-ALREADY-ENABLED)
        (map-set pools-data-map { yield-token: yield-token, expiry: expiry } (merge pool {oracle-enabled: true}))
        (ok true)
    )    
)

;; @desc get-oracle-average
;; @desc returns the moving average used to determine oracle price
;; @param yield-token-trait; yield-token
;; @returns (response uint uint)
(define-read-only (get-oracle-average (expiry uint) (yield-token principal))
    (ok (get oracle-average (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL)))
)

;; @desc set-oracle-average
;; @restricted contract-owner
;; @param yield-token-trait; yield-token
;; @returns (response bool uint)
(define-public (set-oracle-average (expiry uint) (yield-token principal) (new-oracle-average uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
            (pool-updated (merge pool {
                oracle-average: new-oracle-average,
                oracle-resilient: (try! (get-oracle-instant expiry yield-token))
                }))
        )
        (try! (check-is-owner))
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (asserts! (< new-oracle-average ONE_8) ERR-ORACLE-AVERAGE-BIGGER-THAN-ONE)
        (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-updated)
        (ok true)
    )    
)

;; @desc get-oracle-resilient
;; @desc price-oracle that is less up to date but more resilient to manipulation
;; @param yield-token-trait; yield-token
;; @returns (response uint uint)
(define-read-only (get-oracle-resilient (expiry uint) (yield-token principal))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (ok (+ (mul-down (- ONE_8 (get oracle-average pool)) (try! (get-oracle-instant expiry yield-token)))
               (mul-down (get oracle-average pool) (get oracle-resilient pool))))
    )
)

;; @desc get-oracle-instant
;; @desc price-oracle that is more up to date but less resilient to manipulation
;; @param yield-token-trait; yield-token
;; @returns (response uint uint)
(define-read-only (get-oracle-instant (expiry uint) (yield-token principal))
    (ok (div-down ONE_8 (try! (get-price expiry yield-token))))
)

;; @desc create-pool
;; @restricted contract-owner
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param pool-token; pool token representing ownership of the pool
;; @param multisig-vote; DAO used by pool token holers
;; @param dx; amount of token added
;; @param dy; amount of yield-token added
;; @returns (response bool uint)
(define-public (create-pool (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (pool-token-trait <sft-trait>) (multisig-vote principal) (dx uint) (dy uint)) 
    (begin
        (try! (check-is-owner))
        (asserts! (is-none (map-get? pools-data-map { yield-token: (contract-of yield-token-trait), expiry: expiry })) ERR-POOL-ALREADY-EXISTS)
        (let
            (
                (yield-token (contract-of yield-token-trait))            
                (pool-id (+ (var-get pool-count) u1))
                (pool-data {
                    total-supply: u0,
                    balance-token: u0,                
                    balance-yield-token: u0,
                    balance-virtual: u0,
                    fee-to-address: multisig-vote,
                    pool-token: (contract-of pool-token-trait),
                    fee-rate-yield-token: u0,
                    fee-rate-token: u0,
                    fee-rebate: u0,
                    listed: (* block-height ONE_8),
                    oracle-enabled: false,
                    oracle-average: u0,
                    oracle-resilient: u0,
                    token-trait: (contract-of token-trait)
                })
            )
        
            (map-set pools-map { pool-id: pool-id } { yield-token: yield-token, expiry: expiry })
            (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-data)
        
            (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u500) ERR-TOO-MANY-POOLS))
            (var-set pool-count pool-id)

            (try! (contract-call? .alex-vault add-approved-token yield-token))
            (try! (contract-call? .alex-vault add-approved-token (contract-of token-trait)))
            (try! (contract-call? .alex-vault add-approved-token (contract-of pool-token-trait)))

            (try! (add-to-position expiry yield-token-trait token-trait pool-token-trait dx (some dy)))            
            (print { object: "pool", action: "created", data: pool-data })
            (ok true)
        )
    )
)

;; @desc buy-and-add-to-position
;; @desc helper function to buy required yield-token before adding position
;; @desc returns units of pool tokens minted, dx, dy-actual and dy-virtual added
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param pool-token; pool token representing ownership of the pool
;; @param dx; amount of token added (part of which will be used to buy yield-token)
;; @returns (response (tuple uint uint uint uint) uint)
(define-public (buy-and-add-to-position (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (pool-token-trait <sft-trait>) (dx uint) (max-dy (optional uint)))
    (let
        (
            (dy-act (get dy-act (try! (get-token-given-position expiry (contract-of yield-token-trait) dx))))
            (dx-adjusted (- dx (div-down dx (+ dx (try! (get-x-given-y expiry (contract-of yield-token-trait) dy-act))))))
            (dx-to-buy-dy-adjusted (- dx dx-adjusted))
        )
        (and (> dy-act u0) (is-ok (swap-x-for-y expiry yield-token-trait token-trait dx-to-buy-dy-adjusted none)))
        (add-to-position expiry yield-token-trait token-trait pool-token-trait dx-adjusted max-dy)
    )
)

;; @desc roll-position
;; @desc roll given liquidity position to another pool
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param pool-token; pool token representing ownership of the pool
;; @param percent; percentage of pool token held to reduce
;; @param yield-token-trait-to-roll; yield token to roll
;; @param pool-token-trait-to-roll; pool token representing ownership of the pool to roll to
;; @returns (response (tuple uint uint) uint)
(define-public (roll-position 
    (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (pool-token-trait <sft-trait>) (percent uint) 
    (expiry-to-roll uint))
    (let
        (
            (reduce-data (try! (reduce-position expiry yield-token-trait token-trait pool-token-trait percent)))
            (dy-to-dx (get dx (try! (swap-y-for-x expiry yield-token-trait token-trait (get dy reduce-data) none))))
        )
        (buy-and-add-to-position expiry-to-roll yield-token-trait token-trait pool-token-trait (+ (get dx reduce-data) dy-to-dx) none)
    )
)

;; @desc add-to-position
;; @desc returns units of pool tokens minted, dx, dy-actual and dy-virtual added
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param pool-token; pool token representing ownership of the pool
;; @param dx; amount of token added
;; @returns (response (tuple uint uint uint uint) uint)
(define-public (add-to-position (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (pool-token-trait <sft-trait>) (dx uint) (max-dy (optional uint)))
    (begin
        ;; dx must be greater than zero
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (yield-token (contract-of yield-token-trait))
                (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
                (balance-token (get balance-token pool))            
                (balance-yield-token (get balance-yield-token pool))
                (balance-virtual (get balance-virtual pool))
                (total-supply (get total-supply pool))
                (add-data (try! (get-token-given-position expiry yield-token dx)))
                (new-supply (get token add-data))
                (new-dy-act (get dy-act add-data))
                (new-dy-vir (get dy-vir add-data))
                (pool-updated (merge pool {
                    total-supply: (+ new-supply total-supply),
                    balance-token: (+ balance-token dx),
                    balance-yield-token: (+ balance-yield-token new-dy-act),
                    balance-virtual: (+ balance-virtual new-dy-vir)   
                }))
                (sender tx-sender)
            )
            (asserts! (and (is-eq (get token-trait pool) (contract-of token-trait)) (is-eq (get pool-token pool) (contract-of pool-token-trait))) ERR-INVALID-TOKEN)

            ;; at least one of dy must be greater than zero            
            (asserts! (or (> new-dy-act u0) (> new-dy-vir u0)) ERR-INVALID-LIQUIDITY)
            (asserts! (>= (default-to u340282366920938463463374607431768211455 max-dy) new-dy-act) ERR-EXCEEDS-MAX-SLIPPAGE)

            ;; send x to vault
            (unwrap! (contract-call? token-trait transfer-fixed dx sender .alex-vault none) ERR-TRANSFER-FAILED)
            ;; send y to vault
            (and (> new-dy-act u0) (unwrap! (contract-call? yield-token-trait transfer-fixed expiry new-dy-act sender .alex-vault) ERR-TRANSFER-FAILED))
        
            ;; mint pool token and send to tx-sender
            (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-updated)    
            (as-contract (try! (contract-call? pool-token-trait mint-fixed expiry new-supply sender)))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {supply: new-supply, balance-token: dx, balance-yield-token: new-dy-act, balance-virtual: new-dy-vir})
        )
    )
)    

;; @desc reduce-position
;; @desc returns dx and dy-actual due to the position
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param pool-token; pool token representing ownership of the pool
;; @param percent; percentage of pool token held to reduce
;; @returns (response (tuple uint uint) uint)
(define-public (reduce-position (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (pool-token-trait <sft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        (let
            (
                (yield-token (contract-of yield-token-trait))
                (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
                (balance-token (get balance-token pool))
                (balance-yield-token (get balance-yield-token pool))
                (balance-virtual (get balance-virtual pool))                
                (total-supply (get total-supply pool))
                (total-shares (unwrap-panic (contract-call? pool-token-trait get-balance-fixed expiry tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))                 
                (reduce-data (try! (get-position-given-burn expiry yield-token shares)))
                (dx (get dx reduce-data))
                (dy-act (get dy-act reduce-data))
                (dy-vir (get dy-vir reduce-data))
                (pool-updated (merge pool {
                    total-supply: (if (<= total-supply shares) u0 (- total-supply shares)),
                    balance-token: (if (<= balance-token dx) u0 (- balance-token dx)),
                    balance-yield-token: (if (<= balance-yield-token dy-act) u0 (- balance-yield-token dy-act)),
                    balance-virtual: (if (<= balance-virtual dy-vir) u0 (- balance-virtual dy-vir))
                    })
                )
                (sender tx-sender)
            )
            (asserts! (and (is-eq (get token-trait pool) (contract-of token-trait)) (is-eq (get pool-token pool) (contract-of pool-token-trait))) ERR-INVALID-TOKEN)

            (and (> dx u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-trait dx sender))))
            (and (> dy-act u0) (as-contract (try! (contract-call? .alex-vault transfer-sft yield-token-trait expiry dy-act sender))))

            (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-updated)
            (as-contract (try! (contract-call? pool-token-trait burn-fixed expiry shares sender)))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy-act})
        )    
    )    
)

;; @desc swap-x-for-y
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param dx; amount of token to swap
;; @param min-dy; optional, min amount of yield-token to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-x-for-y (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (yield-token (contract-of yield-token-trait))
                (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
                (balance-token (get balance-token pool))
                (balance-yield-token (get balance-yield-token pool))

                ;; lambda ~= 1 - fee-rate-yield-token * yield
                (fee-yield (mul-down (try! (get-yield expiry yield-token)) (get fee-rate-yield-token pool)))
                (dx-net-fees (mul-down dx (if (<= ONE_8 fee-yield) u0 (- ONE_8 fee-yield))))
                (fee (if (<= dx dx-net-fees) u0 (- dx dx-net-fees)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))

                (dy (try! (get-y-given-x expiry yield-token dx-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-token: (+ balance-token dx-net-fees fee-rebate),
                            balance-yield-token: (if (<= balance-yield-token dy) u0 (- balance-yield-token dy)),
                            oracle-resilient: (if (get oracle-enabled pool) (try! (get-oracle-resilient expiry yield-token)) u0)
                        }
                    )
                )
                (sender tx-sender)
            )
            (asserts! (is-eq (get token-trait pool) (contract-of token-trait)) ERR-INVALID-TOKEN)
            (asserts! (< (default-to u0 min-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)

            (and (> dx u0) (unwrap! (contract-call? token-trait transfer-fixed dx sender .alex-vault none) ERR-TRANSFER-FAILED))
            (and (> dy u0) (as-contract (try! (contract-call? .alex-vault transfer-sft yield-token-trait expiry dy sender))))
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance (contract-of token-trait) (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

;; @desc swap-y-for-x
;; @param yield-token-trait; yield token
;; @param token-trait; token
;; @param dy; amount of yield token to swap
;; @param min-dx; optional, min amount of token to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-y-for-x (expiry uint) (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (dy uint) (min-dx (optional uint)))
    (begin
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (yield-token (contract-of yield-token-trait))
                (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
                (balance-token (get balance-token pool))
                (balance-yield-token (get balance-yield-token pool))

                ;; lambda ~= 1 - fee-rate-token * yield
                (fee-yield (mul-down (try! (get-yield expiry yield-token)) (get fee-rate-token pool)))
                (dy-net-fees (mul-down dy (if (<= ONE_8 fee-yield) u0 (- ONE_8 fee-yield))))
                (fee (if (<= dy dy-net-fees) u0 (- dy dy-net-fees)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))

                (dx (try! (get-x-given-y expiry yield-token dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                            balance-token: (if (<= balance-token dx) u0 (- balance-token dx)),
                            balance-yield-token: (+ balance-yield-token dy-net-fees fee-rebate),
                            oracle-resilient: (if (get oracle-enabled pool) (try! (get-oracle-resilient expiry yield-token)) u0)
                        }
                    )
                )
                (sender tx-sender)
            )
            (asserts! (is-eq (get token-trait pool) (contract-of token-trait)) ERR-INVALID-TOKEN)
            (asserts! (< (default-to u0 min-dx) dx) ERR-EXCEEDS-MAX-SLIPPAGE)

            (and (> dx u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-trait dx sender))))
            (and (> dy u0) (unwrap! (contract-call? yield-token-trait transfer-fixed expiry dy sender .alex-vault) ERR-TRANSFER-FAILED))
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance yield-token (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { yield-token: yield-token, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

;; @desc get-fee-rebate
;; @param yield-token-trait; yield token
;; @returns (response uint uint)
(define-read-only (get-fee-rebate (expiry uint) (yield-token principal))
    (ok (get fee-rebate (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL)))
)

;; @desc set-fee-rebate
;; @restricted contract-owner
;; @param yield-token-trait; yield token
;; @param fee-rebate; new fee-rebate
;; @returns (response bool uint)
(define-public (set-fee-rebate (expiry uint) (yield-token principal) (fee-rebate uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))

        (map-set pools-data-map { yield-token: yield-token, expiry: expiry } (merge pool { fee-rebate: fee-rebate }))
        (ok true)
    )
)

;; @desc get-fee-rate-yield-token
;; @param yield-token-trait; yield token
;; @returns (response uint uint)
(define-read-only (get-fee-rate-yield-token (expiry uint) (yield-token principal))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (ok (get fee-rate-yield-token pool))
    )
)

;; @desc get-fee-rate-token
;; @param yield-token-trait; yield token
;; @returns (response uint uint)
(define-read-only (get-fee-rate-token (expiry uint) (yield-token principal))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (ok (get fee-rate-token pool))
    )
)

;; @desc set-fee-rate-yield-token
;; @restricted fee-to-address
;; @param yield-token-trait; yield token
;; @param fee-rate-yield-token; new fee-rate-yield-token
;; @returns (response bool uint)
(define-public (set-fee-rate-yield-token (expiry uint) (yield-token principal) (fee-rate-yield-token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (asserts! (is-eq tx-sender (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map { yield-token: yield-token, expiry: expiry } (merge pool { fee-rate-yield-token: fee-rate-yield-token }))
        (ok true)
    
    )
)

;; @desc set-fee-rate-token
;; @restricted fee-to-address
;; @param yield-token-trait; yield token
;; @param fee-rate-token; new fee-rate-token
;; @returns (response bool uint)
(define-public (set-fee-rate-token (expiry uint) (yield-token principal) (fee-rate-token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (asserts! (is-eq tx-sender (get fee-to-address pool)) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map { yield-token: yield-token, expiry: expiry } (merge pool { fee-rate-token: fee-rate-token }))
        (ok true) 
    )
)

;; @desc get-fee-to-address
;; @param yield-token-trait; yield token
;; @returns (response principal uint)
(define-read-only (get-fee-to-address (expiry uint) (yield-token principal))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (ok (get fee-to-address pool))
    )
)

(define-public (set-fee-to-address (expiry uint) (yield-token principal) (fee-to-address principal))
    (let 
        (
            (pool (try! (get-pool-details expiry yield-token)))
        )
        (try! (check-is-owner))

        (map-set pools-data-map 
            { 
                yield-token: yield-token, expiry: expiry
            }
            (merge pool { fee-to-address: fee-to-address })
        )
        (ok true)     
    )
)

;; @desc units of yield token given units of token
;; @param yield-token-trait; yield token
;; @param dx; amount of token being added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (expiry uint) (yield-token principal) (dx uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
            (dy (try! (get-y-given-x-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) dx)))
        )
        (asserts! (> (get balance-yield-token pool) dy) ERR-DY-BIGGER-THAN-AVAILABLE)
        (ok dy)        
    )
)

;; @desc units of token given units of yield token
;; @param yield-token-trait; yield token
;; @param dy; amount of yield token being added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (expiry uint) (yield-token principal) (dy uint))
    
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (get-x-given-y-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) dy)
    )
)

;; @desc units of token required for a target price
;; @param yield-token-trait; yield token
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (expiry uint) (yield-token principal) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (get-x-given-price-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) price)
    )
)

;; @desc units of yield token required for a target price
;; @param yield-token-trait; yield token
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (expiry uint) (yield-token principal) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (get-y-given-price-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) price)
    )
)

;; @desc units of token required for a target yield
;; @param yield-token-trait; yield token
;; @param yield; target yield
;; @returns (response uint uint)
(define-read-only (get-x-given-yield (expiry uint) (yield-token principal) (yield uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (get-x-given-yield-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) yield)
    )
)

;; @desc units of yield token required for a target yield
;; @param yield-token-trait; yield token
;; @param yield; target yield
;; @returns (response uint uint)
(define-read-only (get-y-given-yield (expiry uint) (yield-token principal) (yield uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
        )
        (get-y-given-yield-internal (get balance-token pool) (+ (get balance-yield-token pool) (get balance-virtual pool)) (try! (get-t expiry (get listed pool))) yield)
    )
)

;; @desc units of pool token to be minted, together with break-down of yield-token given amount of token being added
;; @param yield-token-trait; yield token
;; @param dx; amount of token added
;; @returns (response (tuple uint uint uint) uint)
(define-read-only (get-token-given-position (expiry uint) (yield-token principal) (dx uint))

    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
            (balance-actual (get balance-yield-token pool))
            (balance-virtual (get balance-virtual pool))
            (balance-yield-token (+ balance-actual balance-virtual))
            (data (try! (get-token-given-position-internal (get balance-token pool) balance-yield-token (try! (get-t expiry (get listed pool))) (get total-supply pool) dx)))
            (token (get token data))
            (dy (get dy data))
            (dy-act (if (is-eq token dy) u0 (mul-down dy (if (is-eq balance-yield-token u0) u0 (div-down balance-actual balance-yield-token)))))
        )        
        (ok {token: token, dy-act: dy-act, dy-vir: (if (is-eq token dy) token (if (<= dy dy-act) u0 (- dy dy-act)))})
    )

)

;; @desc units of token, yield-token and yield-token (virtual) required to mint given units of pool-token
;; @param yield-token-trait; yield token
;; @param token; units of pool token to be minted
;; @returns (response (tuple uint uint uint) uint)
(define-read-only (get-position-given-mint (expiry uint) (yield-token principal) (token uint))

    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
            (balance-actual (get balance-yield-token pool))
            (balance-virtual (get balance-virtual pool))
            (balance-yield-token (+ balance-actual balance-virtual))
            (balance-token (get balance-token pool))
            (data (try! (get-position-given-mint-internal balance-token balance-yield-token (try! (get-t expiry (get listed pool))) (get total-supply pool) token)))   
            (dx (get dx data))
            (dy (get dy data))
            (dy-act (mul-down dy (div-down balance-actual balance-yield-token)))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: (if (<= dy dy-act) u0 (- dy dy-act))})
    )
)

;; @desc units of token, yield-token and yield-token (virtual) to be returned after burning given units of pool-token
;; @param yield-token-trait; yield token
;; @param token; units of pool token to be burnt
;; @returns (response (tuple uint uint uint) uint)
(define-read-only (get-position-given-burn (expiry uint) (yield-token principal) (token uint))
    
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { yield-token: yield-token, expiry: expiry }) ERR-INVALID-POOL))
            (balance-actual (get balance-yield-token pool))
            (balance-virtual (get balance-virtual pool))
            (balance-yield-token (+ balance-actual balance-virtual))
            (balance-token (get balance-token pool))
            (data (try! (get-position-given-burn-internal balance-token balance-yield-token (try! (get-t expiry (get listed pool))) (get total-supply pool) token)))   
            (dx (get dx data))
            (dy (get dy data))
            (dy-act (mul-down dy (div-down balance-actual balance-yield-token)))
        )
        (ok {dx: dx, dy-act: dy-act, dy-vir: (if (<= dy dy-act) u0 (- dy dy-act))})
    )
)

;; yield-token-equation
;; implementation of Yield Token AMM (https://docs.alexgo.io/whitepaper/automated-market-making-of-alex)

;; constants
;;
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))

;; max in/out as % of liquidity
(define-data-var MAX-IN-RATIO uint (* u30 (pow u10 u6))) ;; 30%
(define-data-var MAX-OUT-RATIO uint (* u30 (pow u10 u6))) ;; 30%

;; @desc get-max-in-ratio
;; @returns uint
(define-read-only (get-max-in-ratio)
  (var-get MAX-IN-RATIO)
)

;; @desc set-max-in-ratio
;; @param new-max-in-ratio; new MAX-IN-RATIO
;; @returns (response bool uint)
(define-public (set-max-in-ratio (new-max-in-ratio uint))
  (begin
    (try! (check-is-owner))
    ;; MI-03
    (asserts! (> new-max-in-ratio u0) ERR-MAX-IN-RATIO)    
    (var-set MAX-IN-RATIO new-max-in-ratio)
    (ok true)
  )
)

;; @desc get-max-out-ratio
;; @returns uint
(define-read-only (get-max-out-ratio)
  (var-get MAX-OUT-RATIO)
)

;; @desc set-max-out-ratio
;; @param new-max-out-ratio; new MAX-OUT-RATIO
;; @returns (response bool uint)
(define-public (set-max-out-ratio (new-max-out-ratio uint))
  (begin
    (try! (check-is-owner))
    ;; MI-03
    (asserts! (> new-max-out-ratio u0) ERR-MAX-OUT-RATIO)    
    (var-set MAX-OUT-RATIO new-max-out-ratio)
    (ok true)
  )
)

;; @desc get-price
;; @desc b_y = balance-yield-token
;; @desc b_x = balance-token
;; @desc price = (b_y / b_x) ^ t
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @returns (response uint uint)
(define-private (get-price-internal (balance-x uint) (balance-y uint) (t uint))
  (begin
    (asserts! (>= balance-y balance-x) ERR-INVALID-BALANCE)      
    (ok (pow-up (div-down balance-y balance-x) t))
  )
)

;; @desc get-yield
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @returns (response uint uint)
(define-private (get-yield-internal (balance-x uint) (balance-y uint) (t uint))
  (let
    (
      (price (try! (get-price-internal balance-x balance-y t)))
    )    
    (if (<= price ONE_8) (ok u0) (ok (- price ONE_8)))
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc d_y = b_y - (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_x + d_x) ^ (1 - t)) ^ (1 / (1 - t))
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param dx; amount of token added
;; @returns (response uint uint)
(define-private (get-y-given-x-internal (balance-x uint) (balance-y uint) (t uint) (dx uint))
  (begin
    (asserts! (>= balance-x dx) ERR-INVALID-BALANCE)
    (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)     
    (let 
      (
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-down balance-x t-comp))
        (y-pow (pow-down balance-y t-comp))
        (x-dx-pow (pow-down (+ balance-x dx) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term x-dx-pow) u0 (- add-term x-dx-pow)))
        (final-term (pow-down term t-comp-num))
        (dy (if (<= balance-y final-term) u0 (- balance-y final-term)))
      )
      
      (asserts! (< dy (mul-down balance-y (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
      (ok dy)
    )  
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc d_x = (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_y - d_y) ^ (1 - t)) ^ (1 / (1 - t)) - b_x
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param dy; amount of yield-token added
;; @returns (response uint uint)
(define-private (get-x-given-y-internal (balance-x uint) (balance-y uint) (t uint) (dy uint))
  (begin
    (asserts! (>= balance-y dy) ERR-INVALID-BALANCE)
    (asserts! (< dy (mul-down balance-y (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
    (let 
      (          
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-down balance-x t-comp))
        (y-pow (pow-down balance-y t-comp))
        (y-dy-pow (pow-up (if (<= balance-y dy) u0 (- balance-y dy)) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term y-dy-pow) u0 (- add-term y-dy-pow)))
        (final-term (pow-down term t-comp-num))
        (dx (if (<= final-term balance-x) u0 (- final-term balance-x)))
      )

      (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
      (ok dx)
    )  
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc spot = (b_y / b_x) ^ t
;; @desc d_x = b_x * ((1 + spot ^ ((1 - t) / t) / (1 + price ^ ((1 - t) / t)) ^ (1 / (1 - t)) - 1)
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param price; target price
;; @returns (response uint uint)
(define-private (get-x-given-price-internal (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (< price (try! (get-price-internal balance-x balance-y t))) ERR-NO-LIQUIDITY) 
    (let 
      (
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (numer (+ ONE_8 (pow-down (div-down balance-y balance-x) t-comp)))
        (denom (+ ONE_8 (pow-down price (div-down t-comp t))))
        (lead-term (pow-down (div-down numer denom) t-comp-num))
      )
      (if (<= lead-term ONE_8) (ok u0) (ok (mul-up balance-x (- lead-term ONE_8))))
    )
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc spot = (b_y / b_x) ^ t
;; @desc d_y = b_y - b_x * (1 + spot ^ ((1 - t) / t) / (1 + price ^ ((1 - t) / t)) ^ (1 / (1 - t))
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param price; target price
;; @returns (response uint uint)
(define-private (get-y-given-price-internal (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (> price (try! (get-price-internal balance-x balance-y t))) ERR-NO-LIQUIDITY) 
    (let 
      (
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (numer (+ ONE_8 (pow-down (div-down balance-y balance-x) t-comp)))
        (denom (+ ONE_8 (pow-down price (div-down t-comp t))))
        (lead-term (mul-up balance-x (pow-down (div-down numer denom) t-comp-num)))
      )
      (if (<= balance-y lead-term) (ok u0) (ok (- balance-y lead-term)))
    )
  )
)

;; @desc follows from get-x-given-price
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param yield; target yield
;; @returns (response uint uint)
(define-private (get-x-given-yield-internal (balance-x uint) (balance-y uint) (t uint) (yield uint))
  (get-x-given-price-internal balance-x balance-y t (+ ONE_8 yield))
)

;; @desc follows from get-y-given-price
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param yield; target yield
;; @returns (response uint uint)
(define-private (get-y-given-yield-internal (balance-x uint) (balance-y uint) (t uint) (yield uint))
  (get-y-given-price-internal balance-x balance-y t (+ ONE_8 yield))
)

;; @desc get-token-given-position
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param dx; amount of token added
;; @returns (response (tuple uint uint) uint)
(define-private (get-token-given-position-internal (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (dx uint))
  (begin
    (asserts! (> dx u0) ERR-NO-LIQUIDITY)
    (ok
      (if (or (is-eq total-supply u0) (is-eq balance-x balance-y)) ;; either at inception or if yield == 0
        {token: dx, dy: dx}
        (let
          (
            ;; if total-supply > zero, we calculate dy proportional to dx / balance-x
            (dy (mul-down balance-y (div-down dx balance-x)))
            (token (mul-down total-supply (div-down dx balance-x)))
          )
          {token: token, dy: dy}
        )
      )            
    )
  )
)

;; @desc get-position-given-mint
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param token; amount of pool token to be minted
;; @returns (response (tuple uint uint) uint)
(define-private (get-position-given-mint-internal (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
  (begin
    (asserts! (> total-supply u0) ERR-NO-LIQUIDITY)
    (let
      (
        (token-div-supply (div-down token total-supply))
        (dx (mul-down balance-x token-div-supply))
        (dy (mul-down balance-y token-div-supply))
      )                
      (ok {dx: dx, dy: dy})
    )      
  )
)

;; @desc get-position-given-burn
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param token; amount of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-private (get-position-given-burn-internal (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
    (get-position-given-mint-internal balance-x balance-y t total-supply token)
)

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) ONE_8))

(define-private (div-down (a uint) (b uint))
  (contract-call? .math-fixed-point div-down a b)
)

(define-private (div-up (a uint) (b uint))
  (contract-call? .math-fixed-point div-up a b)
)

(define-private (mul-down (a uint) (b uint))
  (contract-call? .math-fixed-point mul-down a b)
)

(define-private (mul-up (a uint) (b uint))
  (contract-call? .math-fixed-point mul-up a b)
)

(define-private (pow-down (a uint) (b uint))
  (contract-call? .math-fixed-point pow-down a b)
)

(define-private (pow-up (a uint) (b uint))
  (contract-call? .math-fixed-point pow-up a b)
)