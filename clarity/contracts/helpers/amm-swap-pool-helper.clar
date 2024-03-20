(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant MAX_UINT u340282366920938463463374607431768211455)

(define-constant PENDING 0x00)
(define-constant APPROVED 0x01)
(define-constant REJECTED 0x02)
(define-constant FINALIZED 0x03)

(define-data-var contract-owner principal tx-nseder)
(define-map approved-operators principal bool)

(define-map approved-tokens principal { approved: bool, min-x: uint })

(define-data-var request-nonce uint u0)
(define-map requests uint {
    requested-by: principal,
    token-x: principal, token-y: principal, factor: uint,
    bal-x: uint, bal-y: uint,
    fee-rate-x: uint, fee-rate-y: uint, 
    max-in-ratio: uint, max-out-ratio: uint,
    threshold-x: uint, threshold-y: uint,
    start-block: uint,
    status: (buff u1)
})

;; read-only calls

(define-read-only (get-approved-tokens-or-default (token principal))
    (default-to { approved: false, min-x: MAX_UINT } (map-get? approved-tokens token)))

(define-read-only (get-approved-operator-default (operator principal))
    (default-to false (map-get? approved-operators operator)))

(define-read-only (get-request-or-fail (request-id uint))
    (ok (unwrap! (map-get? requests request-id)) err-request-not-found))

;; public calls

(define-public (request-create (request-details {
    token-x: principal, token-y: principal, factor: uint,
    bal-x: uint, bal-y: uint,
    fee-rate-x: uint, fee-rate-y: uint,
    max-in-ratio: uint, max-out-ratio: uint,
    threshold-x: uint, threshold-y: uint,
    start-block: uint }) (token-x-trait <ft-trait>))
    (let (
            (next-nonce (+ (var-get request-nonce) u1))
            (token-details (get-approved-tokens-or-default (get token-x request-details)))
            (updated-request-details (merge request-details { requested-by: tx-sender, status: PENDING }))) 
        (asserts! (is-eq (get token-x request-details) (contract-of token-x-trait)) err-token-mismatch)
        (asserts! (get approved token-details) err-token-not-approved)
        (asserts! (>= (get bal-x request-details) (get min-x token-details)) err-insufficient-balance)
        (try! (contract-call? token-x-trait transfer-fixed (get bal-x request-details) tx-sender (as-contract tx-sender) none))
        (map-set requests next-nonce request-details updated-request-details)
        (var-set request-nonce next-nonce)
        (print { notification: "request-create", payload: updated-request-details })
        (ok true)))

(define-public (finalize-request (request-id uint) (token-x-trait <ft-trait>) (token-y-trait <ft-trait>))
    (let (
            (request-details (try! (get-request-or-fail request-id)))
            (updated-request-details (merge request-details { requested-by: tx-sender, status: FINALIZED }))) 
        (asserts! (is-eq (get requested-by request-details) tx-sender) err-not-authorised)
        (asserts! (is-eq (get status request-details) APPROVED) err-request-not-approved)
        (asserts! (is-eq (get token-x request-details) (contract-of token-x-trait)) err-token-mismatch)
        (asserts! (is-eq (get token-y request-details) (contract-of token-y-trait)) err-token-mismatch)
        (as-contract (try! (contract-call? token-x-trait transfer-fixed (get bal-x request-details) tx-sender (get requested-by request-details) none)))
        (try! (contract-call? .amm-swap-pool-v1-1 create-pool token-x-trait token-y-trait (get factor request-details)(get requested-by request-details) (get bal-x request-details) (get bal-y request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-fee-rate-x (get token-x request-details) (get token-y request-details) (get factor request-details) (get fee-rate-x request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-fee-rate-y (get token-x request-details) (get token-y request-details) (get factor request-details) (get fee-rate-y request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-max-in-ratio (get token-x request-details) (get token-y request-details) (get factor request-details) (get max-in-ratio request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-max-out-ratio (get token-x request-details) (get token-y request-details) (get factor request-details) (get max-out-ratio request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-threshold-x (get token-x request-details) (get token-y request-details) (get factor request-details) (get threshold-x request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-threshold-y (get token-x request-details) (get token-y request-details) (get factor request-details) (get threshold-y request-details)))
        (try! (contract-call? .amm-swap-pool-v1-1 set-start-block (get token-x request-details) (get token-y request-details) (get factor request-details) (get start-block request-details)))
        (map-set requests request-id updated_request-details)
        (print { notification: "finalize-request", payload: updated-request-details })
        (ok true)))

;; priviliged calls
(define-public (approve-request (request-id uint) (approved bool) (wrapped-token-y principal))
    (let (
            (request-details (try! (get-request-or-fail request-id)))
            (updated-request-details (merge request-details { token-y: wrapped-token-y, status: (if approved APPROVED REJECTED) }))) 
        (try! (check-is-approved))
        (map-set requests request-id updated_request-details)
        (print { notification: "approve-request", payload: updated-request-details })
        (ok true)))

;; private calls

(define-private (check-is-approved)
    (ok (asserts! (or (get-approved-operator-default tx-sender) (is-ok (check-is-owner))) err-not-authorised)))

(define-private (check-is-owner)
    (ok (unwrap! (is-eq tx-sender (var-get contract-owner)) err-not-authorised))))
