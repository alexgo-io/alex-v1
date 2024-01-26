;;
;; launchpad-buyback
;;

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

(define-map buybacks uint uint)
(define-map claimed { launch-id: uint, claimer: principal } uint)

;; governance functions

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

	;; launch-token: principal,
	;; payment-token: principal,
	;; launch-owner: principal,
	;; launch-tokens-per-ticket: uint,
	;; price-per-ticket-in-fixed: uint,
	;; activation-threshold: uint,
	;; registration-start-height: uint,
	;; registration-end-height: uint,
	;; claim-end-height: uint,
	;; total-tickets: uint,
	;; apower-per-ticket-in-fixed: (list 6 {apower-per-ticket-in-fixed: uint, tier-threshold: uint}),
	;; registration-max-tickets: uint,
	;; fee-per-ticket-in-fixed: uint,
	;; total-registration-max: uint,
	;; max-size-factor: uint

(define-public (create-buyback (launch-id uint) (payment-token-trait <ft-trait>) (pct uint) (start-block uint) (end-block uint))
  (let (
      (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
      (total-tickets-won (try! (contract-call? .alex-launchpad-v1-7 get-total-tickets-won launch-id))))
    (try! (check-is-owner))
    (asserts! (< start-block end-block) ERR-INVALID-BLOCKS)
    (asserts! (<= pct ONE_8) ERR-INVALID-PCT)
    (asserts! (< (get registration-end-height launch-details) start-block) ERR-INVALID-BLOCKS)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (try! (contract-call? payment-token-trait transfer-fixed (mul-down (* total-tickets-won (get price-per-ticket-in-fixed launch-details)) pct) tx-sender (as-contract tx-sender) none))
    (ok (map-set buybacks launch-id pct))
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

(define-read-only (block-timestamp)
  (if (is-eq chain-id u1)
    (ok (unwrap! (get-block-info? time block-height) ERR-GET-BLOCK-INFO))
    (ok (var-get temp-timestamp))
  )
)

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
