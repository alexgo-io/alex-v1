(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait transfer-trait .trait-transfer.transfer-trait)

;; dual-farm-pool v1.01
;; CHANGELOG
;; - the emission of dual token is independent of base token

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-NOT-FOUND (err u1003))

(define-data-var contract-owner principal tx-sender)

(define-map pair-details 
  { 
    base-token: principal,
    dual-token-payer: principal
  }
  {
    dual-token: principal,
    emission-per-block: uint
  }
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-read-only (get-pair-details (base-token principal) (dual-token-payer principal))
  (map-get? pair-details { base-token: base-token, dual-token-payer: dual-token-payer })
)

(define-read-only (get-pair-details-or-fail (base-token principal) (dual-token-payer principal))
  (ok (unwrap! (get-pair-details base-token dual-token-payer) ERR-NOT-FOUND))
)

(define-read-only (get-emission-per-block-or-default (base-token principal) (dual-token-payer principal))
  (match (get-pair-details base-token dual-token-payer) details (get emission-per-block details) u0)
)

(define-public (set-emission-per-block (base-token principal) (dual-token-payer principal) (new-emission-per-block uint))
  (begin
    (try! (check-is-owner))
    (ok (map-set pair-details { base-token: base-token, dual-token-payer: dual-token-payer } 
      (merge (try! (get-pair-details-or-fail base-token dual-token-payer)) { emission-per-block: new-emission-per-block }))
    )    
  )
)

;; @desc add-token 
;; @params token
;; @returns (response bool)
(define-public (add-token (base-token principal) (dual-token-payer principal) (dual-token principal) (emission-per-block uint))
  (begin
    (try! (check-is-owner))
    (map-set pair-details { base-token: base-token, dual-token-payer: dual-token-payer } { dual-token: dual-token, emission-per-block: emission-per-block })
    (contract-call? .alex-reserve-pool add-token base-token)
  )
)

;; STAKING REWARD CLAIMS

;; calls function to claim staking reward in active logic contract
;; @desc claim-staking-reward
;; @params token-trait; ft-trait
;; @params target-cycle
;; @returns (response tuple)
(define-private (claim-staking-reward-by-tx-sender (base-token-trait <ft-trait>) (dual-token-payer-trait <transfer-trait>) (target-cycle uint))
  (let
    (
      (base-token (contract-of base-token-trait))
      (dual-token-payer (contract-of dual-token-payer-trait))
      (details (try! (get-pair-details-or-fail base-token dual-token-payer)))      
      (claimed (try! (contract-call? .alex-reserve-pool claim-staking-reward base-token-trait target-cycle)))
      (entitled-dual (get emission-per-block details))
      (sender tx-sender)
    )
    (and 
      (> entitled-dual u0)
      (as-contract (try! (contract-call? dual-token-payer-trait transfer-fixed entitled-dual tx-sender sender)))
    )
    (ok { to-return: (get to-return claimed), entitled-token: (get entitled-token claimed), entitled-dual: entitled-dual })
  )
)

(define-public (claim-staking-reward (token <ft-trait>) (dual-token <transfer-trait>) (reward-cycles (list 200 uint)))
  (ok 
    (map 
      claim-staking-reward-by-tx-sender 
      (list 
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
        token token token token token token token token token token token token token token token token token token token token
      ) 
      (list 
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token
        dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token dual-token        
      )       
      reward-cycles      
    )
  )
)

(define-constant ONE_8 u100000000)

;; @desc mul-down
;; @params a
;; @params b
;; @returns uint
(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; contract initialisation
;; (set-contract-owner .executor-dao)
