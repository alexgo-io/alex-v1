
;; trait-equation
;; <add a description here>

;; constants
;;

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
(define-trait trait-equation
    (
        ;; (get-y-given-x (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dx uint) (response uint uint))
        (get-y-given-x (uint uint uint uint uint) (response uint uint))

        ;;(get-x-given-y (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (dy uint) (response uint uint))
        (get-x-given-y (uint uint uint uint uint) (response uint uint))
        
        ;;(get-x-given-price (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (price uint) (response uint uint))
        (get-x-given-price (uint uint uint uint uint) (response uint uint))

        ;;(get-token-given-position (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (x uint) (y uint) (response {token, y} uint))
        (get-token-given-position (uint uint uint uint uint uint uint) (response {token: uint, y: uint} uint))

        ;;(get-position-given-mint (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint) (response {x, y} uint))
        (get-position-given-mint (uint uint uint uint uint uint) (response {x: uint, y: uint} uint))

        ;;(get-position-given-burn (balance-x uint) (balance-y uint) (weight-x uint) (weight-y uint) (total-supply uint) (token uint) (response {x, y} uint))
        (get-position-given-burn (uint uint uint uint uint uint) (response {x: uint, y: uint} uint))
    )
)