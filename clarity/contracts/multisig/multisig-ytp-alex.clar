(impl-trait .trait-multisig-vote.multisig-vote-sft-trait)
(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)



;; Alex voting for MultiSig DAO
;;
;; Voting and proposing the proposals
;; A proposal will just update the DAO with new contracts.

;; Voting can be done by locking up the corresponding pool token.
;; Common Trait and for each pool, implementation is required.
;;

;; Errors
(define-constant ERR-INVALID-BALANCE (err u1001))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-BLOCK-HEIGHT-NOT-REACHED (err u8003))
(define-constant ERR-NOT-AUTHORIZED (err u1000))

(define-constant ONE_8 u100000000)

(define-data-var contract-owner principal tx-sender)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

;; Proposal variables
;; With Vote, we can set :
;; 1. contract to have right to mint/burn token
;; 2. Set Feerate / Fee address / Collect Fees
(define-map proposals
  { id: uint }
  {
    id: uint,
    proposer: principal,
    expiry: uint,
    title: (string-utf8 256),
    url: (string-utf8 256),
    is-open: bool,
    start-block-height: uint,
    end-block-height: uint,
    yes-votes: uint,
    no-votes: uint,
    new-fee-rate-token: uint,
    new-fee-rate-yield-token: uint
   }
)

(define-data-var proposal-count uint u0)
(define-data-var proposal-ids (list 100 uint) (list u0))
(define-data-var threshold uint u75000000) ;; 75%
(define-data-var proposal-threshold uint u10) ;; 10%
(define-data-var voting-period uint u1440) ;; approx. 10 days

(define-public (set-voting-period (new-voting-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set voting-period new-voting-period))
  )
)
(define-public (set-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set threshold new-threshold))
  )
)
(define-public (set-proposal-threshold (new-proposal-threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set proposal-threshold new-proposal-threshold))
  )
)

(define-data-var total-supply-of-token uint u0)
(define-data-var threshold-percentage uint u0)

(define-map votes-by-member { proposal-id: uint, member: principal } { vote-count: uint })
(define-map tokens-by-member { proposal-id: uint, member: principal, token: principal, expiry: uint } { amount: uint })

;; Get all proposals in detail
;; @desc get-proposals
;; @returns (response optional (tuple))
(define-read-only (get-proposals)
  (ok (map get-proposal-by-id (var-get proposal-ids)))
)

;; Get all proposal ID in list
;; @desc get-proposal-ids
;; @returns (ok list)
(define-read-only (get-proposal-ids)
  (ok (var-get proposal-ids))
)

;; Get votes for a member on proposal
;; @desc get-votes-by-member-by-id
;; @params proposal-id
;; @params member
;; @returns (optional (tuple))
(define-read-only (get-votes-by-member-by-id (proposal-id uint) (member principal))
  (default-to
    { vote-count: u0 }
    (map-get? votes-by-member { proposal-id: proposal-id, member: member })
  )
)

;; @desc get-tokens-by-member-by-id
;; @params proposal-id
;; @params member
;; @params token; sft-trait
;; @params expiry
;; @returns (optional (tuple))
(define-read-only (get-tokens-by-member-by-id (proposal-id uint) (member principal) (token <sft-trait>) (expiry uint))
  (default-to
    { amount: u0 }
    (map-get? tokens-by-member { proposal-id: proposal-id, member: member, token: (contract-of token), expiry: expiry })
  )
)

;; Get proposal
;; @desc get-proposal-by-id
;; @params proposal-id
;; @returns (optional (tuple))
(define-read-only (get-proposal-by-id (proposal-id uint))
  (default-to
    {
      id: u0,
      proposer: (var-get contract-owner),
      expiry: u0,
      title: u"",
      url: u"",
      is-open: false,
      start-block-height: u0,
      end-block-height: u0,
      yes-votes: u0,
      no-votes: u0,
      new-fee-rate-token: u0,    ;; Default token feerate
      new-fee-rate-yield-token: u0  ;; default yield-token feerate
    }
    (map-get? proposals { id: proposal-id })
  )
)

;; To check which tokens are accepted as votes, Only by staking Pool Token is allowed.
;; @desc is-token-accepted
;; @params token; sft-trait
;; @returns bool
(define-read-only (is-token-accepted (token principal))
    (is-eq token .ytp-alex-v1)
)

;; Start a proposal
;; Requires 10% of the supply in your wallet
;; Default voting period is 10 days (144 * 10 blocks)
;; @desc propose
;; @params expiry
;; @params start-block-height
;; @params title
;; @params url
;; @params new-fee-rate-x
;; @params new-fee-rate-y
;; @returns uint
(define-public (propose
    (expiry uint)
    (start-block-height uint)
    (title (string-utf8 256))
    (url (string-utf8 256))
    (new-fee-rate-token uint)
    (new-fee-rate-yield-token uint)
  )
  (let (
    (proposer-balance (unwrap-panic (contract-call? .ytp-alex-v1 get-balance-fixed expiry tx-sender)))
    (total-supply (unwrap-panic (contract-call? .ytp-alex-v1 get-total-supply-fixed expiry)))
    (proposal-id (+ u1 (var-get proposal-count)))
  )

    ;; Requires 10% of the supply
    (asserts! (>= (* proposer-balance (var-get proposal-threshold)) total-supply) ERR-INVALID-BALANCE)
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      {
        id: proposal-id,
        proposer: tx-sender,
        expiry: expiry,
        title: title,
        url: url,
        is-open: true,
        start-block-height: start-block-height,
        end-block-height: (+ start-block-height (var-get voting-period)),
        yes-votes: u0,
        no-votes: u0,
        new-fee-rate-token: new-fee-rate-token,
        new-fee-rate-yield-token: new-fee-rate-yield-token
      }
    )
    (var-set proposal-count proposal-id)
    (var-set proposal-ids (unwrap-panic (as-max-len? (append (var-get proposal-ids) proposal-id) u100)))
    (ok proposal-id)
  )
)

;; @desc vote-for
;; @params token; sft-trait
;; @params proposal-id uint
;; @params amount
;; @returns (response uint)
(define-public (vote-for (token <sft-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (expiry (get expiry proposal))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token expiry)))
  )

    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted (contract-of token)) ERR-INVALID-TOKEN)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) ERR-NOT-AUTHORIZED)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) ERR-NOT-AUTHORIZED)

    ;; Voter should stake the corresponding pool token to the vote contract.
    (try! (contract-call? token transfer-fixed expiry amount tx-sender (as-contract tx-sender)))
    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { yes-votes: (+ amount (get yes-votes proposal)) }))
    (map-set votes-by-member
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ amount vote-count) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token), expiry: expiry }
      { amount: (+ amount token-count)})

    (ok amount)
  )
)

;; @desc vote-against
;; @params token;sft-trait
;; @params proposal-id
;; @params amount
;; @returns (response uint)
(define-public (vote-against (token <sft-trait>) (proposal-id uint) (amount uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (expiry (get expiry proposal))
    (vote-count (get vote-count (get-votes-by-member-by-id proposal-id tx-sender)))
    (token-count (get amount (get-tokens-by-member-by-id proposal-id tx-sender token expiry)))
  )
    ;; Can vote with corresponding pool token
    (asserts! (is-token-accepted (contract-of token)) ERR-INVALID-TOKEN)
    ;; Proposal should be open for voting
    (asserts! (get is-open proposal) ERR-NOT-AUTHORIZED)
    ;; Vote should be casted after the start-block-height
    (asserts! (>= block-height (get start-block-height proposal)) ERR-NOT-AUTHORIZED)
    ;; Voter should stake the corresponding pool token to the vote contract.
    (try! (contract-call? token transfer-fixed expiry amount tx-sender (as-contract tx-sender)))

    ;; Mutate
    (map-set proposals
      { id: proposal-id }
      (merge proposal { no-votes: (+ amount (get no-votes proposal)) }))
    (map-set votes-by-member
      { proposal-id: proposal-id, member: tx-sender }
      { vote-count: (+ amount vote-count) })
    (map-set tokens-by-member
      { proposal-id: proposal-id, member: tx-sender, token: (contract-of token), expiry: expiry }
      { amount: (+ amount token-count)})
    (ok amount)
  )
)

;; @desc end-proposal
;; @params proposal-id
;; @returns (response bool)
(define-public (end-proposal (proposal-id uint))
  (let
    (
      (proposal (get-proposal-by-id proposal-id))
      (expiry (get expiry proposal))
      (threshold-percent (var-get threshold))
      (total-supply (unwrap-panic (contract-call? .ytp-alex-v1 get-total-supply-fixed expiry)))
      (threshold-count (mul-up total-supply threshold-percent))
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
    (ok true)
  )
)

;; Return votes to voter(member)
;; This function needs to be called for all members
;; @desc return-votes-to-member
;; @params token; sft-trait
;; @params proposal-id
;; @params member
;; @returns (response bool)
(define-public (return-votes-to-member (token <sft-trait>) (proposal-id uint) (member principal))
  (let
    (
      (proposal (get-proposal-by-id proposal-id))
      (expiry (get expiry proposal))
      (token-count (/ (get amount (get-tokens-by-member-by-id proposal-id member token expiry)) ONE_8))
    )

    (asserts! (is-token-accepted (contract-of token)) ERR-INVALID-TOKEN)
    (asserts! (not (get is-open proposal)) ERR-NOT-AUTHORIZED)
    (asserts! (>= block-height (get end-block-height proposal)) ERR-NOT-AUTHORIZED)

    ;; Return the pool token
    (as-contract (try! (contract-call? token transfer-fixed expiry token-count (as-contract tx-sender) member)))
    (ok true)
  )
)

;; Make needed contract changes on DAO
;; @desc execute-proposal
;; @params proposal-id
;; @returns (response bool)
(define-private (execute-proposal (proposal-id uint))
  (let (
    (proposal (get-proposal-by-id proposal-id))
    (expiry (get expiry proposal))
    (new-fee-rate-token (get new-fee-rate-token proposal))
    (new-fee-rate-yield-token (get new-fee-rate-yield-token proposal))
  )

    ;; Setting for Yield Token Pool
    (as-contract (try! (contract-call? .yield-token-pool set-fee-rate-token expiry .yield-alex-v1 new-fee-rate-token)))
    (as-contract (try! (contract-call? .yield-token-pool set-fee-rate-yield-token expiry .yield-alex-v1 new-fee-rate-yield-token)))

    (ok true)
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
