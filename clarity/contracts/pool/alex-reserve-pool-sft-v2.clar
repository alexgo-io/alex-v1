(use-trait sft-trait .trait-semi-fungible.semi-fungible-trait)

;; alex-reserve-pool-sft-v2
;; replaces alex-reserve-pool-sft ("v1") to accommodate Nakamoto upgrade
;;
;; 1/ v2 is set to v1's contract owner
;; 2/ before v2 is used, v1's coinbase must be set to zero.
;; 3/ `get-reward-cycle` returns the correct cycle based on the block-height and the activation block of v2 (before => v1, after => v2)
;; 4/ `get-staker-at-cycle` and `get-staking-stats-at-cycle` aggregate across v1 and v2.
;; 5/ new stakes are added to v2.
;; 6/ `claim-staking-reward` calls into v1 and v2 separately, to ensure v1 data is updated post claim

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-USER-ALREADY-REGISTERED (err u10001))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-CONTRACT-NOT-ACTIVATED (err u10005))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-CANNOT-STAKE (err u10016))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-AMOUNT-EXCEED-RESERVE (err u2024))
(define-constant ERR-INVALID-TOKEN (err u2026))

(define-constant ONE_8 u100000000) ;; 8 decimal places
(define-constant MAX_UINT u340282366920938463463374607431768211455)

(define-constant MAX-REWARD-CYCLES u32)
(define-constant REWARD-CYCLE-INDEXES (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31))

(define-data-var contract-owner principal tx-sender)

;; STAKING CONFIGURATION
(define-data-var reward-cycle-length uint u525) ;; number of block-heights per cycle
(define-data-var token-halving-cycle uint u100) ;; number of cycles it takes for token emission to transition to the next

;; activation-block for each stake-able token
(define-map activation-block { token: principal, token-id: uint } uint)

;; token <> coinbase-amounts
(define-map coinbase-amounts { token: principal, token-id: uint } { coinbase-amount-1: uint, coinbase-amount-2: uint, coinbase-amount-3: uint, coinbase-amount-4: uint, coinbase-amount-5: uint })

;; At a given reward cycle, what is the total amount of tokens staked
(define-map staking-stats-at-cycle { token: principal, token-id: uint, reward-cycle: uint } uint)

;; At a given reward cycle and user ID:
;; - what is the total tokens staked?
;; - how many tokens should be returned? (based on staking period)
(define-map staker-at-cycle { token: principal, token-id: uint, reward-cycle: uint, user-id: uint } { amount-staked: uint, to-return: uint })

;; users-nonce for each stake-able token
(define-map users-nonce { token: principal, token-id: uint } uint)

;; store user principal by user id
(define-map users { token: principal, token-id: uint, user-id: uint } principal)
;; store user id by user principal
(define-map user-ids { token: principal, token-id: uint, user: principal } uint)

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))))

(define-public (set-legacy-contract-owner (owner principal))
  (begin 
    (try! (check-is-owner))
    (as-contract (contract-call? .alex-reserve-pool-sft set-contract-owner owner))))

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)))

(define-private (check-is-approved-token (token principal) (token-id uint))
  (ok (asserts! (is-token-approved token token-id) ERR-INVALID-TOKEN)))

;; @desc get-reward-cycle-length
;; @returns uint
(define-read-only (get-reward-cycle-length)
  (var-get reward-cycle-length))

;; @desc set-reward-cycle-length
;; @restricted Contract-Owner
;; @params new-reward-cycle-length
;; @returns (response bool)
(define-public (set-reward-cycle-length (new-reward-cycle-length uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set reward-cycle-length new-reward-cycle-length))))

;; @desc is-token-approved
;; @params token
;; @returns bool
(define-read-only (is-token-approved (token principal) (token-id uint))
  (contract-call? .alex-reserve-pool-sft is-token-approved token token-id))

;; @desc add-token 
;; @params token
;; @returns (response bool)
(define-public (add-token (token principal) (token-id uint))
  (begin
    (try! (check-is-owner))
    (as-contract (contract-call? .alex-reserve-pool-sft add-token token token-id))))

(define-read-only (get-apower-multiplier-in-fixed-or-default (token principal) (token-id uint))
  (contract-call? .alex-reserve-pool-sft get-apower-multiplier-in-fixed-or-default token token-id))

(define-public (set-apower-multiplier-in-fixed (token principal) (token-id uint) (new-apower-multiplier-in-fixed uint))
  (begin
    (try! (check-is-owner))
    (as-contract (contract-call? .alex-reserve-pool-sft set-apower-multiplier-in-fixed token token-id new-apower-multiplier-in-fixed))))

;; @desc get-activation-block-or-default 
;; @params token
;; @returns uint
(define-read-only (get-activation-block-or-default (token principal) (token-id uint))
  (default-to MAX_UINT (map-get? activation-block { token: token, token-id: token-id })))

(define-public (set-activation-block (token principal) (token-id uint) (new-activation-block uint))
  (begin
    (try! (check-is-owner))
    (ok (map-set activation-block { token: token, token-id: token-id } new-activation-block))))

;; returns the total staked tokens for a given reward cycle
;; @desc get-staking-stats-at-cycle 
;; @params token 
;; @params reward-cycle
;; @returns (optional (tuple))
(define-read-only (get-staking-stats-at-cycle (token principal) (token-id uint) (reward-cycle uint))
  (match (contract-call? .alex-reserve-pool-sft get-staking-stats-at-cycle token token-id reward-cycle)
    some-value 
    (match (map-get? staking-stats-at-cycle {token: token, token-id: token-id, reward-cycle: reward-cycle})
      some-value-v2 (some (+ some-value some-value-v2))
      (some some-value))
    none))

;; returns the total staked tokens for a given reward cycle
;; or, zero
;; @desc get-staking-stats-at-cycle-or-default
;; @params token
;; @params reward-cycle
;; @returns uint
(define-read-only (get-staking-stats-at-cycle-or-default (token principal) (token-id uint) (reward-cycle uint))
  (default-to u0 (get-staking-stats-at-cycle token token-id reward-cycle)))

;; @desc get-user-id
;; @params token
;; @params user
;; @returns (some user-id) or none
(define-read-only (get-user-id (token principal) (token-id uint) (user principal))
  (match (map-get? user-ids {token: token, token-id: token-id, user: user})
    some-value (some some-value)
    (contract-call? .alex-reserve-pool-sft get-user-id token token-id user)))
    


;; @desc get-user
;; @params token
;; @params user-id
;; @returns (some user-principal) or none
(define-read-only (get-user (token principal) (token-id uint) (user-id uint))
  (match (map-get? users {token: token, token-id: token-id, user-id: user-id})
    some-value (some some-value)
    (contract-call? .alex-reserve-pool-sft get-user token token-id user-id)))

;; returns (some number of registered users), used for activation and tracking user IDs, or none
;; @desc get-registered-users-nonce 
;; @params token 
;; @returns (optional (tuple))
(define-read-only (get-registered-users-nonce (token principal) (token-id uint))
  (match (map-get? users-nonce {token: token, token-id: token-id})
    some-value (some some-value)
    (contract-call? .alex-reserve-pool-sft get-registered-users-nonce token token-id)))

;; @desc get-registered-users-nonce-or-default 
;; @params token
;; @returns uint
(define-read-only (get-registered-users-nonce-or-default (token principal) (token-id uint))
  (default-to u0 (get-registered-users-nonce token token-id)))

;; returns user ID if it has been created, or creates and returns new ID
;; @desc get-or-create-user-id 
;; @params token 
;; @params user
;; @returns (response bool)/ (optional (tuple))
(define-private (get-or-create-user-id (token principal) (token-id uint) (user principal))
  (match
    (map-get? user-ids {token: token, token-id: token-id, user: user})
    value value
    (let
      (
        (new-id (+ u1 (get-registered-users-nonce-or-default token token-id)))
      )
      (map-insert users {token: token, token-id: token-id, user-id: new-id} user)
      (map-insert user-ids {token: token, token-id: token-id, user: user} new-id)
      (map-set users-nonce {token: token, token-id: token-id} new-id)
      new-id
    )
  )
)

;; @desc get-staker-at-cycle 
;; @params token 
;; @params reward-cycl
;; @params user-id 
;; @returns (optional (tuple))
(define-read-only (get-staker-at-cycle (token principal) (token-id uint) (reward-cycle uint) (user-id uint))
  (match (contract-call? .alex-reserve-pool-sft get-staker-at-cycle token token-id reward-cycle user-id)
    some-value
    (match (map-get? staker-at-cycle { token: token, token-id: token-id, reward-cycle: reward-cycle, user-id: user-id })
      some-value-v2 (some { amount-staked: (+ (get amount-staked some-value) (get amount-staked some-value-v2)), to-return: (+ (get to-return some-value) (get to-return some-value-v2)) })
      (some some-value))
    none))

;; @desc get-staker-at-cycle-or-default 
;; @params token 
;; @params reward-cycle
;; @params user-id
;; @returns (optional (tuple))
(define-read-only (get-staker-at-cycle-or-default (token principal) (token-id uint) (reward-cycle uint) (user-id uint))
  (default-to { amount-staked: u0, to-return: u0 } (get-staker-at-cycle token token-id reward-cycle user-id)))

(define-read-only (get-staker-at-cycle-or-default-v2 (token principal) (token-id uint) (reward-cycle uint) (user-id uint))
  (default-to { amount-staked: u0, to-return: u0 } (map-get? staker-at-cycle { token: token, token-id: token-id, reward-cycle: reward-cycle, user-id: user-id })))

(define-read-only (get-staking-stats-at-cycle-or-default-v2 (token principal) (token-id uint) (reward-cycle uint))
  (default-to u0 (map-get? staking-stats-at-cycle { token: token, token-id: token-id, reward-cycle: reward-cycle })))

;; get the reward cycle for a given Stacks block height
;; @desc get-reward-cycle 
;; @params token 
;; @params stacks-height
;; @returns response
(define-read-only (get-reward-cycle (token principal) (token-id uint) (stacks-height uint))
  (if (< stacks-height (get-activation-block-or-default token token-id))
    (contract-call? .alex-reserve-pool-sft get-reward-cycle token token-id stacks-height)
    (some (+ (/ (- stacks-height (get-activation-block-or-default token token-id)) (var-get reward-cycle-length)) (unwrap-panic (contract-call? .alex-reserve-pool-sft get-reward-cycle token token-id (- (get-activation-block-or-default token token-id) u1))) u1))))

;; determine if staking is active in a given cycle
;; @desc staking-active-at-cycle 
;; @params token 
;; @params reward-cycle
;; @response bool
(define-read-only (staking-active-at-cycle (token principal) (token-id uint) (reward-cycle uint))
  (or
    (contract-call? .alex-reserve-pool-sft staking-active-at-cycle token token-id reward-cycle) 
    (is-some (map-get? staking-stats-at-cycle {token: token, token-id: token-id, reward-cycle: reward-cycle}))))

;; get the first Stacks block height for a given reward cycle.
;; @desc get-first-stacks-block-in-reward-cycle
;; @params token 
;; @params reward-cycle 
;; @returns uint
(define-read-only (get-first-stacks-block-in-reward-cycle (token principal) (token-id uint) (reward-cycle uint))
  (let (
      (first-cycle (unwrap-panic (get-reward-cycle token token-id (get-activation-block-or-default token token-id)))))
    (if (< reward-cycle first-cycle)
      (contract-call? .alex-reserve-pool-sft get-first-stacks-block-in-reward-cycle token token-id reward-cycle)
      (+ (get-activation-block-or-default token token-id) (* (var-get reward-cycle-length) (- reward-cycle first-cycle))))))

;; getter for get-entitled-staking-reward that specifies block height
;; @desc get-staking-reward
;; @params token
;; @params user-id
;; @params target-cycle
;; @returns uint
(define-read-only (get-staking-reward (token principal) (token-id uint) (user-id uint) (target-cycle uint))
  (get-entitled-staking-reward token token-id user-id target-cycle block-height))

;; @desc get-entitled-staking-reward
;; @params token
;; @params user-id
;; @params target-cycle
;; @params stacks-height
;; @returns uint
(define-private (get-entitled-staking-reward (token principal) (token-id uint) (user-id uint) (target-cycle uint) (stacks-height uint))
  (let
    (
      (total-staked-this-cycle (get-staking-stats-at-cycle-or-default token token-id target-cycle))
      (user-staked-this-cycle (get amount-staked (get-staker-at-cycle-or-default token token-id target-cycle user-id)))
    )
    (match (get-reward-cycle token token-id stacks-height)
      current-cycle
      (div-down (mul-down (get-coinbase-amount-or-default token token-id target-cycle) user-staked-this-cycle) total-staked-this-cycle)      
      u0
    )
  )
)

;; STAKING ACTIONS

;; @desc stake-tokens
;; @params token-trait; ft-trait
;; @params amount-token
;; @params lock-period
;; @response (ok response)
(define-public (stake-tokens (token-trait <sft-trait>) (token-id uint) (amount-token uint) (lock-period uint))
  (begin
    (try! (check-is-approved-token (contract-of token-trait) token-id))
    (stake-tokens-at-cycle token-trait token-id tx-sender (get-or-create-user-id (contract-of token-trait) token-id tx-sender) amount-token block-height lock-period)
  )
)

;; @desc stake-tokens-at-cycle
;; @params token-trait; ft-trait
;; @params user
;; @params user-id
;; @params amount-token
;; @params start-height 
;; @params lock-period
;; @returns (ok response)
(define-private (stake-tokens-at-cycle (token-trait <sft-trait>) (token-id uint) (user principal) (user-id uint) (amount-token uint) (start-height uint) (lock-period uint))
  (let
    (
      (token (contract-of token-trait))
      (current-cycle (unwrap! (get-reward-cycle token token-id start-height) ERR-STAKING-NOT-AVAILABLE))
      (target-cycle (+ u1 current-cycle))
      (commitment {
        token: token,
        token-id: token-id,
        staker-id: user-id,
        amount: amount-token,
        first: target-cycle,
        last: (+ target-cycle lock-period)
      })
    )   
    (try! (check-is-approved-token (contract-of token-trait) token-id)) 
    (asserts! (>= block-height (get-activation-block-or-default token token-id)) ERR-CONTRACT-NOT-ACTIVATED)
    (asserts! (and (> lock-period u0) (<= lock-period MAX-REWARD-CYCLES)) ERR-CANNOT-STAKE)
    (asserts! (> amount-token u0) ERR-CANNOT-STAKE)
    (unwrap! (contract-call? token-trait transfer-fixed token-id amount-token tx-sender .alex-vault-v1-1) ERR-TRANSFER-FAILED)
    (try! (fold stake-tokens-closure REWARD-CYCLE-INDEXES (ok commitment)))
    (ok true)
  )
)

;; @desc stake-tokens-closure
;; @params reward-cycle-idx
;; @returns bool/error
(define-private (stake-tokens-closure (reward-cycle-idx uint)
  (commitment-response (response 
    {
      token: principal,
      token-id: uint,
      staker-id: uint,
      amount: uint,
      first: uint,
      last: uint
    }
    uint
  )))

  (match commitment-response
    commitment 
    (let
      (
        (token (get token commitment))
        (token-id (get token-id commitment))
        (staker-id (get staker-id commitment))
        (amount-token (get amount commitment))
        (first-cycle (get first commitment))
        (last-cycle (get last commitment))
        (target-cycle (+ first-cycle reward-cycle-idx))
      )
      (begin
        (if (and (>= target-cycle first-cycle) (< target-cycle last-cycle))
          (begin 
            (if (is-eq target-cycle (- last-cycle u1))
              (set-tokens-staked token token-id staker-id target-cycle amount-token amount-token)
              (set-tokens-staked token token-id staker-id target-cycle amount-token u0)
            )
            true
          )
          false
        )
        commitment-response
      )
    )
    err-value commitment-response
  )
)

;; @desc set-tokens-staked
;; @params token
;; @params user-id
;; @params target-cycle
;; @params amount-staked
;; @params to-return
;; @returns (response bool)
(define-private (set-tokens-staked (token principal) (token-id uint) (user-id uint) (target-cycle uint) (amount-staked uint) (to-return uint))
  (let
    (
      (this-staker-at-cycle (get-staker-at-cycle-or-default-v2 token token-id target-cycle user-id))
    )
    (map-set staking-stats-at-cycle {token: token, token-id: token-id, reward-cycle: target-cycle} (+ amount-staked (get-staking-stats-at-cycle-or-default-v2 token token-id target-cycle)))
    (map-set staker-at-cycle
      {
        token: token,
        token-id: token-id,
        reward-cycle: target-cycle,
        user-id: user-id
      }
      {
        amount-staked: (+ amount-staked (get amount-staked this-staker-at-cycle)),
        to-return: (+ to-return (get to-return this-staker-at-cycle))
      }
    )
  )
)

;; STAKING REWARD CLAIMS

;; calls function to claim staking reward in active logic contract
;; @desc claim-staking-reward
;; @params token-trait; ft-trait
;; @params target-cycle
;; @returns (response tuple)
(define-public (claim-staking-reward (token-trait <sft-trait>) (token-id uint) (target-cycle uint))
  (begin
    (try! (check-is-approved-token (contract-of token-trait) token-id))
    (asserts! (is-eq u0 (contract-call? .alex-reserve-pool-sft get-coinbase-amount-or-default (contract-of token-trait) token-id target-cycle)) ERR-CONTRACT-NOT-ACTIVATED)
    (try! (contract-call? .alex-reserve-pool-sft claim-staking-reward token-trait token-id target-cycle))
    (claim-staking-reward-at-cycle token-trait token-id tx-sender block-height target-cycle)
  )
)

;; @desc claim-staking-reward-at-cycle
;; @params token-trait; ft-trait
;; @params user
;; @params stacks-height
;; @params target-cycle
;; @returns (response tuple)
(define-private (claim-staking-reward-at-cycle (token-trait <sft-trait>) (token-id uint) (user principal) (stacks-height uint) (target-cycle uint))
  (let
    (
      (token (contract-of token-trait))
      (current-cycle (unwrap! (get-reward-cycle token token-id stacks-height) ERR-STAKING-NOT-AVAILABLE))
      (user-id (unwrap! (get-user-id token token-id user) ERR-USER-ID-NOT-FOUND))
      (entitled-token (get-entitled-staking-reward token token-id user-id target-cycle stacks-height))
      (to-return (get to-return (get-staker-at-cycle-or-default-v2 token token-id target-cycle user-id)))
    )
    (try! (check-is-approved-token (contract-of token-trait) token-id))
    (asserts! (> current-cycle target-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    ;; disable ability to claim again
    (map-set staker-at-cycle
      {
        token: token,
        token-id: token-id,
        reward-cycle: target-cycle,
        user-id: user-id
      }
      {
        amount-staked: u0,
        to-return: u0
      }
    )
    ;; send back tokens if user was eligible
    (and (> to-return u0) (as-contract (try! (contract-call? .alex-vault-v1-1 transfer-sft token-trait token-id to-return user))))
    ;; send back rewards if user was eligible
    (and (> entitled-token u0) (as-contract (try! (contract-call? .age000-governance-token mint-fixed entitled-token user))))
    (and 
      (> entitled-token u0) 
      (> (get-apower-multiplier-in-fixed-or-default token token-id) u0) 
      (as-contract (try! (contract-call? .token-apower mint-fixed (mul-down entitled-token (get-apower-multiplier-in-fixed-or-default token token-id)) user)))
    )
    (ok { to-return: to-return, entitled-token: entitled-token })
  )
)

;; @desc get-token-halving-cycle
;; @returns uint
(define-read-only (get-token-halving-cycle)
  (var-get token-halving-cycle)
)

;; @desc set-token-halving-cycle
;; @params new-token-halving-cycle
;; @returns (response bool)
(define-public (set-token-halving-cycle (new-token-halving-cycle uint))
  (begin
    (try! (check-is-owner))
    (var-set token-halving-cycle new-token-halving-cycle)    
    (ok (set-coinbase-thresholds))))

;; store block height at each halving, set by register-user in core contract
(define-data-var coinbase-threshold-1 uint (var-get token-halving-cycle))
(define-data-var coinbase-threshold-2 uint (* u2 (var-get token-halving-cycle)))
(define-data-var coinbase-threshold-3 uint (* u3 (var-get token-halving-cycle)))
(define-data-var coinbase-threshold-4 uint (* u4 (var-get token-halving-cycle)))
(define-data-var coinbase-threshold-5 uint (* u5 (var-get token-halving-cycle)))

;; @desc set-coinbase-thresholds
;; @returns (response bool)
(define-private (set-coinbase-thresholds)
  (begin
    (var-set coinbase-threshold-1 (var-get token-halving-cycle))
    (var-set coinbase-threshold-2 (* u2 (var-get token-halving-cycle)))
    (var-set coinbase-threshold-3 (* u3 (var-get token-halving-cycle)))
    (var-set coinbase-threshold-4 (* u4 (var-get token-halving-cycle)))
    (var-set coinbase-threshold-5 (* u5 (var-get token-halving-cycle)))
  )
)

;; return coinbase thresholds if contract activated
;; @desc get-coinbase-thresholds
;; @returns (response tuple)
(define-read-only (get-coinbase-thresholds)
  (ok {
      coinbase-threshold-1: (var-get coinbase-threshold-1),
      coinbase-threshold-2: (var-get coinbase-threshold-2),
      coinbase-threshold-3: (var-get coinbase-threshold-3),
      coinbase-threshold-4: (var-get coinbase-threshold-4),
      coinbase-threshold-5: (var-get coinbase-threshold-5)
  })
)

;; @desc set-coinbase-amount
;; @restricted Contract-Owner
;; @params token
;; @params coinbase-1
;; @params coinbase-2
;; @params coinbase-3
;; @params coinbase-4
;; @params coinbase-5
;; @returns (response bool)
(define-public (set-coinbase-amount (token principal) (token-id uint) (coinbase-1 uint) (coinbase-2 uint) (coinbase-3 uint) (coinbase-4 uint) (coinbase-5 uint))
  (begin
    (try! (check-is-owner))
      (map-set coinbase-amounts 
        { token: token, token-id: token-id }
        { coinbase-amount-1: coinbase-1, coinbase-amount-2: coinbase-2, coinbase-amount-3: coinbase-3, coinbase-amount-4: coinbase-4, coinbase-amount-5: coinbase-5 })
      (ok true)))

(define-public (set-legacy-coinbase-amount (token principal) (token-id uint) (coinbase-1 uint) (coinbase-2 uint) (coinbase-3 uint) (coinbase-4 uint) (coinbase-5 uint))
  (begin 
    (try! (check-is-owner))
    (as-contract (contract-call? .alex-reserve-pool-sft set-coinbase-amount token token-id coinbase-1 coinbase-2 coinbase-3 coinbase-4 coinbase-5))))  

;; function for deciding how many tokens to mint, depending on when they were mined
;; @desc get-coinbase-amount-or-default
;; @params token
;; @params reward-cycle
;; @returns uint
(define-read-only (get-coinbase-amount-or-default (token principal) (token-id uint) (reward-cycle uint))
  (let
    (
      (coinbase 
        (default-to 
          {
            coinbase-amount-1: u0,
            coinbase-amount-2: u0,
            coinbase-amount-3: u0,
            coinbase-amount-4: u0,
            coinbase-amount-5: u0
          } 
          (map-get? coinbase-amounts 
            {
              token: token,
              token-id: token-id 
            }
          ))
      )
    )
    ;; computations based on each halving threshold
    (asserts! (> reward-cycle (var-get coinbase-threshold-1)) (get coinbase-amount-1 coinbase))
    (asserts! (> reward-cycle (var-get coinbase-threshold-2)) (get coinbase-amount-2 coinbase))
    (asserts! (> reward-cycle (var-get coinbase-threshold-3)) (get coinbase-amount-3 coinbase))
    (asserts! (> reward-cycle (var-get coinbase-threshold-4)) (get coinbase-amount-4 coinbase))
    (asserts! (> reward-cycle (var-get coinbase-threshold-5)) (get coinbase-amount-5 coinbase))
    ;; default value after 5th halving
    u0
  )
)

;; @desc mul-down
;; @params a
;; @params b
;; @returns uint
(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

;; @desc div-down
;; @params a
;; @params b
;; @returns uint
(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)
