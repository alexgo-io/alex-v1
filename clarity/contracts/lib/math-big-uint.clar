
;; The maximum digits clarity can give in uint is 39 digits, otherwise it overflows
(define-read-only (maximum-integer (a uint) (b uint))
    (* a b)
)

(define-read-only (multiplication-with-scientific-notation (a int) (a-exp int) (b int) (b-exp int))
    (contract-call? .math-log-exp-biguint multiplication-with-scientific-notation a a-exp b b-exp)
)

(define-read-only (division-with-scientific-notation (a int) (a-exp int) (b int) (b-exp int))
    (contract-call? .math-log-exp-biguint division-with-scientific-notation a a-exp b b-exp)
)

(define-read-only (ln-with-scientific-notation (a int) (exp int))
    (contract-call? .math-log-exp-biguint ln-fixed a exp)
)