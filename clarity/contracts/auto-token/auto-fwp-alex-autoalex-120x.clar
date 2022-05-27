(impl-trait .trait-ownable.ownable-trait)
(impl-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-AVAILABLE-ALEX (err u20000))
(define-constant ERR-BLOCK-HEIGHT (err u2043))
(define-constant ERR-NOT-ENOUGH-ALEX (err u20001))

(define-fungible-token auto-fwp-alex-autoalex-120x)

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-data-var token-name (string-ascii 32) "Auto ALEX / autoALEX Pool 120x")
(define-data-var token-symbol (string-ascii 32) "auto-fwp-alex-autoalex-120x")
(define-data-var token-uri (optional (string-utf8 256)) (some u"https://cdn.alexlab.co/metadata/token-auto-fwp-alex-autoalex-120x.json"))

(define-data-var token-decimals uint u8)
(define-data-var transferrable bool false)

(define-read-only (get-transferrable)
	(ok (var-get transferrable))
)

(define-public (set-transferrable (new-transferrable bool))
	(begin 
		(try! (check-is-owner))
		(ok (var-set transferrable new-transferrable))
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

;; --- Authorisation check

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

;; Other

(define-public (set-name (new-name (string-ascii 32)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-name new-name))
	)
)

(define-public (set-symbol (new-symbol (string-ascii 32)))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-symbol new-symbol))
	)
)

(define-public (set-decimals (new-decimals uint))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-decimals new-decimals))
	)
)

(define-public (set-token-uri (new-uri (optional (string-utf8 256))))
	(begin
		(try! (check-is-owner))
		(ok (var-set token-uri new-uri))
	)
)

(define-public (add-approved-contract (new-approved-contract principal))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts new-approved-contract true))
	)
)

(define-public (set-approved-contract (owner principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-contracts owner approved))
	)
)

;; --- Public functions

;; sip010-ft-trait

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))	
    (begin
		    (asserts! (var-get transferrable) ERR-TRANSFER-FAILED)
        (asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
        (try! (ft-transfer? auto-fwp-alex-autoalex-120x amount sender recipient))
        (match memo to-print (print to-print) 0x)
        (ok true)
    )
)

(define-read-only (get-name)
	(ok (var-get token-name))
)

(define-read-only (get-symbol)
	(ok (var-get token-symbol))
)

(define-read-only (get-decimals)
	(ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance auto-fwp-alex-autoalex-120x who))
)

(define-read-only (get-total-supply)
	(ok (ft-get-supply auto-fwp-alex-autoalex-120x))
)

(define-read-only (get-token-uri)
	(ok (var-get token-uri))
)

;; --- Protocol functions

(define-constant ONE_8 u100000000)

;; @desc mint
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response bool)
(define-public (mint (amount uint) (recipient principal))
	(begin		
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ft-mint? auto-fwp-alex-autoalex-120x amount recipient)
	)
)

;; @desc burn
;; @restricted ContractOwner/Approved Contract
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response bool)
(define-public (burn (amount uint) (sender principal))
	(begin
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ft-burn? auto-fwp-alex-autoalex-120x amount sender)
	)
)

;; @desc pow-decimals
;; @returns uint
(define-private (pow-decimals)
  (pow u10 (unwrap-panic (get-decimals)))
)

;; @desc fixed-to-decimals
;; @params amount
;; @returns uint
(define-read-only (fixed-to-decimals (amount uint))
  (/ (* amount (pow-decimals)) ONE_8)
)

;; @desc decimals-to-fixed 
;; @params amount
;; @returns uint
(define-private (decimals-to-fixed (amount uint))
  (/ (* amount ONE_8) (pow-decimals))
)

;; @desc get-total-supply-fixed
;; @params token-id
;; @returns (response uint)
(define-read-only (get-total-supply-fixed)
  (ok (decimals-to-fixed (unwrap-panic (get-total-supply))))
)

;; @desc get-balance-fixed
;; @params token-id
;; @params who
;; @returns (response uint)
(define-read-only (get-balance-fixed (account principal))
  (ok (decimals-to-fixed (unwrap-panic (get-balance account))))
)

;; @desc transfer-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @params recipient
;; @returns (response bool)
(define-public (transfer-fixed (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (transfer (fixed-to-decimals amount) sender recipient memo)
)

;; @desc mint-fixed
;; @params token-id
;; @params amount
;; @params recipient
;; @returns (response bool)
(define-public (mint-fixed (amount uint) (recipient principal))
  (mint (fixed-to-decimals amount) recipient)
)

;; @desc burn-fixed
;; @params token-id
;; @params amount
;; @params sender
;; @returns (response bool)
(define-public (burn-fixed (amount uint) (sender principal))
  (burn (fixed-to-decimals amount) sender)
)

(define-private (mint-fixed-many-iter (item {amount: uint, recipient: principal}))
	(mint-fixed (get amount item) (get recipient item))
)

(define-public (mint-fixed-many (recipients (list 200 {amount: uint, recipient: principal})))
	(begin
		(asserts! (or (is-ok (check-is-approved)) (is-ok (check-is-owner))) ERR-NOT-AUTHORIZED)
		(ok (map mint-fixed-many-iter recipients))
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map available-alex principal uint)
(define-map borrowed-alex principal uint)

(define-data-var start-block uint u340282366920938463463374607431768211455)
(define-data-var end-block uint u340282366920938463463374607431768211455)

(define-read-only (get-start-block)
  (var-get start-block)
)

(define-public (set-start-block (new-start-block uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set start-block new-start-block))
  )
)

(define-read-only (get-end-block)
  (var-get end-block)
)

(define-public (set-end-block (new-end-block uint))
  (begin 
    (try! (check-is-owner))
    (ok (var-set end-block new-end-block))
  )
)

(define-public (set-available-alex (user principal) (new-amount uint))
    (begin 
        (try! (check-is-owner))
        (ok (map-set available-alex user new-amount))
    )
)

(define-read-only (get-available-alex-or-default (user principal))
    (default-to u0 (map-get? available-alex user))
)

(define-read-only (get-borrowed-alex-or-default (user principal))
  (default-to u0 (map-get? borrowed-alex user))
)

(define-public (add-to-position (dx uint))
    (let 
        (
          (sender tx-sender)
          (pool (try! (contract-call? .simple-weight-pool-alex get-token-given-position .age000-governance-token .auto-alex dx none)))
          (atalex-in-alex (mul-down (try! (contract-call? .auto-alex get-intrinsic)) (get dy pool)))          
          (alex-to-atalex (div-down (mul-down dx atalex-in-alex) (+ dx atalex-in-alex)))
          (atalex-amount (try! (contract-call? .auto-alex get-token-given-position alex-to-atalex)))
          (alex-available (get-available-alex-or-default sender))
          (alex-borrowed (get-borrowed-alex-or-default sender))                        
        )
        (asserts! (>= block-height (var-get start-block)) ERR-BLOCK-HEIGHT)
        (asserts! (>= alex-available dx) ERR-AVAILABLE-ALEX)        

        (as-contract (try! (contract-call? .age000-governance-token mint-fixed dx tx-sender)))
        (as-contract (try! (contract-call? .auto-alex add-to-position alex-to-atalex)))
        (as-contract (try! (contract-call? .simple-weight-pool-alex add-to-position .age000-governance-token .auto-alex .fwp-alex-autoalex (- dx alex-to-atalex) (some atalex-amount))))
        (map-set available-alex sender (- alex-available dx))
        (map-set borrowed-alex sender (+ alex-borrowed dx))
		    (try! (ft-mint? auto-fwp-alex-autoalex-120x (fixed-to-decimals (get token pool)) sender))
        (print { object: "pool", action: "position-added", data: (get token pool)})
        (ok { total-alex-borrowed: (+ alex-borrowed dx), position: (get token pool) })
    )
)

(define-public (reduce-position)
  (let 
    (
      (sender tx-sender)
      (alex-borrowed (get-borrowed-alex-or-default sender))
      (supply (unwrap-panic (get-balance-fixed sender)))
      (total-supply (unwrap-panic (get-total-supply-fixed)))
      (share (div-down supply total-supply))
      (pool (as-contract (try! (contract-call? .simple-weight-pool-alex reduce-position .age000-governance-token .auto-alex .fwp-alex-autoalex share))))  
      (atalex-in-alex (mul-down (try! (contract-call? .auto-alex get-intrinsic)) (get dy pool)))
      (alex-shortfall (if (<= alex-borrowed (get dx pool)) u0 (- alex-borrowed (get dx pool))))
    )
    (asserts! (> block-height (var-get end-block)) ERR-BLOCK-HEIGHT)
    (asserts! (> atalex-in-alex alex-shortfall) ERR-NOT-ENOUGH-ALEX)

    (let
      (
        (alex-to-lender (- alex-borrowed alex-shortfall))
        (atalex-to-lender (div-down (mul-down (get dy pool) alex-shortfall) atalex-in-alex))
        (alex-to-borrower (- (get dx pool) alex-to-loender))
        (atalex-to-borrower (- (get dy pool) atalex-to-lender))
      )
    
      (and (> alex-to-lender u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed alex-to-lender tx-sender .executor-dao none))))
      (and (> atalex-to-lender u0) (as-contract (try! (contract-call? .auto-alex transfer-fixed atalext-to-lender tx-sender .executor-dao none))))

      (and (> alex-to-borrower u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed alex-to-borrower tx-sender sender none))))
      (and (> atalex-to-borrower u0) (as-contract (try! (contract-call? .auto-alex transfer-fixed atalex-to-borrower tx-sender sender none))))

	    (try! (ft-burn? auto-fwp-alex-autoalex-120x (fixed-to-decimals supply) sender))
      (print { object: "pool", action: "position-reduced", data: supply })
      (ok { alex: alex-to-borrower, atalex: atalex-to-borrower })
  )
)

(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)