(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant err-not-authorized (err u1000))

(define-constant ONE_8 u100000000)

(define-map locked uint uint)

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
	(locked-percent uint)
	)
	(let 
		(
			(launch-id (try! (contract-call? .alex-launchpad-v1-3 create-pool launch-token-trait payment-token-trait offering)))
		) 		
		(ok (map-set locked launch-id locked-percent))
	)
)

(define-public (add-to-position (launch-id uint) (tickets uint) (launch-token-trait <ft-trait>))
	(let
		(
			(offering (unwrap! (unwrap! (contract-call? .alex-launchpad-v1-3 get-launch launch-id))))
			(locked-percent (unwrap! (map-get? locked launch-id)))
		)
		(try! (contract-call? .alex-launchpad-v1-3 add-to-position launch-id tickets launch-token-trait))
		(contract-call? launch-token-trait transfer-fixed (* (get launch-tokens-per-ticket offering) tickets ONE_8 locked-percent) tx-sender (as-contract tx-sender) none)
	)
)

;; TODO calculate the locked payment tokens and withhold
;; TODO inject liquidity and mint LP tokens
(define-public (claim (launch-id uint) (input (list 200 principal)) (launch-token-trait <ft-trait>) (payment-token-trait <ft-trait>))
	(begin
		(var-set tm-amount (* ONE_8 (try! (claim-process launch-id input (contract-of launch-token-trait) payment-token-trait))))
		(fold transfer-many-iter input launch-token-trait)
		(ok true)
	)
)

;; TODO redeem LP after lock period

(define-public (transfer-all-to-owner (token-trait <ft-trait>))
	(let 
		(
			(balance (try! (contract-call? token-trait get-balance-fixed (as-contract tx-sender))))
		)
		(try! (check-is-owner))
		(and 
			(> balance u0) 
			(as-contract 
				(try!
					(contract-call? 
						token-trait 
						transfer-fixed 
				 		balance
						tx-sender 
						(var-get contract-owner) 
						none
					)
				)
			)
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