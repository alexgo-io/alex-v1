
;; math-log-exp
;; Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 
;; Everything here is in 18 decimal.

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 18 decimal fixed point numbers.
(define-constant ONE_18 (pow 10 18))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^18, 
;; which makes the largest exponent ln((2^127 - 1) / 10^18) = 46.5831602572.
;; The smallest possible result is 10^(-18), which makes largest negative argument
;; ln(10^(-18)) = -41.446531673892822312.
;; We use 46.0 and -41.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 46 ONE_18))
(define-constant MIN_NATURAL_EXPONENT (* -41 ONE_18))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint ONE_18)))

;; 18 decimal constants
;; Because largest exponent is 46, we can ignore the x0 and x1 case in Balancer Math
(define-constant x_a_list (list 
{x_pre: 32000000000000000000, a_pre: 78962960182680695161000000000000} ;; x2 = 2^5, a2 = e^(x2)
{x_pre: 16000000000000000000, a_pre: 8886110520507872636760000} ;; x3 = 2^4, a3 = e^x3)
{x_pre: 8000000000000000000, a_pre: 2980957987041728274740} ;; x4 = 2^3, a4 = e^x4)
{x_pre: 4000000000000000000, a_pre: 54598150033144239078} ;; x5 = 2^2, a5 = e^x5)
{x_pre: 2000000000000000000, a_pre: 7389056098930650227} ;; x6 = 2^1, a6 = e^x6)
{x_pre: 1000000000000000000, a_pre: 2718281828459045235} ;; x7 = 2^0, a7 = e^x7)
{x_pre: 500000000000000000, a_pre: 1648721270700128147} ;; x8 = 2^-1, a8 = e^x8)
{x_pre: 250000000000000000, a_pre: 1284025416687741484} ;; x9 = 2^-2, a9 = e^x9)
{x_pre: 125000000000000000, a_pre: 1133148453066826317} ;; x10 = 2^-3, a10 = e^x10)
{x_pre: 62500000000000000, a_pre: 1064494458917859430} ;; x11 = 2^-4, a11 = e^x11)
))

(define-constant X_OUT_OF_BOUNDS (err u10100))
(define-constant Y_OUT_OF_BOUNDS (err u10101))
(define-constant PRODUCT_OUT_OF_BOUNDS (err u10102))
(define-constant INVALID_EXPONENT (err u10103))
(define-constant OUT_OF_BOUNDS (err u10104))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
(define-private (ln-priv (a int))
  (let
    (
      (a_sum (fold accumulate_division x_a_list {a: a, sum: 0}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a ONE_18) ONE_18) (+ out_a ONE_18)))
      (z_squared (/ (* z z) ONE_18))
      (div_list (list 3 5 7 9 11))
      (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
      (seriesSum (get seriesSum num_sum_zsq))
      (r (+ out_sum (* seriesSum 2)))
    )
    (ok r)
  )
)

(define-private (accumulate_division (x_a_pre (tuple (x_pre int) (a_pre int))) (rolling_a_sum (tuple (a int) (sum int))))
  (let
    (
      (rolling_a (get a rolling_a_sum))
      (rolling_sum (get sum rolling_a_sum))
      (a_pre (get a_pre x_a_pre))
      (x_pre (get x_pre x_a_pre))
    )
    (if (>= rolling_a a_pre)
      {a: (/ (* rolling_a ONE_18) a_pre), sum: (+ rolling_sum x_pre)}
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
      (next_num (/ (* rolling_num z_squared) ONE_18))
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
      (logx-times-y (/ (* (unwrap-panic (ln-priv x-int)) y-int) ONE_18))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) (err PRODUCT_OUT_OF_BOUNDS))
    (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
  )
)

;; firstAN is always 1 so don't need to handle that
(define-private (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (let
      (
        (x_product (fold accumulate_product x_a_list {x: x, product: ONE_18}))
        (product (get product x_product))
        (term (get x x_product))
        (seriesSum (+ ONE_18 term))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: term, seriesSum: seriesSum, x: (get x x_product)}))
        (sum (get seriesSum term_sum_x))
      )
      (ok (/ (* product sum) ONE_18))
    )
  )
)

(define-private (accumulate_product (x_a_pre (tuple (x_pre int) (a_pre int))) (rolling_x_p (tuple (x int) (product int))))
  (let
    (
      (rolling_x (get x rolling_x_p))
      (rolling_product (get product rolling_x_p))
      (x_pre (get x_pre x_a_pre))
      (a_pre (get a_pre x_a_pre))
    )
    (if (>= rolling_x x_pre)
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) ONE_18)}
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
      (next_term (/ (/ (* rolling_term x) ONE_18) n))
      (next_sum (+ rolling_sum next_term))
    )
    {term: next_term, seriesSum: next_sum, x: x}
  )
)

;; public functions
;;

;; Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
(define-public (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) (err X_OUT_OF_BOUNDS))

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD_EXPONENT_BOUND) (err Y_OUT_OF_BOUNDS))

    (if (is-eq y u0) 
      (ok (to-uint ONE_18))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-public (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) (err INVALID_EXPONENT))
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by ONE_18.
      (ok (/ (* ONE_18 ONE_18) (unwrap-panic (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
(define-public (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (unwrap-panic (ln-priv base)) ONE_18))
      (logArg (* (unwrap-panic (ln-priv arg)) ONE_18))
    )
    (ok (/ (* logArg ONE_18) logBase))
  )
)

;; Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
(define-public (ln-fixed (a int))
  (begin
    (asserts! (> a 0) (err OUT_OF_BOUNDS))
    (if (< a ONE_18)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by ONE_18.
      (ok (- 0 (unwrap-panic (ln-priv (/ (* ONE_18 ONE_18) a)))))
      (ln-priv a)
    )
  )
)

