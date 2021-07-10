

(define-trait oracle-trait
  (

    ;; get-price(source:string-ascii, symbol:string-ascii):uint
    (get-price ((string-ascii 32) (string-ascii 32)) (response uint uint))

 )
)