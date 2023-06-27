(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-AUTHORIZED (err u1001))
(define-constant ERR-RECIPIENT-NOT-AUTHORIZED (err u1002))
(define-constant ERR-CHAIN-NOT-AUTHORIZED (err u1003))
(define-constant ERR-WRAPPER-NOT-AUTHORIZED (err u1004))

(define-data-var contract-owner principal tx-sender)
(define-map approved-tokens principal bool)
(define-map approved-recipients principal bool)
(define-map approved-wrappers principal bool)
(define-data-var chain-nonce uint u0)
(define-map approved-chains uint { name: (string-utf8 256), buff-length: uint })

(define-read-only (get-approved-chain-or-fail (the-chain-id uint))
  (ok (unwrap! (map-get? approved-chains the-chain-id) ERR-CHAIN-NOT-AUTHORIZED))
)

(define-public (set-approved-chain (chain-details { name: (string-utf8 256), buff-length: uint }))
  (let 
    (
      (the-chain-id (+ (var-get chain-nonce) u1))
    ) 
    (try! (check-is-owner))
    (var-set chain-nonce the-chain-id)
    (ok (map-set approved-chains the-chain-id chain-details))
  )
)

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

(define-public (set-approved-token (token principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-tokens token approved))
	)
)

(define-private (check-is-approved-token (token principal))
  (ok (asserts! (default-to false (map-get? approved-tokens token)) ERR-TOKEN-NOT-AUTHORIZED))
)

(define-public (set-approved-recipient (recipient principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-recipients recipient approved))
	)
)

(define-private (check-is-approved-recipient (recipient principal))
  (ok (asserts! (default-to false (map-get? approved-recipients recipient)) ERR-RECIPIENT-NOT-AUTHORIZED))
)

(define-public (transfer-to-unwrap (token-trait <ft-trait>) (amount-in-fixed uint) (recipient principal) (the-chain-id uint) (settle-address (buff 256)))
  (let 
    (
      (chain-details (try! (get-approved-chain-or-fail the-chain-id)))
    ) 
    (try! (check-is-approved-token (contract-of token-trait)))
    (try! (check-is-approved-recipient recipient))
    (try! (contract-call? token-trait transfer-fixed amount-in-fixed tx-sender recipient none))
    (ok { chain: (get name chain-details), settle-address: (buff-slice settle-address u0 (get buff-length chain-details)) })
  )
)

(define-public (transfer-to-wrap (token-trait <ft-trait>) (amount-in-fixed uint) (recipient principal) (the-chain-id uint) (tx-id (buff 256)))
  (let 
    (
      (chain-details (try! (get-approved-chain-or-fail the-chain-id)))
    )
    (try! (check-is-approved-token (contract-of token-trait)))
    (try! (contract-call? token-trait transfer-fixed amount-in-fixed tx-sender recipient none))
    (ok { chain: (get name chain-details), tx-id: tx-id })
  )
)

(define-private (buff-slice-iterator (byte (buff 1)) (state {accumulator: (buff 256), index: uint, start: uint, end: uint}))
	(let
		(
			(start (get start state))
			(end (get end state))
			(index (get index state))
			(accumulator (get accumulator state))
		)
		{
			start: start,
			end: end,
			accumulator: (if (and (>= index start) (< index end)) (unwrap-panic (as-max-len? (concat accumulator byte) u256)) accumulator),
			index: (+ index u1)
		}
	)
)

(define-read-only (buff-slice (bytes (buff 256)) (start uint) (end uint))
	(get accumulator (fold buff-slice-iterator bytes {accumulator: 0x, index: u0, start: start, end: end}))
)

;; contract initialisation
;; (set-contract-owner .executor-dao)
