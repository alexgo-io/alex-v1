(impl-trait .trait-multisig-vote.multisig-vote-trait)
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
(define-constant ERR-NOT-ENOUGH-BALANCE (err u8000))
(define-constant ERR-NO-FEE-CHANGE (err u8001))
(define-constant ERR-INVALID-POOL-TOKEN (err u8002))
(define-constant ERR-BLOCK-HEIGHT-NOT-REACHED (err u8003))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-MATH-CALL (err u2010))
(define-constant ERR-COLLECT-FEE (err u8004))
(define-constant ERR-TRANSFER-X-FAILED (err u3001))

(define-constant ONE_8 u100000000)

;; Constants
(define-constant DEFAULT_OWNER tx-sender)

(define-constant NOW-COLLECTING false)

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
    new-fee-rate-token: uint,
    new-fee-rate-aytoken: uint
   }
)

(define-map collect-round
  { id: uint }
  {
    is-open: bool, 
  }
)

(define-data-var collect-round-count uint u0)

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
      new-fee-rate-token: u0,    ;; Default token feerate
      new-fee-rate-aytoken: u0  ;; default aytoken feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; Get collect-round information
(define-read-only (get-collect-round-by-id (collect-id uint))
  (default-to
    {
      is-open : false
    }
    (map-get? collect-round { id: collect-id })
  )
)


;; To check which tokens are accepted as votes, Only by staking Pool Token is allowed. 
(define-read-only (is-token-accepted (token <ft-trait>))
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
        new-fee-rate-token: new-fee-rate-token,
        new-fee-rate-aytoken: new-fee-rate-aytoken
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
        (total-supply (* (unwrap-panic (contract-call? .ytp-yield-wbtc-79760-wbtc get-total-supply)) ONE_8))
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
    (and (> yes-votes threshold-count) (try! (execute-proposal proposal-id token aytoken)))
    (ok true))
)

;; Return votes to voter(member)
;; This function needs to be called for all members
(define-public (return-votes-to-member (token <ft-trait>) (proposal-id uint) (member principal))
  (let 
    (
      (token-count (/ (get amount (get-tokens-by-member-by-id proposal-id member token)) ONE_8))
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
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (new-fee-rate-token (get new-fee-rate-token proposal))
    (new-fee-rate-aytoken (get new-fee-rate-aytoken proposal))
  ) 
  
    ;; Setting for Yield Token Pool
    (try! (contract-call? .yield-token-pool set-fee-rate-token .yield-wbtc-79760 new-fee-rate-token))
    (try! (contract-call? .yield-token-pool set-fee-rate-aytoken .yield-wbtc-79760 new-fee-rate-aytoken))
    
    (ok true)
  )
)

;; Multisig can collect fee anytime. 
;; After executing this function, Multisig needs to have gAlex, which is for rebate to pool token holders.
;; Users can receive their rebate gAlex Tokens by calling retreive-rebate function
(define-public (collect-fees)
  (let (
    (collect-id (+ u1 (var-get collect-round-count)))
  ) 

    ;; Assure that Collecting is not currently happening
    (asserts! (is-eq (var-get NOW-COLLECTING) false))

    ;; Initialize a new fee collecting round
    (map-set collect-round { id: collect-id } { is-open : true } )
    
    ;; Execute Collect Fee function in pool
    (asserts! (contract-call? .yield-token-pool collect-fees .yield-wbtc-79760 .token-wbtc) ERR-COLLECT-FEE)
    
    ;; Currently accumulated gAlex tokens
    (total-collected-galex (* (unwrap-panic (contract-call? .token-alex get-balance (as-contract tx-sender))) ONE_8))
    
    ;; Set the flag so only one collecting round can happen
    (var-set NOW-COLLECTING true)

    (ok total-collected-galex)
  )
)

;; Users use this retreive-rebate funtion to retreive rebate using pool-token.
;; parameter : (token : pool-token , amount : amount of user holding pool token , collect-id : current collection round)
(define-public (retreive-rebate (token <ft-trait>) (amount uint) (collect-id uint))
  (let (

    (collect-round (get-collect-round-by-id collect-id))
    ;; Total supply of pool token
    (total-supply (* (unwrap-panic (contract-call? .ytp-yield-wbtc-79760-wbtc get-total-supply)) ONE_8))
    ;; Calculate how much percentage of pool token does user has 
    (user-percentage (unwrap-panic (contract-call? .math-fixed-point div-down amount total-supply)))
    ;; Get the balance of gAlex token which is owned by Multisig
    (rebated-galex (* (unwrap-panic (contract-call? .token-alex get-balance (as-contract tx-sender))) ONE_8))
    ;; Calculate how much user shall receive
    (users-rebate (unwrap-panic (contract-call? .math-fixed-point mul-down rebated-galex user-percentage)))
  ) 
    ;; Check whether the collect round is open
    (asserts! (get is-open collect-round) ERR-NOT-AUTHORIZED)

    ;; Check whether it is valid pool token
    (asserts! (is-token-accepted token) ERR-INVALID-POOL-TOKEN)

    ;; Check user's pool token amount is valid (Lock)
    (unwrap! (contract-call? token transfer amount tx-sender .alex-vault none) ERR-TRANSFER-X-FAILED)

    ;; User receives gAlex rebate
    (unwrap! (contract-call? .token-alex transfer users-rebate (as-contract tx-sender) tx-sender none) ERR-TRANSFER-X-FAILED)
    
    ;; Return user's pool token amount after verification (Unlock)
    (unwrap! (contract-call? token transfer amount .alex-vault tx-sender none) ERR-TRANSFER-X-FAILED)

    ;; If all pool-token holders finished retreiving, close the colleting round 
    (and 
        (is-eq (unwrap-panic (contract-call? .token-alex get-balance (as-contract tx-sender)) ONE_8) u0) 
    
        (and (map-set collect-round { id: collect-id } { is-open : false }) (var-set NOW-COLLECTING false))
    )
    
    (ok users-rebate)
  )
)
