;; -- autoALEX creation/staking/redemption

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-REQUEST-ID-NOT-FOUND (err u10019))

(define-constant PENDING 0x00)
(define-constant FINALIZED 0x01)
(define-constant REVOKED 0x02)

;; data maps and vars
;;

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-data-var start-cycle uint u340282366920938463463374607431768211455)
(define-data-var redeem-request-nonce uint u0)

(define-map staked-cycle uint bool)
(define-map redeem-requests uint { requested-by: principal, shares: uint, redeem-cycle: uint, status: (buff 1) })
(define-map redeem-shares-per-cycle uint uint)
(define-map redeem-tokens-per-cycle uint uint)

;; read-only calls

(define-read-only (get-pending)
  PENDING)

(define-read-only (get-finalized)
  FINALIZED)

(define-read-only (get-revoked)
  REVOKED)

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-read-only (get-start-cycle)
  (var-get start-cycle))

(define-read-only (is-cycle-staked (reward-cycle uint))
  (default-to false (map-get? staked-cycle reward-cycle)))

(define-read-only (get-redeem-shares-per-cycle-or-default (reward-cycle uint))
  (default-to u0 (map-get? redeem-shares-per-cycle reward-cycle)))

(define-read-only (get-redeem-tokens-per-cycle-or-default (reward-cycle uint))
  (default-to u0 (map-get? redeem-tokens-per-cycle reward-cycle)))

(define-read-only (get-redeem-request-or-fail (request-id uint))
  (ok (unwrap! (map-get? redeem-requests request-id) ERR-REQUEST-ID-NOT-FOUND)))

;; governance calls

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

(define-public (set-approved-contract (owner principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts owner approved))))

(define-public (set-start-cycle (new-start-cycle uint))
  (begin 
    (try! (check-is-owner))
    (map-set staked-cycle new-start-cycle true)
    (ok (var-set start-cycle new-start-cycle))))

;; privileged functions
;;   

(define-public (set-staked-cycle (cycle uint) (staked bool))
  (begin 
    (try! (check-is-approved))
    (ok (map-set staked-cycle cycle staked))))

(define-public (set-redeem-request (request-id uint) (request-details { requested-by: principal, shares: uint, redeem-cycle: uint, status: (buff 1) }))
  (let (
      (next-nonce (+ (var-get redeem-request-nonce) u1))
      (id (if (> request-id u0) request-id (begin (var-set redeem-request-nonce next-nonce) next-nonce))))
    (try! (check-is-approved))
    (map-set redeem-requests id request-details)
    (ok id)))

(define-public (set-redeem-shares-per-cycle (reward-cycle uint) (shares uint))
  (begin 
    (try! (check-is-approved))
    (ok (map-set redeem-shares-per-cycle reward-cycle shares))))

(define-public (set-redeem-tokens-per-cycle (reward-cycle uint) (tokens uint))
  (begin 
    (try! (check-is-approved))
    (ok (map-set redeem-tokens-per-cycle reward-cycle tokens))))

;; private functions
;;

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (check-is-approved)
  (ok (asserts! (or (default-to false (map-get? approved-contracts tx-sender)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)))