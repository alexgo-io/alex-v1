(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-TIMESTAMP (err u1001))
(define-constant ERR-UNKNOWN-EVENT-ID (err u1002))
(define-constant ERR-TOKEN-NOT-MATCHED (err u1003))
(define-constant ERR-INVALID-AMOUNT (err u1004))
(define-constant ERR-ALREADY-CLAIMED (err u1005))
(define-constant ERR-INVALID-USER (err u1006))
(define-constant ERR-GET-BLOCK-INFO (err u1007))

(define-data-var contract-owner principal tx-sender)

(define-data-var event-nonce uint u0)
(define-map events uint { token: principal, deposited: uint, allocated: uint, claimed: uint, start-timestamp: uint, end-timestamp: uint })
(define-map claims { event: uint, claimer: principal } uint)
(define-map claimed { event: uint, claimer: principal } bool)

(define-data-var temp-event-id uint u0)

;; governance functions

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-public (create-event (token-trait <ft-trait>) (amount uint) (start-timestamp uint) (end-timestamp uint))
  (let 
    (
      (event-id (+ (var-get event-nonce) u1))
    )
    (try! (check-is-owner))
    (try! (contract-call? token-trait transfer-fixed amount tx-sender (as-contract tx-sender) none))
    (asserts! (< start-timestamp end-timestamp) ERR-INVALID-TIMESTAMP)
    (map-set events event-id { token: (contract-of token-trait), deposited: amount, allocated: u0, claimed: u0, start-timestamp: start-timestamp, end-timestamp: end-timestamp })
    (var-set event-nonce event-id)
    (ok event-id)
  )
)

(define-public (update-event (event-id uint) (token-trait <ft-trait>) (top-up-amount uint) (start-timestamp uint) (end-timestamp uint))
  (let 
    (
      (event-details (try! (get-event-details-or-fail event-id)))
    )    
    (try! (check-is-owner))
    (asserts! (is-eq (contract-of token-trait) (get token event-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (< start-timestamp end-timestamp) ERR-INVALID-TIMESTAMP)
    (and (> top-up-amount u0) (try! (contract-call? token-trait transfer-fixed top-up-amount tx-sender (as-contract tx-sender) none)))
    (ok (map-set events event-id (merge event-details { deposited: (+ (get deposited event-details) top-up-amount), start-timestamp: start-timestamp, end-timestamp: end-timestamp })))
  )
)

(define-public (set-claim-many (event-id uint) (claim-many (list 1000 { claimer: principal, amount: uint })))
  (let 
    (
      (event-details (try! (get-event-details-or-fail event-id)))
    ) 
    (try! (check-is-owner))
    (var-set temp-event-id event-id)
    (ok (map-set events event-id (merge event-details { allocated: (try! (fold set-claim-iter claim-many (ok (get allocated event-details)))) })))
  )
)

(define-read-only (block-timestamp)
  (match (get-block-info? time block-height)
    timestamp
    (ok timestamp)
    ;; (ok u100000001) ;; TODO: testing only
    ERR-GET-BLOCK-INFO
  )
)

(define-public (send-excess-token (event-id uint) (token-trait <ft-trait>) (receiver principal))
  (let 
    (
      (event-details (try! (get-event-details-or-fail event-id)))
      (current-timestamp (try! (block-timestamp)))
    ) 
    (try! (check-is-owner))
    (asserts! (is-eq (contract-of token-trait) (get token event-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (> current-timestamp (get end-timestamp event-details)) ERR-INVALID-TIMESTAMP)
    (as-contract (try! (contract-call? token-trait transfer-fixed (- (get deposited event-details) (get claimed event-details)) tx-sender receiver none)))
    (ok (map-set events event-id (merge event-details { deposited: (get claimed event-details) })))
  )
)

;; read-only functions

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-event-details-or-fail (event-id uint))
  (ok (unwrap! (map-get? events event-id) ERR-UNKNOWN-EVENT-ID))
)

(define-read-only (get-claim-or-default (event-id uint) (claimer principal))
  (default-to u0 (map-get? claims { event: event-id, claimer: claimer }))
)

(define-read-only (get-claimed-or-default (event-id uint) (claimer principal))
  (default-to false (map-get? claimed { event: event-id, claimer: claimer }))
)


;; external functions

(define-public (claim-for-claimer (event-id uint) (claimer principal) (token-trait <ft-trait>))
  (let 
    (
      (event-details (try! (get-event-details-or-fail event-id)))
      (claim-amount (get-claim-or-default event-id claimer))      
      (current-timestamp (try! (block-timestamp)))
    )
    (asserts! (and (>= current-timestamp (get start-timestamp event-details)) (<= current-timestamp (get end-timestamp event-details))) ERR-INVALID-TIMESTAMP)
    (asserts! (is-eq (contract-of token-trait) (get token event-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (not (get-claimed-or-default event-id claimer)) ERR-ALREADY-CLAIMED)
    (and (> claim-amount u0) (as-contract (try! (contract-call? token-trait transfer-fixed claim-amount tx-sender claimer none))))
    (map-set events event-id (merge event-details { claimed: (+ (get claimed event-details) claim-amount) }))
    (ok (map-set claimed { event: event-id, claimer: claimer } true))
  )
)

;; internal functions

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (set-claim-iter (claim { claimer: principal, amount: uint }) (previous-response (response uint uint)))
  (match previous-response
    prev-ok
    (let 
      (
        (amount-so-far (+ prev-ok (get amount claim)))
        (event-details (try! (get-event-details-or-fail (var-get temp-event-id))))
      )
      (asserts! (<= amount-so-far (get deposited event-details)) ERR-INVALID-AMOUNT)
      (asserts! (map-insert claims { event: (var-get temp-event-id), claimer: (get claimer claim) } (get amount claim)) ERR-INVALID-USER)
      (ok amount-so-far)
    )
    prev-err
    previous-response
  )
)
