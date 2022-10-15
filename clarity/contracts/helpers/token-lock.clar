(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-AUTHORIZED (err u1001))
(define-constant ERR-SCHEDULE-NOT-FOUND (err u1002))
(define-constant ERR-BLOCK-HEIGHT-NOT-REACHED (err u1003))
(define-constant ERR-WORKER-NOT-AUTHORIZED (err u1004))

(define-data-var contract-owner principal tx-sender)
(define-map tokens-to-vest principal uint)
(define-map approved-tokens principal bool)
(define-map approved-workers principal bool)

(define-map vesting-schedule 
    {recipient: principal, token: principal, vesting-id: uint} 
    {amount: uint, vesting-timestamp: uint}
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

(define-public (set-approved-worker (worker principal) (approved bool))
	(begin
		(try! (check-is-owner))
		(ok (map-set approved-workers worker approved))
	)
)

(define-private (check-is-approved-worker (worker principal))
  (ok (asserts! (default-to false (map-get? approved-workers worker)) ERR-WORKER-NOT-AUTHORIZED))
)

(define-read-only (get-tokens-to-vest-or-default (token principal))
    (default-to u0 (map-get? tokens-to-vest token))
)

(define-public (set-vesting-schedule (token principal) (address principal) (height uint) (amount uint))
    (begin 
        (try! (check-is-owner))
        (try! (check-is-approved-token token))
        (map-set token-schedule { token: token, address: address, block-height: height } amount)
        (ok (map-set tokens-to-vest token (+ (get-tokens-to-vest-or-default token) amount)))    
    )
)

(define-private (set-token-schedule-iter (item { token: principal, address: principal, block-height: uint, amount: uint }))
    (set-token-schedule (get token item) (get address item) (get block-height item) (get amount item))
)

(define-public (set-token-schedule-many (items (list 200 { token: principal, address: principal, block-height: uint, amount: uint })))
    (ok (map set-token-schedule-iter items))
)

(define-read-only (get-token-schedule-or-fail (token principal) (address principal) (height uint))
    (ok (unwrap! (map-get? token-schedule { token: token, address: address, block-height: height }) ERR-SCHEDULE-NOT-FOUND))
)

(define-private (get-tokens-iter (token-trait <ft-trait>) (address principal) (height uint))
    (let 
        (
            (token (contract-of token-trait))
            (amount (try! (get-token-schedule-or-fail token address height)))
        )
        (asserts! (> block-height height) ERR-BLOCK-HEIGHT-NOT-REACHED)
        (map-set token-schedule { token: token, address: address, block-height: height } u0)
        (map-set tokens-to-vest token (- (get-tokens-to-vest-or-default token) amount))
        (as-contract (try! (contract-call? token-trait transfer-fixed amount tx-sender address none)))
        (ok { token: token, address: address, block-height: height, amount: amount })
    )
)

(define-public (get-tokens (token-trait <ft-trait>) (height uint))
    (get-tokens-iter token-trait tx-sender height)
)

(define-public (get-tokens-many (token-trait <ft-trait>) (heights (list 200 uint)))
    (ok 
        (map 
            get-tokens 
            (list 
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
            )        
            heights
        )
    )
)

(define-public (get-tokens-on-behalf (token-trait <ft-trait>) (address principal) (height uint))
    (begin 
        (try! (check-is-approved-worker tx-sender))
        (get-tokens-iter token-trait address height)
    )
)

(define-public (get-tokens-on-behalf-many (token-trait <ft-trait>) (addresses (list 200 principal)) (heights (list 200 uint)))
    (ok 
        (map 
            get-tokens-on-behalf 
            (list 
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
                token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait	token-trait
            )  
            addresses 
            heights
        )
    )
)
