(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-TIMESTAMP (err u1001))
(define-constant ERR-UNKNOWN-EVENT-ID (err u1002))
(define-constant ERR-GET-BLOCK-INFO (err u1003))
(define-constant ERR-TOKEN-MISMATCH (err u1004))

(define-constant ONE_8 u100000000)

(define-constant apower .token-apower)

(define-data-var contract-owner principal tx-sender)

(define-data-var event-nonce uint u0)
(define-map events uint { bridged-token: principal, apower-per-bridged: uint, start-timestamp: uint, end-timestamp: uint })

;; governance functions

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-public (create-event (bridged-token principal) (apower-per-bridged uint) (start-timestamp uint) (end-timestamp uint))
  (let 
    (
      (event-id (+ (var-get event-nonce) u1))
    )
    (try! (check-is-owner))
    (asserts! (< start-timestamp end-timestamp) ERR-INVALID-TIMESTAMP)
    (map-set events event-id { bridged-token: bridged-token, apower-per-bridged: apower-per-bridged, start-timestamp: start-timestamp, end-timestamp: end-timestamp })
    (var-set event-nonce event-id)
    (ok event-id)
  )
)

;; read-only functions

(define-read-only (block-timestamp)
  (ok (unwrap! (get-block-info? time (- block-height u1)) ERR-GET-BLOCK-INFO))
)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-read-only (get-event-details-or-fail (event-id uint))
  (ok (unwrap! (map-get? events event-id) ERR-UNKNOWN-EVENT-ID))
)

;; external functions

(define-public (transfer-to-wrap
  (event-id uint)
  (order
      {
        to: uint,
        token: uint,
        amount-in-fixed: uint,
        chain-id: uint,
        salt: (buff 256)
      }
    )
    (token-trait <ft-trait>)
    (signature-packs (list 100 { signer: principal, order-hash: (buff 32), signature: (buff 65)})))
    (let 
      (
        (event-details (try! (get-event-details-or-fail event-id)))
        (current-timestamp (try! (block-timestamp)))
        (apower-to-mint (mul-down (get amount-in-fixed order) (get apower-per-bridged event-details))))
      (asserts! (is-eq (contract-of token-trait) (get bridged-token event-details)) ERR-TOKEN-MISMATCH)
      ;; if timestamp invalid, instead of reverting, it skips and process wrap.
      (and 
        (>= current-timestamp (get start-timestamp event-details)) 
        (<= current-timestamp (get end-timestamp event-details)) 
        (as-contract (try! (contract-call? apower mint-fixed apower-to-mint (try! (contract-call? .bridge-endpoint-v1-02 user-from-id-or-fail (get to order)))))))
      (contract-call? .bridge-endpoint-v1-02 transfer-to-wrap order token-trait signature-packs)
    )
)

;; internal functions

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)