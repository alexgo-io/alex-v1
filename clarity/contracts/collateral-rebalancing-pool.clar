;;(impl-trait .trait-pool.pool-trait)

(use-trait equation-trait .trait-equation.equation-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait vault-trait .trait-vault.vault-trait)
;;(use-trait oracle-trait .trait-oracle.oracle-trait)

;; collateral-rebalancing-pool
;; <add a description here>
;; delta update happens every time contract is called
;; currently it does not support single asset liquidity provision

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant invalid-pool-err (err u201))
(define-constant no-liquidity-err (err u61))
(define-constant invalid-liquidity-err (err u202))
(define-constant transfer-x-failed-err (err u72))
(define-constant transfer-y-failed-err (err u73))
(define-constant pool-already-exists-err (err u69))
(define-constant too-many-pools-err (err u68))
(define-constant percent-greater-than-one (err u5))

(define-constant a1 u27839300)
(define-constant a2 u23038900)
(define-constant a3 u97200)
(define-constant a4 u7810800)
(define-constant oracle-src "nothing")

;; data maps and vars
;;
(define-map pools-map
  { pool-id: uint }
  {
    token-x: principal, ;;token
    token-y: principal, ;;collateral
    strike: uint,
    bs-vol: uint
  }
)

(define-map pools-data-map
  {
    token-x: principal,
    token-y: principal,
    strike: uint,
    bs-vol: uint
  }
  {
    total-supply: uint,
    balance-x: uint,
    balance-y: uint,
    weight-x: uint,
    weight-y: uint,
    fee-balance-x: uint,
    fee-balance-y: uint,
    fee-to-address: principal,
    yield-token: principal,
    equation: principal
  }
)

(define-data-var pool-count uint u0)
(define-data-var pools-list (list 2000 uint) (list))

;; private functions
;;

;; Approximation of Error Function using Abramowitz and Stegun
;; https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
(define-private (erf (x uint))
    (let
        (
            (a1x (unwrap-panic (contract-call? .math-fixed-point mul-down a1 x)))
            (x2 (unwrap-panic (contract-call? .math-fixed-point pow-down x u200000000)))
            (a2x (unwrap-panic (contract-call? .math-fixed-point mul-down a2 x2)))
            (x3 (unwrap-panic (contract-call? .math-fixed-point pow-down x u300000000)))
            (a3x (unwrap-panic (contract-call? .math-fixed-point mul-down a3 x3)))
            (x4 (unwrap-panic (contract-call? .math-fixed-point pow-down x u400000000)))
            (a4x (unwrap-panic (contract-call? .math-fixed-point mul-down a4 x4)))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8 a1x)))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed denom a2x)))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed denom a3x)))
            (denom (unwrap-panic (contract-call? .math-fixed-point add-fixed denom a4x)))
            (denom (unwrap-panic (contract-call? .math-fixed-point pow-down denom u400000000)))
            (base (unwrap-panic (contract-call? .math-fixed-point div-down ONE_8 denom))))
        )
    )
    
    (contract-call? .math-fixed-point sub-fixed ONE_8 base)
)

;; BUG: sqrti needs re-written
(define-private (get-weight-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-yield-token <yield-token-trait>))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol }) invalid-pool-err))                  
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (weight-x (get weight-x pool))
            (weight-y (get weight-y pool))

            ;; use itself as price oracle, rather than using external
            ;; probably it doesn't work?
            (bxwy (unwrap-panic (contract-call? .math-fixed-point mul-up balance-x weight-y)))
            (bywx (unwrap-panic (contract-call? .math-fixed-point mul-down balance-y weight-x)))
            (spot (unwrap-panic (contract-call? .math-fixed-point div-up bxwy bywx))
            ;;(symbol (concat (unwrap-panic (as-max-len? (unwrap-panic (contract-call? token-x-trait get-symbol)) u15)) 
            ;;        (concat "-" (unwrap-panic (as-max-len? (unwrap-panic (contract-call? token-y-trait get-symbol)) u15))))
            ;;(spot (contract-call? the-oracle oracle-src symbol))            

            (t (unwrap-panic (contract-call? the-yield-token get-maturity)))
            ;; TODO APYs assumed zero            
            (ln-spot (unwrap-panic (contract-call? .math-fixed-point div-up spot strike)))
            (ln-spot (unwrap-panic (contract-call? .math-log-exp ln-fixed sk)))
            (rand (unwrap-panic (contract-call? .math-fixed-point pow-down bs-vol u200000000)))
            (rand (unwrap-panic (contract-call? .math-fixed-point div-up rand u200000000)))
            (rand (unwrap-panic (contract-call? .math-fixed-point mul-up rand t)))
            (numer (unwrap-panic (contract-call? .math-fixed-point add-fixed ln-spot rand)))
            (sqrt-t (unwrap-panic (contract-call? .math-fixed-point pow-down t u50000000)))
            (denom (unwrap-panic (contract-call? .math-fixed-point mul-down bs-vol sqrt-t)))
            (d1 (unwrap-panic (contract-call? .math-fixed-point div-up numer denom)))
            (sqrt-2 (unwrap-panic (contract-call? .math-fixed-point pow-down u200000000 u50000000)))
            (d1 (unwrap-panic (contract-call? .math-fixed-point div-up d1 sqrt-2))) 
            (d1 (unwrap-panic (erf d1)))           
            (d1 (unwrap-panic (contract-call? .math-fixed-point add-fixed ONE_8 d1)))            
       )
       (contract-call? .math-fixed-point div-up d1 u200000000)        
    )
)

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
(define-read-only (get-pool-details (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint))
    (let 
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (map-get? pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol }))
       )
        (if (is-some pool)
            (ok pool)
            (err invalid-pool-err)
       )
   )
)

(define-public (create-pool (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-equation <equation-trait>) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint)) 
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool-id (+ (var-get pool-count) u1))
            (pool-data {
                total-supply: u0,
                balance-x: u0,
                balance-y: u0,
                weight-x: u0,
                weight-y: u1,
                fee-balance-x: u0,
                fee-balance-y: u0,
                fee-to-address: (contract-of the-yield-token),
                yield-token: (contract-of the-yield-token),
            })
       )
        (asserts!
            (and
                (is-none (map-get? pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol }))
                (is-none (map-get? pools-data-map { token-x: token-y, token-y: token-x, strike: strike, bs-vol: bs-vol }))
           )
            pool-already-exists-err
       )

        (map-set pools-map { pool-id: pool-id } { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol })
        (map-set pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol } pool-data)
        
        (var-set pools-list (unwrap! (as-max-len? (append (var-get pools-list) pool-id) u2000) too-many-pools-err))
        (var-set pool-count pool-id)
        (try! (add-to-position token-x-trait token-y-trait strike bs-vol the-equation the-yield-token the-vault dx dy))
        (print { object: "pool", action: "created", data: pool-data })
        (ok true)
   )
)

(define-public (add-to-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-equation <equation-trait>) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (dx uint) (dy uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap! (map-get? pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol }) invalid-pool-err))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait strike bs-vol the-yield-token)))
            (weight-y (- u1 weight-x))
            (add-data (unwrap-panic (contract-call? the-equation get-token-given-position balance-x balance-y weight-x weight-y total-supply dx dy)))
            (new-supply (get token add-data))
            (new-dy (get dy add-data))
            (pool-updated (merge pool {
                total-supply: (+ new-supply (get total-supply pool)),
                balance-x: (+ balance-x dx),
                balance-y: (+ balance-y new-dy),
                weight-x: weight-x,
                weight-y: weight-y
            }))
       )

        (asserts! (and (> dx u0) (> new-dy u0)) invalid-liquidity-err)

        ;; send x to vault
        (asserts! (is-ok (contract-call? token-x-trait transfer dx tx-sender (contract-of the-vault) none)) transfer-x-failed-err)
        ;; send y to vault
        (asserts! (is-ok (contract-call? token-y-trait transfer new-dy tx-sender (contract-of the-vault) none)) transfer-y-failed-err)
        ;; mint pool token and send to tx-sender
        (map-set pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol } pool-updated)
        (try! (contract-call? the-yield-token mint tx-sender new-supply))
        (print { object: "pool", action: "liquidity-added", data: pool-updated })
        (ok true)
   )
)    

(define-public (reduce-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-equation <equation-trait>) (the-yield-token <yield-token-trait>) (the-vault <vault-trait>) (percent uint))
    (let
        (
            (token-x (contract-of token-x-trait))
            (token-y (contract-of token-y-trait))
            (pool (unwrap-panic (map-get? pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol })))
            (balance-x (get balance-x pool))
            (balance-y (get balance-y pool))
            (shares (* (unwrap-panic (contract-call? the-yield-token get-balance tx-sender)) (/ percent u100)))
            (total-supply (get total-supply pool))
            (weight-x (unwrap-panic (get-weight-x token-x-trait token-y-trait strike bs-vol the-yield-token)))
            (weight-y (- u1 weight-x))            
            (reduce-data (unwrap-panic (contract-call? the-equation get-position-given-burn balance-x balance-y weight-x weight-y total-supply shares)))
            (dx (get dx reduce-data))
            (dy (get dy reduce-data))
            (pool-updated (merge pool {
                total-supply: (- total-supply shares),
                balance-x: (- (get balance-x pool) dx),
                balance-y: (- (get balance-y pool) dy),
                weight-x: weight-x,
                weight-y: weight-y
                })
           )
       )

        (asserts! (<= percent u100) percent-greater-than-one)
        (asserts! (is-ok (contract-call? token-x-trait transfer dx (contract-of the-vault) tx-sender none)) transfer-x-failed-err)
        (asserts! (is-ok (contract-call? token-y-trait transfer dy (contract-of the-vault) tx-sender none)) transfer-y-failed-err)

        (map-set pools-data-map { token-x: token-x, token-y: token-y, strike: strike, bs-vol: bs-vol } pool-updated)
        (try! (contract-call? the-yield-token burn tx-sender shares))

        (print { object: "pool", action: "liquidity-removed", data: pool-updated })
        (ok {dx: dx, dy: dy})
   )
)

(define-public (swap-x-for-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-equation <equation-trait>) (dx uint))
    (ok true)
)

(define-public (swap-y-for-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-equation <equation-trait>) (dy uint))
    (ok true)
)

(define-public (set-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (address principal))
    (ok true)
)

(define-read-only (get-fee-to-address (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint))
    ;; return principal
    (ok none)
)

(define-read-only (get-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint))
    (ok {x: u0, y: u0})
)

(define-public (collect-fees (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint))
    (ok true)
)

(define-read-only (get-y-given-x (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (dx uint))
    (ok u0)
)

(define-read-only (get-x-given-y (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (dy uint))
    (ok u0)
)

(define-read-only (get-x-given-price (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (price uint))
    (ok u0)
)

(define-read-only (get-token-given-position (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-yield-token <yield-token-trait>) (x uint) (y uint))
    (ok {token: u0, y: u0})
)

(define-read-only (get-position-given-mint (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-yield-token <yield-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)

(define-read-only (get-position-given-burn (token-x-trait <ft-trait>) (token-y-trait <ft-trait>) (strike uint) (bs-vol uint) (the-yield-token <yield-token-trait>) (token uint))
    (ok {x: u0, y: u0})
)