;; trait-pool
;; <add a description here>

;; constants
;;

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
(define-trait pool-trait
    (
        (get-pool-contracts (uint) (response {token-x: principal, token-y: principal, weight-x: uint, weight-y: uint} uint))
        (get-pool-count () (response uint uint))
        (get-pools () (response (list 2000 {token-x: principal, token-y: principal, weight-x: uint, weight-y: uint}) uint))
    )
)
