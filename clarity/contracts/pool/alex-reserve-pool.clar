(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

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

(define-data-var oracle-src (string-ascii 32) "coingecko")
(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

(define-read-only (get-owner)
  (ok (var-get contract-owner))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner owner))
  )
)

(define-read-only (get-oracle-src)
  (ok (var-get oracle-src))
)

(define-public (set-oracle-src (new-oracle-src (string-ascii 32)))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set oracle-src new-oracle-src))
  )
)

(define-map reserve principal uint)

(define-read-only (get-balance (token <ft-trait>))
  (default-to u0 (map-get? reserve (contract-of token)))
)

(define-public (add-to-balance (token <ft-trait>) (amount uint) (sender principal))
  (begin
    (asserts! (default-to false (map-get? approved-contracts sender)) ERR-NOT-AUTHORIZED)
    (ok (map-set reserve (contract-of token) (+ amount (get-balance token))))
  )
)

;; if sender is an approved contract, then transfer requested amount from vault to recipient
(define-public (transfer-ft (token <ft-trait>) (amount uint) (sender principal) (recipient principal))
  (begin     
    (asserts! (default-to false (map-get? approved-contracts sender)) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (get-balance token)) ERR-AMOUNT-EXCEED-RESERVE)
    (ok (as-contract (unwrap! (contract-call? token transfer amount .alex-vault recipient none) ERR-TRANSFER-FAILED)))
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
(define-data-var activation-reached bool false)
(define-data-var activation-threshold uint u20)
(define-data-var users-nonce uint u0)
;; store user principal by user id
(define-map users uint principal)
;; store user id by user principal
(define-map user-ids principal uint)

;; returns Stacks block height registration was activated at plus activationDelay
(define-read-only (get-activation-block)
  (begin
    (asserts! (var-get activation-reached) ERR-CONTRACT-NOT-ACTIVATED)
    (ok (var-get activation-block))
  )
)

;; returns activation delay
(define-read-only (get-activation-delay)
  (var-get activation-delay)
)

;; returns activation status as boolean
(define-read-only (get-activation-status)
  (var-get activation-reached)
)

;; returns activation threshold
(define-read-only (get-activation-threshold)
  (var-get activation-threshold)
)

(define-public (set-activation-block (new-activation-block uint))
  (begin
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set activation-block new-activation-block))
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
        (var-set activation-reached true)
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
    (asserts! (get-activation-status) ERR-CONTRACT-NOT-ACTIVATED)
    (asserts! (and (> lock-period u0) (<= lock-period MAX-REWARD-CYCLES)) ERR-CANNOT-STAKE)
    (asserts! (> amount-token u0) ERR-CANNOT-STAKE)
    (try! (contract-call? .token-alex transfer amount-token tx-sender .alex-vault none))
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
    (and (> to-return u0) (try! (as-contract (contract-call? .token-alex transfer to-return .alex-vault user none))))
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
    (asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
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


;; math-fixed-point
;; Fixed Point Math
;; following https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/FixedPoint.sol

;; constants
;;
(define-constant SCALE-UP-OVERFLOW (err u5001))
(define-constant SCALE-DOWN-OVERFLOW (err u5002))
(define-constant ADD-OVERFLOW (err u5003))
(define-constant SUB-OVERFLOW (err u5004))
(define-constant MUL-OVERFLOW (err u5005))
(define-constant DIV-OVERFLOW (err u5006))
(define-constant POW-OVERFLOW (err u5007))

;; With 8 fixed digits you would have a maximum error of 0.5 * 10^-8 in each entry, 
;; which could aggregate to about 8 x 0.5 * 10^-8 = 4 * 10^-8 relative error 
;; (i.e. the last digit of the result may be completely lost to this error).
(define-constant MAX-POW-RELATIVE-ERROR u4) 

;; public functions
;;

(define-read-only (get-one)
    (ok ONE_8)
)

(define-read-only (scale-up (a uint))
  (* a ONE_8)
)

(define-read-only (scale-down (a uint))
  (/ a ONE_8)
)

(define-read-only (mul-down (a uint) (b uint))
  (/ (* a b) ONE_8)
)


(define-read-only (mul-up (a uint) (b uint))
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

(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

(define-read-only (div-up (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (+ u1 (/ (- (* a ONE_8) u1) b))
  )
)

(define-read-only (pow-down (a uint) (b uint))    
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX-POW-RELATIVE-ERROR)))
        )
        (if (< raw max-error)
            u0
            (- raw max-error)
        )
    )
)

(define-read-only (pow-up (a uint) (b uint))
    (let
        (
            (raw (unwrap-panic (pow-fixed a b)))
            (max-error (+ u1 (mul-up raw MAX-POW-RELATIVE-ERROR)))
        )
        (+ raw max-error)
    )
)

;; math-log-exp
;; Exponentiation and logarithm functions for 8 decimal fixed point numbers (both base and exponent/argument).
;; Exponentiation and logarithm with arbitrary bases (x^y and log-x(y)) are implemented by conversion to natural 
;; exponentiation and logarithm (where the base is Euler's number).
;; Reference: https://github.com/balancer-labs/balancer-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
;; MODIFIED: because we use only 128 bits instead of 256, we cannot do 20 decimal or 36 decimal accuracy like in Balancer. 

;; constants
;;
;; All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
;; two numbers, and multiply by ONE when dividing them.
;; All arguments and return values are 8 decimal fixed point numbers.
(define-constant iONE_8 (pow 10 8))
(define-constant ONE_10 (pow 10 10))

;; The domain of natural exponentiation is bound by the word size and number of decimals used.
;; The largest possible result is (2^127 - 1) / 10^8, 
;; which makes the largest exponent ln((2^127 - 1) / 10^8) = 69.6090111872.
;; The smallest possible result is 10^(-8), which makes largest negative argument ln(10^(-8)) = -18.420680744.
;; We use 69.0 and -18.0 to have some safety margin.
(define-constant MAX-NATURAL-EXPONENT (* 69 iONE_8))
(define-constant MIN-NATURAL-EXPONENT (* -18 iONE_8))

(define-constant MILD-EXPONENT-BOUND (/ (pow u2 u126) (to-uint iONE_8)))

;; Because largest exponent is 69, we start from 64
;; The first several a-n are too large if stored as 8 decimal numbers, and could cause intermediate overflows.
;; Instead we store them as plain integers, with 0 decimals.
(define-constant x-a-list-no-deci (list 
{x-pre: 6400000000, a-pre: 6235149080811616882910000000, use-deci: false} ;; x1 = 2^6, a1 = e^(x1)
))
;; 8 decimal constants
(define-constant x-a-list (list 
{x-pre: 3200000000, a-pre: 7896296018268069516100, use-deci: true} ;; x2 = 2^5, a2 = e^(x2)
{x-pre: 1600000000, a-pre: 888611052050787, use-deci: true} ;; x3 = 2^4, a3 = e^(x3)
{x-pre: 800000000, a-pre: 298095798704, use-deci: true} ;; x4 = 2^3, a4 = e^(x4)
{x-pre: 400000000, a-pre: 5459815003, use-deci: true} ;; x5 = 2^2, a5 = e^(x5)
{x-pre: 200000000, a-pre: 738905610, use-deci: true} ;; x6 = 2^1, a6 = e^(x6)
{x-pre: 100000000, a-pre: 271828183, use-deci: true} ;; x7 = 2^0, a7 = e^(x7)
{x-pre: 50000000, a-pre: 164872127, use-deci: true} ;; x8 = 2^-1, a8 = e^(x8)
{x-pre: 25000000, a-pre: 128402542, use-deci: true} ;; x9 = 2^-2, a9 = e^(x9)
{x-pre: 12500000, a-pre: 113314845, use-deci: true} ;; x10 = 2^-3, a10 = e^(x10)
{x-pre: 6250000, a-pre: 106449446, use-deci: true} ;; x11 = 2^-4, a11 = e^x(11)
))

(define-constant X-OUT-OF-BOUNDS (err u5009))
(define-constant Y-OUT-OF-BOUNDS (err u5010))
(define-constant PRODUCT-OUT-OF-BOUNDS (err u5011))
(define-constant INVALID-EXPONENT (err u5012))
(define-constant OUT-OF-BOUNDS (err u5013))

;; private functions
;;

;; Internal natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-private (ln-priv (a int))
  (let
    (
      (a-sum-no-deci (fold accumulate-division x-a-list-no-deci {a: a, sum: 0}))
      (a-sum (fold accumulate-division x-a-list {a: (get a a-sum-no-deci), sum: (get sum a-sum-no-deci)}))
      (out-a (get a a-sum))
      (out-sum (get sum a-sum))
      (z (/ (* (- out-a iONE_8) iONE_8) (+ out-a iONE_8)))
      (z-squared (/ (* z z) iONE_8))
      (div-list (list 3 5 7 9 11))
      (num-sum-zsq (fold rolling-sum-div div-list {num: z, seriesSum: z, z-squared: z-squared}))
      (seriesSum (get seriesSum num-sum-zsq))
      (r (+ out-sum (* seriesSum 2)))
   )
    (ok r)
 )
)

(define-private (accumulate-division (x-a-pre (tuple (x-pre int) (a-pre int) (use-deci bool))) (rolling-a-sum (tuple (a int) (sum int))))
  (let
    (
      (a-pre (get a-pre x-a-pre))
      (x-pre (get x-pre x-a-pre))
      (use-deci (get use-deci x-a-pre))
      (rolling-a (get a rolling-a-sum))
      (rolling-sum (get sum rolling-a-sum))
   )
    (if (>= rolling-a (if use-deci a-pre (* a-pre iONE_8)))
      {a: (/ (* rolling-a (if use-deci iONE_8 1)) a-pre), sum: (+ rolling-sum x-pre)}
      {a: rolling-a, sum: rolling-sum}
   )
 )
)

(define-private (rolling-sum-div (n int) (rolling (tuple (num int) (seriesSum int) (z-squared int))))
  (let
    (
      (rolling-num (get num rolling))
      (rolling-sum (get seriesSum rolling))
      (z-squared (get z-squared rolling))
      (next-num (/ (* rolling-num z-squared) iONE_8))
      (next-sum (+ rolling-sum (/ next-num n)))
   )
    {num: next-num, seriesSum: next-sum, z-squared: z-squared}
 )
)

;; Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
;; arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
;; x^y = exp(y * ln(x)).
;; Reverts if ln(x) * y is smaller than `MIN-NATURAL-EXPONENT`, or larger than `MAX-NATURAL-EXPONENT`.
(define-private (pow-priv (x uint) (y uint))
  (let
    (
      (x-int (to-int x))
      (y-int (to-int y))
      (lnx (unwrap-panic (ln-priv x-int)))
      (logx-times-y (/ (* lnx y-int) iONE_8))
    )
    (asserts! (and (<= MIN-NATURAL-EXPONENT logx-times-y) (<= logx-times-y MAX-NATURAL-EXPONENT)) PRODUCT-OUT-OF-BOUNDS)
    (ok (to-uint (unwrap-panic (exp-fixed logx-times-y))))
  )
)

(define-private (exp-pos (x int))
  (begin
    (asserts! (and (<= 0 x) (<= x MAX-NATURAL-EXPONENT)) (err INVALID-EXPONENT))
    (let
      (
        ;; For each x-n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        ;; it and compute the accumulated product.
        (x-product-no-deci (fold accumulate-product x-a-list-no-deci {x: x, product: 1}))
        (x-adj (get x x-product-no-deci))
        (firstAN (get product x-product-no-deci))
        (x-product (fold accumulate-product x-a-list {x: x-adj, product: iONE_8}))
        (product-out (get product x-product))
        (x-out (get x x-product))
        (seriesSum (+ iONE_8 x-out))
        (div-list (list 2 3 4 5 6 7 8 9 10 11 12))
        (term-sum-x (fold rolling-div-sum div-list {term: x-out, seriesSum: seriesSum, x: x-out}))
        (sum (get seriesSum term-sum-x))
     )
      (ok (* (/ (* product-out sum) iONE_8) firstAN))
   )
 )
)

(define-private (accumulate-product (x-a-pre (tuple (x-pre int) (a-pre int) (use-deci bool))) (rolling-x-p (tuple (x int) (product int))))
  (let
    (
      (x-pre (get x-pre x-a-pre))
      (a-pre (get a-pre x-a-pre))
      (use-deci (get use-deci x-a-pre))
      (rolling-x (get x rolling-x-p))
      (rolling-product (get product rolling-x-p))
   )
    (if (>= rolling-x x-pre)
      {x: (- rolling-x x-pre), product: (/ (* rolling-product a-pre) (if use-deci iONE_8 1))}
      {x: rolling-x, product: rolling-product}
   )
 )
)

(define-private (rolling-div-sum (n int) (rolling (tuple (term int) (seriesSum int) (x int))))
  (let
    (
      (rolling-term (get term rolling))
      (rolling-sum (get seriesSum rolling))
      (x (get x rolling))
      (next-term (/ (/ (* rolling-term x) iONE_8) n))
      (next-sum (+ rolling-sum next-term))
   )
    {term: next-term, seriesSum: next-sum, x: x}
 )
)

;; public functions
;;

(define-read-only (get-exp-bound)
  (ok MILD-EXPONENT-BOUND)
)

;; Exponentiation (x^y) with unsigned 8 decimal fixed point base and exponent.
(define-read-only (pow-fixed (x uint) (y uint))
  (begin
    ;; The ln function takes a signed value, so we need to make sure x fits in the signed 128 bit range.
    (asserts! (< x (pow u2 u127)) X-OUT-OF-BOUNDS)

    ;; This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 128 bit range.
    (asserts! (< y MILD-EXPONENT-BOUND) Y-OUT-OF-BOUNDS)

    (if (is-eq y u0) 
      (ok (to-uint iONE_8))
      (if (is-eq x u0) 
        (ok u0)
        (pow-priv x y)
      )
    )
  )
)

;; Natural exponentiation (e^x) with signed 8 decimal fixed point exponent.
;; Reverts if `x` is smaller than MIN-NATURAL-EXPONENT, or larger than `MAX-NATURAL-EXPONENT`.
(define-read-only (exp-fixed (x int))
  (begin
    (asserts! (and (<= MIN-NATURAL-EXPONENT x) (<= x MAX-NATURAL-EXPONENT)) (err INVALID-EXPONENT))
    (if (< x 0)
      ;; We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
      ;; fits in the signed 128 bit range (as it is larger than MIN-NATURAL-EXPONENT).
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (/ (* iONE_8 iONE_8) (unwrap-panic (exp-pos (* -1 x)))))
      (exp-pos x)
    )
  )
)

;; Logarithm (log(arg, base), with signed 8 decimal fixed point base and argument.
(define-read-only (log-fixed (arg int) (base int))
  ;; This performs a simple base change: log(arg, base) = ln(arg) / ln(base).
  (let
    (
      (logBase (* (unwrap-panic (ln-priv base)) iONE_8))
      (logArg (* (unwrap-panic (ln-priv arg)) iONE_8))
   )
    (ok (/ (* logArg iONE_8) logBase))
 )
)

;; Natural logarithm (ln(a)) with signed 8 decimal fixed point argument.
(define-read-only (ln-fixed (a int))
  (begin
    (asserts! (> a 0) (err OUT-OF-BOUNDS))
    (if (< a iONE_8)
      ;; Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)).
      ;; If a is less than one, 1/a will be greater than one.
      ;; Fixed point division requires multiplying by iONE_8.
      (ok (- 0 (unwrap-panic (ln-priv (/ (* iONE_8 iONE_8) a)))))
      (ln-priv a)
   )
 )
)

;; contract initialisation
(begin
  (map-set approved-contracts .collateral-rebalancing-pool true)  
)
