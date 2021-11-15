(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait yield-token-trait .trait-yield-token.yield-token-trait)

;; alex-reserve-pool

(define-constant ERR-INVALID-POOL-ERR (err u2001))
(define-constant ERR-NO-LIQUIDITY (err u2002))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-TRANSFER-X-FAILED (err u3001))
(define-constant ERR-TRANSFER-Y-FAILED (err u3002))
(define-constant ERR-POOL-ALREADY-EXISTS (err u2000))
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant ERR-PERCENT-GREATER-THAN-ONE (err u5000))
(define-constant ERR-NO-FEE (err u2005))
(define-constant ERR-NO-FEE-Y (err u2006))
(define-constant ERR-WEIGHTED-EQUATION-CALL (err u2009))
(define-constant ERR-MATH-CALL (err u2010))
(define-constant ERR-INTERNAL-FUNCTION-CALL (err u1001))
(define-constant ERR-GET-WEIGHT-FAIL (err u2012))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))
(define-constant ERR-GET-PRICE-FAIL (err u2015))
(define-constant ERR-GET-SYMBOL-FAIL (err u6000))
(define-constant ERR-GET-ORACLE-PRICE-FAIL (err u7000))
(define-constant ERR-EXPIRY (err u2017))
(define-constant ERR-GET-BALANCE-FAIL (err u6001))
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-USER-ALREADY-REGISTERED (err u10001))
(define-constant ERR-USER-NOT-FOUND (err u10002))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-ACTIVATION-THRESHOLD-REACHED (err u10004))
(define-constant ERR-UNABLE-TO-SET-THRESHOLD (err u10021))
(define-constant ERR-CONTRACT-NOT-ACTIVATED (err u10005))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-CANNOT-STAKE (err u10016))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-NOTHING-TO-REDEEM (err u10018))
(define-constant ERR-AMOUNT-EXCEED-RESERVE (err u2024))

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-data-var CONTRACT-OWNER principal tx-sender)
(define-map approved-contracts principal bool)

(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

(define-map reserve principal uint)

(define-read-only (get-balance (token principal))
  (default-to u0 (map-get? reserve token))
)

(define-public (add-to-balance (token principal) (amount uint))
  (begin
    (asserts! (default-to false (map-get? approved-contracts contract-caller)) ERR-NOT-AUTHORIZED)
    (ok (map-set reserve token (+ amount (get-balance token))))
  )
)

(define-public (remove-from-balance (token principal) (amount uint))
  (begin
    (asserts! (default-to false (map-get? approved-contracts contract-caller)) ERR-NOT-AUTHORIZED)
    (asserts! (< amount (get-balance token)) ERR-AMOUNT-EXCEED-RESERVE)
    (ok (map-set reserve token (- (get-balance token) amount)))
  )
)

;; STAKING CONFIGURATION

(define-constant MAX-REWARD-CYCLES u32)
(define-constant REWARD-CYCLE-INDEXES (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31))

;; how long a reward cycle is
(define-data-var reward-cycle-length uint u2100)

;; At a given reward cycle, what is the total amount of tokens staked
(define-map staking-stats-at-cycle uint uint)

;; At a given reward cycle and user ID:
;; - what is the total tokens staked?
;; - how many tokens should be returned? (based on staking period)
(define-map staker-at-cycle
  {
    reward-cycle: uint,
    user-id: uint
  }
  {
    amount-staked: uint,
    to-return: uint
  }
)

(define-data-var activation-block uint u10000000)
(define-data-var activation-delay uint u150)
(define-data-var activation-threshold uint u20)
(define-data-var users-nonce uint u0)
;; store user principal by user id
(define-map users uint principal)
;; store user id by user principal
(define-map user-ids principal uint)

;; returns Stacks block height registration was activated at plus activationDelay
(define-read-only (get-activation-block)
  (begin
    (ok (var-get activation-block))
  )
)

(define-public (set-activation-block (new-activation-block-before-delay uint))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set activation-block (+ new-activation-block-before-delay (var-get activation-delay))))
  )
)

;; returns activation delay
(define-read-only (get-activation-delay)
  (var-get activation-delay)
)

;; returns activation threshold
(define-read-only (get-activation-threshold)
  (var-get activation-threshold)
)

(define-public (set-activation-threshold (new-activation-threshold uint))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set activation-threshold new-activation-threshold))
  )
)

;; returns the total staked tokens for a given reward cycle
(define-read-only (get-staking-stats-at-cycle (reward-cycle uint))
  (map-get? staking-stats-at-cycle reward-cycle)
)

;; returns the total staked tokens for a given reward cycle
;; or, zero
(define-read-only (get-staking-stats-at-cycle-or-default (reward-cycle uint))
  (default-to u0 (map-get? staking-stats-at-cycle reward-cycle))
)

;; returns (some user-id) or none
(define-read-only (get-user-id (user principal))
  (map-get? user-ids user)
)

;; returns (some user-principal) or none
(define-read-only (get-user (user-id uint))
  (map-get? users user-id)
)

;; returns number of registered users, used for activation and tracking user IDs
(define-read-only (get-registered-users-nonce)
  (var-get users-nonce)
)

;; returns user ID if it has been created, or creates and returns new ID
(define-private (get-or-create-user-id (user principal))
  (match
    (map-get? user-ids user)
    value value
    (let
      (
        (new-id (+ u1 (var-get users-nonce)))
      )
      (map-set users new-id user)
      (map-set user-ids user new-id)
      (var-set users-nonce new-id)
      new-id
    )
  )
)

;; registers users that signal activation of contract until threshold is met
(define-public (register-user (memo (optional (string-utf8 50))))
  (let
    (
      (new-id (+ u1 (var-get users-nonce)))
      (threshold (var-get activation-threshold))
    )
    (asserts! (is-none (map-get? user-ids tx-sender)) ERR-USER-ALREADY-REGISTERED)
    (asserts! (<= new-id threshold) ERR-ACTIVATION-THRESHOLD-REACHED)

    (if (is-some memo) (print memo) none)

    (get-or-create-user-id tx-sender)

    (if (is-eq new-id threshold)
      (let
        (
          (activation-block-val (+ block-height (var-get activation-delay)))
        )
        (var-set activation-block activation-block-val)
        (set-coinbase-thresholds)
        (ok true)
      )
      (ok true)
    )
  )
)

(define-read-only (get-staker-at-cycle (reward-cycle uint) (user-id uint))
  (map-get? staker-at-cycle { reward-cycle: reward-cycle, user-id: user-id })
)

(define-read-only (get-staker-at-cycle-or-default (reward-cycle uint) (user-id uint))
  (default-to { amount-staked: u0, to-return: u0 }
    (map-get? staker-at-cycle { reward-cycle: reward-cycle, user-id: user-id }))
)

;; get the reward cycle for a given Stacks block height
(define-read-only (get-reward-cycle (stacks-height uint))
  (let
    (
      (first-staking-block (var-get activation-block))
      (rcLen (var-get reward-cycle-length))
    )
    (if (>= stacks-height first-staking-block)
      (some (/ (- stacks-height first-staking-block) rcLen))
      none)
  )
)

;; determine if staking is active in a given cycle
(define-read-only (staking-active-at-cycle (reward-cycle uint))
  (is-some (map-get? staking-stats-at-cycle reward-cycle))
)

;; get the first Stacks block height for a given reward cycle.
(define-read-only (get-first-stacks-block-in-reward-cycle (reward-cycle uint))
  (+ (var-get activation-block) (* (var-get reward-cycle-length) reward-cycle))
)

;; getter for get-entitled-staking-reward that specifies block height
(define-read-only (get-staking-reward (user-id uint) (target-cycle uint))
  (get-entitled-staking-reward user-id target-cycle block-height)
)

(define-private (get-entitled-staking-reward (user-id uint) (target-cycle uint) (stacks-height uint))
  (let
    (
      (total-staked-this-cycle (get-staking-stats-at-cycle-or-default target-cycle))
      (user-staked-this-cycle (get amount-staked (get-staker-at-cycle-or-default target-cycle user-id)))
    )
    (match (get-reward-cycle stacks-height)
      current-cycle
      (if (or (<= current-cycle target-cycle) (is-eq u0 user-staked-this-cycle))
        ;; this cycle hasn't finished, or staker contributed nothing
        u0
        (div-down user-staked-this-cycle total-staked-this-cycle)
      )
      ;; before first reward cycle
      u0
    )
  )
)

;; STAKING ACTIONS

(define-public (stake-tokens (amount-token uint) (lock-period uint))
  (stake-tokens-at-cycle tx-sender (get-or-create-user-id tx-sender) amount-token block-height lock-period)
)

(define-private (stake-tokens-at-cycle (user principal) (user-id uint) (amount-token uint) (start-height uint) (lock-period uint))
  (let
    (
      (current-cycle (unwrap! (get-reward-cycle start-height) ERR-STAKING-NOT-AVAILABLE))
      (target-cycle (+ u1 current-cycle))
      (commitment {
        staker-id: user-id,
        amount: amount-token,
        first: target-cycle,
        last: (+ target-cycle lock-period)
      })
    )
    (asserts! (>= block-height (var-get activation-block)) ERR-CONTRACT-NOT-ACTIVATED)
    (asserts! (and (> lock-period u0) (<= lock-period MAX-REWARD-CYCLES)) ERR-CANNOT-STAKE)
    (asserts! (> amount-token u0) ERR-CANNOT-STAKE)
    (unwrap! (contract-call? .token-alex transfer amount-token tx-sender .alex-vault none) ERR-TRANSFER-FAILED)
    (match (fold stake-tokens-closure REWARD-CYCLE-INDEXES (ok commitment))
      ok-value (ok true)
      err-value (err err-value)
    )
  )
)

(define-private (stake-tokens-closure (reward-cycle-idx uint)
  (commitment-response (response 
    {
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
        (staker-id (get staker-id commitment))
        (amount-token (get amount commitment))
        (first-cycle (get first commitment))
        (last-cycle (get last commitment))
        (target-cycle (+ first-cycle reward-cycle-idx))
        (this-staker-at-cycle (get-staker-at-cycle-or-default target-cycle staker-id))
        (amount-staked (get amount-staked this-staker-at-cycle))
        (to-return (get to-return this-staker-at-cycle))
      )
      (begin
        (if (and (>= target-cycle first-cycle) (< target-cycle last-cycle))
          (begin
            (if (is-eq target-cycle (- last-cycle u1))
              (set-tokens-staked staker-id target-cycle amount-token amount-token)
              (set-tokens-staked staker-id target-cycle amount-token u0)
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

(define-private (set-tokens-staked (user-id uint) (target-cycle uint) (amount-staked uint) (to-return uint))
  (let
    (
      (this-staker-at-cycle (get-staker-at-cycle-or-default target-cycle user-id))
    )
    (map-set staking-stats-at-cycle target-cycle (+ amount-staked (get-staking-stats-at-cycle-or-default target-cycle)))
    (map-set staker-at-cycle
      {
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
(define-public (claim-staking-reward (target-cycle uint))
  (claim-staking-reward-at-cycle tx-sender block-height target-cycle)
)

(define-private (claim-staking-reward-at-cycle (user principal) (stacks-height uint) (target-cycle uint))
  (let
    (
      (current-cycle (unwrap! (get-reward-cycle stacks-height) ERR-STAKING-NOT-AVAILABLE))
      (user-id (unwrap! (get-user-id user) ERR-USER-ID-NOT-FOUND))
      (entitled-token (get-entitled-staking-reward user-id target-cycle stacks-height))
      (to-return (get to-return (get-staker-at-cycle-or-default target-cycle user-id)))
    )
    (asserts! (> current-cycle target-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (or (> to-return u0) (> entitled-token u0)) ERR-NOTHING-TO-REDEEM)
    ;; disable ability to claim again
    (map-set staker-at-cycle
      {
        reward-cycle: target-cycle,
        user-id: user-id
      }
      {
        amount-staked: u0,
        to-return: u0
      }
    )
    ;; send back tokens if user was eligible
    (and (> to-return u0) (try! (contract-call? .alex-vault transfer-ft .token-alex to-return user)))
    ;; send back rewards if user was eligible
    (and (> entitled-token u0) (try! (as-contract (contract-call? .token-alex mint user (mul-down entitled-token (get-coinbase-amount target-cycle))))))
    (ok true)
  )
)

;; TOKEN CONFIGURATION

(define-data-var token-halving-cycle uint u100)

(define-read-only (get-token-halving-cycle)
  (var-get token-halving-cycle)
)

(define-public (set-token-halving-cycle (new-token-halving-cycle uint))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (var-set token-halving-cycle new-token-halving-cycle)
    (set-coinbase-thresholds)
    (ok true)
  )
)

;; store block height at each halving, set by register-user in core contract
(define-data-var coinbase-threshold-1 uint u0)
(define-data-var coinbase-threshold-2 uint u0)
(define-data-var coinbase-threshold-3 uint u0)
(define-data-var coinbase-threshold-4 uint u0)
(define-data-var coinbase-threshold-5 uint u0)

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
(define-read-only (get-coinbase-thresholds)
  (ok {
      coinbase-threshold-1: (var-get coinbase-threshold-1),
      coinbase-threshold-2: (var-get coinbase-threshold-2),
      coinbase-threshold-3: (var-get coinbase-threshold-3),
      coinbase-threshold-4: (var-get coinbase-threshold-4),
      coinbase-threshold-5: (var-get coinbase-threshold-5)
  })
)

;; function for deciding how many tokens to mint, depending on when they were mined
(define-read-only (get-coinbase-amount (reward-cycle uint))
  (begin
    ;; computations based on each halving threshold
    (asserts! (> reward-cycle (var-get coinbase-threshold-1)) (* u100000 ONE_8))
    (asserts! (> reward-cycle (var-get coinbase-threshold-2)) (* u50000 ONE_8))
    (asserts! (> reward-cycle (var-get coinbase-threshold-3)) (* u25000 ONE_8))
    (asserts! (> reward-cycle (var-get coinbase-threshold-4)) (* u12500 ONE_8))
    (asserts! (> reward-cycle (var-get coinbase-threshold-5)) (* u6250 ONE_8))
    ;; default value after 5th halving
    (* u3125 ONE_8)
  )
)

(define-read-only (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

;; contract initialisation
(begin
  (map-set approved-contracts .collateral-rebalancing-pool true)  
  (map-set approved-contracts .fixed-weight-pool true)
  (map-set approved-contracts .yield-token-pool true)  
)
