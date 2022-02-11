(contract-call? .banana-token mint-fixed u1000000000000000 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(contract-call? .ido-ticket mint-fixed u500000000000 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(contract-call? .ido-ticket mint-fixed u500000000000 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
(contract-call? .lottery create-pool .banana-token .ido-ticket .wrapped-stx {ido-owner: 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5, ido-tokens-per-ticket: u24, price-per-ticket-in-fixed: u1000000000, activation-threshold: u10, registration-start-height: (+ block-height u1), registration-end-height: (+ block-height u144), claim-end-height: (+ block-height u288)})
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery add-to-position u0 u10 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.banana-token)
::advance_chain_tip 1
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery register u0 u10 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.ido-ticket 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-stx)
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery register u0 u20 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.ido-ticket 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-stx)
::advance_chain_tip 145
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery get-ido u0)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery get-total-tickets-registered u0)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery get-vrf-uint u145)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery get-offering-walk-parameters u0)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u371421 u600000) ;; => ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u405394 u600000) ;; 776815 => ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u362907 u600000) ;; 1139722 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u368840 u600000) ;; 1508562 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u383017 u600000) ;; 1891579 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u237198 u600000) ;; 2128777 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u507847 u600000) ;; 2636624 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u75556 u600000) ;; 2712180 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u35509 u600000) ;; 2747689 => ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u376074 u600000) ;; 3123763
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery lcg-next u238067 u600000) ;; 3361830
;; ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG start: u0        , end: u1000000
;; ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC start: u1000000, end: u3000000
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery claim u0 (list 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG) 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.banana-token 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-stx)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery claim u0 (list 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC) 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.banana-token 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-stx)
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lottery claim u0 (list 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC) 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.banana-token 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-stx)
::get_assets_maps