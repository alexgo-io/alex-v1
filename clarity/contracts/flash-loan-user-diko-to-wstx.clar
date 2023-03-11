(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant ONE_8 u100000000)
(define-constant ERR-NO-ARB-EXISTS (err u9000))

;; @desc execute
;; @params collateral
;; @params amount
;; @params memo ; expiry
;; @returns (response boolean)
(define-public (execute (token <ft-trait>) (amount uint) (memo (optional (buff 16))))
    (let
        (   
            (swapped-to-alex (try! (contract-call? .swap-helper-v1-03 swap-helper .token-wstx .age000-governance-token amount none)))      
            (swapped-to-diko (try! (contract-call? .amm-swap-pool swap-helper .age000-governance-token .token-wdiko ONE_8 swapped-to-alex none)))      
            (swapped-back
                (/
                    (*
                        (unwrap-panic 
                            (element-at 
                                (try! (contract-call? 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.arkadiko-swap-v2-1 swap-y-for-x
                                    'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.wrapped-stx-token
                                    'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.arkadiko-token
                                    (/ (* swapped-to-diko u1000000) ONE_8)
                                    u0)
                                )
                                u0
                            )
                        )
                        ONE_8
                    )
                    u1000000
                )
            )
            
            
            (amount-with-fee (mul-up amount (+ ONE_8 (unwrap-panic (contract-call? .alex-vault get-flash-loan-fee-rate)))))
        )
        (ok (asserts! (>= swapped-back amount-with-fee) ERR-NO-ARB-EXISTS))
    )
)

;; @desc mul-up
;; @params a
;; @params b
;; @returns uint
(define-private (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)