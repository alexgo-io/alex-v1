;; math-fixed-point
;; Fixed Point Math

;; public functions
;;

;; @desc mul-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-down (a uint) (b uint))
    (mul-fixed a b)
)

;; @desc mul-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (mul-up (a uint) (b uint))
    (mul-fixed-up a b)
)

;; @desc div-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-down (a uint) (b uint))
    (div-fixed a b)
)

;; @desc div-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-up (a uint) (b uint))
    (div-fixed-up a b)
)

;; @desc pow-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-down (a uint) (b uint))    
    (pow-fixed a b)
)

;; @desc pow-up
;; @params a 
;; @params b
;; @returns uint
(define-read-only (pow-up (a uint) (b uint))
    (pow-fixed-up a b)
)

;; math-log-exp
;; Exponentiation and logarithm functions for 16 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log-x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 16 decimal fixed point numbers.
(define-constant SIGNED-ONE-16 (pow 10 16))
(define-constant UNSIGNED-ONE-16 (pow u10 u16))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^16, 
;; which makes the largest exponent ln((2^127 - 1) / 10^16) = 51.1883304432
;; The smallest possible result is 10^(-16), which makes largest negative argument ln(10^(-16)) = -36.8413614879
;; We use 51.0 and -36.0 to have some safety margin.
(define-constant MAX-NATURAL-EXPONENT {x: 51, exp: 0})
(define-constant MIN-NATURAL-EXPONENT {x: -36, exp: 0})

(define-constant MILD-EXPONENT-BOUND (pow u2 u126))
(define-constant UPPER-BASE-BOUND {x: 17014118346046923173168730371588410572, exp: 1}) ;; this is 2^126
(define-constant UPPER-BASE-BOUND-SCALE-DOWN {x: 1701411834604692317316, exp: 17})
(define-constant LOWER-EXPONENT-BOUND {x: 85070591730234615865843651857942052864, exp: 0}) ;; this is 2^126
(define-constant LOWER-EXPONENT-BOUND-SCALE-DOWN {x: 8507059173023461586584, exp: 16})
(define-constant ZERO {x: 0, exp: 0})
(define-constant ONE {x: 1, exp: 0})
(define-constant TWO {x: 2, exp: 0})
(define-constant MANTISSA-LIMIT 100000000000)
(define-constant DIGITS-31 9999999999999999999999999999999)
(define-constant DIGIT-LIST (list u10 u10 u10 u10 u10 u10 u10 u10))
(define-constant TAYLOR-SERIES-TERMS-6 (list 3 5 7 9 11))
(define-constant TAYLOR-SERIES-TERMS-12 (list 2 3 4 5 6 7 8 9 10 11 12))

;; Because largest exponent is 51, we start from 32
;; The first several a-n are too large if stored as 16 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.

;; a-pre is in scientific notation
;; a-n can all be stored in 16 decimal place

;; 16 decimal constants
;; We must keep a-pre to 16 digits so that division won't give us 0 when divided by SIGNED-ONE-16
(define-constant x-a-list (list 
{x-pre: 32, x-pre-exp: 0, a-pre: 7896296018268069, a-pre-exp: -2} ;; x0 = 2^5, a0 = e^(x0)
{x-pre: 16, x-pre-exp: 0, a-pre: 8886110520507873, a-pre-exp: -9} ;; x1 = 2^4, a1 = e^(x1)
{x-pre: 8, x-pre-exp: 0, a-pre: 2980957987041728, a-pre-exp: -12} ;; x2 = 2^3, a2 = e^(x2)
{x-pre: 4, x-pre-exp: 0, a-pre: 5459815003314424, a-pre-exp: -14} ;; x3 = 2^2, a3 = e^(x3)
{x-pre: 2, x-pre-exp: 0, a-pre: 7389056098930650, a-pre-exp: -15} ;; x4 = 2^1, a4 = e^(x4)
{x-pre: 1, x-pre-exp: 0, a-pre: 2718281828459045, a-pre-exp: -15} ;; x5 = 2^0, a5 = e^(x5)
{x-pre: 5, x-pre-exp: -1, a-pre: 1648721270700128, a-pre-exp: -15} ;; x6 = 2^-1, a6 = e^(x6)
{x-pre: 25, x-pre-exp: -2, a-pre: 1284025416687741, a-pre-exp: -15} ;; x7 = 2^-2, a7 = e^(x7)
{x-pre: 125, x-pre-exp: -3, a-pre: 1133148453066826, a-pre-exp: -15} ;; x8 = 2^-3, a8 = e^(x8)
{x-pre: 625, x-pre-exp: -4, a-pre: 1064494458917859, a-pre-exp: -15} ;; x9 = 2^-4, a9 = e^(x9)
{x-pre: 3125, x-pre-exp: -5, a-pre: 1031743407499103, a-pre-exp: -15} ;; x10 = 2^-5, a10 = e^(x10)
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

(define-private (ln-priv (n {x: int, exp: int}))
    (let
        (
            ;; decomposition
            (a-sum (fold accumulate-division x-a-list {a: n, sum: ZERO}))
            (out-a-transformed (transform-to-16 (get a a-sum)))
            ;; z calculation
            (z (div-scientific-with-lost-precision (sub-scientific out-a-transformed ONE) (add-scientific out-a-transformed ONE)))
            (z-squared-scaled-down (scale-down-with-lost-precision (mul-scientific-with-lost-precision z z)))
            ;; taylor series
            (num-sum-zsq (fold rolling-sum-div TAYLOR-SERIES-TERMS-6 {n: z, seriesSum: z, z-squared: z-squared-scaled-down}))
        )
        (add-scientific (get sum a-sum) (mul-scientific-with-lost-precision (scale-down-with-lost-precision (get seriesSum num-sum-zsq)) TWO))
    )
)

(define-private (accumulate-division (x-a-pre {x-pre: int, x-pre-exp: int, a-pre: int, a-pre-exp: int}) (rolling-a-sum {a: {x: int, exp: int}, sum: {x: int, exp: int}}))
    (let
        (
            (a-pre (get a-pre x-a-pre))
            (a-pre-exp (get a-pre-exp x-a-pre))
        )
        (if (greater-than-equal-to (get a rolling-a-sum) {x: a-pre, exp: a-pre-exp})
            {
                a: (div-scientific (get a rolling-a-sum) {x: a-pre, exp: a-pre-exp}),
                sum: (add-scientific (get sum rolling-a-sum) {x: (get x-pre x-a-pre), exp: (get x-pre-exp x-a-pre)}) 
            }
            rolling-a-sum
        )
    )
)

(define-private (rolling-sum-div (n int) (rolling {n: {x: int, exp: int}, seriesSum: {x: int, exp: int}, z-squared: {x: int, exp: int}}))
    (let
        (
            (next-num-scaled-down (scale-down-with-lost-precision (mul-scientific-with-lost-precision (get n rolling) (get z-squared rolling))))
            (next-sum-div (div-scientific-with-lost-precision next-num-scaled-down {x: n, exp: 0}))
            (next-sum (add-scientific next-sum-div (get seriesSum rolling)))
        )
        {n: next-num-scaled-down, seriesSum: next-sum, z-squared: (get z-squared rolling)}
    )
) 

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN-NATURAL-EXPONENT`, or larger than `MAX-NATURAL-EXPONENT`.
(define-private (pow-priv (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (let
        (
            (logx-times-y (mul-scientific-with-lost-precision (ln-priv n1) n2))
        )
        (asserts! (and (greater-than-equal-to logx-times-y MIN-NATURAL-EXPONENT) (greater-than-equal-to MAX-NATURAL-EXPONENT logx-times-y)) ERR-INVALID-EXPONENT)
        (exp-scientific logx-times-y)
    )
)


(define-private (exp-pos (n {x: int, exp: int}))
    (let
        (
            ;; For each x-n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            ;; it and compute the accumulated product.
            (x-product (fold accumulate-product x-a-list {x: n, product: ONE}))
            (x-out (get x x-product))
            (seriesSum (add-scientific ONE (transform-to-16 x-out)))
            (term-sum-x (fold rolling-div-sum TAYLOR-SERIES-TERMS-12 {term: x-out, seriesSum: seriesSum, x: x-out}))
            (r (mul-scientific (transform-to-16 (get product x-product)) (get seriesSum term-sum-x)))
        )
        (if (greater-than-equal-to n ONE)
            (scale-down-with-lost-precision r)
            r
        )
    )
)

(define-private (accumulate-product (x-a-pre {x-pre: int, x-pre-exp: int, a-pre: int, a-pre-exp: int}) (rolling-x-p {x: {x: int, exp: int}, product: {x: int, exp: int}}))
    (let
        (
            (x-pre (get x-pre x-a-pre))
            (x-pre-exp (get x-pre-exp x-a-pre))
            (a-pre (get a-pre x-a-pre))
            (a-pre-exp (get a-pre-exp x-a-pre))
            (rolling-x (get x rolling-x-p))
            (rolling-product (get product rolling-x-p))
        )
        (if (greater-than-equal-to rolling-x {x: x-pre, exp: x-pre-exp})
            {
                x: (sub-scientific rolling-x {x: x-pre, exp: x-pre-exp}),
                product: (mul-scientific rolling-product {x: a-pre, exp: a-pre-exp})
            }
            {x: rolling-x, product: rolling-product}
        )
    )
)

(define-private (rolling-div-sum (n int) (rolling {term: {x: int, exp: int}, seriesSum: {x: int, exp: int}, x: {x: int, exp: int}}))
    (let
        (
            (next-term-div-transformed (transform-to-16 (div-scientific-with-lost-precision (transform-to-16 (mul-scientific-with-lost-precision (get term rolling) (get x rolling))) {x: n, exp: 0})))
        )
        {term: next-term-div-transformed, seriesSum: (add-scientific (get seriesSum rolling) next-term-div-transformed), x: (get x rolling)}
    )
)

;; this function should take uint as parameter for digits to check the max range
(define-read-only (pow-scientific (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (begin   
        (asserts! (and (>= (get x n1) 0) (>= (get x n2) 0)) ERR-NOT-POSITIVE)
        ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
        (asserts! (not (greater-than-equal-to (scale-down-with-lost-precision n1) UPPER-BASE-BOUND-SCALE-DOWN)) ERR-X-OUT-OF-BOUNDS)
        (asserts! (< (get x n1) MANTISSA-LIMIT) ERR-X-OUT-OF-BOUNDS-MANTISSA)
        (asserts! (<= (get exp n1) 23) ERR-X-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

        ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
        (asserts! (not (greater-than-equal-to (scale-down-with-lost-precision n2) LOWER-EXPONENT-BOUND-SCALE-DOWN)) ERR-Y-OUT-OF-BOUNDS)
        (asserts! (< (get x n2) MANTISSA-LIMIT) ERR-Y-OUT-OF-BOUNDS-MANTISSA)
        (asserts! (<= (get exp n2) 23) ERR-Y-OUT-OF-BOUNDS-EXP) ;; because transformations fail after 25

        (if (is-eq (get x n2) 0) 
            (ok ONE)
            (if (is-eq (get x n1) 0) 
                (ok ZERO)
                (pow-priv n1 n2)
            )
        )
    )
)

;; Natural exponentiation (e^x) with signed 16 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN-NATURAL-EXPONENT, or larger than `MAX-NATURAL-EXPONENT`.
(define-read-only (exp-scientific (n {x: int, exp: int}))
    (let 
        (
            (x (get x n))
            (exp (get exp n))
        )   
        (asserts! (and (greater-than-equal-to n MIN-NATURAL-EXPONENT) (greater-than-equal-to MAX-NATURAL-EXPONENT n)) ERR-INVALID-EXPONENT)
        (if (greater-than-equal-to n ZERO)
            (ok (exp-pos n))
            ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            ;; fits in the signed 128 bit range (as it is larger than MIN-NATURAL-EXPONENT).
            ;; Fixed point division requires multiplying by SIGNED-ONE-16.
            (ok (div-scientific ONE (transform-to-16 (exp-pos (mul-scientific-with-lost-precision n {x: -1, exp: 0})))))
        )
    )
)

;; ;; Logarithm (log(n, b), with signed 16 decimal fixed point base and argument.
(define-read-only (log-scientific (n {x: int, exp: int}) (b {x: int, exp: int}))
    ;; This performs a simple base change: log(n, b) = ln(n) / ln(b).
    (div-scientific-with-lost-precision (ln-priv n) (ln-priv b))
)

;; Natural logarithm (ln(a)) with signed 16 decimal fixed point argument.
(define-read-only (ln-scientific (n {x: int, exp: int}))
    (begin 
        (asserts! (> (get x n) 0) ERR-OUT-OF-BOUNDS)
        (if (greater-than-equal-to n ONE)
            (ok (ln-priv n))
            ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
            ;; If a is less than one, 1/a will be greater than one.
            ;; Fixed point division requires multiplying by ONE-8.
            (ok (sub-scientific ZERO (ln-priv (div-scientific-with-lost-precision ONE n))))
        )
    )
)

(define-read-only (scale-up (a int))
    (* a SIGNED-ONE-16)
)

(define-read-only (scale-down (a int))
    (/ a SIGNED-ONE-16)
)

(define-read-only (scale-up-scientific (n {x: int, exp: int}))
    (mul-scientific-with-lost-precision n {x: 1, exp: 16})
)

(define-read-only (scale-down-scientific (n {x: int, exp: int}))
    (div-scientific-with-lost-precision n {x: 1, exp: 16})
)

(define-read-only (scale-down-with-lost-precision (n {x: int, exp: int}))
    {   
        x: (/ (get x n) SIGNED-ONE-16), 
        exp: (+ (get exp n) 16)
    }    
)

(define-read-only (greater-than-equal-to (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (if (> (get exp n1) (get exp n2))
        (>= (transform-get-x (get x n1) (get exp n1) (get exp n2)) (get x n2))
        (>= (get x n1) (transform-get-x (get x n2) (get exp n2) (get exp n1)))
    )        
)

(define-read-only (add-scientific (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (if (> (get exp n1) (get exp n2))
        {x: (+ (transform-get-x (get x n1) (get exp n1) (get exp n2)) (get x n2)), exp: (get exp n2) }
        {x: (+ (transform-get-x (get x n2) (get exp n2) (get exp n1)) (get x n1)), exp: (get exp n1) }
    )
)

(define-read-only (sub-scientific (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (if (> (get exp n1) (get exp n2))
        {x: (- (transform-get-x (get x n1) (get exp n1) (get exp n2)) (get x n2)), exp: (get exp n2) }
        {x: (- (get x n1) (transform-get-x (get x n2) (get exp n2) (get exp n1))), exp: (get exp n1) }
    )
)

(define-read-only (div-scientific-with-lost-precision (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    {
        x: (/ (scale-up (get x n1)) (get x n2)), 
        exp: (+ (- (get exp n1) (get exp n2)) -16)
    }
)

(define-read-only (mul-scientific-with-lost-precision (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    {   
        x: (* (get x n1) (get x n2)), 
        exp: (+ (get exp n1) (get exp n2))
    }
)

(define-private (div-scientific-with-precision-priv (n1 {x: int, exp: int}) (n2 {x: int, exp: int}) (base-exp int)) 
     (let
        (
            (division (/ (get x n1) (get x n2)))
            (division-exponent (+ (- (get exp n1) (get exp n2)) base-exp))
            (remainder (/ (* SIGNED-ONE-16 (- (get x n1) (* division (get x n2)))) (get x n2)))
            (remainder-exponent (+ division-exponent -16))
        )
        (add-scientific {x: division, exp: division-exponent} {x: remainder, exp: remainder-exponent})
    )
)

(define-read-only (div-scientific (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (if (> (get x n1) (get x n2)) 
        (div-scientific-with-precision-priv n1 n2 0)
        (div-scientific-with-precision-priv {x: (scale-up (get x n1)), exp: (get exp n1)} n2 -16)
    )
)

;; mul-scientific-with-precision
;; this function truncates the mantissa of numbers to 16 digits 
;; and then multiply the numbers
;; 10000000000000000 ^ 3 * 9999999999999999999999 ^ 5 --> 1000000000000000 ^ 4 * 9999999999999999 ^ 11
;; {x: 1000000000000000 * 9999999999999999, exp: 4 + 11 }
;; {x: 9999999999999999999999, exp: 15}
(define-read-only (mul-scientific (n1 {x: int, exp: int}) (n2 {x: int, exp: int}))
    (let
        (
            (a-count (digit-count (get x n1)))
            (first (if (> a-count 16)
                {x: (/ (get x n1) (pow 10 (- a-count 16))), exp: (+ (get exp n1) (- a-count 16))}
                {x: (get x n1), exp: (get exp n1)}
            ))
            (b-count (digit-count (get x n2)))
        )
        (if (> b-count 16)
            {x: (* (/ (get x n2) (pow 10 (- b-count 16))) (get x first)), exp: (+ (+ (get exp n2) (- b-count 16)) (get exp first))}
            {x: (* (get x n2) (get x first)), exp: (+ (get exp n2) (get exp first))}
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
(define-private (transform-get-x (x int) (exp int) (power int))
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
(define-private (transform (x int) (exp int) (power int))
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

(define-private (transform-to-16 (n {x: int, exp: int}))
    (if (< (get exp n) -16)
        {x: (/ (get x n) (pow 10 (+ (* (get exp n) -1) -16))), exp: -16}
        n
    )
)

(define-private (digit-count (digits int))
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

(define-read-only (pow-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (unwrap-panic (pow-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2)))))
)

(define-read-only (pow-fixed-up (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed-up (unwrap-panic (pow-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2)))))
)

(define-read-only (log-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (log-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (ln-fixed (n uint))
    (unwrap-panic (from-scientific-to-fixed (unwrap-panic (ln-scientific (from-fixed-to-scientific n)))))
)

(define-read-only (exp-fixed (n uint))
    (unwrap-panic (from-scientific-to-fixed (unwrap-panic (exp-scientific (from-fixed-to-scientific n)))))
)

(define-read-only (add-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (add-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (sub-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (sub-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (mul-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (mul-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (mul-fixed-up (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed-up (mul-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (div-fixed (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed (div-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)

(define-read-only (div-fixed-up (n1 uint) (n2 uint))
    (unwrap-panic (from-scientific-to-fixed-up (div-scientific (from-fixed-to-scientific n1) (from-fixed-to-scientific n2))))
)


(define-private (count-zero (a uint) (result (tuple (input uint) (continue bool) (zero int))))
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
(define-read-only (from-fixed-to-scientific (n uint))
    (let 
        (
            (transformed-input (fold count-zero DIGIT-LIST {input: n, continue: true, zero: 0}))
            (exp (- (get zero transformed-input) 8))
        )
        {x: (to-int (get input transformed-input)), exp: exp}
    )  
)

;; transform scientific notation to 8-digit fixed-point notation
(define-read-only (from-scientific-to-fixed (n {x: int, exp: int}))
    (let 
        (
            (x (get x n))
            (new-exp (+ 8 (get exp n)))
        )
        (asserts! (> x 0) ERR-NOT-POSITIVE)
        (if (>= new-exp 0)
            (ok (to-uint (* x (pow 10 new-exp))))
            (ok (to-uint (/ x (pow 10 (* -1 new-exp)))))
        )
    )  
)

;; transform scientific notation to 8-digit fixed-point notation
(define-read-only (from-scientific-to-fixed-up (n {x: int, exp: int}))
    (let 
        (
            (x (get x n))
            (new-exp (+ 8 (get exp n)))
        )
        (asserts! (> x 0) ERR-NOT-POSITIVE)
        (if (>= new-exp 0)
            (ok (to-uint (* x (pow 10 new-exp))))
            (ok (to-uint (+ 1 (/ (- x 1) (pow 10 (* -1 new-exp))))))
        )
    )  
)