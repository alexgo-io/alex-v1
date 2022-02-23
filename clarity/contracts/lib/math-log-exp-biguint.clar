
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
(define-constant UPPER_BASE_BOUND_SCALE_DOWN {x: u1701411834604692317316, exp: 17})
(define-constant LOWER_EXPONENT_BOUND {x: u85070591730234615865843651857942052864, exp: 0}) ;; this is 2^126
(define-constant LOWER_EXPONENT_BOUND_SCALE_DOWN {x: u8507059173023461586584, exp: 16})
(define-constant ZERO {x: 0, exp: 0})
(define-constant ONE {x: 1, exp: 0})
(define-constant MANTISSA_LIMIT u100000000000)
(define-constant DIGITS_31 9999999999999999999999999999999)
(define-constant DIGIT_LIST (list u10 u10 u10 u10 u10 u10 u10 u10))
(define-constant TAYLOR_SERIES_TERMS_6 (list 3 5 7 9 11))
(define-constant TAYLOR_SERIES_TERMS_12 (list 2 3 4 5 6 7 8 9 10 11 12))

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
            (a_sum (fold accumulate_division x_a_list {a: num, sum: ZERO}))
            (out_sum (get sum a_sum))
            (out_a_transformed (transform-to-16 (get a a_sum)))
            (out_a_transformed_x (get x out_a_transformed))
            (out_a_transformed_exp (get exp out_a_transformed))
            (out_a_sn_sub (subtraction-with-scientific-notation out_a_transformed_x out_a_transformed_exp 1 0))
            (out_a_sn_add (addition-with-scientific-notation out_a_transformed_x out_a_transformed_exp 1 0))
            ;; z calculation
            (z (division-with-scientific-notation (get x out_a_sn_sub) (get exp out_a_sn_sub) (get x out_a_sn_add) (get exp out_a_sn_add)))
            (z_x (get x z))
            (z_exp (get exp z))
            (z_squared_scaled_down (scale-down-with-lost-precision (multiplication-with-scientific-notation z_x z_exp z_x z_exp)))
            ;; taylor series
            (num_sum_zsq (fold rolling_sum_div TAYLOR_SERIES_TERMS_6 {num: z, seriesSum: z, z_squared: z_squared_scaled_down}))
            (seriesSumScaledDown (scale-down-with-lost-precision (get seriesSum num_sum_zsq)))
            (seriesSumDouble (multiplication-with-scientific-notation (get x seriesSumScaledDown) (get exp seriesSumScaledDown) 2 0))
        )
        (ok (addition-with-scientific-notation (get x out_sum) (get exp out_sum) (get x seriesSumDouble) (get exp seriesSumDouble)))
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
            (rolling_a_x (get x rolling_a))
            (rolling_a_exp (get exp rolling_a))
            (rolling_sum (get sum rolling_a_sum))
        )
        (if (greater-than-equal-to rolling_a_x rolling_a_exp a_pre a_pre_exp)
            {
                a: (division-with-scientific-notation-with-precision rolling_a_x  rolling_a_exp a_pre a_pre_exp),
                sum: (addition-with-scientific-notation (get x rolling_sum) (get exp rolling_sum) x_pre x_pre_exp) 
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
            (next_num_scaled_down (scale-down-with-lost-precision (multiplication-with-scientific-notation (get x rolling_num) (get exp rolling_num) (get x z_squared) (get exp z_squared))))
            (next_sum_div (division-with-scientific-notation (get x next_num_scaled_down) (get exp next_num_scaled_down) n 0))
            (next_sum (addition-with-scientific-notation (get x next_sum_div) (get exp next_sum_div) (get x rolling_sum) (get exp rolling_sum)))
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
            (lnx (unwrap-panic (ln-priv {x: (to-int (get x tuple-x)), exp: (get exp tuple-x)})))
            (logx_times_y (multiplication-with-scientific-notation (get x lnx) (get exp lnx) (to-int (get x tuple-y)) (get exp tuple-y)))
            (log_x (get x logx_times_y))
            (log_exp (get exp logx_times_y))
        )
        (asserts! (and (greater-than-equal-to log_x log_exp (get x MIN_NATURAL_EXPONENT) (get exp MIN_NATURAL_EXPONENT))
                    (greater-than-equal-to (get x MAX_NATURAL_EXPONENT) (get exp MAX_NATURAL_EXPONENT) log_x log_exp)) 
                    ERR-INVALID-EXPONENT)
        (exp-fixed logx_times_y)
    )
)


(define-read-only (exp-pos (num (tuple (x int) (exp int))))
    (let
        (
            ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            ;; it and compute the accumulated product.
            (x_product (fold accumulate_product x_a_list {x: num, product: ONE}))
            (transformed_product (transform-to-16 (get product x_product)))
            (x_out (get x x_product))
            (transformed_x_out (transform-to-16 x_out))
            (seriesSum (addition-with-scientific-notation 1 0 (get x transformed_x_out) (get exp transformed_x_out)))
            (term_sum_x (fold rolling_div_sum TAYLOR_SERIES_TERMS_12 {term: x_out, seriesSum: seriesSum, x: x_out}))
            (sum (get seriesSum term_sum_x))
            (r (multiplication-with-scientific-notation-with-precision (get x transformed_product) (get exp transformed_product) (get x sum) (get exp sum)))
        )
        (if (greater-than-equal-to (get x num) (get exp num) 1 0)
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
            (rolling_x_a (get x rolling_x))
            (rolling_x_exp (get exp rolling_x))
            (rolling_product (get product rolling_x_p))
        )
        (if (greater-than-equal-to rolling_x_a rolling_x_exp x_pre x_pre_exp)
            {
                x: (subtraction-with-scientific-notation rolling_x_a rolling_x_exp x_pre x_pre_exp),
                product: (multiplication-with-scientific-notation-with-precision (get x rolling_product) (get exp rolling_product) a_pre a_pre_exp)
            }
            {x: rolling_x, product: rolling_product}
        )
    )
)

(define-private (rolling_div_sum (n int) (rolling (tuple (term (tuple (x int) (exp int))) (seriesSum (tuple (x int) (exp int))) (x (tuple (x int) (exp int))))))
  (let
    (
      (x (get x rolling))
      (rolling_term (get term rolling))
      (rolling_sum (get seriesSum rolling))
      (next_term_transformed (transform-to-16 (multiplication-with-scientific-notation (get x rolling_term) (get exp rolling_term) (get x x) (get exp x))))
      (next_term_div_transformed (transform-to-16 (division-with-scientific-notation (get x next_term_transformed) (get exp next_term_transformed) n 0)))
      (next_sum (addition-with-scientific-notation (get x rolling_sum) (get exp rolling_sum) (get x next_term_div_transformed) (get exp next_term_div_transformed)))
   )
    {term: next_term_div_transformed, seriesSum: next_sum, x: x}
 )
)

;; this function should take uint as parameter for digits to check the max range
(define-read-only (pow-fixed (tuple-x (tuple (x uint) (exp int))) (tuple-y (tuple (x uint) (exp int))))
  (let
    (
        (mantissa-x (get x tuple-x))
        (mantissa-y (get x tuple-y))
        (x-scaled-down (scale-down-with-lost-precision-uint tuple-x))
        (y-scaled-down (scale-down-with-lost-precision-uint tuple-y))
    )
    
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (not (greater-than-equal-to-uint (get x x-scaled-down) (get exp x-scaled-down) (get x UPPER_BASE_BOUND_SCALE_DOWN) (get exp UPPER_BASE_BOUND_SCALE_DOWN))) ERR-X-OUT-OF-BOUNDS)
    (asserts! (< mantissa-x MANTISSA_LIMIT) ERR-X-OUT-OF-BOUNDS-MANTISSA)
    (asserts! (<= (get exp tuple-x) 23) ERR-X-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (not (greater-than-equal-to-uint (get x y-scaled-down) (get exp y-scaled-down) (get x LOWER_EXPONENT_BOUND_SCALE_DOWN) (get exp LOWER_EXPONENT_BOUND_SCALE_DOWN))) ERR-Y-OUT-OF-BOUNDS)
    (asserts! (< mantissa-y MANTISSA_LIMIT) ERR-Y-OUT-OF-BOUNDS-MANTISSA)
    (asserts! (<= (get exp tuple-y) 23) ERR-Y-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

    (if (is-eq mantissa-y u0) 
      (ok ONE)
      (if (is-eq mantissa-x u0) 
        (ok ZERO)
        (pow-priv tuple-x tuple-y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 16 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
(define-read-only (exp-fixed (num (tuple (x int) (exp int))))
    (let 
        (
            (x (get x num))
            (exp (get exp num))
        )   
        (asserts! (and (greater-than-equal-to x exp (get x MIN_NATURAL_EXPONENT) (get exp MIN_NATURAL_EXPONENT))
        (greater-than-equal-to (get x MAX_NATURAL_EXPONENT) (get exp MAX_NATURAL_EXPONENT) x exp)) ERR-INVALID-EXPONENT)
        (if (greater-than-equal-to x exp 0 0)
            (ok (exp-pos num))
            ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            ;; Fixed point division requires multiplying by ONE_16.
            (let
                (
                    (exponent_result (exp-pos (multiplication-with-scientific-notation x exp -1 0)))
                    (transformed_result (transform-to-16 exponent_result))
                )
                (ok (division-with-scientific-notation-with-precision 1 0  (get x transformed_result) (get exp transformed_result)))
            )
        )
    )
)

;; ;; Logarithm (log(arg, base), with signed 16 decimal fixed point base and argument.
(define-read-only (log-fixed (arg (tuple (x int) (exp int))) (base (tuple (x int) (exp int))))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (unwrap-panic (ln-priv base)))
      (logArg (unwrap-panic (ln-priv arg)))
   )
   (division-with-scientific-notation (get x logArg) (get exp logArg) (get x logBase) (get exp logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 16 decimal fixed point argument.
(define-read-only (ln-fixed (num (tuple (x int) (exp int))))
    (let 
        (
            (x (get x num))
            (exp (get exp num))
        )
        (asserts! (> x 0) ERR-OUT-OF-BOUNDS)
        (if (greater-than-equal-to x exp 1 0)
            (ln-priv num)
            ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
            ;; If a is less than one, 1/a will be greater than one.
            ;; Fixed point division requires multiplying by ONE_8.
            (let
                (
                    (ln (unwrap-panic (ln-priv (division-with-scientific-notation 1 0 x exp))))
                )
                (ok (subtraction-with-scientific-notation 0 0 (get x ln) (get exp ln)))
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
    (multiplication-with-scientific-notation (get x num) (get exp num) 1 16)
)

(define-read-only (scale-down-with-scientific-notation (num (tuple (x int) (exp int))))
    (division-with-scientific-notation (get x num) (get exp num) 1 16)
)

(define-read-only (scale-down-with-lost-precision (num (tuple (x int) (exp int))))
    {   
        x: (/ (get x num) ONE_16), 
        exp: (+ (get exp num) 16)
    }    
)

(define-read-only (scale-down-with-lost-precision-uint (num (tuple (x uint) (exp int))))
    { 
        x: (/ (get x num) uONE_16), 
        exp: (+ (get exp num) 16)
    }
)

(define-read-only (greater-than-equal-to-uint (a uint) (a_exp int) (b uint) (b_exp int))
    (let 
        (
            (a-int (to-int a))
            (b-int (to-int b))
        )
        (if (> a_exp b_exp)
            (if (>= (transform-get-x  a-int a_exp b_exp) b-int) true false)
            (if (>= a-int (transform-get-x b-int b_exp a_exp)) true false) 
        )
    )        
)

(define-read-only (greater-than-equal-to (a int) (a_exp int) (b int) (b_exp int))
    (if (> a_exp b_exp)
        (if (>= (transform-get-x a a_exp b_exp) b) true false)
        (if (>= a (transform-get-x b b_exp a_exp)) true false)
    )       
)

(define-read-only (addition-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    (if (> a_exp b_exp)
        {x: (+ (transform-get-x a a_exp b_exp) b), exp: b_exp }
        {x: (+ (transform-get-x b b_exp a_exp) a), exp: a_exp }
    )
)

(define-read-only (subtraction-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    (if (> a_exp b_exp)
        {x: (- (transform-get-x a a_exp b_exp) b), exp: b_exp }
        {x: (- a (transform-get-x b b_exp a_exp)), exp: a_exp }
    )
)

(define-read-only (division-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    {
        x: (/ (scale-up a) b), 
        exp: (+ (- a_exp b_exp) -16)
    }
)

(define-read-only (multiplication-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    {   
        x: (* a b), 
        exp: (+ a_exp b_exp)
    }
)

(define-private (division-with-scientific-notation-with-precision-priv (a int) (a_exp int) (b int) (b_exp int) (base_exp int)) 
     (let
        (
            (division (/ a b))
            (division-exponent (+ (- a_exp b_exp) base_exp))
            (factor (- a (* division b)))

            (remainder (/ (* ONE_16 factor) b))
            
            (remainder-exponent (+ division-exponent -16))
        )
        (addition-with-scientific-notation division division-exponent remainder remainder-exponent)
    )
)

(define-read-only (division-with-scientific-notation-with-precision (a int) (a_exp int) (b int) (b_exp int))
    (if (> a b) 
        (division-with-scientific-notation-with-precision-priv a a_exp b b_exp 0)
        (division-with-scientific-notation-with-precision-priv (scale-up a) a_exp b b_exp -16)
    )
)

;; multiplication-with-scientific-notation-with-precision
;; this function truncates the mantissa of numbers to 16 digits 
;; and then multiply the numbers
;; 10000000000000000 ^ 3 * 9999999999999999999999 ^ 5 --> 1000000000000000 ^ 4 * 9999999999999999 ^ 11
;; {x: 1000000000000000 * 9999999999999999, exp: 4 + 11 }
;; {x: 9999999999999999999999, exp: 15}
(define-read-only (multiplication-with-scientific-notation-with-precision (a int) (a_exp int)  (b int) (b_exp int))
    (let
        (
            (a-count (digit-count a))
            (first (if (> a-count 16)
                {x: (/ a (pow 10 (- a-count 16))), exp: (+ a_exp (- a-count 16))}
                {x: a, exp: a_exp}
            ))
            (b-count (digit-count b))
        )
        (if (> b-count 16)
            {x: (* (/ b (pow 10 (- b-count 16))) (get x first)), exp: (+ (+ b_exp (- b-count 16)) (get exp first))}
            {x: (* b (get x first)), exp: (+ b_exp (get exp first))}
        )
    )
)

;; transformation-get-x - this function returns only mantissa 
;; we are not creating tuple here for cost optimisations 
;; this can be where only mantissa is required
;; You cannot transform -ve exponent to +ve exponent
;; Meaning you cannot go forward exponent, only backwards
;; 35 * 10^-3 transform -2 (FORWARD) ;; 3.5 * 10^-2 (NOT POSSIBLE)
;; 35 * 10^3 transform 1 (BACKWARD) ;; 3500 * 10^1 (POSSIBLE)
(define-read-only (transform-get-x (x int) (exp int) (power int))
    (let
        (
            (exp-diff (- power exp))
            (diff-power (if (>= exp-diff 0) exp-diff (* -1 exp-diff)))
        )
        (if (and (<= exp-diff 25) (>= exp-diff -25))
            (* x (pow 10 diff-power))
            x
        )
    )
)

;; transformation
;; You cannot transform -ve exponent to +ve exponent
;; Meaning you cannot go forward exponent, only backwards
;; 35 * 10^-3 transform -2 (FORWARD) ;; 3.5 * 10^-2 (NOT POSSIBLE)
;; 35 * 10^3 transform 1 (BACKWARD) ;; 3500 * 10^1 (POSSIBLE)
(define-read-only (transform (x int) (exp int) (power int))
    (let
        (
            (exp-diff (- power exp))
            (diff-power (if (>= exp-diff 0) exp-diff (* -1 exp-diff)))
        )
        (if (and (<= exp-diff 25) (>= exp-diff -25))
            {
                x: (* x (pow 10 diff-power)),
                exp: power
            }
            {x: x, exp: exp}
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
            (new-exp (+ 8 (get exp num)))
        )
        ;; (asserts! (< result DIGITS_31) INT_RANGE_EXCEEDED)
        (if (>= new-exp 0)
            (ok (* x (pow 10 new-exp)))
            (ok (/ x (pow 10 (* -1 new-exp))))
        )
    )  
)