(define-non-fungible-token stx404nft uint)
(define-fungible-token stx404)

(define-constant err-not-authorised (err u1000))
(define-constant err-invalid-id (err u1001))
(define-constant err-max-supply (err u1002))

(define-constant max-supply u10000)
(define-constant one-8 u100000000)

(define-data-var contract-owner principal tx-sender)
(define-data-var id-nonce uint u0)
(define-map owned principal (list 10000 uint))
(define-data-var available-ids (list 10000 uint) (list ))

;; read-only calls
(define-read-only (get-contract-owner)
    (var-get contract-owner))

(define-read-only (get-last-token-id)
    (ok (var-get id-nonce)))

(define-read-only (get-token-uri (id uint))
    (ok (some "")))

(define-read-only (get-owner (id uint))
    (ok (nft-get-owner? stx404nft id)))

(define-read-only (get-owned-or-default (owner principal))
    (default-to (list ) (map-get? owned owner)))

(define-read-only (is-id-owned-by-or-default (id uint) (owner principal))
    (match (nft-get-owner? stx404nft id)
        some-value (is-eq some-value owner)
        false))

(define-read-only (get-decimals)
    (ok u8))

(define-read-only (get-balance (owner principal))
    (ok (ft-get-balance stx404 owner)))

(define-read-only (get-total-supply)
    (ok (ft-get-supply stx404)))

;; governance calls

(define-public (mint (recipient principal))
    (let (
        (id (var-get id-nonce)))
        (try! (check-is-owner))
        (asserts! (< id max-supply) err-max-supply)
        (try! (ft-mint? stx404 one-8 recipient))
        (try! (nft-mint? stx404nft id recipient))
        (map-set owned recipient (unwrap-panic (as-max-len? (append (get-owned-or-default recipient) id) u10000)))
        (ok (var-set id-nonce (+ id u1)))))

;; public calls

(define-public (transfer (amount-or-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq sender tx-sender) err-not-authorised)
        (if (<= amount-or-id max-supply) ;; id transfer
            (let (
                (check-id (asserts! (is-id-owned-by-or-default amount-or-id sender) err-invalid-id))
                (owned-by-sender (get-owned-or-default sender))
                (owned-by-recipient (get-owned-or-default recipient))
                (id-idx (unwrap-panic (index-of? owned-by-sender amount-or-id))))
                (map-set owned sender (pop owned-by-sender id-idx))
                (map-set owned recipient (unwrap-panic (as-max-len? (append owned-by-recipient amount-or-id) u10000)))
                (try! (ft-transfer? stx404 one-8 sender recipient))
                (try! (nft-transfer? stx404nft amount-or-id sender recipient))
                (ok true))
            (let (
                (balance-sender (unwrap-panic (get-balance sender)))
                (balance-recipient (unwrap-panic (get-balance recipient)))
                (check-balance (try! (ft-transfer? stx404 amount-or-id sender recipient)))
                (no-to-treasury (- (/ balance-sender one-8) (/ (- balance-sender amount-or-id) one-8)))
                (no-to-recipient (- (/ (+ balance-recipient amount-or-id) one-8) (/ balance-recipient one-8)))
                (owned-by-sender (get-owned-or-default sender))
                (owned-by-recipient (get-owned-or-default recipient))
                (ids-to-treasury (if (is-eq no-to-treasury u0) (list ) (unwrap-panic (slice? owned-by-sender (- (len owned-by-sender) no-to-treasury) (len owned-by-sender)))))
                (new-available-ids (if (is-eq no-to-treasury u0) (var-get available-ids) (unwrap-panic (as-max-len? (concat (var-get available-ids) ids-to-treasury) u10000))))
                (ids-to-recipient (if (is-eq no-to-recipient u0) (list ) (unwrap-panic (slice? new-available-ids (- (len new-available-ids) no-to-recipient) (len new-available-ids))))))
                (var-set sender-temp sender)
                (var-set recipient-temp (as-contract tx-sender))
                (and (> no-to-treasury u0) (try! (fold check-err (map nft-transfer-iter ids-to-treasury) (ok true))))
                (var-set sender-temp (as-contract tx-sender))
                (var-set recipient-temp recipient)
                (and (> no-to-recipient u0) (try! (fold check-err (map nft-transfer-iter ids-to-recipient) (ok true))))
                (map-set owned sender (if (is-eq no-to-treasury u0) owned-by-sender (unwrap-panic (slice? owned-by-sender u0 (- (len owned-by-sender) no-to-treasury)))))
                (map-set owned recipient (if (is-eq no-to-recipient u0) owned-by-recipient (unwrap-panic (as-max-len? (concat owned-by-recipient ids-to-recipient) u10000))))
                (var-set available-ids (if (is-eq no-to-recipient u0) new-available-ids (unwrap-panic (slice? new-available-ids u0 (- (len new-available-ids) no-to-recipient)))))
                (ok true)))))

;; private calls

(define-data-var sender-temp principal tx-sender)
(define-data-var recipient-temp principal tx-sender)

(define-private (nft-transfer-iter (id uint))
    (nft-transfer? stx404nft id (var-get sender-temp) (var-get recipient-temp)))

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior ok-value result err-value (err err-value)))

(define-private (check-is-owner)
    (ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorised)))

(define-private (pop (target (list 10000 uint)) (idx uint))
    (match (slice? target (+ idx u1) (len target))
        some-value (unwrap-panic (as-max-len? (concat (unwrap-panic (slice? target u0 idx)) some-value) u1000))
        (unwrap-panic (slice? target u0 idx))))



