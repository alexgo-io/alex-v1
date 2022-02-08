
;; The maximum digits clarity can give in uint is 39 digits, otherwise it overflows
(define-read-only (maximum-unsigned-integer (a uint) (b uint))
    (* a b)
)

;; The maximum digits clarity can give in int is 39 digits, otherwise it overflows
(define-read-only (maximum-integer (a int) (b int))
    (* a b)
)