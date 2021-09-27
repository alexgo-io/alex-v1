
;; math-log-exp
;; Exponentiation and logarithm functions for 10 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 10 decimal fixed point numbers.
(define-constant ONE_8 (pow 10 8))
(define-constant ONE_10 (pow 10 10))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^10, 
;; which makes the largest exponent ln((2^127 - 1) / 10^10) = 65.0038410012.
;; The smallest possible result is 10^(-10), which makes largest negative argument ln(10^(-10)) = -23.0258509
;; We use 65.0 and -23.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 65 ONE_10))
(define-constant MIN_NATURAL_EXPONENT (* -23 ONE_10))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint ONE_10)))

;; Because largest exponent is 60, we start from 32
;; The first several a_n are too large if stored as 10 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.
(define-constant x_a_list_no_deci (list 
{x_pre: 640000000000, a_pre: 6235149080811616882909238708, use_deci: false} ;; x1 = 2^6, a1 = e^(x1)
))
;; 12 decimal constants
(define-constant x_a_list (list 
{x_pre: 320000000000, a_pre: 789629601826806951609780, use_deci: true} ;; x2 = 2^5, a2 = e^(x2)
{x_pre: 160000000000, a_pre: 88861105205078726, use_deci: true} ;; x3 = 2^4, a3 = e^(x3)
{x_pre: 80000000000, a_pre: 29809579870417, use_deci: true} ;; x4 = 2^3, a4 = e^(x4)
{x_pre: 40000000000, a_pre: 545981500331, use_deci: true} ;; x5 = 2^2, a5 = e^(x5)
{x_pre: 20000000000, a_pre: 73890560989, use_deci: true} ;; x6 = 2^1, a6 = e^(x6)
{x_pre: 10000000000, a_pre: 27182818284, use_deci: true} ;; x7 = 2^0, a7 = e^(x7)
{x_pre: 5000000000, a_pre: 16487212707, use_deci: true} ;; x8 = 2^-1, a8 = e^(x8)
{x_pre: 2500000000, a_pre: 12840254167, use_deci: true} ;; x9 = 2^-2, a9 = e^(x9)
{x_pre: 1250000000, a_pre: 11331484531, use_deci: true} ;; x10 = 2^-3, a10 = e^(x10)
{x_pre: 625000000, a_pre: 10644944589, use_deci: true} ;; x11 = 2^-4, a11 = e^x(11)
))


(define-constant ERR-X-OUT-OF-BOUNDS (err u5009))
(define-constant ERR-Y-OUT-OF-BOUNDS (err u5010))
(define-constant ERR-PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant ERR-INVALID-EXPONENT (err u5012))
(define-constant ERR-OUT-OF-BOUNDS (err u5013))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 10 decimal fixed point argument.
(define-read-only (ln-priv (a int))
  (let
    (
      (a_sum_no_deci (fold accumulate_division x_a_list_no_deci {a: a, sum: 0}))
      (a_sum (fold accumulate_division x_a_list {a: (get a a_sum_no_deci), sum: (get sum a_sum_no_deci)}))
      (out_a (get a a_sum))
      (out_sum (get sum a_sum))
      (z (/ (* (- out_a ONE_10) ONE_10) (+ out_a ONE_10)))
      (z_squared (/ (* z z) ONE_10))
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
    (if (>= rolling_a (if use_deci a_pre (* a_pre ONE_10)))
      {a: (/ (* rolling_a (if use_deci ONE_10 1)) a_pre), sum: (+ rolling_sum x_pre)}
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
      (next_num (/ (* rolling_num z_squared) ONE_10))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) ONE_10))
    )
    (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) ERR-PRODUCT-OUT-OF-BOUNDS)
    (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
    ;;(ok (to-uint logx-times-y))
  )
)

(define-read-only (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX_NATURAL_EXPONENT)) (err ERR-INVALID-EXPONENT))
    (let
      (
        ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
        (x_product_no_deci (fold accumulate_product x_a_list_no_deci {x: x, product: 1}))
        (x_adj (get x x_product_no_deci))
        (firstAN (get product x_product_no_deci))
        (x_product (fold accumulate_product x_a_list {x: x_adj, product: ONE_10}))
        (product_out (get product x_product))
        (x_out (get x x_product))
        (seriesSum (+ ONE_10 x_out))
        (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
        (sum (get seriesSum term_sum_x))
     )
      (ok (* (/ (* product_out sum) ONE_10) firstAN))
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
      {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) (if use_deci ONE_10 1))}
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
      (next_term (/ (/ (* rolling_term x) ONE_10) n))
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

;; Exponentiation (x^y) with unsigned 10 decimal fixed point base and exponent.
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) ERR-X-OUT-OF-BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD_EXPONENT_BOUND) ERR-Y-OUT-OF-BOUNDS)

    (if (is-eq y u0) 
      (ok (to-uint ONE_10))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 10 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) (err ERR-INVALID-EXPONENT))
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by ONE_10.
      (ok (/ (* ONE_10 ONE_10) (unwrap-panic (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 10 decimal fixed point base and argument.
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (unwrap-panic (ln-priv base)) ONE_10))
      (logArg (* (unwrap-panic (ln-priv arg)) ONE_10))
   )
    (ok (/ (* logArg ONE_10) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 10 decimal fixed point argument.
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) (err ERR-OUT-OF-BOUNDS))
    (if (< a ONE_10)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by ONE_10.
      (ok (- 0 (unwrap-panic (ln-priv (/ (* ONE_10 ONE_10) a)))))
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
      (logx-times-y (/ (* lnx y-int) ONE_10))
      ;;(r (exp-pos (* -1 logx-times-y)))

      ;;(arg (* 69 ONE_10))
      ;;(r (exp-pos arg))
      ;;(x_product (fold accumulate_product x_a_list {x: arg, product: ONE_10}))
  )
  ;;(ok logx-times-y)
  ;;x_product
  (ok (pow-fixed x y))
 )
)