(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; liquidity-bootstrapping-pool

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-ALREADY-EXPIRED (err u2011))
(define-constant ERR-EXCEEDS-MAX-SLIPPAGE (err u2020))
(define-constant ERR-PRICE-LOWER-THAN-MIN (err u2021))
(define-constant ERR-PRICE-GREATER-THAN-MAX (err u2022))
(define-constant ERR-INVALID-TOKEN (err u2026))

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
    balance-x-0: uint,
    pool-multisig: principal,
    pool-token: principal,
    listed: uint,
    weight-x-0: uint,
    weight-x-1: uint,
    weight-x-t: uint,
    price-x-min: uint,
    price-x-max: uint,
    project-name: (string-utf8 256)
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 500 uint) (list))

;; private functions
;;

;; liquidity injection is allowed at the pool creation only
;; @desc add-to-position 
;; @params token-x-trait; ft-trait
;; @params token-y-trait; ft-trait
;; @params expiry
;; @params pool-token-trait; ft-trait
;; @params dx
;; @params dy
;; @returns (response bool)
(define-private (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (pool-token-trait <ft-trait>) (dx uint) (max-dy (optional uint)))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)        
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (balance-x-0 (get balance-x-0 pool))
                (total-supply (get total-supply pool))
                (add-data (try! (get-token-given-position token-x token-y expiry dx max-dy)))
                (new-supply (get token add-data))
                (dy (get dy add-data))
                (pool-updated (merge pool {
                    total-supply: (+ new-supply total-supply),
                    balance-x: (+ balance-x dx),
                    balance-y: (+ balance-y dy),
                    balance-x-0: (+ balance-x-0 dx)
                }))
            )
            ;; CR-01
            (asserts! (>= (default-to u340282366920938463463374607431768211455 max-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)
            (asserts! (is-eq (get pool-token pool) (contract-of pool-token-trait)) ERR-INVALID-TOKEN)

            (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
            (unwrap! (contract-call? token-x-trait transfer-fixed dx tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
            (unwrap! (contract-call? token-y-trait transfer-fixed dy tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
        
            ;; mint pool token-x and send to tx-sender
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? pool-token-trait mint-fixed new-supply tx-sender))
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok true)
        )
    )
)

;; public functions
;;

;; @desc get-pool-count
;; @returns uint
(define-read-only (get-pool-count)
    (var-get pool-count)
)

;; @desc get-pool-contracts
;; @param pool-id; pool-id
;; @returns (response (tutple) uint)
(define-read-only (get-pool-contracts (pool-id uint))
    (ok (map-get? pools-map {pool-id: pool-id}))
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
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @returns (response (tuple) uint)
(define-read-only (get-pool-details (token-x principal) (token-y principal) (expiry uint))
    (ok (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
)

;; @desc get-weight-x
;; @desc returns weight of token-x (weight of token-y = 1 - weight of token-x)
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @returns (response uint uint)
(define-read-only (get-weight-x (token-x principal) (token-y principal) (expiry uint))
    (begin
        (asserts! (<= (* block-height ONE_8) expiry) ERR-ALREADY-EXPIRED)
        (let 
            (
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))                  
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (weight-x-0 (get weight-x-0 pool))
                (weight-x-1 (get weight-x-1 pool))
                (listed (get listed pool))

                ;; weight-t = weight-x-0 - (block-height - listed) * (weight-x-0 - weight-x-1) / (expiry - listed)
                (now-to-listed (- (* block-height ONE_8) listed))
                (expiry-to-listed (- expiry listed))
                (weight-diff (- weight-x-0 weight-x-1))
                (time-ratio (div-down now-to-listed expiry-to-listed))
                (weight-change (mul-down weight-diff time-ratio))  
            )
            (ok (- weight-x-0 weight-change))
        )
    )   
)

;; @desc get-price-range
;; @desc returns min/max prices
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-price-range (token-x principal) (token-y principal) (expiry uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
        )
        (ok {min-price: (get price-x-min pool), max-price: (get price-x-max pool)})
    )
)

;; @desc set-price-range
;; @restricted pool-multisig
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @returns (response bool uint)
(define-public (set-price-range (token-x principal) (token-y principal) (expiry uint) (min-price uint) (max-price uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (pool-updated (merge pool {
                price-x-min: min-price,
                price-x-max: max-price
                }))            
        )
        (asserts! (is-eq tx-sender (get pool-multisig pool)) ERR-NOT-AUTHORIZED)
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
        (ok true)
    )
)

;; @desc get-balances ({balance-x, balance-y})
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-balances (token-x principal) (token-y principal) (expiry uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
        )
        (ok {balance-x: (get balance-x pool), balance-y: (get balance-y pool)})
    )
)

;; @desc create-pool
;; @restricted contract-owner
;; @param project-name; name of project
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param weight-x-0; weight of token-x at start
;; @param weight-x-1; weight of token-x at end
;; @param expiry; expiry
;; @param pool-token; pool token representing ownership of the pool
;; @param multisig-vote; DAO used by pool token holers
;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response bool uint)
(define-public (create-pool (project-name (string-utf8 256)) (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x-0 uint) (weight-x-1 uint) (expiry uint) (pool-token-trait <ft-trait>) (multisig-vote principal) (price-x-min uint) (price-x-max uint) (dx uint) (dy uint)) 
    (let
        (
            (pool-id (+ (var-get pool-count) u1))
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool-data {
                project-name: project-name,
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                balance-x-0: u0,
                pool-multisig: multisig-vote,
                pool-token: (contract-of pool-token-trait),
                listed: (* block-height ONE_8),
                weight-x-0: weight-x-0,
                weight-x-1: weight-x-1,
                weight-x-t: weight-x-0,
                price-x-min: price-x-min,
                price-x-max: price-x-max
            })
        )
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)     

        (asserts! (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry })) ERR-POOL-ALREADY-EXISTS)             

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, expiry: expiry })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u500) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)

        (try! (contract-call? .alex-vault add-approved-token token-x))
        (try! (contract-call? .alex-vault add-approved-token token-y))
        (try! (contract-call? .alex-vault add-approved-token (contract-of pool-token-trait)))    
        (try! (add-to-position token-x-trait token-y-trait expiry pool-token-trait dx (some dy)))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
    )
)   

;; @desc reduce-position
;; @desc returns dx and dy due to the position
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param pool-token; pool token representing ownership of the pool
;; @param percent; percentage of pool token held to reduce
;; @returns (response (tuple uint uint) uint)
(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (pool-token-trait <ft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE) 
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-shares (unwrap-panic (contract-call? pool-token-trait get-balance-fixed tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
                (total-supply (get total-supply pool))     
                (reduce-data (try! (get-position-given-burn token-x token-y expiry shares)))
                (dx (get dx reduce-data))
                (dy (get dy reduce-data))
                (pool-updated (merge pool {
                    total-supply: (if (<= total-supply shares) u0 (- total-supply shares)),
                    balance-x: (if (<= balance-x dx) u0 (- balance-x dx)),
                    balance-y: (if (<= balance-y dy) u0 (- balance-y dy))
                    })
                )
                (sender tx-sender)
            )
            
            (asserts! (is-eq (get pool-token pool) (contract-of pool-token-trait)) ERR-INVALID-TOKEN)

            (as-contract (try! (contract-call? .alex-vault transfer-ft token-x-trait dx sender)))
            (as-contract (try! (contract-call? .alex-vault transfer-ft token-y-trait dy sender)))            
            
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (try! (contract-call? pool-token-trait burn-fixed shares tx-sender))
            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

;; @desc swap-x-for-y
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param dx; amount of token-x to swap
;; @param min-dy; optional, min amount of token-y to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dx uint) (min-dy (optional uint)))
    (begin
        ;; swap is allowed only until expiry
        (asserts! (<= (* block-height ONE_8) expiry) ERR-ALREADY-EXPIRED)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))       

                ;; swap triggers update of weight
                (weight-x (try! (get-weight-x token-x token-y expiry)))
                (weight-y (- ONE_8 weight-x))
                (dy (try! (get-y-given-x token-x token-y expiry dx)))

                (pool-updated (merge pool {
                    balance-x: (+ balance-x dx),
                    balance-y: (if (<= balance-y dy) u0 (- balance-y dy)),
                    weight-x-t: weight-x }))
                (sender tx-sender)
            )

            (asserts! (< (default-to u0 min-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)
            (asserts! (<= (get price-x-min pool) (div-down dy dx)) ERR-PRICE-LOWER-THAN-MIN)
            (asserts! (>= (get price-x-max pool) (div-down dy dx)) ERR-PRICE-GREATER-THAN-MAX)

            (unwrap! (contract-call? token-x-trait transfer-fixed dx tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
            (as-contract (try! (contract-call? .alex-vault transfer-ft token-y-trait dy sender)))
            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

;; @desc swap-y-for-x
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param dy; amount of token-y to swap
;; @param min-dx; optional, min amount of token-x to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (expiry uint) (dy uint) (min-dx (optional uint)))
    (begin
        ;; swap is allowed only until expiry
        (asserts! (<= (* block-height ONE_8) expiry) ERR-ALREADY-EXPIRED)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; swap triggers update of weight
                (weight-x (try! (get-weight-x token-x token-y expiry)))
                (weight-y (- ONE_8 weight-x))            
                (dx (try! (get-x-given-y token-x token-y expiry dy)))

                (pool-updated (merge pool {
                    balance-x: (if (<= balance-x dx) u0 (- balance-x dx)),
                    balance-y: (+ balance-y dy),
                    weight-x-t: weight-x}))
                (sender tx-sender)
            )

            (asserts! (< (default-to u0 min-dx) dx) ERR-EXCEEDS-MAX-SLIPPAGE)
            (asserts! (<= (get price-x-min pool) (div-down dy dx)) ERR-PRICE-LOWER-THAN-MIN)
            (asserts! (>= (get price-x-max pool) (div-down dy dx)) ERR-PRICE-GREATER-THAN-MAX)

            (as-contract (try! (contract-call? .alex-vault transfer-ft token-x-trait dx sender)))
            (unwrap! (contract-call? token-y-trait transfer-fixed dy tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
            ;; post setting
            (map-set pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

;; @desc units of token-y given units of token-x
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param dx; amount of token-x being added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (token-x principal) (token-y principal) (expiry uint) (dx uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (weight-x (get weight-x-t pool))
        )
        (contract-call? .weighted-equation-v1-01 get-y-given-x (get balance-x pool) (get balance-y pool) weight-x (- ONE_8 weight-x) dx)        
    )
)

;; @desc units of token-x given units of token-y
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param dy; amount of token-y being added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (token-x principal) (token-y principal) (expiry uint) (dy uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (weight-x (get weight-x-t pool))
        )
        (contract-call? .weighted-equation-v1-01 get-x-given-y (get balance-x pool) (get balance-y pool) weight-x (- ONE_8 weight-x) dy)
    )
)

;; @desc units of token-x required for a target price
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (token-x principal) (token-y principal) (expiry uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (- ONE_8 weight-x))            
        )
        (contract-call? .weighted-equation-v1-01 get-x-given-price balance-x balance-y weight-x weight-y price)
    )
)

;; @desc units of token-y required for a target price
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (token-x principal) (token-y principal) (expiry uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x-t pool))
            (weight-y (- ONE_8 weight-x))            
        )
        (contract-call? .weighted-equation-v1-01 get-y-given-price balance-x balance-y weight-x weight-y price)
    )
)

;; @desc units of pool token to be minted given amount of token-x and token-y being added
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-token-given-position (token-x principal) (token-y principal) (expiry uint) (dx uint) (max-dy (optional uint)))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (- ONE_8 weight-x))       
        )
        (contract-call? .weighted-equation-v1-01 get-token-given-position balance-x balance-y weight-x weight-y total-supply dx (default-to u340282366920938463463374607431768211455 max-dy))
    )
)

;; @desc units of token-x/token-y required to mint given units of pool-token
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param token; units of pool token to be minted
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-mint (token-x principal) (token-y principal) (expiry uint) (shares uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))     
            (weight-x (get weight-x-t pool))
            (weight-y (- ONE_8 weight-x))                         
        )
        (contract-call? .weighted-equation-v1-01 get-position-given-mint balance-x balance-y weight-x weight-y total-supply shares)
    )
)

;; @desc units of token-x/token-y to be returned after burning given units of pool-token
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param expiry; expiry
;; @param token; units of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-burn (token-x principal) (token-y principal) (expiry uint) (shares uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, expiry: expiry }) ERR-INVALID-POOL))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (get weight-x-t pool))
            (weight-y (- ONE_8 weight-x))                  
        )
        (contract-call? .weighted-equation-v1-01 get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)
    )
)

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