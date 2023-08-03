(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-AUTHORIZED (err u1001))

(define-data-var contract-owner principal tx-sender)
(define-map approved-tokens principal bool)

(define-data-var event-nonce uint u0)
(define-map event-details uint { token: principal, amount: uint, start-timestamp: uint, end-timestamp: uint })
(define-map claims { event: uint, claimer: principal } uint)
(define-map claimed { event: uint, claimer: principal } uint)

;; governance functions

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-public (set-approved-token (token principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-tokens token approved))
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
    (map-set event-details event-id { token: (contract-of token-trait), amount: amount, start-timestamp: start-timestamp, end-timestamp: end-timestamp })
    (var-set event-nonce event-id)
    (ok event-id)
  )
)

(define-public (update-event (event-id uint) (token-trait <ft-trait>) (amount uint) (start-timestamp uint) (end-timestamp uint))
  (let 
    (
      (event-detail (get-event-detail-or-fail event-id))
    )    
    (try! (check-is-owner))
    (asserts! (is-eq (contract-of token-trait) (get token event-detail)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (>= amount (get amount event-detail)) ERR-INVALID-AMOUNT)
    (asserts! (< start-timestamp end-timestamp) ERR-INVALID-TIMESTAMP)
    (and (> amount (get amount event-detail)) (try! (contract-call? token-trait transfer-fixed (- amount (get amount event-detail)) tx-sender (as-contract tx-sender) none)))
    (ok (map-set event-details event-id ))

  )
)

(define-read-only (get-event-detail-or-fail (event-id uint))
  (ok (unwrap! (map-get? event-details event-id) ERR-UNKNOWN-EVENT-ID))
)

(define-public (set-claim-many (claim-many (list 1000 { event: uint, claimer: principal, amount: uint })))
  (begin 
    (try! (check-is-owner))
    (fold set-claim-iter claim-many (ok true))
  )
)

(define-public (send-token (token-trait <ft-trait>) (amount uint))
  (begin 
    (try! (check-is-owner))
    (as-contract (contract-call? token-trait transfer-fixed amount tx-sender (var-get contract-owner) none))
  )
)

;; read-only functions

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (check-is-approved-token (token principal))
  (ok (asserts! (default-to false (map-get? approved-tokens token)) ERR-TOKEN-NOT-AUTHORIZED))
)

(define-read-only (get-claim-or-default (event uint) (claimer principal) (token principal))
  (default-to u0 (map-get? claims { event: event, claimer: claimer, token: token }))
)

(define-read-only (get-claimed-or-default (event uint) (claimer principal) (token principal))
  (default-to u0 (map-get? claimed { event: event, claimer: claimer, token: token }))
)

;; external functions

(define-public (claim-for-claimer (event uint) (claimer principal) (token-trait <ft-trait>))
  (let 
    (
      (token (contract-of token-trait))
      (claim-limit (get-claim-or-default event claimer token))
      (claimed-so-far (get-claimed-or-default event claimer token))
    )
    (try! (check-is-approved-token token))
    (as-contract (try! (contract-call? token-trait transfer-fixed (- claim-limit claimed-so-far) tx-sender claimer none)))
    (ok (map-set claimed { event: event, claimer: claimer, token: token } claim-limit))
  )
)

;; internal functions

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (set-claim-iter (claim { event: uint, claimer: principal, amount: uint }) (previous-response (response uint uint)))
  (match previous-response
    prev-ok
    (let 
      (
        (amount-so-far (+ prev-ok (get amount claim)))
      )
      (try! (check-is-approved-token (get token claim)))
      (ok (map-set claims { event: (get event claim), claimer: (get claimer claim), token: (get token claim) } (get amount claim)))
    )
    prev-err
    previous-response
  )
)
