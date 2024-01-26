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

(define-map buybacks uint { pct: uint, claimed: uint, paused: bool })
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

;; TODO: need update flexibility
(define-public (open-buyback (launch-id uint) (payment-token-trait <ft-trait>) (pct uint) (start-block uint) (end-block uint))
  (let (
      (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
      (total-tickets-won (try! (contract-call? .alex-launchpad-v1-7 get-total-tickets-won launch-id)))
      (amount (mul-down (* total-tickets-won (get price-per-ticket-in-fixed launch-details)) pct)))
    (try! (check-is-owner))
    (asserts! (< start-block end-block) ERR-INVALID-BLOCKS)
    (asserts! (<= pct ONE_8) ERR-INVALID-PCT)
    (asserts! (< (get registration-end-height launch-details) start-block) ERR-INVALID-BLOCKS)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (try! (contract-call? payment-token-trait transfer-fixed amount tx-sender (as-contract tx-sender) none))
    (ok (map-set buybacks launch-id { pct: pct, claimed: u0, paused: false}))))

(define-public (pause-buyback (launch-id uint) (paused bool))
  (begin 
    (try! (check-is-owner))
    (ok (map-set buybacks (merge (try! (get-buybacks-or-fail launch-id)) { pause: paused })))))

(define-public (close-buyback (launch-id uint) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>) (receiver principal))
  (let (
      (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
      (backback-details (try! (get-buybacks-or-fail launch-id)))
      (buyback-price (mul-down (/ (get price-per-ticket-in-fixed launch-details) (get launch-tokens-per-ticket launch-details)) (get pct buyback-details))) ;; buy-back price per ticket
      (buyback-amount (mul-down (get claimed backback-details) buyback-price))
      (buyback-total (mul-down (* total-tickets-won (get price-per-ticket-in-fixed launch-details)) (get pct buyback-details))))
    (try! (check-is-owner))
    (asserts! (or (< block-height start-block) (> block-height end-block)) ERR-INVALID-BLOCKS)
    (asserts! (is-eq (contract-of launch-token-trait) (get launch-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    
    (as-contract (try! (contract-call? launch-token-trait transfer-fixed (get claimed backback-details) tx-sender receiver none)))
    (as-contract (try! (contract-call? payment-token-trait transfer-fixed (- buyback-total buyback-amount) tx-sender receiveer none)))
    (map-set buybacks launch-id {pct: (get pct backback-details), claimed: (add (get claimed backback-details) launch-amount)})
    (ok true))

(define-public (get-buybacks-or-fail (launch-id uint))
  (let ((backback-details (try! (get buybacks launch-id))))
    (asserts! (is-some backback-details) ERR-UNKNOWN-EVENT-ID)
    backback-details))

(define-public (get-claimed (launch-id uint) (user principal))
  (let ((claimed-amount (try! (get claimed
      (spent-payment (* (get claimed backback-details) (get )) ;; already spent payment-tokens)
      (total-tickets-won (try! (contract-call? .alex-launchpad-v1-7 get-total-tickets-won launch-id)))
      (amount (- (mul-down (* total-tickets-won (get price-per-ticket-in-fixed launch-details)) (get pct buyback-details)) (* (get cla)))      
      (payment-amount (* (get claimed backback-details) )) 
    (try! (check-is-owner))
    (asserts! (is-eq (contract-of launch-token-trait) (get launch-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (or (< block-height start-block) (> block-heght end-block)) ERR-INVALID-BLOCKS)
    (as-contract (try! (contract-call? launch-token-trait transfer-fixed (* ))))
    (as-contract (try! (contract-call? token-trait transfer-fixed (- (get deposited event-details) (get claimed event-details)) tx-sender receiver none)))
    (ok (map-set events event-id (merge event-details { deposited: (get claimed event-details) })))
  )
)

;; read-only functions

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-buybacks-or-fail (launch-id uint))
  (ok (unwrap! (map-get buybacks launch-id) ERR-UNKNOWN-ID)))

(define-read-only (get-claimed-or-default (launch-id uint) (claimer principal))
  (default-to u0 (map-get claimed {launch-id: launch-id, claimer: claimer})))


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
