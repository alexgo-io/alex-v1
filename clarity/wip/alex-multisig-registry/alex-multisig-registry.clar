(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
;;(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; Registry Contract
;; To Define which contract can burn / mint a token
;; To Apply the functionalities in this contract,
;; implementation of calling this contract in burn/mint is required. 

;; Errors
(define-constant authorisation-err (err u1000))

;; Contract addresses
(define-map contracts
  { name: (string-ascii 256) }
  {
    address: principal, 
    qualified-name: principal 
  }
)

(define-map contracts-data
  { qualified-name: principal }
  {
    can-mint: bool,
    can-burn: bool
  }
)


(define-public (set-contract-address (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool))
  (let (
    (current-contract (map-get? contracts { name: name }))
  )
    (begin
    ;; Discussion Required
    ;; Better to save all the multisig contracts to the map in registry contract.
      (asserts! (is-eq contract-caller .alex-ytp-multisig-vote) (err authorisation-err))

      (map-set contracts { name: name } { address: address, qualified-name: qualified-name })
      (if (is-some current-contract)
        (map-set contracts-data { qualified-name: (unwrap-panic (get qualified-name current-contract)) } { can-mint: false, can-burn: false })
        false
      )
      (map-set contracts-data { qualified-name: qualified-name } { can-mint: can-mint, can-burn: can-burn })
      (ok true)
    )
  )
)

(define-read-only (get-contract-address-by-name (name (string-ascii 256)))
  (get address (map-get? contracts { name: name }))
)

;; Check if contract can mint and burn
(define-read-only (get-contract-can-mint-by-qualified-name (qualified-name principal))
  (default-to 
    false
    (get can-mint (map-get? contracts-data { qualified-name: qualified-name }))
  )
)


(define-read-only (get-contract-can-burn-by-qualified-name (qualified-name principal))
  (default-to 
    false
    (get can-burn (map-get? contracts-data { qualified-name: qualified-name }))
  )
)

;; Burning and Mining Tokens
;; Discussion Required -> Need to make another token trait which all token will implement. 
;; (define-public (mint-token (token <yield-token-trait>) (amount uint) (recipient principal))
;;   (begin
;;     (asserts! (is-eq (get-contract-can-mint-by-qualified-name contract-caller) true) authorisation-err)
;;     (contract-call? token mint-from-registry amount recipient)
;;   )
;; )


;; (define-public (burn-token (token <yield-token-trait>) (amount uint) (recipient principal))
;;   (begin
;;     (asserts! (is-eq (get-contract-can-burn-by-qualified-name contract-caller) true) authorisation-err)
;;     (contract-call? token burn-from-registry amount recipient)
;;   )
;; )

;; Registry contract
(begin
  ;; Add initial contracts
  (map-set contracts
    { name: "collateral-rebalancing-pool" }
    {
      address: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE,
      qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.collateral-rebalancing-pool
    }
  )
    (map-set contracts-data
    { qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.collateral-rebalancing-pool }
    {
      can-mint: true,
      can-burn: true
    }
  )

    (map-set contracts
    { name: "yield-usda-token-pool" }
    {
      address: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE,
      qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-token-pool
    }
  )
    (map-set contracts-data
    { qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-token-pool }
    {
      can-mint: true,
      can-burn: true
    }
  )

    (map-set contracts
    { name: "fixed-weight-pool" }
    {
      address: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE,
      qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool
    }
  )
    (map-set contracts-data
    { qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool }
    {
      can-mint: true,
      can-burn: true
    }
  )

    (map-set contracts
    { name: "yield-token-pool" }
    {
      address: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE,
      qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-token-pool
    }
  )
    (map-set contracts-data
    { qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-token-pool }
    {
      can-mint: true,
      can-burn: true
    }
  )

    (map-set contracts
    { name: "liquidity-bootstrapping-pool" }
    {
      address: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE,
      qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.liquidity-bootstrapping-pool
    }
  )
    (map-set contracts-data
    { qualified-name: 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.liquidity-bootstrapping-pool }
    {
      can-mint: true,
      can-burn: true
    }
  )



)