(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait ido-ft-trait .trait-ido-ft.ido-ft-trait)

(define-constant err-unknown-ido (err u100))
(define-constant err-block-height-not-reached (err u101))
(define-constant err-invalid-sequence (err u102))
(define-constant err-invalid-ido-token (err u103))
(define-constant err-invalid-payment-token (err u104))
(define-constant err-cannot-trigger-claim (err u105))
(define-constant err-not-in-claim-phase (err u106))
(define-constant err-no-more-claims (err u107))
(define-constant err-use-claim-simple (err u108))
(define-constant err-more-to-claim (err u109))
(define-constant err-invalid-ido-setting (err u110))
(define-constant err-invalid-input (err u111))
(define-constant err-already-registered (err u112))
(define-constant err-activation-threshold-not-reached (err u113))
(define-constant err-not-authorized (err u1000))

(define-constant walk-resolution (pow u10 u5))
(define-constant claim-grace-period u144)

(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)
(define-map approved-operators principal bool)

(define-data-var ido-id-nonce uint u0)

(define-map offerings
	uint
	{
	ido-token-contract: principal,
	payment-token-contract: principal,
	ido-owner: principal,
	ido-tokens-per-ticket: uint,
	price-per-ticket-in-fixed: uint,
	activation-threshold: uint,
	registration-start-height: uint,
	registration-end-height: uint,
	claim-end-height: uint,
	total-tickets: uint,
	apower-per-ticket-in-fixed: uint
	}
)

(define-map total-tickets-registered uint uint)

(define-map start-indexes uint uint)

(define-map offering-ticket-bounds
	{ido-id: uint, owner: principal}
	{start: uint, end: uint}
)

(define-map offering-ticket-amounts
	{ido-id: uint, owner: principal}
	uint
)

(define-map total-tickets-won uint uint)

(define-map tickets-won
	{ido-id: uint, owner: principal}
	uint
)

(define-map claim-walk-positions uint uint)

(define-public (create-pool
	(ido-token <ft-trait>)
	(payment-token <ft-trait>)
	(offering
		{
		ido-owner: principal,
		ido-tokens-per-ticket: uint,
		price-per-ticket-in-fixed: uint,
		activation-threshold: uint,
		registration-start-height: uint,
		registration-end-height: uint,
		claim-end-height: uint,
		apower-per-ticket-in-fixed: uint
		})
	)
	(let 
		(
			(ido-id (var-get ido-id-nonce))
		)
		(asserts! (is-eq (var-get contract-owner) tx-sender) err-not-authorized)
		(asserts!
			(and
				(< block-height (get registration-start-height offering))
				(< (get registration-start-height offering) (get registration-end-height offering))
				(< (get registration-end-height offering) (get claim-end-height offering))
			)
			err-invalid-ido-setting
		)
		(map-set offerings ido-id (merge offering
			{
				ido-token-contract: (contract-of ido-token),
				payment-token-contract: (contract-of payment-token),
				total-tickets: u0
			})
		)
		(var-set ido-id-nonce (+ ido-id u1))
		(ok ido-id)
	)
)

(define-read-only (get-ido (ido-id uint))
	(ok (map-get? offerings ido-id))
)

(define-public (add-to-position (ido-id uint) (tickets uint) (ido-token <ft-trait>))
	(let ((offering (unwrap! (map-get? offerings ido-id) err-unknown-ido)))
		(asserts! (< block-height (get registration-start-height offering)) err-block-height-not-reached)
		(asserts! (or (is-eq (get ido-owner offering) tx-sender) (is-ok (check-is-approved)) (is-ok (check-is-owner))) err-not-authorized)
		(asserts! (is-eq (contract-of ido-token) (get ido-token-contract offering)) err-invalid-ido-token)
		(try! (contract-call? ido-token transfer-fixed (* (get ido-tokens-per-ticket offering) tickets ONE_8) tx-sender (as-contract tx-sender) none))
		(map-set offerings ido-id (merge offering {total-tickets: (+ (get total-tickets offering) tickets)}))
		(ok true)
	)
)

;; reduce position after claim period ends

(define-read-only (calculate-max-step-size (tickets-registered uint) (total-tickets uint))
	(/ (* u17 (/ (* tickets-registered walk-resolution) total-tickets)) u10)
)

(define-private (next-bounds (ido-id uint) (tickets uint))
	(let
		(
			(start (default-to u0 (map-get? start-indexes ido-id)))
			(end (+ start (* tickets walk-resolution)))
		)
		(map-set start-indexes ido-id end)
		{start: start, end: end}
	)
)

(define-read-only (get-total-tickets-registered (ido-id uint))
	(default-to u0 (map-get? total-tickets-registered ido-id))
)

(define-read-only (get-total-tickets-won (ido-id uint))
	(default-to u0 (map-get? total-tickets-won ido-id))
)

(define-read-only (get-tickets-won (ido-id uint) (owner principal))
	(default-to u0 (map-get? tickets-won {ido-id: ido-id, owner: owner}))
)

(define-read-only (get-offering-ticket-bounds (ido-id uint) (owner principal))
	(map-get? offering-ticket-bounds {ido-id: ido-id, owner: owner})
)

(define-public (register (ido-id uint) (apower-in-fixed uint) (payment-token <ft-trait>))
	(let
		(
			(offering (unwrap! (map-get? offerings ido-id) err-unknown-ido))
			(tickets (/ apower-in-fixed (get apower-per-ticket-in-fixed offering)))
			(bounds (next-bounds ido-id tickets))
			(sender tx-sender)
		)
		(asserts! (is-none (map-get? offering-ticket-bounds {ido-id: ido-id, owner: tx-sender})) err-already-registered)
		(asserts! (> tickets u0) err-invalid-input)
		(asserts! (>= block-height (get registration-start-height offering)) err-block-height-not-reached)
		(asserts! (< block-height (get registration-end-height offering)) err-block-height-not-reached)		
		(asserts! (is-eq (get payment-token-contract offering) (contract-of payment-token)) err-invalid-payment-token)		
		(try! (contract-call? payment-token transfer-fixed (* (get price-per-ticket-in-fixed offering) tickets) sender (as-contract tx-sender) none))		
		(as-contract (try! (contract-call? .token-apower burn-fixed apower-in-fixed sender)))
		(map-set offering-ticket-bounds {ido-id: ido-id, owner: tx-sender} bounds)
		(map-set total-tickets-registered ido-id (+ (get-total-tickets-registered ido-id) tickets))
		(ok bounds)
	)
)

(define-read-only (get-initial-walk-position (registration-end-height uint) (max-step-size uint))
	(ok (lcg-next (try! (get-vrf-uint (+ registration-end-height u1))) max-step-size))
)

(define-read-only (get-last-claim-walk-position (ido-id uint) (registration-end-height uint) (max-step-size uint))
	(match (map-get? claim-walk-positions ido-id)
		position (ok position)
		(get-initial-walk-position registration-end-height max-step-size)
	)
)

(define-read-only (get-offering-walk-parameters (ido-id uint))
	(let
		(
			(offering (unwrap! (map-get? offerings ido-id) err-unknown-ido))
			(max-step-size (calculate-max-step-size (get-total-tickets-registered ido-id) (get total-tickets offering)))
			(walk-position (try! (get-last-claim-walk-position ido-id (get registration-end-height offering) max-step-size)))
		)
		(ok {max-step-size: max-step-size, walk-position: walk-position, total-tickets: (get total-tickets offering)})
	)
)

(define-private (verify-winner-iter (o principal) (p {i: uint, t: uint, r: {start: uint, end: uint}, w: uint, m: uint, l: uint, s: bool}))
	(let
		(
			(k {ido-id: (get i p), owner: o})
			(r (if (is-eq (get t p) u0) (unwrap! (map-get? offering-ticket-bounds k) (merge p {s: false})) (get r p)))
			(e (get end r))
			(l (get l p))
			(n (+ (get w p) (lcg-next (get w p) (get m p))))
			(b (or (>= n e) (is-eq l u1)))
			(t (+ (if (is-eq (get t p) u0) (default-to u0 (map-get? tickets-won k)) (get t p)) u1))
		)
		(asserts! (get s p) p)
		(and b (map-set tickets-won k t))
		(merge p { t: (if b u0 t), r: (if b {start: u0, end: u0} r), w: n, l: (- l u1), s: (and (>= (get w p) (get start r)) (< (get w p) e))})
	)
)

(define-private (claim-process (ido-id uint) (input (list 200 principal)) (ido-token principal) (payment-token <ft-trait>))
	(let
		(
			(offering (unwrap! (map-get? offerings ido-id) err-unknown-ido))
			(total-won (default-to u0 (map-get? total-tickets-won ido-id)))
			(max-step-size (calculate-max-step-size (get-total-tickets-registered ido-id) (get total-tickets offering)))
			(walk-position (try! (get-last-claim-walk-position ido-id (get registration-end-height offering) max-step-size)))
			(result (fold verify-winner-iter input {i: ido-id, t: u0, r: {start: u0, end: u0}, w: walk-position, m: max-step-size, l: (len input), s: true}))
		)
		;;(asserts! (> max-step-size walk-resolution) err-use-claim-simple)
		(asserts! (and (>= block-height (get registration-end-height offering)) (< block-height (get claim-end-height offering))) err-block-height-not-reached)
		(asserts! (and (< total-won (get total-tickets offering)) (< walk-position (unwrap-panic (map-get? start-indexes ido-id)))) err-no-more-claims)
		(asserts! (and (<= (+ (len input) total-won) (get total-tickets offering)) (get s result)) err-invalid-sequence) ;; do we need the first condition?
		(asserts! (<= (get activation-threshold offering) (get-total-tickets-registered ido-id)) err-activation-threshold-not-reached)
 		(asserts! (is-eq (get ido-token-contract offering) ido-token) err-invalid-ido-token)
		(asserts! (is-eq (get payment-token-contract offering) (contract-of payment-token)) err-invalid-payment-token)
		(asserts! (and (>= block-height (get registration-end-height offering)) (< block-height (get claim-end-height offering))) err-not-in-claim-phase)
		(asserts!
			(or
				(>= block-height (+ (get claim-end-height offering) claim-grace-period))
				(is-eq (get ido-owner offering) tx-sender)
				(is-ok (check-is-owner))
				(is-ok (check-is-approved))
			)
			err-cannot-trigger-claim
		)
		(map-set claim-walk-positions ido-id (get w result))
		(map-set total-tickets-won ido-id (+ (len input) total-won))
		(try! (as-contract (contract-call? payment-token transfer-fixed (* (len input) (get price-per-ticket-in-fixed offering)) tx-sender (get ido-owner offering) none)))
		(ok (get ido-tokens-per-ticket offering))
	)
)

(define-public (claim-optimal (ido-id uint) (input (list 200 principal)) (ido-token <ido-ft-trait>) (payment-token <ft-trait>))
	(let 
		(
			(ido-tokens-per-ticket (try! (claim-process ido-id input (contract-of ido-token) payment-token)))
		)
		(as-contract (contract-call? ido-token transfer-many-ido (* ido-tokens-per-ticket ONE_8) input))
	)
)

(define-public (claim-fallback (ido-id uint) (input (list 200 principal)) (ido-token <ft-trait>) (payment-token <ft-trait>))
	(let ((ido-tokens-per-ticket (try! (claim-process ido-id input (contract-of ido-token) payment-token))))
		(var-set tm-amount (* ido-tokens-per-ticket ONE_8))
		(fold transfer-many-iter input ido-token)
		(ok true)
	)
)

(define-data-var tm-amount uint u0)
(define-private (transfer-many-iter (recipient principal) (ido-token <ft-trait>))
	(begin
		(unwrap-panic (as-contract (contract-call? ido-token transfer-fixed (var-get tm-amount) tx-sender recipient none)))
		ido-token
	)
)

(define-private (transfer-many-amounts-iter (e {recipient: principal, amount: uint}) (payment-token <ft-trait>))
	(begin
		(unwrap-panic (as-contract (contract-call? payment-token transfer-fixed (get amount e) tx-sender (get recipient e) none)))
		payment-token
	)
)

(define-private (refund-optimal-iter (e {recipient: principal, amount: uint}) (p {i: uint, p: uint, s: bool}))
	(let
		(
			(k {ido-id: (get i p), owner: (get recipient e)})
			(b (unwrap! (map-get? offering-ticket-bounds k) (merge p {s: false})))
		)
		(asserts! (get s p) p)
		(map-delete offering-ticket-bounds k)
		{
			i: (get i p),
			p: (get p p),
			s: (is-eq (* (- (/ (- (get end b) (get start b)) walk-resolution) (default-to u0 (map-get? tickets-won k))) (get p p)) (get amount e))
		}
	)
)

(define-public (refund-optimal (ido-id uint) (input (list 200 {recipient: principal, amount: uint})) (payment-token <ido-ft-trait>))
	(let 
		(
			(offering (unwrap! (map-get? offerings ido-id) err-unknown-ido))
		)
		(asserts! 
			(and
				(is-eq (default-to u0 (map-get? total-tickets-won ido-id)) (get total-tickets offering)) ;; all winning tickets have been claimed
				;; (>= (unwrap! (map-get? claim-walk-positions ido-id) err-more-to-claim) (unwrap! (map-get? start-indexes ido-id) err-more-to-claim)) ;; claim walk has reached the end
			)
			err-more-to-claim
		)
		(asserts! (is-eq (get payment-token-contract offering) (contract-of payment-token)) err-invalid-payment-token)
		(asserts! (get s
			(fold refund-optimal-iter input
				{
					i: ido-id,
					p: (unwrap! (get price-per-ticket-in-fixed (map-get? offerings ido-id)) err-unknown-ido),
					s: true
				}))
			err-invalid-sequence
		)
		(as-contract (contract-call? payment-token transfer-many-amounts-ido input))
	)
)

(define-private (refund-fallback-iter (e {recipient: principal, amount: uint}) (p {i: uint, p: uint, s: bool}))
	(let
		(
			(k {ido-id: (get i p), owner: (get recipient e)})
			(b (unwrap! (map-get? offering-ticket-bounds k) (merge p {s: false})))
		)
		(asserts! (get s p) p)
		(map-delete offering-ticket-bounds k)
		{
			i: (get i p),
			p: (get p p),
			s: (is-eq (* (- (/ (- (get end b) (get start b)) walk-resolution) (default-to u0 (map-get? tickets-won k))) (get p p)) (get amount e))
		}
	)
)

(define-public (refund-fallback (ido-id uint) (input (list 200 {recipient: principal, amount: uint})) (payment-token <ft-trait>))
	(let 
		(
			(offering (unwrap! (map-get? offerings ido-id) err-unknown-ido))
		)
		(asserts! 
			(and
				(is-eq (default-to u0 (map-get? total-tickets-won ido-id)) (get total-tickets offering)) ;; all winning tickets have been claimed
				;; (>= (unwrap! (map-get? claim-walk-positions ido-id) err-more-to-claim) (unwrap! (map-get? start-indexes ido-id) err-more-to-claim)) ;; claim walk has reached the end
			)
			err-more-to-claim
		)
		(asserts! (is-eq (get payment-token-contract offering) (contract-of payment-token)) err-invalid-payment-token)
		(asserts! (get s
			(fold refund-fallback-iter input
				{
					i: ido-id,
					p: (unwrap! (get price-per-ticket-in-fixed (map-get? offerings ido-id)) err-unknown-ido),
					s: true
				}))
			err-invalid-sequence
		)
		(fold transfer-many-amounts-iter input payment-token)
		(ok true)
	)
)

(define-constant lcg-a u134775813)
(define-constant lcg-c u1)
(define-constant lcg-m u4294967296)

(define-read-only (lcg-next (current uint) (max-step uint))
	(mod (mod (+ (* lcg-a current) lcg-c) lcg-m) max-step)
)

(define-read-only (get-vrf-uint (height uint))
	(ok (buff-to-uint64 (unwrap! (get-block-info? vrf-seed height) err-block-height-not-reached)))
)

(define-constant byte-list
	(list
		0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f
		0x10 0x11 0x12 0x13 0x14 0x15 0x16 0x17 0x18 0x19 0x1a 0x1b 0x1c 0x1d 0x1e 0x1f
		0x20 0x21 0x22 0x23 0x24 0x25 0x26 0x27 0x28 0x29 0x2a 0x2b 0x2c 0x2d 0x2e 0x2f
		0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37 0x38 0x39 0x3a 0x3b 0x3c 0x3d 0x3e 0x3f
		0x40 0x41 0x42 0x43 0x44 0x45 0x46 0x47 0x48 0x49 0x4a 0x4b 0x4c 0x4d 0x4e 0x4f
		0x50 0x51 0x52 0x53 0x54 0x55 0x56 0x57 0x58 0x59 0x5a 0x5b 0x5c 0x5d 0x5e 0x5f
		0x60 0x61 0x62 0x63 0x64 0x65 0x66 0x67 0x68 0x69 0x6a 0x6b 0x6c 0x6d 0x6e 0x6f
		0x70 0x71 0x72 0x73 0x74 0x75 0x76 0x77 0x78 0x79 0x7a 0x7b 0x7c 0x7d 0x7e 0x7f
		0x80 0x81 0x82 0x83 0x84 0x85 0x86 0x87 0x88 0x89 0x8a 0x8b 0x8c 0x8d 0x8e 0x8f
		0x90 0x91 0x92 0x93 0x94 0x95 0x96 0x97 0x98 0x99 0x9a 0x9b 0x9c 0x9d 0x9e 0x9f
		0xa0 0xa1 0xa2 0xa3 0xa4 0xa5 0xa6 0xa7 0xa8 0xa9 0xaa 0xab 0xac 0xad 0xae 0xaf
		0xb0 0xb1 0xb2 0xb3 0xb4 0xb5 0xb6 0xb7 0xb8 0xb9 0xba 0xbb 0xbc 0xbd 0xbe 0xbf
		0xc0 0xc1 0xc2 0xc3 0xc4 0xc5 0xc6 0xc7 0xc8 0xc9 0xca 0xcb 0xcc 0xcd 0xce 0xcf
		0xd0 0xd1 0xd2 0xd3 0xd4 0xd5 0xd6 0xd7 0xd8 0xd9 0xda 0xdb 0xdc 0xdd 0xde 0xdf
		0xe0 0xe1 0xe2 0xe3 0xe4 0xe5 0xe6 0xe7 0xe8 0xe9 0xea 0xeb 0xec 0xed 0xee 0xef
		0xf0 0xf1 0xf2 0xf3 0xf4 0xf5 0xf6 0xf7 0xf8 0xf9 0xfa 0xfb 0xfc 0xfd 0xfe 0xff
	)
)

(define-read-only (byte-to-uint (byte (buff 1)))
	(unwrap-panic (index-of byte-list byte))
)

(define-read-only (buff-to-uint64 (bytes (buff 32)))
	(+
		(match (element-at bytes u0) byte (byte-to-uint byte) u0)
		(match (element-at bytes u1) byte (* (byte-to-uint byte) u256) u0)
		(match (element-at bytes u2) byte (* (byte-to-uint byte) u65536) u0)
		(match (element-at bytes u3) byte (* (byte-to-uint byte) u16777216) u0)
		(match (element-at bytes u4) byte (* (byte-to-uint byte) u4294967296) u0)
		(match (element-at bytes u5) byte (* (byte-to-uint byte) u1099511627776) u0)
		(match (element-at bytes u6) byte (* (byte-to-uint byte) u281474976710656) u0)
		(match (element-at bytes u7) byte (* (byte-to-uint byte) u72057594037927936) u0)
	)
)

(define-read-only (get-contract-owner)
	(ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
	(begin
		(asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized)
		(ok (var-set contract-owner owner))
	)
)

(define-private (check-is-owner)
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized))
)

(define-private (check-is-approved)
	(ok (asserts! (default-to false (map-get? approved-operators tx-sender)) err-not-authorized))
)

(define-public (add-approved-operator (new-approved-operator principal))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-operators new-approved-operator true))
	)
)

;; @desc mul-down
;; @params a
;; @params b
;; @returns uint
(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc div-down
;; @params a
;; @params b
;; @returns uint
(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)