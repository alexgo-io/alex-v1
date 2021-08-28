;;(impl-trait .trait-multisig-vote.multisig-vote-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; This CRP MultiSig is for 
;; - CRP that mines yield-usda-4380 and key-usda-wbtc-4380
;; - Q : On the future, I think helper function which can manage different expiry should be implemented. Any idea on it ? 

;; Errors
(define-constant not-enough-balance-err (err u8000))
(define-constant no-contract-changes-err (err u8001))
(define-constant invalid-vote-token (err u8005))
(define-constant block-height-not-reached (err u8003))
(define-constant authorisation-err (err u1000))
(define-constant status-ok u10000)
(define-constant get-expiry-fail-err (err u2013))

(define-constant ONE_8 u100000000)

;; Constants
(define-constant DEFAULT_OWNER tx-sender)

;; Proposal variables
;; With Vote, we can set :
;; 1. Set Feerate / Collect Fees 
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
    new-fee-rate-collateral: uint,
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

(define-read-only (get-tokens-by-member-by-id (proposal-id uint) (member principal) (vote-token <yield-token-trait>))
  (default-to 
    { amount: u0 }
    (map-get? tokens-by-member { proposal-id: proposal-id, member: member, token: (contract-of vote-token) }) 
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
      fee-collector: .alex-crp-multisig-vote,   ;; Fee Collecting is done by multisig. 
      new-fee-rate-token: u0,    ;; Default token feerate
      new-fee-rate-collateral: u0  ;; default key-token feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; To check which tokens are accepted as votes,
;; Only relevant Yield Token and Key Token can be regarded as vote. 
;; Q. But Should each vote treated equally ?
(define-read-only (is-token-accepted (vote-token <yield-token-trait>))
    (or (is-eq (contract-of vote-token) .yield-usda-4380) (is-eq (contract-of vote-token) .key-usda-wbtc-4380))
)


;; Start a proposal
;; Requires 10% of the supply in your wallet
;; Default voting period is 10 days (144 * 10 blocks)
(define-public (propose
    (start-block-height uint)
    (title (string-utf8 256))
    (url (string-utf8 256))
    (new-fee-rate-token uint)
    (new-fee-rate-collateral uint)
  )
  (let (
    (proposer-yield-balance (unwrap-panic (contract-call? .yield-usda-4380 get-balance tx-sender)))
    (proposer-key-balance (unwrap-panic (contract-call? .key-usda-wbtc-4380 get-balance tx-sender)))
    (total-yield-supply (unwrap-panic (contract-call? .yield-usda-4380 get-total-supply)))
    (total-key-supply (unwrap-panic (contract-call? .key-usda-wbtc-4380 get-total-supply)))
    (proposal-id (+ u1 (var-get proposal-count)))
  )

    ;; Requires 10% of the supply 
    ;; Q. For Now, proposer should have both 10% of yield and key. Discussion is Required. 
    (asserts! (or (>= (* proposer-yield-balance u10) total-yield-supply) (>= (* proposer-key-balance u10) total-key-supply)) not-enough-balance-err)
    ;;(asserts! (>= (* proposer-key-balance u10) total-key-supply) not-enough-balance-err)
    
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
        fee-collector: .alex-crp-multisig-vote,
        new-fee-rate-token: new-fee-rate-token,
        new-fee-rate-collateral: new-fee-rate-collateral
      }
    )
    (var-set proposal-count proposal-id)
    (var-set proposal-ids (unwrap-panic (as-max-len? (append (var-get proposal-ids) proposal-id) u100)))
    (ok true)
  )
)

(define-public (vote-for (vote-token <yield-token-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender vote-token)))
    
  )

    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted vote-token) invalid-vote-token)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) authorisation-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) authorisation-err)
    
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? vote-token transfer amount tx-sender (as-contract tx-sender) none))
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { yes-votes: (+ amount (get yes-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ vote-count amount) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of vote-token) }
      { amount: (+ token-count amount) })

    (ok status-ok)
    
    )
  )




(define-public (vote-against (vote-token <yield-token-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender vote-token)))
  )
    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted vote-token) invalid-vote-token)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) authorisation-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) authorisation-err)
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? vote-token transfer amount tx-sender (as-contract tx-sender) none))

    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { no-votes: (+ amount (get no-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ vote-count amount) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of vote-token) }
      { amount: (+ token-count amount) })
    (ok status-ok)
    )    
)

(define-public (end-proposal (proposal-id uint) (token <ft-trait>) (collateral <ft-trait>) (yield-token <yield-token-trait>) (key-token <yield-token-trait>))
  (let ((proposal (get-proposal-by-id proposal-id))
        (threshold-percent (var-get threshold))
        (total-yield-supply (unwrap-panic (contract-call? .yield-usda-4380 get-total-supply)))
        (total-key-supply (unwrap-panic (contract-call? .key-usda-wbtc-4380 get-total-supply)))
        (total-yield-key (+ total-yield-supply total-key-supply))
        (threshold-count (unwrap-panic (contract-call? .math-fixed-point mul-up total-yield-key threshold-percent)))
        (yes-votes (unwrap-panic (contract-call? .math-fixed-point mul-down (get yes-votes proposal) ONE_8)))
  )

    (asserts! (not (is-eq (get id proposal) u0)) authorisation-err)  
    (asserts! (get is-open proposal) authorisation-err)
    (asserts! (>= block-height (get end-block-height proposal)) block-height-not-reached)

    (map-set proposals
      { id: proposal-id }
      (merge proposal { is-open: false }))

    ;; Execute the proposal when the yes-vote passes threshold-count.
    (and (> yes-votes threshold-count) (try! (execute-proposal proposal-id token collateral yield-token key-token)))
    (ok status-ok))
)

;; Return votes to voter(member)
;; This function needs to be called for all members
(define-public (return-votes-to-member (token <yield-token-trait>) (proposal-id uint) (member principal))
  (let (
    (token-count (get amount (get-tokens-by-member-by-id proposal-id member token)))
    (proposal (get-proposal-by-id proposal-id))
  )

    (asserts! (is-token-accepted token) invalid-vote-token)
    (asserts! (not (get is-open proposal)) authorisation-err)
    (asserts! (>= block-height (get end-block-height proposal)) authorisation-err)

    ;; Return the pool token
    (as-contract (contract-call? token transfer token-count (as-contract tx-sender) member none))
  )
)

;; Make needed contract changes on DAO
(define-private (execute-proposal (proposal-id uint) (token <ft-trait>) (collateral <ft-trait>) (yield-token <yield-token-trait>) (key-token <yield-token-trait>))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (new-fee-rate-token (get new-fee-rate-token proposal))
    (new-fee-rate-collateral (get new-fee-rate-collateral proposal))
    (token-expiry (unwrap! (contract-call? yield-token get-expiry) get-expiry-fail-err))
  ) 
  
    ;; Setting for Collateral Rebalancing Pool
    (try! (contract-call? .collateral-rebalancing-pool set-fee-rate-x token collateral token-expiry new-fee-rate-token))
    (try! (contract-call? .collateral-rebalancing-pool set-fee-rate-y token collateral token-expiry new-fee-rate-collateral))
    
    (ok true)
  )
)
