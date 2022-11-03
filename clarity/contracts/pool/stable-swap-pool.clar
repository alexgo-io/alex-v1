(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; stable-swap-pool

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


(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal,
    factor: uint
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
    end-block: uint,
    threshold-x: uint,
    threshold-y: uint
  }
)

;; @desc get-pool-details
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response (tuple) uint)
(define-read-only (get-pool-details (token-x principal) (token-y principal) (factor uint))
    (ok (unwrap! (get-pool-exists token-x token-y factor) ERR-INVALID-POOL))
)

;; @desc get-pool-exists
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (optional (tuple))
(define-read-only (get-pool-exists (token-x principal) (token-y principal) (factor uint))
    (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) 
)

;; @desc get-balances ({balance-x, balance-y})
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-balances (token-x principal) (token-y principal) (factor uint) (factor uint))
  (let
    (
      (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
    )
    (ok {balance-x: (get balance-x pool), balance-y: (get balance-y pool)})
  )
)

(define-read-only (get-start-block (token-x principal) (token-y principal) (factor uint))
    (ok (get start-block (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

(define-public (set-start-block (token-x principal) (token-y principal) (factor uint) (new-start-block uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y, factor: factor } 
                (merge pool {start-block: new-start-block})
            )
        )    
    )
)

(define-read-only (get-end-block (token-x principal) (token-y principal) (factor uint))
    (ok (get end-block (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

(define-public (set-end-block (token-x principal) (token-y principal) (factor uint) (new-end-block uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y, factor: factor } 
                (merge pool {end-block: new-end-block})
            )
        )    
    )
)

(define-private (check-pool-status (token-x principal) (token-y principal) (factor uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (ok (asserts! (and (>= block-height (get start-block pool)) (<= block-height (get end-block pool))) ERR-NOT-AUTHORIZED))
    )
)

;; @desc get-oracle-enabled
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response bool uint)
(define-read-only (get-oracle-enabled (token-x principal) (token-y principal) (factor uint))
    (ok 
        (get 
            oracle-enabled 
            (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor}) ERR-INVALID-POOL)
        )
    )
)

;; @desc set-oracle-enabled
;; @desc oracle can only be enabled
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response bool uint)
(define-public (set-oracle-enabled (token-x principal) (token-y principal) (factor uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (asserts! (not (get oracle-enabled pool)) ERR-ORACLE-ALREADY-ENABLED)
        (ok
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y, factor: factor } 
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
(define-read-only (get-oracle-average (token-x principal) (token-y principal) (factor uint))
    (ok 
        (get 
            oracle-average 
            (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)
        )
    )
)

;; @desc set-oracle-average
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @returns (response bool uint)
(define-public (set-oracle-average (token-x principal) (token-y principal) (factor uint) (new-oracle-average uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (asserts! (< new-oracle-average ONE_8) ERR-ORACLE-AVERAGE-BIGGER-THAN-ONE)
        (ok 
            (map-set 
                pools-data-map 
                { token-x: token-x, token-y: token-y, factor: factor } 
                (merge pool 
                    {
                    oracle-average: new-oracle-average,
                    oracle-resilient: (try! (get-oracle-instant token-x token-y factor))
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
(define-read-only (get-oracle-resilient (token-x principal) (token-y principal) (factor uint))
    (if (or (is-eq token-x .token-wxusd) (is-eq token-y .token-wxusd))
        (get-oracle-resilient-internal token-x token-y factor)
        (ok
            (div-down                
                (try! (get-oracle-resilient-internal .token-wxusd token-y factor))
                (try! (get-oracle-resilient-internal .token-wxusd token-x factor))                
            )
        )
    )
)

(define-private (get-oracle-resilient-internal (token-x principal) (token-y principal) (factor uint))
    (let
        (
            (exists (is-some (get-pool-exists token-x token-y factor)))
            (pool
                (if exists
                    (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)
                    (unwrap! (map-get? pools-data-map { token-x: token-y, token-y: token-x, factor: factor }) ERR-INVALID-POOL)                    
                )
            )
        )
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (ok (+ (mul-down (- ONE_8 (get oracle-average pool)) (try! (get-oracle-instant-internal token-x token-y factor))) 
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
(define-read-only (get-oracle-instant (token-x principal) (token-y principal) (factor uint))
    (if (or (is-eq token-x .token-wxusd) (is-eq token-y .token-wxusd))
        (get-oracle-instant-internal token-x token-y factor)
        (ok
            (div-down                
                (try! (get-oracle-instant-internal .token-wxusd token-y factor))
                (try! (get-oracle-instant-internal .token-wxusd token-x factor))                
            )
        )
    )
)

(define-private (get-oracle-instant-internal (token-x principal) (token-y principal) (factor uint))
    (let                 
        (
            (exists (is-some (get-pool-exists token-x token-y factor)))
            (pool
                (if exists
                    (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)
                    (unwrap! (map-get? pools-data-map { token-x: token-y, token-y: token-x, factor: factor }) ERR-INVALID-POOL)                    
                )
            )
        )
        (asserts! (get oracle-enabled pool) ERR-ORACLE-NOT-ENABLED)
        (if exists 
            (ok (div-down (get balance-y pool) (get balance-x pool)))
            (ok (div-down (get balance-x pool) (get balance-y pool)))
        )
    )
)

;; @desc correlated-token (y) per token (x)
;; @desc get-price
;; @desc b_y = balance-y
;; @desc b_x = balance-x
;; @desc price = (b_y / b_x) ^ t
;; @returns (response uint uint)
(define-read-only (get-price (token-x principal) (token-y principal) (factor uint))
    (let
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )      
        (ok (get-price-internal (get balance-x pool) (get balance-y pool) factor))
    )
)

(define-private (get-price-internal (balance-x uint) (balance-y uint) (factor uint))
    (let
        (
          (price (pow-down (div-down balance-y balance-x) factor))
        )
        (if (<= price ONE_8) ONE_8 price)
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
(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (pool-token-trait <ft-trait>) (multisig-vote principal) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
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
                end-block: u340282366920938463463374607431768211455,
                threshold-x: u0,
                threshold-y: u0
            })
        )

        (try! (check-is-owner))        

        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, factor: factor }))
            )
            ERR-POOL-ALREADY-EXISTS
        )             
        (map-set pools-data-map { token-x: token-x, token-y: token-y, factor: factor } pool-data)
        
        (try! (fold check-err (map add-approved-token-to-vault (list token-x token-y (contract-of pool-token-trait))) (ok true)))

        (try! (add-to-position token-x-trait token-y-trait factor pool-token-trait dx (some dy)))
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
(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (pool-token-trait <ft-trait>) (dx uint) (max-dy (optional uint)))
    (begin
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-supply (get total-supply pool))
                (add-data (try! (get-token-given-position token-x token-y factor dx max-dy)))
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
            (map-set pools-data-map { token-x: token-x, token-y: token-y, factor: factor } pool-updated)
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
(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (pool-token-trait <ft-trait>) (percent uint))
    (begin
        (asserts! (<= percent ONE_8) ERR-PERCENT-GREATER-THAN-ONE)
        (let
            (
                (token-x (contract-of token-x-trait))
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))
                (total-shares (unwrap-panic (contract-call? pool-token-trait get-balance-fixed tx-sender)))
                (shares (if (is-eq percent ONE_8) total-shares (mul-down total-shares percent)))
                (total-supply (get total-supply pool))
                (reduce-data (try! (get-position-given-burn token-x token-y factor shares)))
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

            (map-set pools-data-map { token-x: token-x, token-y: token-y, factor: factor } pool-updated)

            (as-contract (try! (contract-call? pool-token-trait burn-fixed shares sender)))

            (print { object: "pool", action: "liquidity-removed", data: pool-updated })
            (ok {dx: dx, dy: dy})
        )
    )
)

;; @desc swap-wxusd-for-y
;; @params token-y-trait; ft-trait
;; @params dx 
;; @params min-dy 
;; @returns (ok (tuple))
(define-public (swap-wxusd-for-y (token-y-trait <ft-trait>) (factor uint) (dx uint) (min-dy (optional uint)))    
    (begin
        (try! (check-pool-status .token-wxusd (contract-of token-y-trait) factor))
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)      
        (let
            (
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; fee = dx * fee-rate-x
                (fee (mul-up dx (get fee-rate-x pool)))
                (dx-net-fees (if (<= dx fee) u0 (- dx fee)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))
    
                (dy (try! (get-y-given-wxusd token-y factor dx-net-fees)))                

                (pool-updated
                    (merge pool
                        {
                        balance-x: (+ balance-x dx-net-fees fee-rebate),
                        balance-y: (if (<= balance-y dy) u0 (- balance-y dy)),
                        oracle-resilient:   (if (get oracle-enabled pool) 
                                                (try! (get-oracle-resilient .token-wxusd token-y factor))
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
        
            (unwrap! (contract-call? .token-wxusd transfer-fixed dx sender .alex-vault none) ERR-TRANSFER-FAILED)
            (and (> dy u0) (as-contract (try! (contract-call? .alex-vault transfer-ft token-y-trait dy sender))))
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance .token-wxusd (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor } pool-updated)
            (print { object: "pool", action: "swap-x-for-y", data: pool-updated })
            (ok {dx: dx-net-fees, dy: dy})
        )
    )
)

;; @desc swap-y-for-wxusd 
;; @params token-y-trait
;; @params dy
;; @params dx
;; @returns (response tuple)
(define-public (swap-y-for-wxusd (token-y-trait <ft-trait>) (factor uint) (dy uint) (min-dx (optional uint)))
    (begin
        (try! (check-pool-status .token-wxusd (contract-of token-y-trait) factor))
        (asserts! (> dy u0) ERR-INVALID-LIQUIDITY)
        (let
            (
                (token-y (contract-of token-y-trait))
                (pool (unwrap! (map-get? pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
                (balance-x (get balance-x pool))
                (balance-y (get balance-y pool))

                ;; fee = dy * fee-rate-y
                (fee (mul-up dy (get fee-rate-y pool)))
                (dy-net-fees (if (<= dy fee) u0 (- dy fee)))
                (fee-rebate (mul-down fee (get fee-rebate pool)))

                (dx (try! (get-wxusd-given-y token-y factor dy-net-fees)))

                (pool-updated
                    (merge pool
                        {
                        balance-x: (if (<= balance-x dx) u0 (- balance-x dx)),
                        balance-y: (+ balance-y dy-net-fees fee-rebate),
                        oracle-resilient:   (if (get oracle-enabled pool) 
                                                (try! (get-oracle-resilient .token-wxusd token-y factor))
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
        
            (and (> dx u0) (as-contract (try! (contract-call? .alex-vault transfer-ft .token-wxusd dx sender))))
            (unwrap! (contract-call? token-y-trait transfer-fixed dy sender .alex-vault none) ERR-TRANSFER-FAILED)
            (as-contract (try! (contract-call? .alex-reserve-pool add-to-balance token-y (- fee fee-rebate))))

            ;; post setting
            (map-set pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor } pool-updated)
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
(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dx uint) (min-dy (optional uint)))
    (ok 
        {
            dx: dx, 
            dy: 
                (if (is-eq (contract-of token-x-trait) .token-wxusd)
                    (get dy (try! (swap-wxusd-for-y token-y-trait factor dx min-dy)))
                    (if (is-eq (contract-of token-y-trait) .token-wxusd)
                        (get dx (try! (swap-y-for-wxusd token-x-trait factor dx min-dy)))
                        (get dy (try! (swap-wxusd-for-y token-y-trait factor (get dx (try! (swap-y-for-wxusd token-x-trait factor dx none))) min-dy)))
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
(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dy uint) (min-dx (optional uint)))
    (ok 
        {
            dx:
                (if (is-eq (contract-of token-x-trait) .token-wxusd)
                    (get dx (try! (swap-y-for-wxusd token-y-trait factor dy min-dx)))
                    (if (is-eq (contract-of token-y-trait) .token-wxusd)
                        (get dy (try! (swap-wxusd-for-y token-x-trait factor dy min-dx)))
                        (get dy (try! (swap-wxusd-for-y token-x-trait factor (get dx (try! (swap-y-for-wxusd token-y-trait factor dy none))) min-dx)))
                    )
                ),
            dy: dy
        }
    )
)

(define-read-only (get-threshold-x (token-x principal) (token-y principal) (factor uint))
    (ok (get threshold-x (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

(define-public (set-threshold-x (token-x principal) (token-y principal) (factor uint) (small-threshold uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (map-set pools-data-map { token-x: token-x, token-y: token-y, factor: factor } (merge pool { threshold-x: small-threshold }))
        (ok true)
    )
)

(define-read-only (get-threshold-y (token-x principal) (token-y principal) (factor uint))
    (ok (get threshold-y (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

(define-public (set-threshold-y (token-x principal) (token-y principal) (factor uint) (small-threshold uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))
        (map-set pools-data-map { token-x: token-x, token-y: token-y, factor: factor } (merge pool { threshold-y: small-threshold }))
        (ok true)
    )
)

;; @desc get-fee-rebate
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @returns (response uint uint)
(define-read-only (get-fee-rebate (token-x principal) (token-y principal) (factor uint))
    (ok (get fee-rebate (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

;; @desc set-fee-rebate
;; @restricted contract-owner
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param fee-rebate; new fee-rebate
;; @returns (response bool uint)
(define-public (set-fee-rebate (token-x principal) (token-y principal) (factor uint) (fee-rebate uint))
    (let 
        (            
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (try! (check-is-owner))

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, factor: factor 
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
(define-read-only (get-fee-rate-x (token-x principal) (token-y principal) (factor uint))
    (ok (get fee-rate-x (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

;; @desc get-fee-rate-y
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @returns (response uint uint)
(define-read-only (get-fee-rate-y (token-x principal) (token-y principal) (factor uint))
    (ok (get fee-rate-y (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

;; @desc set-fee-rate-x
;; @restricted fee-to-address
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param fee-rate-x; new fee-rate-x
;; @returns (response bool uint)
(define-public (set-fee-rate-x (token-x principal) (token-y principal) (factor uint) (fee-rate-x uint))
    (let 
        (        
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (asserts! (or (is-eq tx-sender (get fee-to-address pool)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, factor: factor 
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
(define-public (set-fee-rate-y (token-x principal) (token-y principal) (factor uint) (fee-rate-y uint))
    (let 
        (    
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (asserts! (or (is-eq tx-sender (get fee-to-address pool)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, factor: factor 
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
(define-read-only (get-fee-to-address (token-x principal) (token-y principal) (factor uint))
    (ok (get fee-to-address (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL)))
)

(define-public (set-fee-to-address (token-x principal) (token-y principal) (factor uint) (fee-to-address principal))
    (let 
        (
            (pool (try! (get-pool-details token-x token-y factor)))
        )
        (try! (check-is-owner))

        (map-set pools-data-map 
            { 
                token-x: token-x, token-y: token-y, factor: factor 
            }
            (merge pool { fee-to-address: fee-to-address })
        )
        (ok true)     
    )
)

;; @desc get-y-given-wxusd
;; @params token-y-trait; ft-trait 
;; @params dx 
;; @returns (respons uint uint)
(define-read-only (get-y-given-wxusd (token-y principal) (factor uint) (dx uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
            (threshold (get threshold-x pool))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
        )
        (if (> dx threshold)
            (get-y-given-x-internal balance-x balance-y factor dx)
            (let
                (
                    (dist (div-down (- threshold dx) threshold))
                )
                (ok
                    (+ 
                        (mul-down (- ONE_8 dist) (try! (get-y-given-x-internal balance-x balance-y factor threshold)))
                        (mul-down dist (mul-down dx (get-price-internal balance-x balance-y factor)))
                    )                    
                )
            )
        )
    )
)

;; @desc get-wxusd-given-y
;; @params token-y-trait; ft-trait 
;; @params dy
;; @returns (respons uint uint)
(define-read-only (get-wxusd-given-y (token-y principal) (factor uint) (dy uint)) 
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: .token-wxusd, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
            (threshold (get threshold-y pool))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))            
        )
        (if (> dy threshold)
            (get-x-given-y-internal balance-x balance-y factor dy)
            (let
                (
                    (dist (div-down (- threshold dy) threshold))
                )
                (ok 
                    (+
                        (mul-down (- ONE_8 dist) (try! (get-x-given-y-internal balance-x balance-y factor threshold)))
                        (mul-down dist (div-down dy (get-price-internal balance-x balance-y factor)))
                    )
                )
            )            
        )
    )
)

;; @desc units of token-y given units of token-x
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param dx; amount of token-x being added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (token-x principal) (token-y principal) (factor uint) (dx uint))
    (if (is-eq token-x .token-wxusd)
        (get-y-given-wxusd token-y factor dx)
        (if (is-eq token-y .token-wxusd)
            (get-wxusd-given-y token-x factor dx)
            (get-y-given-wxusd token-y factor (try! (get-wxusd-given-y token-x factor dx)))
        )
    )
)

;; @desc units of token-x given units of token-y
;; @param token-x; token-x principal
;; @param token-y; token-y principal
;; @param dy; amount of token-y being added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (token-x principal) (token-y principal) (factor uint) (dy uint)) 
    (if (is-eq token-x .token-wxusd)
        (get-wxusd-given-y token-y factor dy)
        (if (is-eq token-y .token-wxusd)
            (get-y-given-wxusd token-x factor dy)
            (get-y-given-wxusd token-x factor (try! (get-wxusd-given-y token-y factor dy)))
        )
    )
)

;; @desc units of token-x required for a target price
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (token-x principal) (token-y principal) (factor uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (get-x-given-price-internal (get balance-x pool) (get balance-y pool) factor price)
    )
)

;; @desc units of token-y required for a target price
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (token-x principal) (token-y principal) (factor uint) (price uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (get-y-given-price-internal (get balance-x pool) (get balance-y pool) factor price)
    )
)

;; @desc units of pool token to be minted given amount of token-x and token-y being added
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-token-given-position (token-x principal) (token-y principal) (factor uint) (dx uint) (max-dy (optional uint)))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (get-token-given-position-internal (get balance-x pool) (get balance-y pool) factor (get total-supply pool) dx (default-to u340282366920938463463374607431768211455 max-dy))
    )
)

;; @desc units of token-x/token-y required to mint given units of pool-token
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param token; units of pool token to be minted
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-mint (token-x principal) (token-y principal) (factor uint) (token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (get-position-given-mint-internal (get balance-x pool) (get balance-y pool) factor (get total-supply pool) token)
    )
)

;; @desc units of token-x/token-y to be returned after burning given units of pool-token
;; @param token-x; token-x principal
;; @param token-y; token-y principal

;; @param token; units of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-burn (token-x principal) (token-y principal) (factor uint) (token uint))
    (let 
        (
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, factor: factor }) ERR-INVALID-POOL))
        )
        (get-position-given-burn-internal (get balance-x pool) (get balance-y pool) factor (get total-supply pool) token)
    )
)

;; @desc swap
;; @params token-x-trait; ft-trait
;; @params token-y-trait; ft-trait
;; @params dx
;; @params mi-dy
;; @returns (response uint)
(define-public (swap-helper (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (factor uint) (dx uint) (min-dy (optional uint)))
    (ok (get dy (try! (swap-x-for-y token-x-trait token-y-trait factor dx min-dy))))
)

;; @desc get-x-y
;; @params token-x-trait; ft-trait
;; @params token-y-trait; ft-trait
;; @params dy
;; @returns (response uint uint)
(define-read-only (get-helper (token-x principal) (token-y principal) (factor uint) (dx uint))
    (get-y-given-x token-x token-y factor dx)
)

(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))

(define-data-var MAX-IN-RATIO uint (* u5 (pow u10 u6))) ;; 5%
(define-data-var MAX-OUT-RATIO uint (* u5 (pow u10 u6))) ;; 5%

(define-read-only (get-max-in-ratio)
  (var-get MAX-IN-RATIO)
)

(define-public (set-max-in-ratio (new-max-in-ratio uint))
  (begin
    (try! (check-is-owner))
    (asserts! (> new-max-in-ratio u0) ERR-MAX-IN-RATIO)    
    (var-set MAX-IN-RATIO new-max-in-ratio)
    (ok true)
  )
)

(define-read-only (get-max-out-ratio)
  (var-get MAX-OUT-RATIO)
)

(define-public (set-max-out-ratio (new-max-out-ratio uint))
  (begin
    (try! (check-is-owner))
    (asserts! (> new-max-out-ratio u0) ERR-MAX-OUT-RATIO)    
    (var-set MAX-OUT-RATIO new-max-out-ratio)
    (ok true)
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc d_y = b_y - (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_x + d_x) ^ (1 - t)) ^ (1 / (1 - t))
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param dx; amount of token added
;; @returns (response uint uint)
(define-private (get-y-given-x-internal (balance-x uint) (balance-y uint) (t uint) (dx uint))
  (begin
    (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)     
    (let 
      (
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-up ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-up balance-x t-comp))
        (y-pow (pow-up balance-y t-comp))
        (x-dx-pow (pow-down (+ balance-x dx) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term x-dx-pow) u0 (- add-term x-dx-pow)))
        (final-term (pow-up term t-comp-num))
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
;; @desc d_x = b_x - (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_y + d_y) ^ (1 - t)) ^ (1 / (1 - t))
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param dy; amount of correlated-token added
;; @returns (response uint uint)
(define-private (get-x-given-y-internal (balance-x uint) (balance-y uint) (t uint) (dy uint))
  (begin
    (asserts! (< dy (mul-down balance-y (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
    (let 
      (          
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-up ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-up balance-x t-comp))
        (y-pow (pow-up balance-y t-comp))
        (y-dy-pow (pow-down (+ balance-y dy) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term y-dy-pow) u0 (- add-term y-dy-pow)))
        (final-term (pow-up term t-comp-num))
        (dx (if (<= balance-x final-term) u0 (- balance-x final-term)))
      )
      (asserts! (< dx (mul-down balance-x (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
      (ok dx)
    )  
  )
)

;; @desc d_x = dx
;; @desc d_y = dy 
;; @desc b_x = balance-x
;; @desc b_y = balance-y
;; @desc d_y = (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_x - d_x) ^ (1 - t)) ^ (1 / (1 - t)) - b_y
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param dx; amount of token added
;; @returns (response uint uint)
(define-private (get-y-in-given-x-out-internal (balance-x uint) (balance-y uint) (t uint) (dx uint))
  (begin
    (asserts! (< dx (mul-down balance-x (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)     
    (let 
      (
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-down balance-x t-comp))
        (y-pow (pow-down balance-y t-comp))
        (x-dx-pow (pow-up (if (<= balance-x dx) u0 (- balance-x dx)) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term x-dx-pow) u0 (- add-term x-dx-pow)))
        (final-term (pow-down term t-comp-num))
        (dy (if (<= final-term balance-y) u0 (- final-term balance-y)))
      )
      (asserts! (< dy (mul-down balance-y (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
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
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param dy; amount of correlated-token added
;; @returns (response uint uint)
(define-private (get-x-in-given-y-out-internal (balance-x uint) (balance-y uint) (t uint) (dy uint))
  (begin
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
(define-read-only (get-x-given-price-internal (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (< price (get-price-internal balance-x balance-y t)) ERR-NO-LIQUIDITY) 
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
(define-read-only (get-y-given-price-internal (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (> price (get-price-internal balance-x balance-y t)) ERR-NO-LIQUIDITY) 
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

;; @desc get-invariant
;; @desc invariant = b_x ^ (1 - t) + b_y ^ (1 - t)
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param t; factor
;; @returns (response uint uint)
(define-read-only (get-invariant (balance-x uint) (balance-y uint) (t uint))
    (begin
        (ok (+ (pow-down balance-x (- ONE_8 t)) (pow-down balance-y (- ONE_8 t))))
    )
)

;; @desc get-token-given-position
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param dx; amount of token added
;; @returns (response (tuple uint uint) uint)
(define-private (get-token-given-position-internal (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (dx uint) (dy uint))
  (begin
    (asserts! (and (> dx u0) (> dy u0))  ERR-NO-LIQUIDITY)
    (ok
      (if (is-eq total-supply u0)
        {token: (unwrap-panic (get-invariant dx dy t)), dy: dy}
        {token: (mul-down total-supply (div-down dx balance-x)), dy: (mul-down balance-y (div-down dx balance-x))}
      )            
    )
  )
)

;; @desc get-position-given-mint
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (correlated-token)
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
;; @param balance-y; balance of token-y (correlated-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param token; amount of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-private (get-position-given-burn-internal (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
    (get-position-given-mint-internal balance-x balance-y t total-supply token)
)

(define-constant ONE_8 u100000000) ;; 8 decimal places
(define-constant MAX_POW_RELATIVE_ERROR u4) 

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)

(define-private (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_8) b)
   )
)

(define-private (div-up (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (+ u1 (/ (- (* a ONE_8) u1) b))
    )
)

(define-private (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (if (< raw max-error)
            u0
            (- raw max-error)
        )
    )
)

(define-private (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (+ raw max-error)
    )
)

(define-constant UNSIGNED_ONE_8 (pow 10 8))
(define-constant MAX_NATURAL_EXPONENT (* 69 UNSIGNED_ONE_8))
(define-constant MIN_NATURAL_EXPONENT (* -18 UNSIGNED_ONE_8))
(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint UNSIGNED_ONE_8)))
(define-constant x_a_list_no_deci (list {x_pre: 6400000000, a_pre: 62351490808116168829, use_deci: false} ))

(define-constant x_a_list (list 
{x_pre: 3200000000, a_pre: 78962960182680695161, use_deci: true} ;; x2 = 2^5, a2 = e^(x2)
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

(define-constant ERR-X-OUT-OF-BOUNDS (err u5009))
(define-constant ERR-Y-OUT-OF-BOUNDS (err u5010))
(define-constant ERR-PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant ERR-INVALID-EXPONENT (err u5012))
(define-constant ERR-OUT-OF-BOUNDS (err u5013))

(define-private (ln-priv (a int))
  (let
    (
      (a_sum_no_deci (fold accumulate_division x_a_list_no_deci {a: a, sum: 0}))
      (a_sum (fold accumulate_division x_a_list {a: (get a a_sum_no_deci), sum: (get sum a_sum_no_deci)}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a UNSIGNED_ONE_8) UNSIGNED_ONE_8) (+ out_a UNSIGNED_ONE_8)))
      (z_squared (/ (* z z) UNSIGNED_ONE_8))
      (div_list (list 3 5 7 9 11))
      (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
      (seriesSum (get seriesSum num_sum_zsq))
    )
    (+ out_sum (* seriesSum 2))
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
    (if (>= rolling_a (if use_deci a_pre (* a_pre UNSIGNED_ONE_8)))
      {a: (/ (* rolling_a (if use_deci UNSIGNED_ONE_8 1)) a_pre), sum: (+ rolling_sum x_pre)}
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
      (next_num (/ (* rolling_num z_squared) UNSIGNED_ONE_8))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

(define-private (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (ln-priv x-int))
      (logx-times-y (/ (* lnx y-int) UNSIGNED_ONE_8))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) ERR-PRODUCT-OUT-OF-BOUNDS)
    (ok (to-uint (try! (exp-fixed logx-times-y))))
  )
)

(define-private (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (let
      (
        (x_product_no_deci (fold accumulate_product x_a_list_no_deci {x: x, product: 1}))
        (x_adj (get x x_product_no_deci))
        (firstAN (get product x_product_no_deci))
        (x_product (fold accumulate_product x_a_list {x: x_adj, product: UNSIGNED_ONE_8}))
        (product_out (get product x_product))
        (x_out (get x x_product))
        (seriesSum (+ UNSIGNED_ONE_8 x_out))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
        (sum (get seriesSum term_sum_x))
     )
      (ok (* (/ (* product_out sum) UNSIGNED_ONE_8) firstAN))
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
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) (if use_deci UNSIGNED_ONE_8 1))}
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
      (next_term (/ (/ (* rolling_term x) UNSIGNED_ONE_8) n))
      (next_sum (+ rolling_sum next_term))
   )
    {term: next_term, seriesSum: next_sum, x: x}
 )
)

(define-private (pow-fixed (x uint) (y uint))
  (begin
    (asserts! (< x (pow u2 u127)) ERR-X-OUT-OF-BOUNDS)
    (asserts! (< y MILD_EXPONENT_BOUND) ERR-Y-OUT-OF-BOUNDS)
    (if (is-eq y u0) 
      (ok (to-uint UNSIGNED_ONE_8))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

(define-private (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (if (< x 0)
      (ok (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) (try! (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

(define-private (log-fixed (arg int) (base int))
  (let
    (
      (logBase (* (ln-priv base) UNSIGNED_ONE_8))
      (logArg (* (ln-priv arg) UNSIGNED_ONE_8))
   )
    (ok (/ (* logArg UNSIGNED_ONE_8) logBase))
 )
)

(define-private (ln-fixed (a int))
  (begin
    (asserts! (> a 0) ERR-OUT-OF-BOUNDS)
    (if (< a UNSIGNED_ONE_8)
      (ok (- 0 (ln-priv (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) a))))
      (ok (ln-priv a))
   )
 )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)