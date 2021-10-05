(impl-trait .trait-multisig-vote.multisig-vote-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)


;; Alex voting for MultiSig DAO
;; 
;; Voting and proposing the proposals 
;; A proposal will just update the DAO with new contracts.

;; Voting can be done by locking up the corresponding pool token. 
;; This prototype is for ayusda-usda pool token. 
;; Common Trait and for each pool, implementation is required. 
;; 

;; Errors
(define-constant ERR-NOT-ENOUGH-BALANCE (err u8000))
(define-constant ERR-NO-FEE-CHANGE (err u8001))
(define-constant ERR-INVALID-POOL-TOKEN (err u8002))
(define-constant ERR-BLOCK-HEIGHT-NOT-REACHED (err u8003))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-MATH-CALL (err u2010))

(define-constant ONE_8 u100000000)
;; Constants
(define-constant DEFAULT_OWNER tx-sender)

;; Proposal variables
;; With Vote, we can set :
;; 1. contract to have right to mint/burn token 
;; 2. Set Feerate / Fee address / Collect Fees 
(define-map proposals
  { id: uint }
  {
    id: uint,
    proposer: principal,
    title: (string-utf8 256),
    url: (string-utf8 256),
    is-open: bool,
    start-block-height: uint,
    end-block-height: uint,
    yes-votes: uint,
    no-votes: uint,
    new-fee-rate-x: uint,
    new-fee-rate-y: uint
   }
)

(define-data-var proposal-count uint u0)
(define-data-var proposal-ids (list 100 uint) (list u0))
(define-data-var threshold uint u75000000)    ;; 75%

(define-data-var total-supply-of-token uint u0)
(define-data-var threshold-percentage uint u0)

(define-map votes-by-member { proposal-id: uint, member: principal } { vote-count: uint })
(define-map tokens-by-member { proposal-id: uint, member: principal, token: principal } { amount: uint })

;; Get all proposals in detail
(define-read-only (get-proposals)
  (ok (map get-proposal-by-id (var-get proposal-ids)))
)

;; Get all proposal ID in list
(define-read-only (get-proposal-ids)
  (ok (var-get proposal-ids))
)

;; Get votes for a member on proposal
(define-read-only (get-votes-by-member-by-id (proposal-id uint) (member principal))
  (default-to 
    { vote-count: u0 }
    (map-get? votes-by-member { proposal-id: proposal-id, member: member })
  )
)

(define-read-only (get-tokens-by-member-by-id (proposal-id uint) (member principal) (token <ft-trait>))
  (default-to 
    { amount: u0 }
    (map-get? tokens-by-member { proposal-id: proposal-id, member: member, token: (contract-of token) }) 
  )
)

;; Get proposal
(define-read-only (get-proposal-by-id (proposal-id uint))
  (default-to
    {
      id: u0,
      proposer: DEFAULT_OWNER,
      title: u"",
      url: u"",
      is-open: false,
      start-block-height: u0,
      end-block-height: u0,
      yes-votes: u0,
      no-votes: u0,
      new-fee-rate-x: u0,    ;; Default token feerate
      new-fee-rate-y: u0  ;; default aytoken feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; To check which tokens are accepted as votes, Only by staking Pool Token is allowed. 
(define-read-only (is-token-accepted (token <ft-trait>))
    (or (is-eq (contract-of token) .yield-wbtc-240) (is-eq (contract-of token) .key-wbtc-240-usda))
)


;; Start a proposal
;; Requires 10% of the supply in your wallet
;; Default voting period is 10 days (144 * 10 blocks)
(define-public (propose
    (start-block-height uint)
    (title (string-utf8 256))
    (url (string-utf8 256))
    (new-fee-rate-x uint)
    (new-fee-rate-y uint)
  )
  (let 
    (
      (proposer-yield-balance (unwrap-panic (contract-call? .yield-wbtc-240 get-balance tx-sender)))
      (proposer-key-balance (unwrap-panic (contract-call? .key-wbtc-240-usda get-balance tx-sender)))
      (proposer-balance (+ proposer-yield-balance proposer-key-balance))
      (total-yield-supply (unwrap-panic (contract-call? .yield-wbtc-240 get-total-supply)))
      (total-key-supply (unwrap-panic (contract-call? .key-wbtc-240-usda get-total-supply)))
      (total-supply (+ total-yield-supply total-key-supply))
      (proposal-id (+ u1 (var-get proposal-count)))
    )

    ;; Requires 10% of the supply 
    (asserts! (>= (* proposer-balance u10) total-supply) ERR-NOT-ENOUGH-BALANCE)
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      {
        id: proposal-id,
        proposer: tx-sender,
        title: title,
        url: url,
        is-open: true,
        start-block-height: start-block-height,
        end-block-height: (+ start-block-height u1440),
        yes-votes: u0,
        no-votes: u0,
        new-fee-rate-x: new-fee-rate-x,
        new-fee-rate-y: new-fee-rate-y
      }
    )
    (var-set proposal-count proposal-id)
    (var-set proposal-ids (unwrap-panic (as-max-len? (append (var-get proposal-ids) proposal-id) u100)))
    (ok proposal-id)
  )
)

(define-public (vote-for (token <ft-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token)))
    
  )

    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted token) ERR-INVALID-POOL-TOKEN)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) ERR-NOT-AUTHORIZED)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) ERR-NOT-AUTHORIZED)
    
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { yes-votes: (+ amount (get yes-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ amount vote-count) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (+ amount token-count)})

    (ok amount)
    
    )
  )




(define-public (vote-against (token <ft-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token)))
  )
    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted token) ERR-INVALID-POOL-TOKEN)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) ERR-NOT-AUTHORIZED)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) ERR-NOT-AUTHORIZED)
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))

    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { no-votes: (+ amount (get no-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ amount vote-count) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (+ amount token-count)})
    (ok amount)
    )
    
    )

(define-public (end-proposal (proposal-id uint))
  (let ((proposal (get-proposal-by-id proposal-id))
        (threshold-percent (var-get threshold))
        (total-yield-supply (unwrap-panic (contract-call? .yield-wbtc-240 get-total-supply)))
        (total-key-supply (unwrap-panic (contract-call? .key-wbtc-240-usda get-total-supply)))
        (total-supply (* (+ total-yield-supply total-key-supply) ONE_8))
        (threshold-count (unwrap-panic (contract-call? .math-fixed-point mul-up total-supply threshold-percent)))
        (yes-votes (get yes-votes proposal))
  )

    (asserts! (not (is-eq (get id proposal) u0)) ERR-NOT-AUTHORIZED)  ;; Default id
    (asserts! (get is-open proposal) ERR-NOT-AUTHORIZED)
    (asserts! (>= block-height (get end-block-height proposal)) ERR-BLOCK-HEIGHT-NOT-REACHED)

    (map-set proposals
      { id: proposal-id }
      (merge proposal { is-open: false }))

    ;; Execute the proposal when the yes-vote passes threshold-count.
    (and (> yes-votes threshold-count) (try! (execute-proposal proposal-id)))
    (ok true))
)

;; Return votes to voter(member)
;; This function needs to be called for all members
(define-public (return-votes-to-member (token <ft-trait>) (proposal-id uint) (member principal))
  (let 
    (
      (token-count (get amount (get-tokens-by-member-by-id proposal-id member token)))
      (proposal (get-proposal-by-id proposal-id))
    )

    (asserts! (is-token-accepted token) ERR-INVALID-POOL-TOKEN)
    (asserts! (not (get is-open proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (>= block-height (get end-block-height proposal)) ERR-NOT-AUTHORIZED)

    ;; Return the pool token
    (try! (as-contract (contract-call? token transfer token-count (as-contract tx-sender) member none)))
    (ok true)
  )
)

;; Make needed contract changes on DAO
(define-private (execute-proposal (proposal-id uint))
  (let 
    (
      (proposal (get-proposal-by-id proposal-id))
      (new-fee-rate-x (get new-fee-rate-x proposal))
      (new-fee-rate-y (get new-fee-rate-y proposal))
    ) 
  
    (try! (contract-call? .collateral-rebalancing-pool set-fee-rate-x .token-wbtc .token-usda u24000000000 new-fee-rate-x))
    (try! (contract-call? .collateral-rebalancing-pool set-fee-rate-y .token-wbtc .token-usda u24000000000 new-fee-rate-y))
    
    (ok true)
  )
)
