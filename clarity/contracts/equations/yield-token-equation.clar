(impl-trait .trait-ownable.ownable-trait)

;; yield-token-equation
;; implementation of Yield Token AMM (https://docs.alexgo.io/whitepaper/automated-market-making-of-alex)

;; constants
;;

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))
(define-constant ERR-INVALID-BALANCE (err u1001))

(define-data-var contract-owner principal tx-sender)

;; max in/out as % of liquidity
(define-data-var MAX-IN-RATIO uint (* u1 (pow u10 u6))) ;; 1%
(define-data-var MAX-OUT-RATIO uint (* u1 (pow u10 u6))) ;; 1%

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
;; @desc d_x = b_x - (b_x ^ (1 - t) + b_y ^ (1 - t) - (b_y + d_y) ^ (1 - t)) ^ (1 / (1 - t))
;; @param balance-x; balance of token-x (token)
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param dy; amount of yield-token added
;; @returns (response uint uint)
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (t uint) (dy uint))
  (begin
    (asserts! (>= balance-y dy) ERR-INVALID-BALANCE)
    (asserts! (< dy (mul-down balance-y (var-get MAX-IN-RATIO))) ERR-MAX-IN-RATIO)
    (let 
      (          
        (t-comp (if (<= ONE_8 t) u0 (- ONE_8 t)))
        (t-comp-num-uncapped (div-down ONE_8 t-comp))
        (t-comp-num (if (< t-comp-num-uncapped MILD_EXPONENT_BOUND) t-comp-num-uncapped MILD_EXPONENT_BOUND))            
        (x-pow (pow-down balance-x t-comp))
        (y-pow (pow-down balance-y t-comp))
        (y-dy-pow (pow-down (+ balance-y dy) t-comp))
        (add-term (+ x-pow y-pow))
        (term (if (<= add-term y-dy-pow) u0 (- add-term y-dy-pow)))
        (final-term (pow-down term t-comp-num))
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
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param dx; amount of token added
;; @returns (response uint uint)
(define-read-only (get-y-in-given-x-out (balance-x uint) (balance-y uint) (t uint) (dx uint))
  (begin
    (asserts! (>= balance-x dx) ERR-INVALID-BALANCE)
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
;; @param balance-y; balance of token-y (yield-token)
;; @param t; time-to-maturity
;; @param dy; amount of yield-token added
;; @returns (response uint uint)
(define-read-only (get-x-in-given-y-out (balance-x uint) (balance-y uint) (t uint) (dy uint))
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
(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (t uint) (total-supply uint) (dx uint) (dy uint))
  (begin
    (asserts! (> dx u0) ERR-NO-LIQUIDITY)
    (ok
      (if (or (is-eq total-supply u0) (is-eq balance-x balance-y)) ;; either at inception or if yield == 0
        {token: dx, dy: dy}
        {token: (mul-down total-supply (div-down dx balance-x)), dy: (mul-down balance-y (div-down dx balance-x))}
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



;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant ONE_8 u100000000) ;; 8 decimal places

;; TODO: this needs to be reviewed/updated
;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 

;; public functions
;;

;; @desc scale-up
;; @params a 
;; @returns uint
(define-read-only (scale-up (a uint))
    (* a ONE_8)
)

;; @desc scale-down
;; @params a 
;; @returns uint
(define-read-only (scale-down (a uint))
    (/ a ONE_8)
)

;; @desc mul-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc mul-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-up (a uint) (b uint))
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

;; @desc div-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-down (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (/ (* a ONE_8) b)
   )
)

;; @desc div-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-up (a uint) (b uint))
    (if (is-eq a u0)
        u0
        (+ u1 (/ (- (* a ONE_8) u1) b))
    )
)

;; @desc pow-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-down (a uint) (b uint))    
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

;; @desc pow-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX_POW_RELATIVE_ERROR)))
        )
        (+ raw max-error)
    )
)

;; math-log-exp
;; Exponentiation and logarithm functions for 8 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 8 decimal fixed point numbers.
(define-constant UNSIGNED_ONE_8 (pow 10 8))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^8, 
;; which makes the largest exponent ln((2^127 - 1) / 10^8) = 69.6090111872.
;; The smallest possible result is 10^(-8), which makes largest negative argument ln(10^(-8)) = -18.420680744.
;; We use 69.0 and -18.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 69 UNSIGNED_ONE_8))
(define-constant MIN_NATURAL_EXPONENT (* -18 UNSIGNED_ONE_8))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint UNSIGNED_ONE_8)))

;; Because largest exponent is 69, we start from 64
;; The first several a_n are too large if stored as 8 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.

(define-constant x_a_list_no_deci (list 
{x_pre: 6400000000, a_pre: 62351490808116168829, use_deci: false} ;; x1 = 2^6, a1 = e^(x1)
))

;; 8 decimal constants
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

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 8 decimal fixed point argument.

;; @desc ln-priv
;; @params a
;; @ returns (response uint)
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

;; @desc accumulate_division
;; @params x_a_pre ; tuple(x_pre a_pre use_deci)
;; @params rolling_a_sum ; tuple (a sum)
;; @returns uint
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

;; @desc rolling_sum_div
;; @params n
;; @params rolling ; tuple (num seriesSum z_squared)
;; @Sreturns tuple
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

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.

;; @desc pow-priv
;; @params x
;; @params y
;; @returns (response uint)
(define-read-only (pow-priv (x uint) (y uint))
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

;; @desc exp-pos
;; @params x
;; @returns (response uint)
(define-read-only (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (let
      (
        ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
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

;; @desc accumulate_product
;; @params x_a_pre ; tuple (x_pre a_pre use_deci)
;; @params rolling_x_p ; tuple (x product)
;; @returns tuple
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

;; @desc rolling_div_sum
;; @params n
;; @params rolling ; tuple (term seriesSum x)
;; @returns tuple
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

;; public functions
;;

;; Exponentiation (x^y) with unsigned 8 decimal fixed point base and exponent.
;; @desc pow-fixed
;; @params x
;; @params y
;; @returns (response uint)
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) ERR-X-OUT-OF-BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
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

;; Natural exponentiation (e^x) with signed 8 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.

;; @desc exp-fixed
;; @params x
;; @returns (response uint)
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) ERR-INVALID-EXPONENT)
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by UNSIGNED_ONE_8.
      (ok (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) (try! (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 8 decimal fixed point base and argument.
;; @desc log-fixed
;; @params arg
;; @params base
;; @returns (response uint)
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (ln-priv base) UNSIGNED_ONE_8))
      (logArg (* (ln-priv arg) UNSIGNED_ONE_8))
   )
    (ok (/ (* logArg UNSIGNED_ONE_8) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 8 decimal fixed point argument.

;; @desc ln-fixed
;; @params a
;; @returns (response uint)
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) ERR-OUT-OF-BOUNDS)
    (if (< a UNSIGNED_ONE_8)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by UNSIGNED_ONE_8.
      (ok (- 0 (ln-priv (/ (* UNSIGNED_ONE_8 UNSIGNED_ONE_8) a))))
      (ok (ln-priv a))
   )
 )
)
