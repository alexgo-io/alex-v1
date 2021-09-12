;;(impl-trait .trait-multisig-vote.multisig-vote-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
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
(define-constant not-enough-balance-err (err u8000))
(define-constant no-contract-changes-err (err u8001))
(define-constant invalid-pool-token (err u8002))
(define-constant block-height-not-reached (err u8003))
(define-constant not-authorized-err (err u1000))
(define-constant status-ok u10000)
(define-constant math-call-err (err u2010))

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
    fee-collector: principal,
    new-fee-rate-token: uint,
    new-fee-rate-aytoken: uint
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

(define-read-only (get-tokens-by-member-by-id (proposal-id uint) (member principal) (token <yield-token-trait>))
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
      fee-collector: .alex-ytp-multisig-vote,
      new-fee-rate-token: u0,    ;; Default token feerate
      new-fee-rate-aytoken: u0  ;; default aytoken feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; To check which tokens are accepted as votes, Only by staking Pool Token is allowed. 
(define-read-only (is-token-accepted (token <yield-token-trait>))
    (is-eq (contract-of token) .ytp-yield-wbtc-79760-wbtc)
)


;; Start a proposal
;; Requires 10% of the supply in your wallet
;; Default voting period is 10 days (144 * 10 blocks)
(define-public (propose
    (start-block-height uint)
    (title (string-utf8 256))
    (url (string-utf8 256))
    (new-fee-rate-token uint)
    (new-fee-rate-aytoken uint)
  )
  (let (
    (proposer-balance (* (unwrap-panic (contract-call? .ytp-yield-wbtc-79760-wbtc get-balance tx-sender)) ONE_8))
    (total-supply (* (unwrap-panic (contract-call? .ytp-yield-wbtc-79760-wbtc get-total-supply)) ONE_8))
    (proposal-id (+ u1 (var-get proposal-count)))
  )

    ;; Requires 10% of the supply 
    (asserts! (>= (* proposer-balance u10) total-supply) not-enough-balance-err)
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
        fee-collector: .alex-ytp-multisig-vote,
        new-fee-rate-token: new-fee-rate-token,
        new-fee-rate-aytoken: new-fee-rate-aytoken
      }
    )
    (var-set proposal-count proposal-id)
    (var-set proposal-ids (unwrap-panic (as-max-len? (append (var-get proposal-ids) proposal-id) u100)))
    (ok true)
  )
)

(define-public (vote-for (token <yield-token-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token)))
    
  )

    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted token) invalid-pool-token)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) not-authorized-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) not-authorized-err)
    
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { yes-votes: (unwrap! (contract-call? .math-fixed-point add-fixed amount (get yes-votes proposal)) math-call-err) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (unwrap! (contract-call? .math-fixed-point add-fixed amount vote-count) math-call-err) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (unwrap! (contract-call? .math-fixed-point add-fixed amount token-count) math-call-err) })


    (ok status-ok)
    
    )
  )




(define-public (vote-against (token <yield-token-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token)))
  )
    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted token) invalid-pool-token)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) not-authorized-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) not-authorized-err)
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))

    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { no-votes: (unwrap! (contract-call? .math-fixed-point add-fixed amount (get no-votes proposal)) math-call-err) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (unwrap! (contract-call? .math-fixed-point add-fixed amount vote-count) math-call-err) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (unwrap! (contract-call? .math-fixed-point add-fixed amount token-count) math-call-err) })
    (ok status-ok)
    )
    
    )

(define-public (end-proposal (proposal-id uint) (token <yield-token-trait>) (aytoken <yield-token-trait>))
  (let ((proposal (get-proposal-by-id proposal-id))
        (threshold-percent (var-get threshold))
        (total-supply (* (unwrap-panic (contract-call? .ytp-yield-wbtc-79760-wbtc get-total-supply)) ONE_8))
        (threshold-count (unwrap-panic (contract-call? .math-fixed-point mul-up total-supply threshold-percent)))
        (yes-votes (* (get yes-votes proposal) ONE_8))
  )

    (asserts! (not (is-eq (get id proposal) u0)) not-authorized-err)  ;; Default id
    (asserts! (get is-open proposal) not-authorized-err)
    (asserts! (>= block-height (get end-block-height proposal)) block-height-not-reached)

    (map-set proposals
      { id: proposal-id }
      (merge proposal { is-open: false }))

    ;; Execute the proposal when the yes-vote passes threshold-count.
    (and (> yes-votes threshold-count) (try! (execute-proposal proposal-id token aytoken)))
    (ok status-ok))
)

;; Return votes to voter(member)
;; This function needs to be called for all members
(define-public (return-votes-to-member (token <yield-token-trait>) (proposal-id uint) (member principal))
  (let (
    (token-count (/ (get amount (get-tokens-by-member-by-id proposal-id member token)) ONE_8)
    (proposal (get-proposal-by-id proposal-id))
  )

    (asserts! (is-token-accepted token) invalid-pool-token)
    (asserts! (not (get is-open proposal)) not-authorized-err)
    (asserts! (>= block-height (get end-block-height proposal)) not-authorized-err)

    ;; Return the pool token
    (as-contract (contract-call? token transfer token-count (as-contract tx-sender) member none))
  )
)

;; Make needed contract changes on DAO
(define-private (execute-proposal (proposal-id uint) (token <yield-token-trait>) (aytoken <yield-token-trait>))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (new-fee-rate-token (get new-fee-rate-token proposal))
    (new-fee-rate-aytoken (get new-fee-rate-aytoken proposal))
  ) 
  
    ;; Setting for Yield Token Pool
    (try! (contract-call? .yield-token-pool set-fee-rate-token token new-fee-rate-token))
    (try! (contract-call? .yield-token-pool set-fee-rate-aytoken aytoken new-fee-rate-aytoken))
    
    (ok true)
  )
)
