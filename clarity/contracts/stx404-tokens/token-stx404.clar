(define-non-fungible-token stx404nft uint)
(define-fungible-token stx404)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-ID (err u1001))
(define-constant ERR-MAX-SUPPLY (err u1002))

(define-constant MAX-SUPPLY u10000)
(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)
(define-data-var id-nonce uint u0)
(define-map owned principal (list 10000 uint))

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
    
(define-read-only (get-name)
    (ok "stx404"))

(define-read-only (get-symbol)
    (ok "stx404"))

(define-read-only (get-decimals)
    (ok u8))

(define-read-only (get-balance (owner principal))
    (ok (ft-get-balance stx404 owner)))

(define-read-only (get-balance-fixed (account principal))
    (ok (decimals-to-fixed (unwrap-panic (get-balance account)))))

(define-read-only (get-total-supply)
    (ok (ft-get-supply stx404)))

(define-read-only (get-total-supply-fixed)
    (ok (decimals-to-fixed (unwrap-panic (get-total-supply)))))

(define-read-only (fixed-to-decimals (amount uint))
    (/ (* amount (pow-decimals)) ONE_8))

;; governance calls

(define-public (mint (recipient principal))
    (let (
        (id (var-get id-nonce)))
        (try! (check-is-owner))
        (asserts! (< id MAX-SUPPLY) ERR-MAX-SUPPLY)
        (try! (ft-mint? stx404 ONE_8 tx-sender))
        (try! (nft-mint? stx404nft id tx-sender))
        (map-set owned tx-sender (unwrap-panic (as-max-len? (append (get-owned-or-default tx-sender) id) u10000)))
        (var-set id-nonce (+ id u1))
        (transfer id tx-sender recipient)))

;; public calls
(define-public (transfer (amount-or-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
        (if (<= amount-or-id MAX-SUPPLY) ;; id transfer
            (let (
                (check-id (asserts! (is-id-owned-by-or-default amount-or-id sender) ERR-INVALID-ID))
                (owned-by-sender (get-owned-or-default sender))
                (owned-by-recipient (get-owned-or-default recipient))
                (id-idx (unwrap-panic (index-of? owned-by-sender amount-or-id))))

                (map-set owned sender (unwrap-panic (as-max-len? (concat (unwrap-panic (slice? owned-by-sender u0 id-idx)) (unwrap-panic (slice? owned-by-sender (+ id-idx u1) (len owned-by-sender)))) u10000)))
                (map-set owned recipient (unwrap-panic (as-max-len? (append owned-by-recipient amount-or-id) u10000)))
                (try! (ft-transfer? stx404 ONE_8 sender recipient))
                (try! (nft-transfer? stx404nft amount-or-id sender recipient))
                (ok true))
            (let (
                (check-balance (try! (ft-transfer? stx404 amount-or-id sender recipient)))
                (no-ids (/ amount-or-id ONE_8))
                (owned-by-sender (get-owned-or-default sender))
                (owned-by-recipient (get-owned-or-default recipient))
                (ids-to-move (unwrap-panic (slice? owned-by-sender (- (len owned-by-sender) no-ids) (len owned-by-sender))))
                (ids-to-keep (unwrap-panic (slice? owned-by-sender u0 (- (len owned-by-sender) no-ids)))))
                
                (var-set sender-temp sender)
                (var-set recipient-temp recipient)
                (try! (fold check-err (map nft-transfer-iter ids-to-move) (ok true)))
                (map-set owned sender ids-to-keep)
                (map-set owned recipient (unwrap-panic (as-max-len? (concat owned-by-recipient ids-to-move) u10000)))
                (ok true)))))

(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (transfer (fixed-to-decimals amount) sender recipient))



;; private calls

(define-private (decimals-to-fixed (amount uint))
    (/ (* amount ONE_8) (pow-decimals)))

;; @desc pow-decimals
;; @returns uint
(define-private (pow-decimals)
    (pow u10 (unwrap-panic (get-decimals))))

(define-data-var sender-temp principal tx-sender)
(define-data-var recipient-temp principal tx-sender)

(define-private (nft-transfer-iter (id uint))
    (nft-transfer? stx404nft id (var-get sender-temp) (var-get recipient-temp)))

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior ok-value result err-value (err err-value)))

(define-private (check-is-owner)
    (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))



