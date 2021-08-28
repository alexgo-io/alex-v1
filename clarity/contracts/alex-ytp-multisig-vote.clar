;;(impl-trait .trait-multisig-vote.multisig-vote-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)
(use-trait ft-token .trait-sip-010.sip-010-trait)


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
(define-constant authorisation-err (err u1000))
(define-constant status-ok u10000)

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
    new-fee-rate-aytoken: uint,
    contract-changes: (list 10 (tuple (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool)))
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
      contract-changes: (list { name: "", address: DEFAULT_OWNER, qualified-name: DEFAULT_OWNER, can-mint: false, can-burn: false} ),
      fee-collector: DEFAULT_OWNER,
      new-fee-rate-token: u0,    ;; Default token feerate
      new-fee-rate-aytoken: u0  ;; default aytoken feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; To check which tokens are accepted as votes, Only by staking Pool Token is allowed. 
(define-read-only (is-token-accepted (token <yield-token-trait>))
    (is-eq (contract-of token) .pool-token-usda-ayusda)
)


;; Start a proposal
;; Requires 10% of the supply in your wallet
;; Default voting period is 10 days (144 * 10 blocks)
(define-public (propose
    (start-block-height uint)
    (title (string-utf8 256))
    (url (string-utf8 256))
    (contract-changes (list 10 (tuple (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool))))
    (fee-collector principal)
    (new-fee-rate-token uint)
    (new-fee-rate-aytoken uint)
  )
  (let (
    (proposer-balance (unwrap-panic (contract-call? .pool-token-usda-ayusda get-balance tx-sender)))
    (total-supply (unwrap-panic (contract-call? .pool-token-usda-ayusda get-total-supply)))
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
        contract-changes: contract-changes,
        fee-collector: fee-collector,
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
    (asserts! (get is-open proposal) authorisation-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) authorisation-err)
    
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { yes-votes: (+ amount (get yes-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ vote-count amount) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (+ token-count amount) })

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
    (asserts! (get is-open proposal) authorisation-err)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) authorisation-err)
    ;; Voter should stake the corresponding pool token to the vote contract. 
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))

    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { no-votes: (+ amount (get no-votes proposal)) }))
    (map-set votes-by-member 
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ vote-count amount) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token) }
      { amount: (+ token-count amount) })
    (ok status-ok)
    )
    
    )

(define-public (end-proposal (proposal-id uint) (token <yield-token-trait>) (aytoken <yield-token-trait>))
  (let ((proposal (get-proposal-by-id proposal-id))
        (threshold-percent (var-get threshold))
        (total-supply (unwrap-panic (contract-call? .pool-token-usda-ayusda get-total-supply)))
        (threshold-count (unwrap-panic (contract-call? .math-fixed-point mul-up total-supply threshold-percent)))
        (yes-votes (unwrap-panic (contract-call? .math-fixed-point mul-down (get yes-votes proposal) ONE_8)))
  )

    (asserts! (not (is-eq (get id proposal) u0)) authorisation-err)  ;; Default id
    (asserts! (get is-open proposal) authorisation-err)
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
    (token-count (get amount (get-tokens-by-member-by-id proposal-id member token)))
    (proposal (get-proposal-by-id proposal-id))
  )

    (asserts! (is-token-accepted token) invalid-pool-token)
    (asserts! (not (get is-open proposal)) authorisation-err)
    (asserts! (>= block-height (get end-block-height proposal)) authorisation-err)

    ;; Return the pool token
    (as-contract (contract-call? token transfer token-count (as-contract tx-sender) member none))
  )
)

;; Make needed contract changes on DAO
(define-private (execute-proposal (proposal-id uint) (token <yield-token-trait>) (aytoken <yield-token-trait>))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (contract-changes (get contract-changes proposal))
    (new-fee-rate-token (get new-fee-rate-token proposal))
    (new-fee-rate-aytoken (get new-fee-rate-aytoken proposal))
    (collector-address (get fee-collector proposal))
  ) 
  
    ;; Setting for Yield Token Pool
    (try! (contract-call? .yield-token-pool set-fee-rate-token aytoken new-fee-rate-token))
    (try! (contract-call? .yield-token-pool set-fee-rate-aytoken aytoken new-fee-rate-aytoken))
    (try! (contract-call? .yield-token-pool set-fee-to-address aytoken collector-address))
    
    (if (> (len contract-changes) u0)
      (begin
        (map execute-proposal-change-contract contract-changes)
        (ok true)
      )
      no-contract-changes-err
    )
    ;; (and (> (len contract-changes) u0) (try! (map execute-proposal-change-contract contract-changes)))
    ;; (ok true)
    ;; no-contract-changes-err
  )
)

;; Helper to execute proposal and change contracts
(define-private (execute-proposal-change-contract (change (tuple (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool))))
  (let (
    (name (get name change))
    (address (get address change))
    (qualified-name (get qualified-name change))
    (can-mint (get can-mint change))
    (can-burn (get can-burn change))
  )
    (if (not (is-eq name ""))
      (begin
        (try! (contract-call? .alex-multisig-registry set-contract-address name address qualified-name can-mint can-burn))
        (ok true)
      )
      (ok false)
    )
  )
)

;; adds a new contract, only new ones allowed
;; Things to be discussed
(define-public (add-contract-address (name (string-ascii 256)) (address principal) (qualified-name principal) (can-mint bool) (can-burn bool))
  (begin
    ;; Who can add the contract to the registry
    ;;(asserts! (is-eq tx-sender (contract-call? .alex-multisig-dao get-dao-owner)) (err authorisation-err))

    (if (is-some (contract-call? .alex-multisig-registry get-contract-address-by-name name))
      (ok false)
      (begin
        (try! (contract-call? .alex-multisig-registry set-contract-address name address qualified-name can-mint can-burn))
        (ok true)
      )
    )
  )
)