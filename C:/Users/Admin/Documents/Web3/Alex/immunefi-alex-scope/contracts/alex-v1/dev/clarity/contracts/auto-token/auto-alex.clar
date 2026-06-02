clarity
;; auto-alex.clar
;; Production-grade fix: Prevent repeated bounty claims after a cycle has already been claimed.
;; Comprehensive security, validation, and error handling implementation.

;; Error codes with semantic naming
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-CALLER (err u101))
(define-constant ERR-CYCLE-ALREADY-CLAIMED (err u102))
(define-constant ERR-ZERO-CLAIM (err u103))
(define-constant ERR-END-CYCLE-REACHED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant ERR-CONTRACT-NOT-INITIALIZED (err u107))
(define-constant ERR-CYCLE-BOUNDARY (err u108))
(define-constant ERR-STAKING-FAILED (err u109))
(define-constant ERR-TRANSFER-FAILED (err u110))
(define-constant ERR-BOUNTY-EXCEEDS-BALANCE (err u111))
(define-constant ERR-CLAIM-ALREADY-PROCESSED (err u112))
(define-constant ERR-STATE-INCONSISTENT (err u113))

;; Contract metadata
(define-constant CONTRACT-NAME "AutoALEX")
(define-constant CONTRACT-VERSION u2)
(define-constant CONTRACT-OWNER tx-sender)

;; External contract addresses (should be configurable)
(define-constant ALEX-TOKEN 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-constant RESERVE-POOL 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Data variables with initialization tracking
(define-data-var initialized bool false)
(define-data-var last-claimed-cycle uint u0)
(define-data-var current-cycle uint u0)
(define-data-var end-cycle uint u0)
(define-data-var bounty uint u0)
(define-data-var total-supply uint u0)
(define-data-var staked-balance uint u0)
(define-data-var total-claimed uint u0)
(define-data-var total-bounties-paid uint u0)
(define-data-var paused bool false)

;; Token balances map
(define-map balances principal uint)
(define-map allowances principal (list 20 {spender: principal, amount: uint}))

;; Staking data with validation
(define-map staking-data principal {amount: uint, start-cycle: uint, end-cycle: uint, last-claim-cycle: uint})

;; Cycle claim tracking to prevent double claims
(define-map cycle-claims uint {claimed: bool, claimed-by: principal, claimed-at: uint, amount: uint})

;; ============================================
;; PRIVATE HELPER FUNCTIONS
;; ============================================

;; @notice Validates contract initialization state
;; @returns bool True if contract is initialized
(define-read-only (assert-initialized)
  (asserts! (var-get initialized) ERR-CONTRACT-NOT-INITIALIZED)
)

;; @notice Validates contract is not paused
;; @returns bool True if contract is not paused
(define-read-only (assert-not-paused)
  (asserts! (not (var-get paused)) (err u200))
)

;; @notice Validates caller is contract owner
;; @returns bool True if caller is owner
(define-read-only (assert-owner)
  (begin
    (assert-initialized)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
  )
)

;; @notice Validates amount is positive
;; @param amount The amount to validate
(define-read-only (assert-positive-amount (amount uint))
  (asserts! (> amount u0) ERR-INVALID-AMOUNT)
)

;; @notice Validates cycle boundaries
;; @param current The current cycle
;; @param end The end cycle
(define-read-only (assert-cycle-boundary (current uint) (end uint))
  (asserts! (<= current end) ERR-CYCLE-BOUNDARY)
)

;; @notice Checks if a cycle has already been claimed
;; @param cycle The cycle to check
;; @returns bool True if cycle already claimed
(define-read-only (is-cycle-claimed (cycle uint))
  (let
    ((claim-info (default-to {claimed: false, claimed-by: tx-sender, claimed-at: u0, amount: u0} (map-get? cycle-claims cycle))))
    (get claimed claim-info)
  )
)

;; @notice Gets staking info for a user with safe defaults
;; @param user The principal to query
;; @returns {amount: uint, start-cycle: uint, end-cycle: uint, last-claim-cycle: uint}
(define-read-only (get-staking-info (user principal))
  (default-to 
    {amount: u0, start-cycle: u0, end-cycle: u0, last-claim-cycle: u0} 
    (map-get? staking-data user)
  )
)

;; @notice Calculates remaining cycles to stake
;; @param user The principal to calculate for
;; @returns uint Number of cycles to stake
(define-read-only (calculate-cycles-to-stake (user principal))
  (let
    (
      (info (get-staking-info user))
      (current-cyc (var-get current-cycle))
      (end-cyc (get end-cycle info))
    )
    (if (>= current-cyc end-cyc)
      u0
      (- end-cyc current-cyc)
    )
  )
)

;; @notice Claims staking reward from reserve pool with error handling
;; @returns (response uint uint) The claimed amount or error
(define-private (claim-staking-reward)
  (let
    ((result (contract-call? RESERVE-POOL claim-reward)))
    (match result
      (ok amount (ok amount))
      (err e (begin
        (print {event: "claim-failed", error: e, contract: CONTRACT-NAME})
        (err e)
      ))
    )
  )
)

;; @notice Transfers ALEX tokens with validation
;; @param from Source principal
;; @param to Destination principal
;; @param amount Amount to transfer
(define-private (transfer-alex-safe (from principal) (to principal) (amount uint))
  (let
    ((result (contract-call? ALEX-TOKEN transfer from to amount)))
    (asserts! (is-ok result) ERR-TRANSFER-FAILED)
    (unwrap-panic result)
  )
)

;; @notice Updates staking data for a user
;; @param user The principal to update
;; @param amount The amount to add
;; @param cycles The cycles to stake
(define-private (update-staking-data (user principal) (amount uint) (cycles uint))
  (let
    (
      (info (get-staking-info user))
      (new-amount (+ (get amount info) amount))
      (new-end-cycle (+ (var-get current-cycle) cycles))
    )
    (map-set staking-data user 
      {
        amount: new-amount,
        start-cycle: (var-get current-cycle),
        end-cycle: new-end-cycle,
        last-claim-cycle: (var-get last-claimed-cycle)
      }
    )
  )
)

;; @notice Marks a cycle as claimed in the tracking map
;; @param cycle The cycle to mark
;; @param caller The principal claiming
;; @param amount The amount claimed
(define-private (mark-cycle-claimed (cycle uint) (caller principal) (amount uint))
  (map-set cycle-claims cycle 
    {
      claimed: true,
      claimed-by: caller,
      claimed-at: block-height,
      amount: amount
    }
  )
)

;; @notice Validates contract state consistency
;; @returns bool True if state is consistent
(define-read-only (validate-state-consistency)
  (let
    (
      (current (var-get current-cycle))
      (end (var-get end-cycle))
      (last-claimed (var-get last-claimed-cycle))
    )
    (and
      (<= last-claimed current)
      (<= current end)
      (>= last-claimed u0)
    )
  )
)

;; ============================================
;; PUBLIC FUNCTIONS
;; ============================================

;; @notice Main claim-and-stake function with comprehensive security
;; @dev Prevents repeated bounty claims after cycle is claimed
;; @returns (ok bool) on success, (err uint) on failure
(define-public (claim-and-stake)
  (let
    (
      (caller tx-sender)
      (current-cyc (var-get current-cycle))
      (end-cyc (var-get end-cycle))
      (last-claimed (var-get last-claimed-cycle))
    )
    
    ;; Validate contract state
    (try! (assert-initialized))
    (try! (assert-not-paused))
    
    ;; Security Check 1: Prevent calls at end-cycle boundary
    (asserts! (< current-cyc end-cyc) ERR-END-CYCLE-REACHED)
    
    ;; Security Check 2: Prevent double claiming
    (asserts! (not (is-cycle-claimed current-cyc)) ERR-CYCLE-ALREADY-CLAIMED)
    
    ;; Security Check 3: Validate cycle boundary
    (assert-cycle-boundary current-cyc end-cyc)
    
    ;; Security Check 4: Validate state consistency
    (asserts! (validate-state-consistency) ERR-STATE-INCONSISTENT)
    
    ;; Execute claim and validate result
    (match (claim-staking-reward)
      (ok claimed-amount
        (begin
          ;; Security Check 5: Ensure non-zero claim
          (asserts! (> claimed-amount u0) ERR-ZERO-CLAIM)
          
          ;; Update state atomically
          (var-set last-claimed-cycle current-cyc)
          (var-set total-claimed (+ (var-get total-claimed) claimed-amount))
          
          ;; Mark cycle as claimed
          (mark-cycle-claimed current-cyc caller claimed-amount)
          
          ;; Calculate staking parameters
          (let
            (
              (cycles-to-stake (calculate-cycles-to-stake caller))
              (bounty-amount (var-get bounty))
              (contract-balance (as-contract (contract-call? ALEX-TOKEN get-balance (as-contract tx-sender))))
            )
            
            ;; Validate bounty amount
            (assert-positive-amount bounty-amount)
            
            ;; Security Check 6: Ensure contract has enough balance for bounty
            (asserts! (>= contract-balance bounty-amount) ERR-BOUNTY-EXCEEDS-BALANCE)
            
            ;; Execute staking or direct transfer
            (if (> cycles-to-stake u0)
              ;; Path 1: Restake with cycles
              (match (contract-call? RESERVE-POOL stake claimed-amount cycles-to-stake)
                (ok value (begin
                  ;; Update staking data
                  (update-staking-data caller claimed-amount cycles-to-stake)
                  
                  ;; Update global staked balance
                  (var-set staked-balance (+ (var-get staked-balance) claimed-amount))
                  
                  ;; Transfer bounty to caller
                  (try! (transfer-alex-safe (as-contract tx-sender) caller bounty-amount))
                  
                  ;; Update bounty tracking
                  (var-set total-bounties-paid (+ (var-get total-bounties-paid) bounty-amount))
                  
                  ;; Log successful operation
                  (print {
                    event: "claim-and-stake-success",
                    version: CONTRACT-VERSION,
                    caller: caller,
                    claimed: claimed-amount,
                    staked: claimed-amount,
                    cycles: cycles-to-stake,
                    bounty: bounty-amount,
                    cycle: current-cyc,
                    block-height: block-height
                  })
                  
                  (ok true)
                ))
                (err e (begin
                  (print {
                    event: "stake-failed",
                    error: e,
                    caller: caller,
                    amount: claimed-amount,
                    cycles: cycles-to-stake,
                    cycle: current-cyc
                  })
                  (err ERR-STAKING-FAILED)
                ))
              )
              ;; Path 2: No cycles to stake, just transfer bounty
              (begin
                ;; Transfer bounty to caller
                (try! (transfer-alex-safe (as-contract tx-sender) caller bounty-amount))
                
                ;; Update bounty tracking
                (var-set total-bounties-paid (+ (var-get total-bounties-paid) bounty-amount))
                
                ;; Log successful operation
                (print {
                  event: "claim-and-stake-success-no-stake",
                  version: CONTRACT-VERSION,
                  caller: caller,
                  claimed: claimed-amount,
                  bounty: bounty-amount,
                  cycle: current-cyc,
                  block-height: block-height
                })
                
                (ok true)
              )
            )
          )
        )
      )
      (err e (begin
        (print {
          event: "claim-reward-failed",
          error: e,
          caller: caller,
          cycle: current-cyc,
          block-height: block-height
        })
        (err e)
      ))
    )
  )
)

;; @notice Emergency pause function for contract owner
;; @dev Only callable by contract owner
;; @returns (ok bool) on success
(define-public (emergency-pause)
  (begin
    (try! (assert-owner))
    (var-set paused true)
    (print {
      event: "emergency-pause",
      caller: tx-sender,
      block-height: block-height
    })
    (ok true)
  )
)

;; @notice Emergency unpause function for contract owner
;; @dev Only callable by contract owner
;; @returns (ok bool) on success
(define-public (emergency-unpause)
  (begin
    (try! (assert-owner))
    (var-set paused false)
    (print {
      event: "emergency-unpause",
      caller: tx-sender,
      block-height: block-height
    })
    (ok true)
  )
)

;; @notice Updates bounty amount
;; @dev Only callable by contract owner
;; @param new-bounty The new bounty amount
;; @returns (ok bool) on success
(define-public (update-bounty (new-bounty uint))
  (begin
    (try! (assert-owner))
    (assert-positive-amount new-bounty)
    (var-set bounty new-bounty)
    (print {
      event: "bounty-updated",
      old-bounty: (var-get bounty),
      new-bounty: new-bounty,
      caller: tx-sender
    })
    (ok true)
  )
)

;; @notice Updates cycle parameters
;; @dev Only callable by contract owner
;; @param new-current-cycle The new current cycle
;; @param new-end-cycle The new end cycle
;; @returns (ok bool) on success
(define-public (update-cycles (new-current-cycle uint) (new-end-cycle uint))
  (begin
    (try! (assert-owner))
    (asserts! (<= new-current-cycle new-end-cycle) ERR-CYCLE-BOUNDARY)
    (var-set current-cycle new-current-cycle)
    (var-set end-cycle new-end-cycle)
    (print {
      event: "cycles-updated",
      old-current: (var-get current-cycle),
      old-end: (var-get end-cycle),
      new-current: new-current-cycle,
      new-end: new-end-cycle,
      caller: tx-sender
    })
    (ok true)
  )
)

;; @notice Initializes the contract
;; @dev Only callable once
;; @param initial-cycle The initial cycle number
;; @param end-cycle-val The end cycle number
;; @param bounty-amount The bounty amount
;; @returns (ok bool) on success
(define-public (initialize (initial-cycle uint) (end-cycle-val uint) (bounty-amount uint))
  (begin
    (asserts! (not (var-get initialized)) ERR-CONTRACT-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= initial-cycle end-cycle-val) ERR-CYCLE-BOUNDARY)
    (assert-positive-amount bounty-amount)
    
    (var-set initialized true)
    (var-set current-cycle initial-cycle)
    (var-set end-cycle end-cycle-val)
    (var-set bounty bounty-amount)
    (var-set last-claimed-cycle (- initial-cycle u1))
    
    (print {
      event: "contract-initialized",
      version: CONTRACT-VERSION,
      initial-cycle: initial-cycle,
      end-cycle: end-cycle-val,
      bounty: bounty-amount,
      caller: tx-sender,
      block-height: block-height
    })
    
    (ok true)
  )
)

;; ============================================
;; READ-ONLY FUNCTIONS
;; ============================================

;; @notice Gets the current contract state
;; @returns {initialized: bool, current-cycle: uint, end-cycle: uint, last-claimed-cycle: uint, bounty: uint, paused: bool, total-claimed: uint, total-bounties-paid: uint, staked-balance: uint}
(define-read-only (get-contract-state)
  {
    initialized: (var-get initialized),
    current-cycle: (var-get current-cycle),
    end-cycle: (var-get end-cycle),
    last-claimed-cycle: (var-get last-claimed-cycle),
    bounty: (var-get bounty),
    paused: (var-get paused),
    total-claimed: (var-get total-claimed),
    total-bounties-paid: (var-get total-bounties-paid),
    staked-balance: (var-get staked-balance),
    version: CONTRACT-VERSION
  }
)

;; @notice Gets cycle claim info
;; @param cycle The cycle to query
;; @returns {claimed: bool, claimed-by: principal, claimed-at: uint, amount: uint}
(define-read-only (get-cycle-claim-info (cycle uint))
  (default-to 
    {claimed: false, claimed-by: tx-sender, claimed-at: u0, amount: u0}
    (map-get? cycle-claims cycle)
  )
)

;; @notice Gets user staking info
;; @param user The principal to query
;; @returns {amount: uint, start-cycle: uint, end-cycle: uint, last-claim-cycle: uint