(impl-trait .trait-ownable.ownable-trait)

;; simple-equation
;; simple-equation implements 50:50 weighted-equation-v1-01 (i.e. uniswap)
;; implementation of Balancer WeightedMath (https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol)

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-WEIGHT-SUM (err u4000))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))

(define-data-var contract-owner principal tx-sender)

;; max in/out as % of liquidity
(define-data-var MAX-IN-RATIO uint (* u1 (pow u10 u6))) ;; 1%
(define-data-var MAX-OUT-RATIO uint (* u1 (pow u10 u6))) ;; 1%


;; @desc get-contract-owner
;; @returns principal
(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

;; @desc set-contract-owner
;; @param new-contract-owner; new contract-owner
;; @returns (response bool uint)
(define-public (set-contract-owner (new-contract-owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner new-contract-owner))
  )
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

;; @desc get-max-in-ratio
;; @returns uint
(define-read-only (get-max-in-ratio)
  (var-get MAX-IN-RATIO)
)

;; @desc set-max-in-ratio
;; @param new-max-in-ratio; new MAX-IN-RATIO
;; @returns (response bool)
(define-public (set-max-in-ratio (new-max-in-ratio uint))
  (begin
    (try! (check-is-owner))
    ;; MI-03
    (asserts! (and (> new-max-in-ratio u0) (< new-max-in-ratio ONE_8)) ERR-MAX-IN-RATIO)
    (ok (var-set MAX-IN-RATIO new-max-in-ratio))
  )
)

;; @desc get-max-out-ratio
;; @returns unit
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
    (asserts! (and (> new-max-out-ratio u0) (< new-max-out-ratio ONE_8)) ERR-MAX-OUT-RATIO)
    (ok (var-set MAX-OUT-RATIO new-max-out-ratio))
  )
)

;; @desc get-invariant
;; @desc invariant = b_x * b_y
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @returns (response uint uint)
(define-read-only (get-invariant (balance-x uint) (balance-y uint))
  (ok (pow-down (mul-down balance-x balance-y) u50000000))
)

;; @desc get-y-given-x
;; @desc d_y = dy
;; @desc b_y = balance-y
;; @desc b_x = balance-x                /      /            b_x             \  \           
;; @desc d_x = dx          d_y = b_y * |  1 - | ---------------------------  |  |          
;; @desc w_x = weight-x                 \      \       ( b_x + d_x )        /  /           
;; @desc w_y = weight-y                                                                       
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param weight-x; weight of token-x
;; @param weight-y; weight of token-y
;; @param dx; amount of token-x added
;; @returns (response uint uint)
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (dx uint))
    (begin
        (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
        (let 
            (
              (dy (div-down (mul-down balance-y dx) (+ balance-x dx)))
            )
            (asserts! (< dy (mul-down balance-y (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
            (ok dy)
        ) 
    )    
)

;; @desc d_y = dy                                                                            
;; @desc b_y = balance-y
;; @desc b_x = balance-x              /     /            b_y             \   \          
;; @desc d_x = dx         d_x = b_x * | 1 - | --------------------------  |   |         
;; @desc w_x = weight-x               \     \       ( b_y + d_y )         /   /          
;; @desc w_y = weight-y                                                           
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param weight-x; weight of token-x
;; @param weight-y; weight of token-y
;; @param dy; amount of token-y added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (dy uint))
    (begin
        (asserts! (< dy (mul-down balance-y (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
        (let 
            (
              (dx (div-down (mul-down balance-x dy) (+ balance-y dy)))
            )
            (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
            (ok dx)
        )
    )
)

;; @desc d_y = dy                                                                            
;; @desc b_y = balance-y
;; @desc b_x = balance-x              /  /            b_y             \      \          
;; @desc d_x = dx         d_x = b_x * |  | --------------------------  | - 1  |         
;; @desc w_x = weight-x               \  \       ( b_y - d_y )         /      /          
;; @desc w_y = weight-y                                                           
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param weight-x; weight of token-x
;; @param weight-y; weight of token-y
;; @param dy; amount of token-y added
;; @returns (response uint uint)
(define-read-only (get-x-in-given-y-out (balance-x uint) (balance-y uint) (dy uint))
    (begin
        (asserts! (< dy (mul-down balance-y (var-get MAX-OUT-RATIO))) ERR-MAX-OUT-RATIO)
        (let 
            (
              (dx (div-down (mul-down balance-x dy) (- balance-y dy)))
            )
            (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
            (ok dx)
        )
    )
)

;; @desc d_y = dy                                                                            
;; @desc b_y = balance-y
;; @desc b_x = balance-x              /  /            b_x             \      \          
;; @desc d_x = dx         d_y = b_y * |  | --------------------------  | - 1  |         
;; @desc w_x = weight-x               \  \       ( b_x - d_x )         /      /          
;; @desc w_y = weight-y                                                           
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param weight-x; weight of token-x
;; @param weight-y; weight of token-y
;; @param dy; amount of token-y added
;; @returns (response uint uint)
(define-read-only (get-y-in-given-x-out (balance-x uint) (balance-y uint) (dx uint))
    (begin
        (asserts! (< dx (mul-down balance-x (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
        (let 
            (
              (dy (div-down (mul-down balance-y dx) (- balance-x dx)))
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
;; @desc spot = b_y / b_x
;; @desc d_x = b_x * ((spot / price) ^ 0.5 - 1)
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (price uint))
  (let
    (
      (spot (div-down balance-y balance-x))
      (power (pow-down (div-down spot price) u50000000))
    )
    (asserts! (< price spot) ERR-NO-LIQUIDITY)
    (ok (mul-down balance-x (if (<= power ONE_8) u0 (- power ONE_8))))
  )  
)

;; @desc follows from get-x-given-price
;; @desc d_y = b_y * ((price / spot) ^ 0.5 - 1)
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param price; target price
;; @returns (response uint uint)
(define-read-only (get-y-given-price (balance-x uint) (balance-y uint) (price uint))
  (let
    (
      (spot (div-down balance-y balance-x))
      (power (pow-down (div-down price spot) u50000000))
    )
    (asserts! (> price spot) ERR-NO-LIQUIDITY)
    (ok (mul-down balance-y (if (<= power ONE_8) u0 (- power ONE_8))))
  )
)

;; @desc get-token-given-position
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param total-supply; total supply of pool tokens
;; @param dx; amount of token-x added
;; @param dy; amount of token-y added
;; @returns (response (tutple uint uint) uint)
(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (total-supply uint) (dx uint) (dy uint))
  (ok
    (if (is-eq total-supply u0)
      {token: (unwrap-panic (get-invariant dx dy)), dy: dy}
      {token: (div-down (mul-down total-supply dx) balance-x), dy: (div-down (mul-down balance-y dx) balance-x)}
    )
  )  
)

;; @desc get-position-given-mint
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param total-supply; total supply of pool tokens
;; @param token; amount of pool token minted
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (total-supply uint) (token uint))
    (begin
        (asserts! (> total-supply u0) ERR-NO-LIQUIDITY)        
        (ok {dx: (div-down (mul-down balance-x token) total-supply), dy: (div-down (mul-down balance-y token) total-supply)})
    )
)

;; @desc get-position-given-burn
;; @param balance-x; balance of token-x
;; @param balance-y; balance of token-y
;; @param total-supply; total supply of pool tokens
;; @param token; amount of pool token to be burnt
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y total-supply token)
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

;; contract initialisation
;; (set-contract-owner .executor-dao)