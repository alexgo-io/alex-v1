(use-trait oracle-trait .trait-oracle-v1.oracle-trait)


(define-trait equation-trait
  (

    ;; get-y-given-x(dx uint):uint
    (get-y-given-x (uint) (response uint uint))

    ;; get-x-given-y(dy uint):uint
    (get-x-given-y (uint) (response uint uint))

    ;; get-x-given-price(price uint):uint
    (get-x-given-price (uint) (response uint uint))

    ;; get-token-given-position(x uint, y uint):uint
    (get-token-given-position (uint uint) (response uint uint))

    ;; get-position-given-mint(token uint):list(uint, uint)
    (get-position-given-mint (uint) (response (list 2 uint) uint))

    ;; get-position-given-burn(token uint):list(uint, uint)
    (get-position-given-burn (uint) (response (list 2 uint) uint))

  )
)
