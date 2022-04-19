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
        ;; .token-diko to be replaced by 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.arkadiko-alex-dual-yield-v1-1 in prod.
        ;; see https://github.com/arkadiko-dao/arkadiko/blob/f8b0fc3707af60956431a632ccbb64bd29c0f7e3/clarity/contracts/arkadiko-alex-dual-yield-v1-1.clar
        ;; multiplier to ALEX reward to be set at pool activation so total DIKO rewarded per cycle == 12.5k for the first 100 cycles
        ;; see https://github.com/alexgo-io/alex-v1/blob/38b93cbdfa1d0ef11214406904879f59f003aa21/clarity/contracts/pool/dual-farming-pool.clar#L81
        (as-contract (contract-call? .token-wdiko transfer-fixed amount tx-sender recipient none))
    )
)

;; @desc fixed-to-decimals
;; @params amount
;; @returns uint
(define-private (fixed-to-decimals (amount uint))
  (/ (* amount token-decimal) ONE_8)
)

(map-set approved-contracts .dual-farming-pool true)

