
;; ;; IAuthorizer
;; ;; <add a description here>

;; ;; constants
;; (define-constant ERR-CANNOT-PERFORM u20001)

;; (define-type-alias actionId uint)
;; (define-type-alias address (string-ascii 32))

;; ;;

;; ;; data maps and vars
;; ;;

;; ;; private functions
;; ;;

;; ;; public functions
;; ;;

;; ;; canPerform(actionId : bytes32, account: address, where: address) : bool
;; (define-read-only (can-perform (uint actionId) (address account) (address where))
    
;;     ;; Check whether tx-sender corresponds to account
;;     (asserts! (is-eq tx-sender account) (err u1))

;;     ;; CAN PERFORM LOGIC IMPLEMENTED HERE
;;     (if actionId
;;         (begin
;;           ;;CAN PERFORM LOGIC ERR IMPLEMENTED HERE
;;         )
;;         (err ERR-CANNOT-PERFORM)
;;     )
;;   (ok true)
;; )
