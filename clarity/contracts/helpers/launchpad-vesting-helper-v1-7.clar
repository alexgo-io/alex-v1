(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-SCHEDULE-NOT-FOUND (err u1001))
(define-constant ERR-PAUSED (err u1002))
(define-constant ERR-TOKEN-MISMATCH (err u1004))
(define-constant ERR-VESTING-NOT-STARTED (err u1005))
(define-constant ERR-INVALID-VESTING-DETAILS (err u1006))

(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)

(define-map vestings uint { multiplier: uint, start: uint, end: uint })
(define-map checkpoints { launch-id: uint, user: principal } uint)

(define-data-var paused bool true)

;; read-only calls

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-read-only (get-vesting-or-fail (launch-id uint))
    (ok (unwrap! (map-get? vestings launch-id) ERR-SCHEDULE-NOT-FOUND)))

(define-read-only (get-checkpoint-or-fail (launch-id uint) (user principal))
    (let (
            (vesting-details (try! (get-vesting-or-fail launch-id))))
        (match (map-get? checkpoints { launch-id: launch-id, user: user })
            some-value (ok some-value)
            (ok (get start vesting-details)))))

(define-read-only (is-paused)
  (var-get paused))

;; governance calls

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

(define-public (transfer (token-trait <ft-trait>) (amount uint) (recipient principal))
    (begin
        (try! (check-is-owner))
        (as-contract (contract-call? token-trait transfer-fixed amount tx-sender recipient none))))

(define-public (set-vesting (launch-id uint) (details { multiplier: uint, start: uint, end: uint }) (token-trait <ft-trait>))
    (let (
            (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
            (total-tickets-won (contract-call? .alex-launchpad-v1-7 get-total-tickets-won launch-id))
            (total-amount (* total-tickets-won (get launch-tokens-per-ticket launch-details) (get multiplier details))))
        (try! (check-is-owner))
        (asserts! (is-eq (contract-of token-trait) (get launch-token launch-details)) ERR-TOKEN-MISMATCH)
        (asserts! (> (get end details) (get start details)) ERR-INVALID-VESTING-DETAILS)
        (map-set vestings launch-id details)
        (print { notification: "set-vesting", payload: { launch-id: launch-id, details: details } })
        (contract-call? token-trait transfer-fixed total-amount tx-sender (as-contract tx-sender) none)))

(define-public (pause (new-paused bool))
  (begin
    (try! (check-is-owner))
    (ok (var-set paused new-paused))))

;; public calls

(define-public (claim (launch-id uint) (user principal) (token-trait <ft-trait>))
    (let (
            (vesting-details (try! (get-vesting-or-fail launch-id)))
            (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
            (tickets-won (contract-call? .alex-launchpad-v1-7 get-tickets-won launch-id user))
            (total-amount (mul-down tickets-won (mul-down (get launch-tokens-per-ticket launch-details) (get multiplier vesting-details))))
            (checkpoint (* (try! (get-checkpoint-or-fail launch-id user)) ONE_8))
            (new-checkpoint (* (min (get end vesting-details) block-height) ONE_8))
            (vesting-period (* (- (get end vesting-details) (get start vesting-details)) ONE_8))
            (vested-amount (div-down (mul-down total-amount (- new-checkpoint checkpoint)) vesting-period)))
        (asserts! (not (is-paused)) ERR-PAUSED)
        (asserts! (> block-height (get start vesting-details)) ERR-VESTING-NOT-STARTED)
        (asserts! (is-eq (contract-of token-trait) (get launch-token launch-details)) ERR-TOKEN-MISMATCH)

        (map-set checkpoints { launch-id: launch-id, user: user } new-checkpoint)
        (and (> vested-amount u0) (try! (as-contract (contract-call? token-trait transfer-fixed vested-amount tx-sender user none))))

        (print { notification: "claim", payload: { launch-id: launch-id, user: user, amount: vested-amount } })
        (ok true)))

;; private calls

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8))

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0) u0 (/ (* a ONE_8) b)))

(define-private (min (a uint) (b uint))
    (if (<= a b) a b))
