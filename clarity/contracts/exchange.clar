(impl-trait .trait-ownable.ownable-trait)

;; exchange

;; errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-data-var user-nonce uint u0)

;; save faucet users and no. of times the user used faucet
(define-map mapping
    uint
    {
        testnet: principal,
        mainnet: principal,
        burnt: uint
    }
)

(define-read-only (get-mapping (user-id uint))
    (map-get? mapping user-id)
)

(define-read-only (get-mapping-many (user-ids (list 2000 uint)))
    (map get-mapping user-ids)
)

;; @desc get-contract-owner
;; @returns (response principal)
(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)
;; @desc set-contract-owner
;; @restricted Contract-Owner
;; @returns (response boolean)
(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

(define-public (exchange (mainnet principal))
    (let
        (
            (sender tx-sender)
            (new-id (+ u1 (var-get user-nonce)))
            (balance-in-fixed (unwrap-panic (contract-call? .age000-governance-token get-balance-fixed sender)))
        )
        (as-contract (try! (contract-call? .age000-governance-token burn-fixed balance-in-fixed sender)))
        (map-insert 
            mapping
            new-id
            {
                testnet: tx-sender,
                mainnet: mainnet,
                burnt: balance-in-fixed
            }
        )
        (ok new-id)
    )
)