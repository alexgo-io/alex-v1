
;; IVault-trait
;; <add a description here>
;;(use-trait IAuthorizer .IAuthorizer.IAuthorizer-trait)
;;(use-trait IAsset .IAsset.IAsset-trait)
;;(use-trait IFlashLoanRecipient .IFlashLoanRecipient.IFlashLoanRecipient-trait)
;;(use-trait IProtocolFeesCollector .IFlashLoanRecipient.IFlashLoanRecipient-trait)

;; constants
;;

;; data maps and vars
;;
(define-constant MAX_SIZE 100)

(define-trait ivault-trait
  (

    (get-authorizer () (response <IAuthorizer>)) ;; to be checked

    (set-authorizer (<IAuthorizer> uint) (response uint uint))

    (has-approved-relayer ((user address) (relayer address)) (response bool))

    (set-relayer-approval ((user address) (relayer address) (approved bool))

    (get-internal-balance ((user address) (tokens <SIP-010>)) (tokens (list MAX_SIZE uint)))

    (manager-user-balance (user-balance-op <ops>))

    (register-pool (specialization <pool-specialization>) (buff 32))

    (get-pool (pool-id (buff 32)) (response address <pool-specialization>))

    (register-tokens ((pool-id address) (tokens <SIP-010>)))

    (deregister-tokens ((pool-id address) (tokens <SIP-010>)))

    (get-pool-token-info ((pool-id address) (tokens <SIP-010>)))

    (get-pool-tokens (pool-id address))

    (join-pool ((pool-id (buff 32)) (sender address) (recipient address) (request <join-pool-request>)))

    (exit-pool ((pool-id (buff 32)) (sender address) (recipient address) (request <exit-pool-request>)))

    (swap ((single-swap <single-swap>) (funds <fund-management>) (limit uint) (deadline (list MAX_SIZE uint))) (list MAX_SIZE uint))

    (flash-loan ((recipient <IFlashLoanRecipient>) (token <SIP-010>) (amounts (list MAX_SIZE uint)) (userdata (buff 1))))

    (get-protocol ())

    (set-paused (paused bool))
    
  )
)

;; private functions
;;

;; public functions
;;
