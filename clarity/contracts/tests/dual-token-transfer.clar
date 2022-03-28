(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-transfer.transfer-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant token-decimal (pow u10 u6))
(define-constant ONE_8 (pow u10 u8))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

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

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

(define-public (add-approved-contract (new-approved-contract principal))
  (begin
    (try! (check-is-owner))
    (ok (map-set approved-contracts new-approved-contract true))
  )
)

(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
        (as-contract (contract-call? .token-diko mint (fixed-to-decimals amount) recipient))
    )
)

;; @desc fixed-to-decimals
;; @params amount
;; @returns uint
(define-private (fixed-to-decimals (amount uint))
  (/ (* amount token-decimal) ONE_8)
)

(map-set approved-contracts .dual-farming-pool true)
