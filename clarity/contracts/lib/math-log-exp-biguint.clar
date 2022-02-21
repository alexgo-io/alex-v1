
;; math-log-exp
;; Exponentiation and logarithm functions for 16 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 16 decimal fixed point numbers.
(define-constant ONE_16 (pow 10 16))
(define-constant uONE_16 (pow u10 u16))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^16, 
;; which makes the largest exponent ln((2^127 - 1) / 10^16) = 51.1883304432
;; The smallest possible result is 10^(-16), which makes largest negative argument ln(10^(-16)) = -36.8413614879
;; We use 51.0 and -36.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT {x: 51, exp: 0})
(define-constant MIN_NATURAL_EXPONENT {x: -36, exp: 0})

(define-constant MILD_EXPONENT_BOUND (pow u2 u126))
(define-constant UPPER_BASE_BOUND {x: u17014118346046923173168730371588410572, exp: 1}) ;; this is 2^126
(define-constant LOWER_EXPONENT_BOUND {x: u85070591730234615865843651857942052864, exp: 0}) ;; this is 2^126
(define-constant DIGITS_31 9999999999999999999999999999999)
(define-constant DIGIT_LIST (list u10 u10 u10 u10 u10 u10 u10 u10))

;; Because largest exponent is 51, we start from 32
;; The first several a_n are too large if stored as 16 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.

;; a_pre is in scientific notation
;; a_n can all be stored in 16 decimal place

;; 16 decimal constants
;; We must keep a_pre to 16 digits so that division won't give us 0 when divided by ONE_16
(define-constant x_a_list (list 
{x_pre: 32, x_pre_exp: 0, a_pre: 7896296018268069, a_pre_exp: -2} ;; x0 = 2^5, a0 = e^(x0)
{x_pre: 16, x_pre_exp: 0, a_pre: 8886110520507873, a_pre_exp: -9} ;; x1 = 2^4, a1 = e^(x1)
{x_pre: 8, x_pre_exp: 0, a_pre: 2980957987041728, a_pre_exp: -12} ;; x2 = 2^3, a2 = e^(x2)
{x_pre: 4, x_pre_exp: 0, a_pre: 5459815003314424, a_pre_exp: -14} ;; x3 = 2^2, a3 = e^(x3)
{x_pre: 2, x_pre_exp: 0, a_pre: 7389056098930650, a_pre_exp: -15} ;; x4 = 2^1, a4 = e^(x4)
{x_pre: 1, x_pre_exp: 0, a_pre: 2718281828459045, a_pre_exp: -15} ;; x5 = 2^0, a5 = e^(x5)
{x_pre: 5, x_pre_exp: -1, a_pre: 1648721270700128, a_pre_exp: -15} ;; x6 = 2^-1, a6 = e^(x6)
{x_pre: 25, x_pre_exp: -2, a_pre: 1284025416687741, a_pre_exp: -15} ;; x7 = 2^-2, a7 = e^(x7)
{x_pre: 125, x_pre_exp: -3, a_pre: 1133148453066826, a_pre_exp: -15} ;; x8 = 2^-3, a8 = e^(x8)
{x_pre: 625, x_pre_exp: -4, a_pre: 1064494458917859, a_pre_exp: -15} ;; x9 = 2^-4, a9 = e^(x9)
{x_pre: 3125, x_pre_exp: -5, a_pre: 1031743407499103, a_pre_exp: -15} ;; x10 = 2^-5, a10 = e^(x10)
))

(define-constant ERR-X-OUT-OF-BOUNDS (err u5009))
(define-constant ERR-X-OUT-OF-BOUNDS-MANTISSA (err u50091))
(define-constant ERR-X-OUT-OF-BOUNDS-EXP (err u50092))
(define-constant ERR-Y-OUT-OF-BOUNDS (err u5010))
(define-constant ERR-Y-OUT-OF-BOUNDS-MANTISSA (err u50101))
(define-constant ERR-Y-OUT-OF-BOUNDS-EXP (err u50102))
(define-constant ERR-PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant ERR-INVALID-EXPONENT (err u5012))
(define-constant ERR-OUT-OF-BOUNDS (err u5013))
(define-constant ERR-NOT-POSITIVE (err u5014))
(define-constant INT_RANGE_EXCEEDED  (err u5015))

(define-read-only (ln-priv (num (tuple (x int) (exp int))))
    (let
        (
            ;; decomposition
            (a_sum (fold accumulate_division x_a_list {a: num, sum: {x: 0, exp: 0}}))
            (out_a (get a a_sum))
            (out_a_transformed (transform-to-16 out_a))
            (out_sum (get sum a_sum))
            (out_a_sn_sub (subtraction-with-scientific-notation out_a_transformed {x: 1, exp: 0}))
            (out_a_sn_add (addition-with-scientific-notation out_a_transformed {x: 1, exp: 0}))
            ;; z calculation
            (z (division-with-scientific-notation out_a_sn_sub out_a_sn_add))
            (z_squared (multiplication-with-scientific-notation z z))
            (z_squared_scaled_down (scale-down-with-lost-precision z_squared))
            ;; taylor series
            (div_list (list 3 5 7 9 11))
            (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared_scaled_down}))
            (seriesSum (get seriesSum num_sum_zsq))
            (seriesSumScaledDown (scale-down-with-lost-precision seriesSum))
            (seriesSumDouble (multiplication-with-scientific-notation seriesSumScaledDown {x: 2, exp: 0}))

            (r (addition-with-scientific-notation out_sum seriesSumDouble))
        )
        (ok r)
    )
)

(define-private (accumulate_division (x_a_pre (tuple (x_pre int) (x_pre_exp int) (a_pre int) (a_pre_exp int))) (rolling_a_sum (tuple (a (tuple (x int) (exp int))) (sum (tuple (x int) (exp int))))))
    (let
        (
            (a_pre (get a_pre x_a_pre))
            (a_pre_exp (get a_pre_exp x_a_pre))
            (x_pre (get x_pre x_a_pre))
            (x_pre_exp (get x_pre_exp x_a_pre))
            (rolling_a (get a rolling_a_sum))
            (rolling_sum (get sum rolling_a_sum))
        )
        (if (greater-than-equal-to rolling_a {x: a_pre, exp: a_pre_exp})
            {
                a: (division-with-scientific-notation-with-precision rolling_a {x: a_pre, exp: a_pre_exp}),
                sum: (addition-with-scientific-notation rolling_sum {x: x_pre, exp: x_pre_exp}) 
            }
            {a: rolling_a, sum: rolling_sum}
        )
    )
)

(define-private (rolling_sum_div (n int) (rolling (tuple (num (tuple (x int) (exp int))) (seriesSum (tuple (x int) (exp int))) (z_squared (tuple (x int) (exp int))))))
    (let
        (
            (rolling_num (get num rolling))
            (rolling_sum (get seriesSum rolling))
            (z_squared (get z_squared rolling))
            (next_num (multiplication-with-scientific-notation rolling_num z_squared))
            (next_num_scaled_down (scale-down-with-lost-precision next_num))
            (next_sum_div (division-with-scientific-notation next_num_scaled_down {x: n, exp: 0}))
            (next_sum (addition-with-scientific-notation next_sum_div rolling_sum))
        )
        {num: next_num_scaled_down, seriesSum: next_sum, z_squared: z_squared}
    )
) 

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (pow-priv (tuple-x (tuple (x uint) (exp int))) (tuple-y (tuple (x uint) (exp int))))
  (let
    (
      (x-int (to-int (get x tuple-x)))
      (y-int (to-int (get x tuple-y)))
      (lnx (unwrap-panic (ln-priv {x: x-int, exp: (get exp tuple-x)})))
      (logx_times_y (multiplication-with-scientific-notation lnx {x: y-int, exp: (get exp tuple-y)}))
    )
    (asserts! (and (greater-than-equal-to logx_times_y MIN_NATURAL_EXPONENT)
                    (greater-than-equal-to MAX_NATURAL_EXPONENT logx_times_y)) 
                    ERR-INVALID-EXPONENT)
    (exp-fixed logx_times_y)
  )
)

(define-read-only (exp-pos (num (tuple (x int) (exp int))))
    (let
        (
            ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            ;; it and compute the accumulated product.
            (x_product (fold accumulate_product x_a_list {x: num, product: {x: 1, exp: 0}}))
            (product_out (get product x_product))
            (transformed_product (transform-to-16 product_out))
            (x_out (get x x_product))
            (transformed_x (transform-to-16 x_out))
            (seriesSum (addition-with-scientific-notation {x: 1, exp: 0} transformed_x))
            (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
            (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
            (sum (get seriesSum term_sum_x))
            (r (multiplication-with-scientific-notation-with-precision transformed_product sum))
        )
        (if (greater-than-equal-to {x: (get x num), exp: (get exp num)} {x: 1, exp: 0})
            (scale-down-with-lost-precision r)
         r
        )
    )
)

(define-private (accumulate_product (x_a_pre (tuple (x_pre int) (x_pre_exp int) (a_pre int) (a_pre_exp int))) (rolling_x_p (tuple (x (tuple (x int) (exp int))) (product (tuple (x int) (exp int))))))
    (let
        (
            (x_pre (get x_pre x_a_pre))
            (x_pre_exp (get x_pre_exp x_a_pre))
            (a_pre (get a_pre x_a_pre))
            (a_pre_exp (get a_pre_exp x_a_pre))
            (rolling_x (get x rolling_x_p))
            (rolling_product (get product rolling_x_p))
        )
        (if (greater-than-equal-to rolling_x {x: x_pre, exp: x_pre_exp})
            {
                x: (subtraction-with-scientific-notation rolling_x {x: x_pre, exp: x_pre_exp}),
                product: (multiplication-with-scientific-notation-with-precision rolling_product {x: a_pre, exp: a_pre_exp})
            }
            {x: rolling_x, product: rolling_product}
        )
    )
)

(define-private (rolling_div_sum (n int) (rolling (tuple (term (tuple (x int) (exp int))) (seriesSum (tuple (x int) (exp int))) (x (tuple (x int) (exp int))))))
  (let
    (
      (rolling_term (get term rolling))
      (rolling_sum (get seriesSum rolling))
      (x (get x rolling))
      (next_term (multiplication-with-scientific-notation rolling_term x))
      (next_term_transformed (transform-to-16 next_term))
      (next_term_div (division-with-scientific-notation next_term_transformed {x: n, exp: 0}))
      (next_term_div_transformed (transform-to-16 next_term_div))
      (next_sum (addition-with-scientific-notation rolling_sum next_term_div_transformed))
   )
    {term: next_term_div_transformed, seriesSum: next_sum, x: x}
 )
)

;; this function should take uint as parameter for digits to check the max range
(define-read-only (pow-fixed (tuple-x (tuple (x uint) (exp int))) (tuple-y (tuple (x uint) (exp int))))
  (begin
    
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (not (greater-than-equal-to-uint (scale-down-with-lost-precision-uint tuple-x) (scale-down-with-lost-precision-uint UPPER_BASE_BOUND))) ERR-X-OUT-OF-BOUNDS)
    (asserts! (< (get x tuple-x) (pow u10 u11)) ERR-X-OUT-OF-BOUNDS-MANTISSA)
    (asserts! (<= (get exp tuple-x) 23) ERR-X-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (not (greater-than-equal-to-uint (scale-down-with-lost-precision-uint tuple-y) (scale-down-with-lost-precision-uint LOWER_EXPONENT_BOUND))) ERR-Y-OUT-OF-BOUNDS)
    (asserts! (< (get x tuple-y) (pow u10 u11)) ERR-Y-OUT-OF-BOUNDS-MANTISSA)
    (asserts! (<= (get exp tuple-y) 23) ERR-Y-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

    (if (is-eq (get x tuple-y) u0) 
      (ok {x: 1, exp: 0})
      (if (is-eq (get x tuple-x) u0) 
        (ok {x: 0, exp: 0})
        (pow-priv tuple-x tuple-y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 16 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (exp-fixed (num (tuple (x int) (exp int))))
  (begin
    (asserts! (and (greater-than-equal-to num MIN_NATURAL_EXPONENT) 
    (greater-than-equal-to MAX_NATURAL_EXPONENT num)) ERR-INVALID-EXPONENT)
    (if (greater-than-equal-to num {x: 0, exp: 0})
      (ok (exp-pos num))
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
      ;; Fixed point division requires multiplying by ONE_16.
      (let
        (
            (multiplication (multiplication-with-scientific-notation num {x: -1, exp: 0}))
            (exponent_result (exp-pos multiplication))
            (transformed_result (transform-to-16 exponent_result))
        )
        (ok (division-with-scientific-notation-with-precision {x: 1, exp: 0} transformed_result))
      )
    )
  )
)

;; Logarithm (log(arg, base), with signed 16 decimal fixed point base and argument.
(define-read-only (log-fixed (arg (tuple (x int) (exp int))) (base (tuple (x int) (exp int))))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (unwrap-panic (ln-priv base)))
      (logArg (unwrap-panic (ln-priv arg)))
   )
   (division-with-scientific-notation logArg logBase)
 )
)

;; Natural logarithm (ln(a)) with signed 16 decimal fixed point argument.
(define-read-only (ln-fixed (num (tuple (x int) (exp int))))
    (begin
        (asserts! (> (get x num) 0) ERR-OUT-OF-BOUNDS)
        (if (greater-than-equal-to num {x: 1, exp: 0})
            (ln-priv num)
            ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
            ;; If a is less than one, 1/a will be greater than one.
            ;; Fixed point division requires multiplying by ONE_8.
            (let
                (
                    (division (division-with-scientific-notation {x: 1, exp: 0} num))
                    
                    (ln (unwrap-panic (ln-priv division)))
                    (ln_a (get x ln))
                    (ln_exp (get exp ln))
                )
                (ok (subtraction-with-scientific-notation {x: 0, exp: 0} {x: ln_a, exp: ln_exp}))
            )
        )
    )
)

(define-read-only (scale-up (a int))
    (* a ONE_16)
)

(define-read-only (scale-down (a int))
    (/ a ONE_16)
)

(define-read-only (scale-up-with-scientific-notation (num (tuple (x int) (exp int))))
    (multiplication-with-scientific-notation num {x: 1, exp: 16})
)

(define-read-only (scale-down-with-scientific-notation (num (tuple (x int) (exp int))))
    (division-with-scientific-notation num {x: 1, exp: 16})
)

(define-read-only (scale-down-with-lost-precision (num (tuple (x int) (exp int))))
    (let 
        (
            (x (/ (get x num) ONE_16))
            (exp (+ (get exp num) 16))
        )
        {x: x, exp: exp}
    )
)

(define-read-only (scale-down-with-lost-precision-uint (num (tuple (x uint) (exp int))))
    (let 
        (
            (x (/ (get x num) uONE_16))
            (exp (+ (get exp num) 16))
        )
        {x: x, exp: exp}
    )
)

(define-read-only (greater-than-equal-to-uint (tuple-a (tuple (x uint) (exp int))) (tuple-b (tuple (x uint) (exp int))))
    (if (> (get exp tuple-a) (get exp tuple-b))
        (let
            (
                (b (to-int (get x tuple-b)))
                (b_exp (get exp tuple-b))
                (a (to-int (get x tuple-a)))
                (a_exp (get exp tuple-a))
                (transformation (transform {x: a, exp: a_exp} b_exp))
                (new_a (get x transformation))
            )
            (if (>= new_a b) true false)
        )
        (let
            (
                (a (to-int (get x tuple-a)))
                (a_exp (get exp tuple-a))
                (b (to-int (get x tuple-b)))
                (b_exp (get exp tuple-b))
                (transformation (transform {x: b, exp: b_exp} a_exp))
                (new_b (get x transformation))
            )
            (if (>= a new_b) true false)
        )
    )       
)

(define-read-only (greater-than-equal-to (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (if (> (get exp tuple-a) (get exp tuple-b))
        (let
            (
                (b (get x tuple-b))
                (b_exp (get exp tuple-b))
                (transformation (transform tuple-a b_exp))
                (new_a (get x transformation))
            )
            (if (>= new_a b) true false)
        )
        (let
            (
                (a (get x tuple-a))
                (a_exp (get exp tuple-a))
                (transformation (transform tuple-b a_exp))
                (new_b (get x transformation))
            )
            (if (>= a new_b) true false)
        )
    )       
)

(define-read-only (addition-with-scientific-notation (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (begin
        (if (> (get exp tuple-a) (get exp tuple-b))
            (let
                (
                    (b (get x tuple-b))
                    (b_exp (get exp tuple-b))
                    (transformation (transform tuple-a b_exp))
                    (new_a (get x transformation))
                    (new_a_exp (get exp transformation))
                    (addition (+ new_a b))
                )
                {x: addition, exp: b_exp}
            )
            (let
                (
                    (a (get x tuple-a))
                    (a_exp (get exp tuple-a))
                    (transformation (transform tuple-b a_exp))
                    (new_b (get x transformation))
                    (new_b_exp (get exp transformation))
                    (addition (+ new_b a))
                )
                {x: addition, exp: a_exp}
            )
        )
    )
)

(define-read-only (subtraction-with-scientific-notation (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (begin
        (if (> (get exp tuple-a) (get exp tuple-b))
            (let
                (
                    (b (get x tuple-b))
                    (b_exp (get exp tuple-b))
                    (transformation (transform tuple-a b_exp))
                    (new_a (get x transformation))
                    (new_a_exp (get exp transformation))
                    (subtraction (- new_a b))
                )
                {x: subtraction, exp: b_exp}
            )
            (let
                (
                    (a (get x tuple-a))
                    (a_exp (get exp tuple-a))
                    (transformation (transform tuple-b a_exp))
                    (new_b (get x transformation))
                    (new_b_exp (get exp transformation))
                    (subtraction (- a new_b))
                )
                {x: subtraction, exp: a_exp}
            )
        )
    )
)

(define-read-only (division-with-scientific-notation (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (let
        (
            (a (get x tuple-a))
            (a_exp (get exp tuple-a))
            (b (get x tuple-b))
            (b_exp (get exp tuple-b))
            (division (/ (scale-up a) b))
            (exponent (+ (- a_exp b_exp) -16))
        )
        {x: division, exp: exponent}
    )
)

(define-read-only (multiplication-with-scientific-notation (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (let
        (
            (a (get x tuple-a))
            (a_exp (get exp tuple-a))
            (b (get x tuple-b))
            (b_exp (get exp tuple-b))
            (product (* a b))
            (exponent (+ a_exp b_exp))
        )
        {x: product, exp: exponent}
    )
)

(define-read-only (division-with-scientific-notation-with-precision (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (let
        (
            (a (get x tuple-a))
            (a-exp (get exp tuple-a))
            (b (get x tuple-b))
            (b-exp (get exp tuple-b))

            (new-a (if (> a b) a (scale-up a)))
            (division (/ new-a b))

            (exponent (if (> a b) 0 -16))
            (division-exponent (+ (- a-exp b-exp) exponent))
            (factor (- new-a (* division b)))

            (remainder (/ (* (pow 10 16) factor) b))
            
            (remainder-exponent (+ division-exponent -16))

            (result (addition-with-scientific-notation {x: division, exp: division-exponent} {x: remainder, exp: remainder-exponent}))

        )
        result
    )
)

(define-read-only (multiplication-with-scientific-notation-with-precision (tuple-a (tuple (x int) (exp int))) (tuple-b (tuple (x int) (exp int))))
    (let
        (   
            (a (get x tuple-a))
            (a-exp (get exp tuple-a))
            (b (get x tuple-b))
            (b-exp (get exp tuple-b))

            (a-count (digit-count a))
            (first (if (> a-count 16)
                {a: (/ a (pow 10 (- a-count 16))), exp: (+ a-exp (- a-count 16))}
                {a: a, exp: a-exp}
            ))
            (b-count (digit-count b))
            (second (if (> b-count 16)
                {a: (/ b (pow 10 (- b-count 16))), exp: (+ b-exp (- b-count 16))}
                {a: b, exp: b-exp}
            ))
            
            (product (* (get a first) (get a second)))
            (exponent (+ (get exp first) (get exp second)))
        )
        {x: product, exp: exponent }
    )
)

;; transformation
;; You cannot transform -ve exponent to +ve exponent
;; Meaning you cannot go forward exponent, only backwards
;; 35 * 10^-3 transform -2 (FORWARD) ;; 3.5 * 10^-2 (NOT POSSIBLE)
;; 35 * 10^3 transform 1 (BACKWARD) ;; 3500 * 10^1 (POSSIBLE)
(define-read-only (transform (num (tuple (x int) (exp int))) (power int))
    (let
        (
            (x (get x num))
            (exp-diff (- power (get exp num)))
            (diff-power (if (>= exp-diff 0) exp-diff (* -1 exp-diff)))
        )
        (if (and (<= exp-diff 25) (>= exp-diff -25))
            {
                x: (* x (pow 10 diff-power)),
                exp: power
            }
            num
        )
    )
)

(define-read-only (transform-to-16 (num (tuple (x int) (exp int))))
    (if (< (get exp num) -16)
        {x: (/ (get x num) (pow 10 (+ (* (get exp num) -1) -16))), exp: -16}
        num
    )
)

(define-read-only (digit-count (digits int))
    (let 
        ((a (if (< digits 0) (* -1 digits) digits)))
        (if (<= a 9)
            1
        (if (<= a 99)
            2
        (if (<= a 999)
            3
        (if (<= a 9999)
            4
        (if (<= a 99999)
            5
        (if (<= a 999999)
            6
        (if (<= a 9999999)
            7
        (if (<= a 99999999)
            8
        (if (<= a 999999999)
            9
        (if (<= a 9999999999)
            10
        (if (<= a 99999999999)
            11
        (if (<= a 999999999999)
            12
        (if (<= a 9999999999999)
            13
        (if (<= a 99999999999999)
            14
        (if (<= a 999999999999999)
            15
        (if (<= a 9999999999999999)
            16
        (if (<= a 99999999999999999)
            17
        (if (<= a 999999999999999999)
            18
        (if (<= a 9999999999999999999)
            19
        (if (<= a 99999999999999999999)
            20
        (if (<= a 999999999999999999999)
            21
        (if (<= a 9999999999999999999999)
            22
        (if (<= a 99999999999999999999999)
            23
        (if (<= a 999999999999999999999999)
            24
        (if (<= a 9999999999999999999999999)
            25
        (if (<= a 99999999999999999999999999)
            26
        (if (<= a 999999999999999999999999999)
            27
        (if (<= a 9999999999999999999999999999)
            28
        (if (<= a 99999999999999999999999999999)
            29
        (if (<= a 999999999999999999999999999999)
            30
        (if (<= a 9999999999999999999999999999999)
            31
        (if (<= a 99999999999999999999999999999999)
            32
        (if (<= a 999999999999999999999999999999999)
            33
        (if (<= a 9999999999999999999999999999999999)
            34
        (if (<= a 99999999999999999999999999999999999)
            35
        (if (<= a 999999999999999999999999999999999999)
            36
        (if (<= a 9999999999999999999999999999999999999)
            37
        (if (<= a 99999999999999999999999999999999999999)
            38
        39
        )))))))))))))))))))))))))))))))))))))
        )
    )
)

(define-read-only (pow-from-fixed-to-fixed (a uint) (b uint))
    (transform-to-fixed (try! (pow-fixed (transform-from-fixed a) (transform-from-fixed b))))
)

(define-read-only (count-zero (a uint) (result (tuple (input uint) (continue bool) (zero int))))
    (let 
        (
            (continue (get continue result))
            (input (get input result))
            (zero (get zero result))
        )
        (if (not continue) 
            result
            (if (is-eq (mod input a) u0)
                {input: (/ input a), continue: true, zero: (+ 1 zero)}
                {input: input, continue: false, zero: zero} 
            )
        )
    )
)

;; transform 8-digit fixed-point notation to 8 decimal scientific notation
(define-read-only (transform-from-fixed (a uint))
    (let 
        (
            (transformed-input (fold count-zero DIGIT_LIST {input: a, continue: true, zero: 0}))
            (exp (- (get zero transformed-input) 8))
        )
        {x: (get input transformed-input), exp: exp}
    )  
)

;; transform scientific notation to 8-digit fixed-point notation
(define-read-only (transform-to-fixed (num (tuple (x int) (exp int))))
    (let 
        (
            (x (get x num))
            (exp (get exp num))
            (new-exp (+ 8 exp))
        )
        ;; (asserts! (< result DIGITS_31) INT_RANGE_EXCEEDED)
        (if (>= new-exp 0)
            (ok (* x (pow 10 new-exp)))
            (ok (/ x (pow 10 (* -1 new-exp))))
        )
    )  
)