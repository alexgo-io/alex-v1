(impl-trait .trait-ownable.ownable-trait)

;; yield-token-equation
;; implementation of Yield Token AMM (https://docs.alexgo.io/whitepaper/automated-market-making-of-alex)

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))
(define-constant ERR-INVALID-BALANCE (err u1001))

(define-data-var contract-owner principal tx-sender)

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
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
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
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    ;; MI-03
    (asserts! (> new-max-out-ratio u0) ERR-MAX-OUT-RATIO)    
    (var-set MAX-OUT-RATIO new-max-out-ratio)
    (ok true)
  )
)

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
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-contract-owner)
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
(define-read-only (get-price (balance-x uint) (balance-y uint) (t uint))
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
(define-read-only (get-yield (balance-x uint) (balance-y uint) (t uint))
  (let
    (
      (price (try! (get-price balance-x balance-y t)))
    )    
    ;; (ok (to-uint (unwrap-panic (ln-fixed (to-int price)))))
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
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (t uint) (dx uint))
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
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (t uint) (dy uint))
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
(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (< price (try! (get-price balance-x balance-y t))) ERR-NO-LIQUIDITY) 
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
(define-read-only (get-y-given-price (balance-x uint) (balance-y uint) (t uint) (price uint))
  (begin
    (asserts! (> price (try! (get-price balance-x balance-y t))) ERR-NO-LIQUIDITY) 
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
(define-read-only (get-x-given-yield (balance-x uint) (balance-y uint) (t uint) (yield uint))
  (get-x-given-price balance-x balance-y t (+ ONE_8 yield))
)

;; @desc follows from get-y-given-price
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param yield; target yield
;; @returns (response uint uint)
(define-read-only (get-y-given-yield (balance-x uint) (balance-y uint) (t uint) (yield uint))
  (get-y-given-price balance-x balance-y t (+ ONE_8 yield))
)

;; @desc get-token-given-position
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param total-supply; total supply of pool tokens
;; @param dx; amount of token added
;; @returns (response (tuple uint uint) uint)
(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (dx uint))
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
(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
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
(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y t total-supply token)
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