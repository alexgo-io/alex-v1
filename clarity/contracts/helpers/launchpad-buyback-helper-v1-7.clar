;;
;; launchpad-buyback
;;

(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-PAUSED (err u1001))
(define-constant ERR-UNKNOWN-ID (err u1002))
(define-constant ERR-TOKEN-NOT-MATCHED (err u1003))
(define-constant ERR-INVALID-BLOCKS (err u1004))
(define-constant ERR-INVALID-PERCENT (err u1005))
(define-constant ERR-INVALID-USER (err u1006))
(define-constant ERR-AMOUNT-EXCEED-CLAIM (err u1007))

(define-constant ONE_8 u100000000) ;; 8 decimal places

(define-data-var contract-owner principal tx-sender)

(define-map buybacks uint { price: uint, reserve: uint, start-block: uint, end-block: uint, claimed: uint, paused: bool })
(define-map claimed { launch-id: uint, claimer: principal } uint)

;; governance functions

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

;; TODO: need update flexibility
(define-public (open-buyback (launch-id uint) (payment-token-trait <ft-trait>) (pct uint) (start-block uint) (end-block uint))
  (let (
      (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
      (total-tickets-won (contract-call? .alex-launchpad-v1-7 get-total-tickets-won launch-id))
      (buyback-price (/ (mul-down (get price-per-ticket-in-fixed launch-details) pct) (get launch-tokens-per-ticket launch-details)))
      (buyback-reserve (* (mul-down (get price-per-ticket-in-fixed launch-details) pct) total-tickets-won)))
    (try! (check-is-owner))
    (asserts! (<= pct ONE_8) ERR-INVALID-PERCENT)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (and (< start-block end-block) (< (get registration-end-height launch-details) start-block)) ERR-INVALID-BLOCKS)

    (try! (contract-call? payment-token-trait transfer-fixed buyback-reserve tx-sender (as-contract tx-sender) none))
    (ok (map-set buybacks launch-id { price: buyback-price, reserve: buyback-reserve, start-block: start-block, end-block: end-block, claimed: u0, paused: false }))))

(define-public (pause-buyback (launch-id uint) (paused bool))
  (begin
    (try! (check-is-owner))
    (ok (map-set buybacks launch-id (merge (try! (get-buybacks-or-fail launch-id)) { paused: paused })))))

(define-public (close-buyback (launch-id uint) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>) (receiver principal))
  (let (
      (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
      (buyback-details (try! (get-buybacks-or-fail launch-id))))
    (try! (check-is-owner))
    (asserts! (or (< block-height (get start-block buyback-details)) (> block-height (get end-block buyback-details))) ERR-INVALID-BLOCKS)
    (asserts! (is-eq (contract-of launch-token-trait) (get launch-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)

    (and (> (get claimed buyback-details) u0) (as-contract (try! (contract-call? launch-token-trait transfer-fixed (get claimed buyback-details) tx-sender receiver none))))
    (and (> (get reserve buyback-details) u0) (as-contract (try! (contract-call? payment-token-trait transfer-fixed (get reserve buyback-details) tx-sender receiver none))))
    (ok { claimed: (get claimed buyback-details), reserve: (get reserve buyback-details) })))

(define-public (transfer-all-to-owner (token-trait <ft-trait>))
	(let (
			(balance (try! (contract-call? token-trait get-balance-fixed (as-contract tx-sender)))))
		(try! (check-is-owner))
		(and (> balance u0) (as-contract (try! (contract-call? token-trait transfer-fixed balance tx-sender (var-get contract-owner) none))))
		(ok true)))

;; read-only functions

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-read-only (get-buybacks-or-fail (launch-id uint))
  (ok (unwrap! (map-get? buybacks launch-id) ERR-UNKNOWN-ID)))

(define-read-only (get-backbacks-or-fail-many (launch-ids (list 100 uint)))
  (ok (map get-buybacks-or-fail launch-ids)))

(define-read-only (is-buyback-paused (launch-id uint))
  (match (map-get? buybacks launch-id)
    some-value (get paused some-value)
    false))

(define-read-only (is-buyback-paused-many (launch-ids (list 100 uint)))
  (map is-buyback-paused launch-ids))

(define-read-only (get-claimed-or-default (launch-id uint) (claimer principal))
  (default-to u0 (map-get? claimed {launch-id: launch-id, claimer: claimer})))

(define-read-only (get-claimed-or-default-many (launch-ids (list 1000 uint)) (claimers (list 1000 principal)))
  (map get-claimed-or-default launch-ids claimers))

(define-read-only (get-available-amount (launch-id uint) (claimer principal))
 (let (
       (launch-details (try! (contract-call? .alex-launchpad-v1-7 get-launch-or-fail launch-id)))
       (buyback-details (try! (get-buybacks-or-fail launch-id)))
       (total-amount (*
         (contract-call? .alex-launchpad-v1-7 get-tickets-won launch-id claimer)
         (get launch-tokens-per-ticket launch-details)
         ONE_8))
       (claimed-amount (get-claimed-or-default launch-id claimer))
       (remaining-amount (- total-amount claimed-amount))
       (payment-amount (mul-down remaining-amount (get price buyback-details))))
      (asserts! (not (is-buyback-paused launch-id)) ERR-PAUSED)
      (asserts! (and (>= block-height (get start-block buyback-details)) (<= block-height (get end-block buyback-details))) ERR-INVALID-BLOCKS)
      (ok { launch-details: launch-details, buyback-details: buyback-details, claimed-amount: claimed-amount, remaining-amount: remaining-amount, payment-amount: payment-amount })))

(define-read-only (get-available-amount-many (launch-ids (list 200 uint)) (claimers (list 200 principal)))
  (map get-available-amount launch-ids claimers))

;; external functions

(define-public (claim-many (launch-ids (list 200 uint)) (amounts (list 200 uint)) (launch-token-traits (list 200 <ft-trait>)) (payment-token-traits (list 200 <ft-trait>)))
  (fold check-err (map claim launch-ids amounts launch-token-traits payment-token-traits) (ok true)))

(define-public (claim (launch-id uint) (amount uint) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>))
  (let (
      (sender tx-sender)
      (available-data (try! (get-available-amount launch-id sender)))
      (launch-details (get launch-details available-data))
      (buyback-details (get buyback-details available-data))      
      (claimed-amount (get claimed-amount available-data))
      (remaining-amount (get remaining-amount available-data))
      (payment-amount (mul-down amount (get price buyback-details))))      
    (asserts! (not (is-buyback-paused launch-id)) ERR-PAUSED)
    (asserts! (and (>= block-height (get start-block buyback-details)) (<= block-height (get end-block buyback-details))) ERR-INVALID-BLOCKS)
    (asserts! (is-eq (contract-of launch-token-trait) (get launch-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (is-eq (contract-of payment-token-trait) (get payment-token launch-details)) ERR-TOKEN-NOT-MATCHED)
    (asserts! (<= amount remaining-amount) ERR-AMOUNT-EXCEED-CLAIM)

    (try! (contract-call? launch-token-trait transfer-fixed amount sender (as-contract tx-sender) none))
    (as-contract (try! (contract-call? payment-token-trait transfer-fixed payment-amount tx-sender sender none)))
    (map-set claimed { launch-id: launch-id, claimer: sender } (+ claimed-amount amount))
    (map-set buybacks launch-id (merge buyback-details { claimed: (+ (get claimed buyback-details) amount), reserve: (- (get reserve buyback-details) payment-amount)}))
    (print { action: "claim", user-claimed: (+ claimed-amount amount), total-claimed: (+ (get claimed buyback-details) amount), reserve: (- (get reserve buyback-details) payment-amount) })
    (ok true)))

;; internal functions

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8))

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
    (match prior
        ok-value result
        err-value (err err-value)))
