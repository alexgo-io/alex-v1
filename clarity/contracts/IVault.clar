
;; ;; IVault
;; ;; <add a description here>

;; ;; <TODO> including traits 

;; ;;(use-trait IAuthorizer .IAuthorizer.IAuthorizer-trait)
;; ;;(use-trait IAsset .IAsset.IAsset-trait)
;; ;;(use-trait IFlashLoanRecipient .IFlashLoanRecipient.IFlashLoanRecipient-trait)
;; ;;(use-trait IProtocolFeesCollector .IFlashLoanRecipient.IFlashLoanRecipient-trait)


;; ;; constants
;; (define-constant ERR_INVALID_IAUTHORIZER u20002)
;; ;;

;; ;; data maps and vars
;; (define-map pool-balance-op
;;   { kind: <pool-balance-op-kind> }
;;   { pool-id : (buff 32) }
;;   ;; { pool-id : <IERC20> }
;;   { amount : uint }
;; )

;; (define-map user-balance-op-kind
;;   { user: principal }
;;   { vault-id: uint }
;; )

;; (define-map pool-specialization
;;   { user: principal }
;;   { vault-id: uint }
;; )

;; (define-map pool-balance-change-kind
;;   { user: principal }
;;   { vault-id: uint }
;; )

;; (define-map swap-kind
;;   { user: principal }
;;   { vault-id: uint }
;; )

;; (define-map user-balance-op
;;   ;; { kind: <user-balance-op-kind> }
;;   ;; { asset: <IAsset> }
;;   { amount: uint }
;;   { sender: address }
;;   { recipient: address }
;; )

;; ;; TODO : MAX_LEN to be defined in constant space

;; (define-map join-pool-request
;;   ;; { assets : (list MAX_LEN <IAsset>) }
;;   ;; { min-amounts-in : (list MAX_LEN uint) }
;;   { user-data : (buff 1 ) }
;;   { from-internal-balance : bool }
;; )

;; (define-map exit-pool-request
;;   ;; { assets : (list MAX_LEN <IAsset>) }
;;   ;; { min-amounts-out : (list MAX_LEN uint) }
;;   { user-data : (buff 1 ) }
;;   { to-internal-balance : bool }
;; )

;; (define-map single-swap
;;   { pool-id: (buff 32) }
;;   ;; { kind : <swap-kind> }
;;   ;; { asset-in : <IAsset> }
;;   ;; { asset-out : <IAsset> }
;;   { amount : uint }
;;   { user-data : (buff 1)}
;; )

;; (define-map batch-swap-step
;;   { pool-id: (buff 32) }
;;   { asset-in-index: uint }
;;   { asset-out-index: uint }
;;   { amount: uint }
;;   { user-data: (buff 1) }
;; )

;; (define-map fund-management
;;   { sender: address }
;;   { from-internal-balance: bool }
;;   { recipient: address }
;;   { to-internal-balance: bool }
;; )


;; ;;

;; ;; private functions
;; (define-read-only (get-internal-balance)
;;     (var-get IAuthorizer)
;; )
;; ;;

;; ;; public functions
;; (define-public (set-IAuthorizer)
;;     (var-get IAuthorizer)
;; )
;; ;;
