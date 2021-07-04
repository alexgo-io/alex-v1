;;(impl-trait .trait-pool.pool-trait)

(use-trait equation-trait .trait-equation.equation-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait pool-token-trait .trait-pool-token.pool-token-trait)

;; fixed-weight-pool
;; <add a description here>

;; constants
;;
(define-constant invalid-pool-err (err u201))
(define-constant no-liquidity-err (err u61))
(define-constant invalid-liquidity-err (err u202))

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
    fee-to-address: (optional principal),
    pool-token: principal,
    equation: principal
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list ))

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

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (equation-xy <equation-trait>) (pool-token-xy <pool-token-trait>))
    (ok true)
)

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (equation-xy <equation-trait>) (pool-token-xy <pool-token-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, weight-x: weight-x, weight-y: weight-y }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (add-data (unwrap-panic (contract-call? equation-xy get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (+ new-supply (get total-supply pool)),
                balance-x: (+ balance-x dx),
                balance-y: (+ balance-y new-dy)
            }))
        )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        ;; (asserts! (is-ok (contract-call? token-x-trait transfer x tx-sender contract-address none)) transfer-x-failed-err)
        ;; send y to vault
        ;; (asserts! (is-ok (contract-call? token-y-trait transfer new-y tx-sender contract-address none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        ;; (map-set pairs-data-map { token-x: token-x, token-y: token-y } pair-updated)
        ;; (try! (contract-call? swap-token-trait mint recipient-address new-shares))
        ;; (print { object: "pair", action: "liquidity-added", data: pair-updated })
        (ok true)
    )
)    

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (equation-xy <equation-trait>) (pool-token-xy <pool-token-trait>) (token uint))
    (ok true)
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (equation-xy <equation-trait>) (dx uint))
    (ok true)
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (equation-xy <equation-trait>) (dy uint))
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

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (pool-token-xy <pool-token-trait>) (x uint) (y uint))
    (ok {token: u0, y: u0})
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (pool-token-xy <pool-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (weight-x uint) (weight-y uint) (pool-token-xy <pool-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)