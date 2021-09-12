(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-trait multisig-vote-trait
  (
    (propose (uint (string-utf8 256) (string-utf8 256) uint uint) (response bool uint))

    (vote-for (<ft-trait> uint uint) (response uint uint))  

    (vote-against (<ft-trait> uint uint) (response uint uint))  

    (end-proposal (uint) (response uint uint))

    (return-votes-to-member (<ft-trait> uint principal) (response bool uint))

))