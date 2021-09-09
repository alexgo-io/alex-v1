(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-trait multisig-vote-trait
  (
    (propose (uint (string-utf8 256) (string-utf8 256) 
    (list 10 (tuple (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool)))
    principal
    uint
    uint)
    (response uint uint))


    (vote-for (<ft-trait> uint uint) (response uint uint))  

    (vote-against (<ft-trait> uint uint) (response uint uint))  

    (end-proposal (uint <ft-trait> <ft-trait>) (response uint uint))

    (return-votes-to-member (<ft-trait> uint principal) (response uint uint))

    ;;(add-contract-address ((string-ascii 256) principal principal bool bool) (response uint uint))

))