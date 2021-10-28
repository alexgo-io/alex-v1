;; weighted-equation
;; implementation of Balancer WeightedMath (https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol)

;; constants
;;
(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-WEIGHT-SUM (err u4000))
(define-constant ERR-MAX-IN-RATIO (err u4001))
(define-constant ERR-MAX-OUT-RATIO (err u4002))
(define-constant ERR-MATH-CALL (err 4003))

;; max in/out as % of liquidity
(define-constant MAX_IN_RATIO (* u30 (pow u10 u6))) ;; 30%
(define-constant MAX_OUT_RATIO (* u30 (pow u10 u6))) ;; 30%
;;(define-constant EQUATION_TOLERANCE u10)

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
;;

;; get-invariant
;; invariant = b_x ^ w_x * b_y ^ w_y 
(define-read-only (get-invariant (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (ok (mul-down (pow-down balance-x weight-x) (pow-down balance-y weight-y)))
    )
)

;; get-y-given-x
;; d_y = dy
;; b_y = balance-y
;; b_x = balance-x                /      /            b_x             \    (w_x / w_y) \           
;; d_x = dx          d_y = b_y * |  1 - | ---------------------------  | ^             |          
;; w_x = weight-x                 \      \       ( b_x + d_x )        /                /           
;; w_y = weight-y                                                                       
(define-read-only (get-y-given-x (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dx uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (asserts! (< dx (mul-down balance-x MAX_IN_RATIO)) ERR-MAX-IN-RATIO)
        (let 
            (
                (denominator (+ balance-x dx))
                (base (div-up balance-x denominator))
                (uncapped-exponent (div-up weight-x weight-y))
                (bound (unwrap-panic (get-exp-bound)))
                (exponent (if (< uncapped-exponent bound) uncapped-exponent bound))
                (power (pow-up base exponent))
                (complement (if (<= ONE_8 power) u0 (- ONE_8 power)))
                (dy (mul-down balance-y complement))
            )
            (asserts! (< dy (mul-down balance-y MAX_OUT_RATIO)) ERR-MAX-OUT-RATIO)
            (ok dy)
        ) 
    )    
)

;; d_y = dy                                                                            
;; b_y = balance-y
;; b_x = balance-x              /  /            b_y             \    (w_y / w_x)      \          
;; d_x = dx         d_x = b_x * |  | --------------------------  | ^             - 1  |         
;; w_x = weight-x               \  \       ( b_y - d_y )         /                    /          
;; w_y = weight-y                                                           
(define-read-only (get-x-given-y (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dy uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (asserts! (< dy (mul-down balance-y MAX_OUT_RATIO)) ERR-MAX-OUT-RATIO)
        (let 
            (
                (denominator (if (<= balance-y dy) u0 (- balance-y dy)))
                (base (div-down balance-y denominator))
                (uncapped-exponent (div-down weight-y weight-x))
                (bound (unwrap-panic (get-exp-bound)))
                (exponent (if (< uncapped-exponent bound) uncapped-exponent bound))
                (power (pow-down base exponent))
                (ratio (if (<= power ONE_8) u0 (- power ONE_8)))
                (dx (mul-down balance-x ratio))
            )
            (asserts! (< dx (mul-down balance-x MAX_IN_RATIO)) ERR-MAX-IN-RATIO)
            (ok dx)
        )
    )
)

;; d_x = dx
;; d_y = dy 
;; b_x = balance-x
;; b_y = balance-y
;; w_x = weight-x 
;; w_y = weight-y
;; spot = b_y * w_x / b_x / w_y
;; d_x = b_x * ((spot / price) ^ w_y - 1)
(define-read-only (get-x-given-price (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (price uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (let
            (
                (numerator (mul-down balance-y weight-x))
                (denominator (mul-up balance-x weight-y))
                (spot (div-down numerator denominator))
            )
            (asserts! (< price spot) ERR-NO-LIQUIDITY)
            (let 
                (
                    (base (div-up spot price))
                    (power (pow-down base weight-y))
                )
                (ok (mul-up balance-x (if (<= power ONE_8) u0 (- power ONE_8))))
            )
        )
    )   
)

;; follows from the above
(define-read-only (get-y-given-price (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (price uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (let
            (
                (numerator (mul-down balance-y weight-x))
                (denominator (mul-up balance-x weight-y))
                (spot (div-down numerator denominator))
            )
            (asserts! (> price spot) ERR-NO-LIQUIDITY)
            (let 
                (
                    (base (div-up spot price))
                    (power (pow-down base weight-y))
                )
                (ok (mul-up balance-y (if (<= ONE_8 power) u0 (- ONE_8 power))))
            )
        )
    )   
)

(define-read-only (get-token-given-position (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (dx uint) (dy uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (ok
            (if (is-eq total-supply u0)
                {token: (unwrap-panic (get-invariant dx dy weight-x weight-y)), dy: dy}
                (let
                    (
                        ;; if total-supply > zero, we calculate dy proportional to dx / balance-x
                        (new-dy (mul-down balance-y 
                                (div-down dx balance-x)))
                        (token (mul-down total-supply  
                                (div-down dx balance-x)))
                    )
                    {token: token, dy: new-dy}
                )   
            )
        ) 
    )    
)

(define-read-only (get-position-given-mint (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (begin
        (asserts! (is-eq (+ weight-x weight-y) ONE_8) ERR-WEIGHT-SUM)
        (asserts! (> total-supply u0) ERR-NO-LIQUIDITY)
        (let
            (   
                ;; first calculate what % you need to mint
                (token-supply (div-down token total-supply))
                ;; calculate dx as % of balance-x corresponding to % you need to mint
                (dx (mul-down balance-x token-supply))
                (dy (mul-down balance-y token-supply))
            )
            (ok {dx: dx, dy: dy})
        )
    )
)

(define-read-only (get-position-given-burn (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint))
    (get-position-given-mint balance-x balance-y weight-x weight-y total-supply token)
)



;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant SCALE_UP_OVERFLOW (err u5001))
(define-constant SCALE_DOWN_OVERFLOW (err u5002))
(define-constant ADD_OVERFLOW (err u5003))
(define-constant SUB_OVERFLOW (err u5004))
(define-constant MUL_OVERFLOW (err u5005))
(define-constant DIV_OVERFLOW (err u5006))
(define-constant POW_OVERFLOW (err u5007))

;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX_POW_RELATIVE_ERROR u4) 

;; public functions
;;

(define-read-only (get_one)
    (ok ONE_8)
)

(define-read-only (scale-up (a uint))
  (* a ONE_8)
)

(define-read-only (scale-down (a uint))
  (/ a ONE_8)
)

(define-read-only (mul-down (a uint) (b uint))
  (/ (* a b) ONE_8)
)


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

(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

(define-read-only (div-up (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (+ u1 (/ (- (* a ONE_8) u1) b))
  )
)

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
(define-constant iONE_8 (pow 10 8))
(define-constant ONE_10 (pow 10 10))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^8, 
;; which makes the largest exponent ln((2^127 - 1) / 10^8) = 69.6090111872.
;; The smallest possible result is 10^(-8), which makes largest negative argument ln(10^(-8)) = -18.420680744.
;; We use 69.0 and -18.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 69 iONE_8))
(define-constant MIN_NATURAL_EXPONENT (* -18 iONE_8))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint iONE_8)))

;; Because largest exponent is 69, we start from 64
;; The first several a_n are too large if stored as 8 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.
(define-constant x_a_list_no_deci (list 
{x_pre: 6400000000, a_pre: 6235149080811616882910000000, use_deci: false} ;; x1 = 2^6, a1 = e^(x1)
))
;; 8 decimal constants
(define-constant x_a_list (list 
{x_pre: 3200000000, a_pre: 7896296018268069516100, use_deci: true} ;; x2 = 2^5, a2 = e^(x2)
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

(define-constant X_OUT_OF_BOUNDS (err u5009))
(define-constant Y_OUT_OF_BOUNDS (err u5010))
(define-constant PRODUCT_OUT_OF_BOUNDS (err u5011))
(define-constant INVALID_EXPONENT (err u5012))
(define-constant OUT_OF_BOUNDS (err u5013))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-private (ln-priv (a int))
  (let
    (
      (a_sum_no_deci (fold accumulate_division x_a_list_no_deci {a: a, sum: 0}))
      (a_sum (fold accumulate_division x_a_list {a: (get a a_sum_no_deci), sum: (get sum a_sum_no_deci)}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a iONE_8) iONE_8) (+ out_a iONE_8)))
      (z_squared (/ (* z z) iONE_8))
      (div_list (list 3 5 7 9 11))
      (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
      (seriesSum (get seriesSum num_sum_zsq))
      (r (+ out_sum (* seriesSum 2)))
   )
    (ok r)
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
    (if (>= rolling_a (if use_deci a_pre (* a_pre iONE_8)))
      {a: (/ (* rolling_a (if use_deci iONE_8 1)) a_pre), sum: (+ rolling_sum x_pre)}
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
      (next_num (/ (* rolling_num z_squared) iONE_8))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
(define-private (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) iONE_8))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) PRODUCT_OUT_OF_BOUNDS)
    (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
  )
)

(define-private (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (let
      (
        ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
        (x_product_no_deci (fold accumulate_product x_a_list_no_deci {x: x, product: 1}))
        (x_adj (get x x_product_no_deci))
        (firstAN (get product x_product_no_deci))
        (x_product (fold accumulate_product x_a_list {x: x_adj, product: iONE_8}))
        (product_out (get product x_product))
        (x_out (get x x_product))
        (seriesSum (+ iONE_8 x_out))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
        (sum (get seriesSum term_sum_x))
     )
      (ok (* (/ (* product_out sum) iONE_8) firstAN))
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
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) (if use_deci iONE_8 1))}
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
      (next_term (/ (/ (* rolling_term x) iONE_8) n))
      (next_sum (+ rolling_sum next_term))
   )
    {term: next_term, seriesSum: next_sum, x: x}
 )
)

;; public functions
;;

(define-read-only (get-exp-bound)
  (ok MILD_EXPONENT_BOUND)
)

;; Exponentiation (x^y) with unsigned 8 decimal fixed point base and exponent.
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) X_OUT_OF_BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD_EXPONENT_BOUND) Y_OUT_OF_BOUNDS)

    (if (is-eq y u0) 
      (ok (to-uint iONE_8))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 8 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (/ (* iONE_8 iONE_8) (unwrap-panic (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 8 decimal fixed point base and argument.
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (unwrap-panic (ln-priv base)) iONE_8))
      (logArg (* (unwrap-panic (ln-priv arg)) iONE_8))
   )
    (ok (/ (* logArg iONE_8) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) (err OUT_OF_BOUNDS))
    (if (< a iONE_8)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (- 0 (unwrap-panic (ln-priv (/ (* iONE_8 iONE_8) a)))))
      (ln-priv a)
   )
 )
)

(define-read-only (test)
  (let
    (
      (x (* u7 (pow u10 u6)))
      (y (* u233 (pow u10 u6)))
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) iONE_8))
      ;;(r (exp-pos (* -1 logx-times-y)))

      ;;(arg (* 69 iONE_8))
      ;;(r (exp-pos arg))
      ;;(x_product (fold accumulate_product x_a_list {x: arg, product: iONE_8}))
  )
  ;;(ok logx-times-y)
  ;;x_product
  (ok (pow-fixed x y))
 )
)
