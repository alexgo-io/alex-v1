(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; simple-weight-pool
;; simple-weight-pool implements 50:50 fixed-weight-pool-v1-01 (i.e. uniswap)
;; simple-weight-pool is anchored to STX (and routes other tokens)

(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-POOL (err u2001))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-EXCEEDS-MAX-SLIPPAGE (err u2020))
(define-constant ERR-ORACLE-NOT-ENABLED (err u7002))
(define-constant ERR-ORACLE-ALREADY-ENABLED (err u7003))
(define-constant ERR-ORACLE-AVERAGE-BIGGER-THAN-ONE (err u7004))
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
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal,
    token-y: principal
  }
)

(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal
  }
  {
    total-supply: uint,
    balance-x: uint,
    balance-y: uint,
    fee-to-address: principal,
    pool-token: principal,
    fee-rate-x: uint,
    fee-rate-y: uint,
    fee-rebate: uint,
    oracle-enabled: bool,
    oracle-average: uint,
    oracle-resilient: uint,
    start-block: uint,
    end-block: uint
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 500 uint) (list))

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
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response (tuple) uint)
(define-read-only (get-pool-details (token-x principal) (token-y principal))
    (ok (unwrap! (get-pool-exists token-x token-y) ERR-INVALID-POOL))
)

;; @desc get-pool-exists
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (optional (tuple))
(define-read-only (get-pool-exists (token-x principal) (token-y principal))
    (map-get? pools-data-map { token-x: token-x, token-y: token-y }) 
)

;; @desc get-balances ({balance-x, balance-y})
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-balances (token-x principal) (token-y principal))
  (let
    (
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
    )
    (ok {balance-x: (get balance-x pool), balance-y: (get balance-y pool)})
  )
)

(define-read-only (get-start-block (token-x principal) (token-y principal))
    (ok (get start-block (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

(define-public (set-start-block (token-x principal) (token-y principal) (new-start-block uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y } 
                (merge pool {start-block: new-start-block})
            )
        )    
    )
)

(define-read-only (get-end-block (token-x principal) (token-y principal))
    (ok (get end-block (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

(define-public (set-end-block (token-x principal) (token-y principal) (new-end-block uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y } 
                (merge pool {end-block: new-end-block})
            )
        )    
    )
)

(define-private (check-pool-status (token-x principal) (token-y principal))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (ok (asserts! (and (>= block-height (get start-block pool)) (<= block-height (get end-block pool))) ERR-NOT-AUTHORIZED))
    )
)

;; @desc get-oracle-enabled
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response bool uint)
(define-read-only (get-oracle-enabled (token-x principal) (token-y principal))
    (ok 
        (get 
            oracle-enabled 
            (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y}) ERR-INVALID-POOL)
        )
    )
)

;; @desc set-oracle-enabled
;; @desc oracle can only be enabled
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response bool uint)
(define-public (set-oracle-enabled (token-x principal) (token-y principal))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (asserts! (not (get oracle-enabled pool)) ERR-ORACLE-ALREADY-ENABLED)
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y } 
                (merge pool {oracle-enabled: true})
            )
        )
    )    
)

;; @desc get-oracle-average
;; @desc returns the moving average used to determine oracle price
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-oracle-average (token-x principal) (token-y principal))
    (ok 
        (get 
            oracle-average 
            (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)
        )
    )
)

;; @desc set-oracle-average
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @returns (response bool uint)
(define-public (set-oracle-average (token-x principal) (token-y principal) (new-oracle-average uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (asserts! (< new-oracle-average ONE_8) ERR-ORACLE-AVERAGE-BIGGER-THAN-ONE)
        (ok 
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y } 
                (merge pool 
                    {
                    oracle-average: new-oracle-average,
                    oracle-resilient: (try! (get-oracle-instant token-x token-y))
                    }
                )
            )
        )
    )    
)

;; @desc get-oracle-resilient
;; @desc price-oracle that is less up to date but more resilient to manipulation
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-oracle-resilient (token-x principal) (token-y principal))
    (if (or (is-eq token-x .token-wstx) (is-eq token-y .token-wstx))
        (get-oracle-resilient-internal token-x token-y)
        (ok
            (div-down                
                (try! (get-oracle-resilient-internal .token-wstx token-y))
                (try! (get-oracle-resilient-internal .token-wstx token-x))                
            )
        )
    )
)

(define-private (get-oracle-resilient-internal (token-x principal) (token-y principal))
    (let
        (
            (pool 
                (if (is-some (get-pool-exists token-x token-y))
                    (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)
                    (unwrap! (map-get? pools-data-map { token-x: token-y, token-y: token-x }) ERR-INVALID-POOL)
                )
            )
        )
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (ok (+ (mul-down (- ONE_8 (get oracle-average pool)) (try! (get-oracle-instant-internal token-x token-y))) 
            (mul-down (get oracle-average pool) (get oracle-resilient pool)))
        )           
    )
)

;; @desc get-oracle-instant
;; price of token-x in terms of token-y
;; @desc price-oracle that is more up to date but less resilient to manipulation
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-oracle-instant (token-x principal) (token-y principal))
    (if (or (is-eq token-x .token-wstx) (is-eq token-y .token-wstx))
        (get-oracle-instant-internal token-x token-y)
        (ok
            (div-down                
                (try! (get-oracle-instant-internal .token-wstx token-y))
                (try! (get-oracle-instant-internal .token-wstx token-x))                
            )
        )
    )
)

(define-private (get-oracle-instant-internal (token-x principal) (token-y principal))
    (begin                
        (if (is-some (get-pool-exists token-x token-y))
            (let
                (
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
                )
                (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
                (ok (div-down (get balance-y pool) (get balance-x pool)))
            )
            (let
                (
                    (pool (unwrap! (map-get? pools-data-map { token-x: token-y, token-y: token-x }) ERR-INVALID-POOL))
                )
                (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
                (ok (div-down (get balance-x pool) (get balance-y pool)))
            )
        )
    )
)

(define-private (add-approved-token-to-vault (token principal))
    (contract-call? .alex-vault add-approved-token token)
)

;; @desc check-err
;; @params result 
;; @params prior
;; @returns (response bool uint)
(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior 
        ok-value result
        err-value (err err-value)
    )
)

;; @desc create-pool
;; @restricted contract-owner
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param pool-token; pool token representing ownership of the pool
;; @param multisig-vote; DAO used by pool token holers
;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response bool uint)
(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (pool-token-trait <ft-trait>) (multisig-vote principal) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool-id (+ (var-get pool-count) u1))
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-to-address: multisig-vote,
                pool-token: (contract-of pool-token-trait),
                fee-rate-x: u0,
                fee-rate-y: u0,
                fee-rebate: u0,
                oracle-enabled: false,
                oracle-average: u0,
                oracle-resilient: u0,
                start-block: u340282366920938463463374607431768211455,
                end-block: u340282366920938463463374607431768211455
            })
        )

        (try! (check-is-owner))        

        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x }))
            )
            ERR-POOL-ALREADY-EXISTS
        )             

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y })
        (map-set pools-data-map { token-x: token-x, token-y: token-y } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u500) ERR-TOO-MANY-POOLS))
        (var-set pool-count pool-id)
        
        (try! (fold check-err (map add-approved-token-to-vault (list token-x token-y (contract-of pool-token-trait))) (ok true)))

        (try! (add-to-position token-x-trait token-y-trait pool-token-trait dx (some dy)))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
    )
)

;; @desc add-to-position
;; @desc returns units of pool tokens minted, dx and dy added
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param pool-token; pool token representing ownership of the pool
;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response (tuple uint uint uint) uint)
(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (pool-token-trait <ft-trait>) (dx uint) (max-dy (optional uint)))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-supply (get total-supply pool))
                (add-data (try! (get-token-given-position token-x token-y dx max-dy)))
                (new-supply (get token add-data))
                (dy (get dy add-data))
                (pool-updated (merge pool {
                    total-supply: (+ new-supply total-supply),
                    balance-x: (+ balance-x dx),
                    balance-y: (+ balance-y dy)
                }))
                (sender tx-sender)
            )
            (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
            ;; CR-01
            (asserts! (>= (default-to u340282366920938463463374607431768211455 max-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)
            (asserts! (is-eq (get pool-token pool) (contract-of pool-token-trait)) ERR-INVALID-TOKEN)

            (unwrap! (contract-call? token-x-trait transfer-fixed dx sender .alex-vault none) ERR-TRANSFER-FAILED)
            (unwrap! (contract-call? token-y-trait transfer-fixed dy sender .alex-vault none) ERR-TRANSFER-FAILED)

            ;; mint pool token and send to tx-sender
            (map-set pools-data-map { token-x: token-x, token-y: token-y } pool-updated)
            (as-contract (try! (contract-call? pool-token-trait mint-fixed new-supply sender)))
            
            (print { object: "pool", action: "liquidity-added", data: pool-updated })
            (ok {supply: new-supply, dx: dx, dy: dy})
        )
    )
)

;; @desc reduce-position
;; @desc returns dx and dy due to the position
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param pool-token; pool token representing ownership of the pool
;; @param percent; percentage of pool token held to reduce
;; @returns (response (tuple uint uint) uint)
(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (pool-token-trait <ft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-shares (unwrap-panic (contract-call? pool-token-trait get-balance-fixed tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
                (total-supply (get total-supply pool))
                (reduce-data (try! (get-position-given-burn token-x token-y shares)))
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

            (as-contract (try! (contract-call? .alex-vault transfer-ft-two token-x-trait dx token-y-trait dy sender)))

            (map-set pools-data-map { token-x: token-x, token-y: token-y } pool-updated)

            (as-contract (try! (contract-call? pool-token-trait burn-fixed shares sender)))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

;; @desc swap-wstx-for-y
;; @params token-y-trait; ft-trait
;; @params dx 
;; @params min-dy 
;; @returns (ok (tuple))
(define-public (swap-wstx-for-y (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))    
    (begin
        (try! (check-pool-status .token-wstx (contract-of token-y-trait)))
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)      
        (let
            (
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; fee = dx * fee-rate-x
                (fee (mul-up dx (get fee-rate-x pool)))
                (dx-net-fees (if (<= dx fee) u0 (- dx fee)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))
    
                (dy (try! (get-y-given-wstx token-y dx-net-fees)))                

                (pool-updated
                    (merge pool
                        {
                        balance-x: (+ balance-x dx-net-fees fee-rebate),
                        balance-y: (if (<= balance-y dy) u0 (- balance-y dy)),
                        oracle-resilient:   (if (get oracle-enabled pool) 
                                                (try! (get-oracle-resilient .token-wstx token-y))
                                                u0
                                            )
                        }
                    )
                )
                (sender tx-sender)             
            )

            ;; a / b <= c / d == ad <= bc for b, d >=0
            (asserts! (<= (mul-down dy balance-x) (mul-down dx-net-fees balance-y)) ERR-INVALID-LIQUIDITY)
            (asserts! (<= (default-to u0 min-dy) dy) ERR-EXCEEDS-MAX-SLIPPAGE)
        
            (unwrap! (contract-call? .token-wstx transfer-fixed dx sender .alex-vault none) ERR-TRANSFER-FAILED)
            (and (> dy u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-y-trait dy sender))))
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance .token-wstx (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: .token-wstx, token-y: token-y } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

;; @desc swap-y-for-wstx 
;; @params token-y-trait
;; @params dy
;; @params dx
;; @returns (response tuple)
(define-public (swap-y-for-wstx (token-y-trait <ft-trait>) (dy uint) (min-dx (optional uint)))
    (begin
        (try! (check-pool-status .token-wstx (contract-of token-y-trait)))
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; fee = dy * fee-rate-y
                (fee (mul-up dy (get fee-rate-y pool)))
                (dy-net-fees (if (<= dy fee) u0 (- dy fee)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))

                (dx (try! (get-wstx-given-y token-y dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                        balance-x: (if (<= balance-x dx) u0 (- balance-x dx)),
                        balance-y: (+ balance-y dy-net-fees fee-rebate),
                        oracle-resilient:   (if (get oracle-enabled pool) 
                                                (try! (get-oracle-resilient .token-wstx token-y))
                                                u0
                                            )
                        }
                    )
                )
                (sender tx-sender)
            )
            ;; a / b >= c / d == ac >= bc for b, d >= 0
            (asserts! (>= (mul-down dy-net-fees balance-x) (mul-down dx balance-y)) ERR-INVALID-LIQUIDITY)
            (asserts! (<= (default-to u0 min-dx) dx) ERR-EXCEEDS-MAX-SLIPPAGE)
        
            (and (> dx u0) (as-contract (try! (contract-call? .alex-vault transfer-ft .token-wstx dx sender))))
            (unwrap! (contract-call? token-y-trait transfer-fixed dy sender .alex-vault none) ERR-TRANSFER-FAILED)
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance token-y (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: .token-wstx, token-y: token-y } pool-updated)
            (print { object: "pool", action: "swap-y-for-x", data: pool-updated })
            (ok {dx: dx, dy: dy-net-fees})
        )
    )
)

;; @desc swap-x-for-y
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param dx; amount of token-x to swap
;; @param min-dy; optional, min amount of token-y to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (ok 
        {
            dx: dx, 
            dy: 
                (if (is-eq (contract-of token-x-trait) .token-wstx)
                    (get dy (try! (swap-wstx-for-y token-y-trait dx min-dy)))
                    (if (is-eq (contract-of token-y-trait) .token-wstx)
                        (get dx (try! (swap-y-for-wstx token-x-trait dx min-dy)))
                        (get dy (try! (swap-wstx-for-y token-y-trait (get dx (try! (swap-y-for-wstx token-x-trait dx none))) min-dy)))
                    )
                )
        }
    )
)

;; @desc swap-y-for-x
;; @param token-x-trait; token-x
;; @param token-y-trait; token-y
;; @param dy; amount of token-y to swap
;; @param min-dx; optional, min amount of token-x to receive
;; @returns (response (tuple uint uint) uint)
(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dy uint) (min-dx (optional uint)))
    (ok 
        {
            dx:
                (if (is-eq (contract-of token-x-trait) .token-wstx)
                    (get dx (try! (swap-y-for-wstx token-y-trait dy min-dx)))
                    (if (is-eq (contract-of token-y-trait) .token-wstx)
                        (get dy (try! (swap-wstx-for-y token-x-trait dy min-dx)))
                        (get dy (try! (swap-wstx-for-y token-x-trait (get dx (try! (swap-y-for-wstx token-y-trait dy none))) min-dx)))
                    )
                ),
            dy: dy
        }
    )
)

;; @desc get-fee-rebate
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @returns (response uint uint)
(define-read-only (get-fee-rebate (token-x principal) (token-y principal))
    (ok (get fee-rebate (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

;; @desc set-fee-rebate
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param fee-rebate; new fee-rebate
;; @returns (response bool uint)
(define-public (set-fee-rebate (token-x principal) (token-y principal) (fee-rebate uint))
    (let 
        (            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y 
            }
            (merge pool { fee-rebate: fee-rebate })
        )
        (ok true)     
    )
)

;; @desc get-fee-rate-x
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-fee-rate-x (token-x principal) (token-y principal))
    (ok (get fee-rate-x (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

;; @desc get-fee-rate-y
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-fee-rate-y (token-x principal) (token-y principal))
    (ok (get fee-rate-y (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

;; @desc set-fee-rate-x
;; @restricted fee-to-address
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param fee-rate-x; new fee-rate-x
;; @returns (response bool uint)
(define-public (set-fee-rate-x (token-x principal) (token-y principal) (fee-rate-x uint))
    (let 
        (        
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (asserts! (or (is-eq tx-sender (get fee-to-address pool)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y 
            }
            (merge pool { fee-rate-x: fee-rate-x })
        )
        (ok true)     
    )
)

;; @desc set-fee-rate-y
;; @restricted fee-to-address
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param fee-rate-y; new fee-rate-y
;; @returns (response bool uint)
(define-public (set-fee-rate-y (token-x principal) (token-y principal) (fee-rate-y uint))
    (let 
        (    
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (asserts! (or (is-eq tx-sender (get fee-to-address pool)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y 
            }
            (merge pool { fee-rate-y: fee-rate-y })
        )
        (ok true)     
    )
)

;; @desc get-fee-to-address
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response principal uint)
(define-read-only (get-fee-to-address (token-x principal) (token-y principal))
    (ok (get fee-to-address (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL)))
)

(define-public (set-fee-to-address (token-x principal) (token-y principal) (fee-to-address principal))
    (let 
        (
            (pool (try! (get-pool-details token-x token-y)))
        )
        (try! (check-is-owner))

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y 
            }
            (merge pool { fee-to-address: fee-to-address })
        )
        (ok true)     
    )
)

;; @desc get-y-given-wstx
;; @params token-y-trait; ft-trait 
;; @params dx 
;; @returns (respons uint uint)
(define-read-only (get-y-given-wstx (token-y principal) (dx uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-y-given-x (get balance-x pool) (get balance-y pool) dx)        
    )
)

;; @desc get-wstx-given-y
;; @params token-y-trait; ft-trait 
;; @params dy
;; @returns (respons uint uint)
(define-read-only (get-wstx-given-y (token-y principal) (dy uint)) 
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-x-given-y (get balance-x pool) (get balance-y pool) dy)
    )
)

;; @desc units of token-y given units of token-x
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param dx; amount of token-x being added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (token-x principal) (token-y principal) (dx uint))
    (if (is-eq token-x .token-wstx)
        (get-y-given-wstx token-y dx)
        (if (is-eq token-y .token-wstx)
            (get-wstx-given-y token-x dx)
            (get-y-given-wstx token-y (try! (get-wstx-given-y token-x dx)))
        )
    )
)

;; @desc units of token-x given units of token-y
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param dy; amount of token-y being added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (token-x principal) (token-y principal) (dy uint)) 
    (if (is-eq token-x .token-wstx)
        (get-wstx-given-y token-y dy)
        (if (is-eq token-y .token-wstx)
            (get-y-given-wstx token-x dy)
            (get-y-given-wstx token-x (try! (get-wstx-given-y token-y dy)))
        )
    )
)

(define-read-only (get-y-in-given-wstx-out (token-y principal) (dx uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-y-in-given-x-out (get balance-x pool) (get balance-y pool) dx)        
    )
)

(define-read-only (get-wstx-in-given-y-out (token-y principal) (dy uint)) 
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wstx, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-x-in-given-y-out (get balance-x pool) (get balance-y pool) dy)
    )
)

(define-read-only (get-y-in-given-x-out (token-x principal) (token-y principal) (dx uint))
    (if (is-eq token-x .token-wstx)
        (get-y-in-given-wstx-out token-y dx)
        (if (is-eq token-y .token-wstx)
            (get-wstx-in-given-y-out token-x dx)
            (get-y-in-given-wstx-out token-y (try! (get-wstx-in-given-y-out token-x dx)))
        )
    )
)

(define-read-only (get-x-in-given-y-out (token-x principal) (token-y principal) (dy uint)) 
    (if (is-eq token-x .token-wstx)
        (get-wstx-in-given-y-out token-y dy)
        (if (is-eq token-y .token-wstx)
            (get-y-in-given-wstx-out token-x dy)
            (get-y-in-given-wstx-out token-x (try! (get-wstx-in-given-y-out token-y dy)))
        )
    )
)

;; @desc units of token-x required for a target price
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (token-x principal) (token-y principal) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-x-given-price (get balance-x pool) (get balance-y pool) price)
    )
)

;; @desc units of token-y required for a target price
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (token-x principal) (token-y principal) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-y-given-price (get balance-x pool) (get balance-y pool) price)
    )
)

;; @desc units of pool token to be minted given amount of token-x and token-y being added
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-token-given-position (token-x principal) (token-y principal) (dx uint) (max-dy (optional uint)))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-token-given-position (get balance-x pool) (get balance-y pool) (get total-supply pool) dx (default-to u340282366920938463463374607431768211455 max-dy))
    )
)

;; @desc units of token-x/token-y required to mint given units of pool-token
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param token; units of pool token to be minted
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-mint (token-x principal) (token-y principal) (token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-position-given-mint (get balance-x pool) (get balance-y pool) (get total-supply pool) token)
    )
)

;; @desc units of token-x/token-y to be returned after burning given units of pool-token
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param token; units of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-burn (token-x principal) (token-y principal) (token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y }) ERR-INVALID-POOL))
        )
        (contract-call? .simple-equation get-position-given-burn (get balance-x pool) (get balance-y pool) (get total-supply pool) token)
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
 
;; @desc swap
;; @params token-x-trait; ft-trait
;; @params token-y-trait; ft-trait
;; @params dx
;; @params mi-dy
;; @returns (response uint)
(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (dx uint) (min-dy (optional uint)))
    (ok (get dy (try! (swap-x-for-y token-x-trait token-y-trait dx min-dy))))
)

;; @desc get-x-y
;; @params token-x-trait; ft-trait
;; @params token-y-trait; ft-trait
;; @params dy
;; @returns (response uint uint)
(define-read-only (get-helper (token-x principal) (token-y principal) (dx uint))
    (get-y-given-x token-x token-y dx)
)

;; contract initialisation
;; (set-contract-owner .executor-dao)