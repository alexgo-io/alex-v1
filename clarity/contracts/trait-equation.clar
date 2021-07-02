
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
        ;; (get-y-given-x (balance-x uint) (balance-y uint) (dx uint) (response uint uint))
        (get-y-given-x (uint) (response uint uint))

        ;;(get-x-given-y (balance-x uint) (balance-y uint) (dy uint) (response uint uint))
        (get-x-given-y (uint) (response uint uint))
        
        ;;(get-x-given-price (balance-x uint) (balance-y uint) (price uint) (response uint uint))
        (get-x-given-price (uint) (response uint uint))

        ;;(get-token-given-position (balance-x uint) (balance-y uint) (total-supply uint) (x uint) (y uint) (response uint uint))
        (get-token-given-position (uint uint) (response uint uint))

        ;;(get-position-given-mint (token uint) (response (list 2 uint) uint))
        (get-position-given-mint (uint) (response (list 2 uint) uint))

        ;;(get-position-given-burn (token uint) (response (list 2 uint) uint))
        (get-position-given-burn (uint) (response (list 2 uint) uint))
    )
)