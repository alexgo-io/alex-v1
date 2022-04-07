(impl-trait 'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait 'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.trait-sip-010.sip-010-trait)

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
            (swapped
                (unwrap-panic 
                    (element-at 
                        (try! (contract-call? 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.arkadiko-swap-v2-1 swap-x-for-y 
                            'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.wrapped-stx-token
                            'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token
                            (/ (* amount u1000000) ONE_8)
                            u0)
                        )
                        u1
                    )
                )
            )
            (swapped-back 
                (try! (contract-call? 'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.swap-helper-v1-01 swap-helper 
                    'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.token-wusda 
                    'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.token-wstx 
                    (/ (* swapped ONE_8) u1000000)
                    none)
                )             
            )
            (amount-with-fee (mul-up amount (+ ONE_8 (unwrap-panic (contract-call? 'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.alex-vault get-flash-loan-fee-rate)))))
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