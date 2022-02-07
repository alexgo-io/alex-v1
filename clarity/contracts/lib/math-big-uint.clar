
;; The maximum digits clarity can give in uint is 39 digits, otherwise it overflows
(define-read-only (maximum-integer (a uint) (b uint))
    (* a b)
)