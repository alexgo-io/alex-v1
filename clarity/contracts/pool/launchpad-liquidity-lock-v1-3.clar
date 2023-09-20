(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorized (err u1000))

(define-constant ONE_8 u100000000)

(define-map locked uint { pct: uint, period: uint })

(define-public (create-pool
	(launch-token-trait <ft-trait>)
	(payment-token-trait <ft-trait>)
	(offering
		{
		launch-owner: principal,
		launch-tokens-per-ticket: uint,
		price-per-ticket-in-fixed: uint,
		activation-threshold: uint,
		registration-start-height: uint,
		registration-end-height: uint,
		claim-end-height: uint,
		apower-per-ticket-in-fixed: (list 6 {apower-per-ticket-in-fixed: uint, tier-threshold: uint}),
		registration-max-tickets: uint,
		fee-per-ticket-in-fixed: uint
		})
	(locked { pct: uint, period: uint })
	)
	(let 
		(
			(launch-id (try! (contract-call? .alex-launchpad-v1-3 create-pool launch-token-trait payment-token-trait offering)))
		) 		
		(ok (map-set locked launch-id locked))
	)
)

(define-read-only (get-launch (launch-id uint))
	(unwrap! (contract-call? .alex-launchpad-v1-3 get-launch launch-id))
)

(define-read-only (get-locked-details (launch-id uint))
	(map-get? locked launch-id)
)

(define-public (add-to-position (launch-id uint) (tickets uint) (launch-token-trait <ft-trait>))
	(let
		(
			(offering (unwrap! (get-launch launch-id)))
			(locked-details (unwrap! (get-locked-details launch-id)))
		)
		(try! (contract-call? .alex-launchpad-v1-3 add-to-position launch-id tickets launch-token-trait))
		(contract-call? launch-token-trait transfer-fixed (mul-down (* (get launch-tokens-per-ticket offering) tickets ONE_8) (get pct locked-details)) tx-sender (as-contract tx-sender) none)
	)
)

(define-public (claim (launch-id uint) (input (list 200 principal)) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>))
	(let 
		(
			(offering (unwrap! (get-launch launch-id)))
			(locked-details (unwrap! (get-locked-details launch-id)))
			(launch-token-amount (* (get launch-tokens-per-ticket offering) (len input) ONE_8 (get pct locked-details)))
			(fee-per-ticket (mul-down (get price-per-ticket-in-fixed offering) (get fee-per-ticket-in-fixed offering)))
			(net-price-per-ticket (- (get price-per-ticket-in-fixed offering) fee-per-ticket))
			(payment-token-amount (mul-down (* net-price-per-ticket (len input)) (get pct locked-details)))
		)
		(try! (contract-call? .alex-launchpad-v1-3 claim launch-id input launch-token-trait payment-token-trait))
		(try! (contract-call? payment-token-trait transfer-fixed payment-token-amount (get launch-owner offering) (as-contract tx-sender) none))
		;; transfer payment-token-amount from launch-owner
		;; inject launch-/payment-token-amount to mint LP tokens (if pool doesn't exist, create one)		
	)
)

;; TODO redeem LP after lock period
(define-public (redeem-liquidity (launch-id uint) (liquidity-token-trait <sft-trait>) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>))
	;; assert block-height > end of launch + locked-period
	;; redeem liquidity tokens
	;; send launch-/payment-tokens to launch-owner
)

;; TODO equivalent for semifungible
(define-public (transfer-all-to-owner (token-trait <ft-trait>))
	(let 
		(
			(balance (try! (contract-call? token-trait get-balance-fixed (as-contract tx-sender))))
		)
		(try! (check-is-owner))
		(and 
			(> balance u0) 
			(as-contract (try! (contract-call? token-trait transfer-fixed balance tx-sender (var-get contract-owner) none)))
		)
		(ok true)
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
	(ok (asserts! (is-eq tx-sender (var-get contract-owner)) err-not-authorized))
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

;; contract initialisation
;; (set-contract-owner .executor-dao)