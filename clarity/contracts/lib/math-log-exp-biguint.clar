
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

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^16, 
;; which makes the largest exponent ln((2^127 - 1) / 10^16) = 51.1883304432
;; The smallest possible result is 10^(-16), which makes largest negative argument ln(10^(-16)) = -36.8413614879
;; We use 51.0 and -36.0 to have some safety margin.
(define-constant MAX_NATURAL_EXPONENT (* 51 ONE_16))
(define-constant MIN_NATURAL_EXPONENT (* -36 ONE_16))

(define-constant MILD_EXPONENT_BOUND (/ (pow u2 u126) (to-uint ONE_16)))

;; Because largest exponent is 51, we start from 32
;; The first several a_n are too large if stored as 16 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.

;; a_pre is in scientific notation
;; a_n can all be stored in 16 decimal place

;; 16 decimal constants
(define-constant x_a_list (list 
{x_pre: 320000000000000000, a_pre: 789629601826806951609780226351, a_exp: -16} ;; x0 = 2^5, a0 = e^(x0)
{x_pre: 160000000000000000, a_pre: 88861105205078726367630, a_exp: -16} ;; x1 = 2^4, a1 = e^(x1)
{x_pre: 80000000000000000, a_pre: 29809579870417282747, a_exp: -16} ;; x2 = 2^3, a2 = e^(x2)
{x_pre: 40000000000000000, a_pre: 545981500331442391, a_exp: -16} ;; x3 = 2^2, a3 = e^(x3)
{x_pre: 20000000000000000, a_pre: 73890560989306502, a_exp: -16} ;; x4 = 2^1, a4 = e^(x4)
{x_pre: 10000000000000000, a_pre: 27182818284590452, a_exp: -16} ;; x5 = 2^0, a5 = e^(x5)
{x_pre: 5000000000000000, a_pre: 16487212707001282, a_exp: -16} ;; x6 = 2^-1, a6 = e^(x6)
{x_pre: 2500000000000000, a_pre: 12840254166877415, a_exp: -16} ;; x7 = 2^-2, a7 = e^(x7)
{x_pre: 1250000000000000, a_pre: 11331484530668263, a_exp: -16} ;; x8 = 2^-3, a8 = e^(x8)
{x_pre: 625000000000000, a_pre: 10644944589178594, a_exp: -16} ;; x9 = 2^-4, a9 = e^(x9)
{x_pre: 312500000000000, a_pre: 10317434074991027, a_exp: -16} ;; x10 = 2^-5, a10 = e^(x10)
))

;; 2^5+2^4+2^3+2^2+2^1+2^0+2^(-1)+2^(-2)+2^(-3)+2^(-4)+2^(-5) = 63.96875
;; 32+16+8+4+2+1+5+25+125+625+3125 = 3,968 0
;; 32+16+8+4+2+1+0.5+0.25+0.125+0.0625+0.03125 = 63.96875 = 6396875 * 10^-5

;; We must keep a_pre to 16 digits so that division won't give us 0 when divided by ONE_16
(define-constant x_a_list_16 (list 
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
(define-constant ERR-Y-OUT-OF-BOUNDS (err u5010))
(define-constant ERR-PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant ERR-INVALID-EXPONENT (err u5012))
(define-constant ERR-OUT-OF-BOUNDS (err u5013))

(define-read-only (scale-up (a int))
    (* a ONE_16)
)

(define-read-only (scale-down (a int))
    (/ a ONE_16)
)

;; private functions
;;

(define-read-only (ln-priv-16 (a int) (a_exp int))
    (let
        (
            ;; decomposition process
            ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L349
            (a_sum (fold accumulate_division_16 x_a_list_16 {a: {a: a, exp: a_exp}, sum: {a: 0, exp: 0}}))
            (out_a (get a a_sum))
            (out_sum (get sum a_sum))
            ;; below is the Taylor series now 
            ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L416 
            ;; z = (a-1)/(a+1) so for precision we multiply dividend with ONE_16 to retain precision
            ;; (z (/ (scale-up (- out_a ONE_16)) (+ out_a ONE_16)))
            ;; (z_squared (/ (* z z) ONE_16))
            ;; (div_list (list 3 5 7 9 11))
            ;; (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
            ;; (seriesSum (get seriesSum num_sum_zsq))
            ;; (r (+ out_sum (* seriesSum 2)))
        )
        (ok a_sum)
        ;; (ok r)
    )
)

(define-private (accumulate_division_16 (x_a_pre (tuple (x_pre int) (x_pre_exp int) (a_pre int) (a_pre_exp int))) (rolling_a_sum (tuple (a (tuple (a int) (exp int))) (sum (tuple (a int) (exp int))))))
  (let
    (
      (a_pre (get a_pre x_a_pre))
      (a_pre_exp (get a_pre_exp x_a_pre))
      
      (x_pre (get x_pre x_a_pre))
      (x_pre_exp (get x_pre_exp x_a_pre))

      (rolling_a (get a rolling_a_sum))
      (rolling_a_a (get a rolling_a))
      (rolling_a_exp (get exp rolling_a))
      
      (rolling_sum (get sum rolling_a_sum))
      (rolling_sum_a (get a rolling_sum))
      (rolling_sum_exp (get exp rolling_sum))
   )
   ;; I think we can simply use a_pre without scaling here
   ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L347
    ;; this rolling a and sum is working as a looped a and sum
    (if (greater-than-equal-to rolling_a_a rolling_a_exp a_pre a_pre_exp) 
    ;; (if true
        {
            a: (division-with-scientific-notation rolling_a_a rolling_a_exp a_pre a_pre_exp),
            sum: (addition-with-scientific-notation rolling_sum_a rolling_sum_exp x_pre x_pre_exp) 
        } ;; rolling_a is scaled up so that precision is not lost when dividing by a_pre
        {a: rolling_a, sum: rolling_sum}
    )
 )
)
;; 50000 0 >= 7896296018268069 -2, true, 50000 0 / 7896296018268069 -2 = 0.000000000633208 -> a: 63320 -14, sum: 32 0
;; 63320 -14 >= 8886110520507873 -9, false -> a: 63320 -14, sum: 32 0
;; 63320 -14 >= 2980957987041728 -12, false -> a: 63320 -14, sum: 32 0
;; 63320 -14 >= 5459815003314423 -14, false -> a: 63320 -14, sum: 32 0
;; 63320 -14 >= 7389056098930650 -15, false -> a: 63320 -14, sum: 32 0

;; 20 * 10 ^ 2
;;788999999999999.9 * 10 ^ -1    
(define-read-only (greater-than-equal-to (a int) (a_exp int) (b int) (b_exp int))
    (if (> a_exp b_exp)
        (let
            (
                (transformation (transform a a_exp b_exp))
                (new_a (get a transformation))
            )
            (if (>= new_a b) true false)
        )
        (let
            (
                (transformation (transform b b_exp a_exp))
                (new_b (get a transformation))
            )
            (if (>= a new_b) true false)
        )
    )       
)

;; 3.4 * 10^5 + 9.7 * 10^6
;; 34 * 10^4 + 97 * 10^5
;; (34+97) * 10^5
;; 131 * 10^5

;; 100 * 10^0 + 35 * 10^-3
;; 100+35 * 10^(0-3)
;; 135 * 10^-3 (WRONG)
;; 100000 * 10^-3 + 35 * 10^-3
;; 100035 * 10^-3 (RIGHT)
(define-read-only (addition-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    (begin
        (if (> a_exp b_exp)
            (let
                (
                    (transformation (transform a a_exp b_exp))
                    (new_a (get a transformation))
                    (new_a_exp (get exp transformation))
                    (addition (+ new_a b))
                )
                {a: addition, exp: b_exp}
            )
            (let
                (
                    (transformation (transform b b_exp a_exp))
                    (new_b (get a transformation))
                    (new_b_exp (get exp transformation))
                    (addition (+ new_b a))
                )
                {a: addition, exp: a_exp}
            )
        )
    )
)

;; transformations upto 16 decimals
;; You cannot transform -ve exponent to +ve exponent
;; Meaning you cannot go forward exponent, only backwards

;; 100 * 10^0 transform -3 (BACKWARD)
;; 100000 * 10^-3 (POSSIBLE)

;; 35 * 10^-3 transform 0 (FORWARDING)
;; 0.0035 * 10^0 (NOT POSSIBLE)

;; 35 * 10^-3 transform -4 (BACKWARD)
;; 350 * 10^-4 (POSSIBLE)

;; 35 * 10^-3 transform -2 (FORWARD)
;; 3.5 * 10^-2 (NOT POSSIBLE)

;; 35 * 10^3 transform 1 (BACKWARD)
;; 3500 * 10^1 (POSSIBLE)


;; 35 * 10^3 transform 3 (BACKWARD)
;; 35 * 10^3 (POSSIBLE)

(define-read-only (transform (a int) (a_exp int) (x int))
    (let
        (
            (exp-diff (- x a_exp))
        )
        (if (is-eq exp-diff 0)
            {a: (* a 1), exp: x}
        (if (or (is-eq exp-diff -1) (is-eq exp-diff 1))
            {a: (* a 10), exp: x}
        (if (or (is-eq exp-diff -2) (is-eq exp-diff 2))
            {a: (* a 100), exp: x}
        (if (or (is-eq exp-diff -3) (is-eq exp-diff 3))
            {a: (* a 1000), exp: x}
        (if (or (is-eq exp-diff -4) (is-eq exp-diff 4))
            {a: (* a 10000), exp: x}
        (if (or (is-eq exp-diff -5) (is-eq exp-diff 5))
            {a: (* a 100000), exp: x}
        (if (or (is-eq exp-diff -6) (is-eq exp-diff 6))
            {a: (* a 1000000), exp: x}
        (if (or (is-eq exp-diff -7) (is-eq exp-diff 7))
            {a: (* a 10000000), exp: x}
        (if (or (is-eq exp-diff -8) (is-eq exp-diff 8))
            {a: (* a 100000000), exp: x}
        (if (or (is-eq exp-diff -9) (is-eq exp-diff 9))
            {a: (* a 1000000000), exp: x}
        (if (or (is-eq exp-diff -10) (is-eq exp-diff 10))
            {a: (* a 10000000000), exp: x}
        (if (or (is-eq exp-diff -11) (is-eq exp-diff 11))
            {a: (* a 100000000000), exp: x}
        (if (or (is-eq exp-diff -12) (is-eq exp-diff 12))
            {a: (* a 1000000000000), exp: x}
        (if (or (is-eq exp-diff -13) (is-eq exp-diff 13))
            {a: (* a 10000000000000), exp: x}
        (if (or (is-eq exp-diff -14) (is-eq exp-diff 14))
            {a: (* a 100000000000000), exp: x}
        (if (or (is-eq exp-diff -15) (is-eq exp-diff 15))
            {a: (* a 1000000000000000), exp: x}
        (if (or (is-eq exp-diff -16) (is-eq exp-diff 16))
            {a: (* a 10000000000000000), exp: x}
        {a: a, exp: a_exp}
        )))))))))))))))))
    )
)

;; 3.4 * 10^5 - 9.7 * 10^6
;; 34 * 10^4 - 97 * 10^5
;; (34-97) * 10^5
;; -63 * 10^5
(define-read-only (subtraction-with-scientific-notation (a int) (a_exp int) (b int) (b_exp int))
    (begin
        (if (> a_exp b_exp)
            (let
                (
                    (transformation (transform a a_exp b_exp))
                    (new_a (get a transformation))
                    (new_a_exp (get exp transformation))
                    (subtraction (- new_a b))
                )
                {a: subtraction, exp: b_exp}
            )
            (let
                (
                    (transformation (transform b b_exp a_exp))
                    (new_b (get a transformation))
                    (new_b_exp (get exp transformation))
                    (subtraction (- new_b a))
                )
                {a: subtraction, exp: a_exp}
            )
        )
    )
)

;; 2.5 / 4 = 0.625
;; (25*10^-1) / (4*10^0)
;; (25/4) * (10^(-1-0))
;; (625*10^14) * (10^-1 * 10^-16)
;; (62500000000000000) * (10^-17)
;; (0.625)
(define-read-only (division-with-scientific-notation (a int) (a-exp int) (b int) (b-exp int))
    (let
        (
            (division (/ (scale-up a) b)) ;; scale-up to get the decimal part precision
            (exponent (+ (- a-exp b-exp) -16)) ;; scale down from the exponent part
        )
        {a: division, exp: exponent}
    )
)

(define-read-only (div-update (a int) (a-exp int) (b int) (b-exp int))
    (let
        (
            (division (/ (scale-up a) b)) ;; scale-up to get the decimal part precision
            (division-exponent (- (+ a-exp -16) b-exp)) ;; scale down from the exponent part
                        
            (factor (- (scale-up a) (* division b)))
            ;; (remainder-exponent (get exp (subtraction-with-scientific-notation (scale-up a) (+ a-exp -16) factor factor-exponent)))

            (remainder (/ (scale-up factor) b))
            ;; (rem-exponent (- (+ remainder-exponent -16) b-exp))
            
            (remainder-exponent (+ division-exponent -16))

            (result (addition-with-scientific-notation division division-exponent remainder remainder-exponent))
        )
        ;; {
        ;;     division: division,
        ;;     division-exponent: division-exponent,
        ;;     remainder: remainder,
        ;;     remainder-exponent: remainder-exponent,
        ;;     finalfinal-answer: final,
        ;; }
        {result: result}
    )
)

;; {division: 63320, division-exponent: -14, finalfinal-answer: {a: 633208277454708827542, exp: -30}, remainder: 8277454708827542, remainder-exponent: -30}
;; 0.000000000633208277454708827542

;; {division: 63320, division-exponent: -14, rem-div: 8277454708827542, rem-exponent: -30}
;; 50000 / 78962960182680.69 
;; 63320*10^-14 + 8277454708827542*10^-30 => 0.000000000633208277454708827542
;; 0.000000000633208277454708827542

;; {exponent: -14, rem: 8277454708827542, result: 63320, result-exponent: -14}
;; 50000 / 78962960182680.69 
;; 0.000000000633208277454708827542 => 0.000000000633208
;; 63320*10^(-14) = 0.0000000006332

;; u63320 * 10^-16 + u8277454708827542 * 10^-32 => 6.332082775E-12

;; {exponent: -14, rem: 1387273544137711, result: 316604}
;; 250000 / 7896296018268069
;; 0.00000000000316604 1387273544137711

(define-read-only (ln-priv (a int))
    (let
        (
            ;; decomposition process
            ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L349
            (a_sum (fold accumulate_division x_a_list {a: a, sum: 0}))
            (out_a (get a a_sum))
            (out_sum (get sum a_sum))
            ;; below is the Taylor series now 
            ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L416 
            ;; z = (a-1)/(a+1) so for precision we multiply dividend with ONE_16 to retain precision
            (z (/ (scale-up (- out_a ONE_16)) (+ out_a ONE_16)))
            (z_squared (/ (* z z) ONE_16))
            (div_list (list 3 5 7 9 11))
            (num_sum_zsq (fold rolling_sum_div div_list {num: z, seriesSum: z, z_squared: z_squared}))
            (seriesSum (get seriesSum num_sum_zsq))
            (r (+ out_sum (* seriesSum 2)))
        )
        (ok a_sum)
        ;; (ok r)
    )
)

(define-private (accumulate_division (x_a_pre (tuple (x_pre int) (a_pre int) (a_exp int))) (rolling_a_sum (tuple (a int) (sum int))))
  (let
    (
      (a_pre (get a_pre x_a_pre))
      (x_pre (get x_pre x_a_pre))
      (rolling_a (get a rolling_a_sum))
      (rolling_sum (get sum rolling_a_sum))
   )
   ;; I think we can simply use a_pre without scaling here
   ;; https://github.com/balancer-labs/balancer-v2-monorepo/blob/a62e10f948c5de65ddfd6d07f54818bf82379eea/pkg/solidity-utils/contracts/math/LogExpMath.sol#L347
    (if (>= rolling_a a_pre) 
      {a: (/ (* rolling_a ONE_16) a_pre), sum: (+ rolling_sum x_pre)} ;; rolling_a is scaled up so that precision is not lost when dividing by a_pre
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
      (next_num (scale-down (* rolling_num z_squared)))
      (next_sum (+ rolling_sum (/ next_num n)))
   )
    {num: next_num, seriesSum: next_sum, z_squared: z_squared}
 )
)

;; ;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; ;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; ;; x^y = exp(y * ln(x)).
;; ;; Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
;; (define-read-only (pow-priv (x uint) (y uint))
;;   (let
;;     (
;;       (x-int (to-int x))
;;       (y-int (to-int y))
;;       (lnx (unwrap-panic (ln-priv x-int)))
;;       (logx-times-y (scale-down (* lnx y-int)))
;;     )
;;     (asserts! (and (<= MIN_NATURAL_EXPONENT logx-times-y) (<= logx-times-y MAX_NATURAL_EXPONENT)) ERR-PRODUCT-OUT-OF-BOUNDS)
;;     (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
;;   )
;; )

;; (define-read-only (exp-pos (x int))
;;     (let
;;         (
;;         ;; For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
;;         ;; it and compute the accumulated product.
;;         (x_product (fold accumulate_product x_a_list {x: x, product: ONE_16}))
;;         (product_out (get product x_product))
;;         (x_out (get x x_product))
;;         (seriesSum (+ ONE_16 x_out))
;;         (div_list (list 2 3 4 5 6 7 8 9 10 11 12))
;;         (term_sum_x (fold rolling_div_sum div_list {term: x_out, seriesSum: seriesSum, x: x_out}))
;;         (sum (get seriesSum term_sum_x))
;;         )
;;         (ok (* (scale-down (* product_out sum)) 1))
;;     )
;; )

;; (define-private (accumulate_product (x_a_pre (tuple (x_pre int) (a_pre int) (a_exp int))) (rolling_x_p (tuple (x int) (product int))))
;;   (let
;;     (
;;       (x_pre (get x_pre x_a_pre))
;;       (a_pre (get a_pre x_a_pre))
;;       (rolling_x (get x rolling_x_p))
;;       (rolling_product (get product rolling_x_p))
;;    )
;;     (if (>= rolling_x x_pre)
;;       {x: (- rolling_x x_pre), product: (/ (* rolling_product a_pre) ONE_16)}
;;       {x: rolling_x, product: rolling_product}
;;    )
;;  )
;; )

;; (define-private (rolling_div_sum (n int) (rolling (tuple (term int) (seriesSum int) (x int))))
;;   (let
;;     (
;;       (rolling_term (get term rolling))
;;       (rolling_sum (get seriesSum rolling))
;;       (x (get x rolling))
;;       (next_term (/ (scale-down (* rolling_term x)) n))
;;       (next_sum (+ rolling_sum next_term))
;;    )
;;     {term: next_term, seriesSum: next_sum, x: x}
;;  )
;; )

;; ;; public functions
;; ;;

;; (define-read-only (get-exp-bound)
;;   (ok MILD_EXPONENT_BOUND)
;; )

;; ;; Exponentiation (x^y) with unsigned 16 decimal fixed point base and exponent.
;; (define-read-only (pow-fixed (x uint) (y uint))
;;   (begin
;;     ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
;;     (asserts! (< x (pow u2 u127)) ERR-X-OUT-OF-BOUNDS)

;;     ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
;;     (asserts! (< y MILD_EXPONENT_BOUND) ERR-Y-OUT-OF-BOUNDS)

;;     (if (is-eq y u0) 
;;       (ok (to-uint ONE_16))
;;       (if (is-eq x u0) 
;;         (ok u0)
;;         (pow-priv x y)
;;       )
;;     )
;;   )
;; )

;; ;; Natural exponentiation (e^x) with signed 16 decimal fixed point exponent.
;; ;; Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
;; (define-read-only (exp-fixed (x int))
;;   (begin
;;     (asserts! (and (<= MIN_NATURAL_EXPONENT x) (<= x MAX_NATURAL_EXPONENT)) (err ERR-INVALID-EXPONENT))
;;     (if (< x 0)
;;       ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
;;       ;; fits in the signed 128 bit range (as it is larger than MIN_NATURAL_EXPONENT).
;;       ;; Fixed point division requires multiplying by ONE_16.
;;       (ok (/ (scale-up ONE_16) (unwrap-panic (exp-pos (* -1 x)))))
;;       (exp-pos x)
;;     )
;;   )
;; )

;; ;; Logarithm (log(arg, base), with signed 16 decimal fixed point base and argument.
;; (define-read-only (log-fixed (arg int) (base int))
;;   ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
;;   (let
;;     (
;;       (logBase (scale-up (unwrap-panic (ln-priv base))))
;;       (logArg (scale-up (unwrap-panic (ln-priv arg))))
;;    )
;;     (ok (/ (scale-up logArg) logBase))
;;  )
;; )

;; ;; Natural logarithm (ln(a)) with signed 16 decimal fixed point argument.
;; (define-read-only (ln-fixed (a int))
;;   (begin
;;     (asserts! (> a 0) (err ERR-OUT-OF-BOUNDS))
;;     (if (< a ONE_16)
;;       ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
;;       ;; If a is less than one, 1/a will be greater than one.
;;       ;; Fixed point division requires multiplying by ONE_16.
;;       (ok (- 0 (unwrap-panic (ln-priv (/ (scale-up ONE_16) a)))))
;;       (ln-priv a)
;;    )
;;  )
;; )