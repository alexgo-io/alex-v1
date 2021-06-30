
;; ;; IAuthorizer-trait
;; ;; <add a description here>

;; ;; constants
;; (define-type-alias actionId uint)
;; (define-type-alias address (string-ascii 32))

;; ;;

;; ;; data maps and vars
;; ;;

;; (define-trait IAuthorizer-trait
;;   (
;;     (get-test-check () (response uint bool))

;;     (can-perform (uint actionId) (address account) (address where) (response (string-ascii 12) bool))

;;   )
;; )