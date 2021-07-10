;;(impl-trait .trait-pool.pool-trait)

(use-trait equation-trait .trait-equation.equation-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)

;; fixed-weight-pool
;; <add a description here>

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant invalid-pool-err (err u201))
(define-constant no-liquidity-err (err u61))
(define-constant invalid-liquidity-err (err u202))
(define-constant transfer-x-failed-err (err u72))
(define-constant transfer-y-failed-err (err u73))
(define-constant pool-already-exists-err (err u69))
(define-constant too-many-pools-err (err u68))
(define-constant percent-greater-than-one (err u5))

;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal,
    token-y: principal,
    weight-x: uint,
    weight-y: uint
  }
)

(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal,
    weight-x: uint,
    weight-y: uint
  }
  {
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

;; private functions
;;

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
(define-read-only (get-pool-details (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }))
       )
        (if (is-some pool)
            (ok pool)
            (err invalid-pool-err)
       )
   )
)

;; TODO: shouldn't the pool token be created as part of create-pool?
(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool-id (+ (var-get pool-count) u1))
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of the-pool-token),
                pool-token: (contract-of the-pool-token),
            })
       )
        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, weight-x: weight-y, weight-y: weight-x }))
           )
            pool-already-exists-err
       )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)
        (try! (add-to-position token-x-trait token-y-trait weight-x weight-y the-pool-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap-panic (contract-call? .weighted-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point add-fixed new-supply (get total-supply pool))),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-x dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point add-fixed balance-y new-dy))
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? token-y-trait transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
        (try! (contract-call? the-pool-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (unwrap-panic (contract-call? .math-fixed-point mul-down (unwrap-panic (contract-call? the-pool-token get-balance tx-sender)) percent)))
            (total-supply (get total-supply pool))
            (reduce-data (unwrap-panic (contract-call? .weighted-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (unwrap-panic (contract-call? .math-fixed-point sub-fixed total-supply shares)),
                balance-x: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-x pool) dx)),
                balance-y: (unwrap-panic (contract-call? .math-fixed-point sub-fixed (get balance-y pool) dy))
                })
           )
       )

        (asserts! (<= percent ONE_8) percent-greater-than-one)
        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y } pool-updated)
        (try! (contract-call? the-pool-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-equation <equation-trait>) (dx uint))
    (ok true)
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-equation <equation-trait>) (dy uint))
    (ok true)
)

(define-public (set-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (address principal))
    (ok true)
)

(define-read-only (get-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    ;; return principal
    (ok none)
)

(define-read-only (get-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (ok {x: u0, y: u0})
)

(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint))
    (ok true)
)

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dx uint))
    (ok u0)
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (dy uint))
    (ok u0)
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (price uint))
    (ok u0)
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (x uint) (y uint))
    (ok {token: u0, y: u0})
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (the-pool-token <pool-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)