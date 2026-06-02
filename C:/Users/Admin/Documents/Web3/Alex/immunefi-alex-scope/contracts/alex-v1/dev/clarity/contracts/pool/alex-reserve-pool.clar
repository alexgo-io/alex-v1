clarity
;; auto-alex.clar
;; Production-grade fix: Track claimed cycles to prevent double-claim attacks
;; Version: 2.0.0
;; Security Level: CRITICAL - User funds protection

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-CYCLE-ALREADY-CLAIMED (err u1001))
(define-constant ERR-INVALID-CYCLE (err u1002))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1003))
(define-constant ERR-CYCLE-NOT-ENDED (err u1004))
(define-constant ERR-ZERO-AMOUNT (err u1005))
(define-constant ERR-BOUNTY-TOO-HIGH (err u1006))
(define-constant ERR-ALREADY-CLAIMED (err u1007))
(define-constant ERR-POSITION-NOT-FOUND (err u1008))
(define-constant ERR-CYCLE-MISMATCH (err u1009))
(define-constant ERR-STAKE-FAILED (err u1010))
(define-constant ERR-UNSTAKE-FAILED (err u1011))
(define-constant ERR-TRANSFER-FAILED (err u1012))
(define-constant ERR-INVALID-PARAMETER (err u1013))
(define-constant ERR-CYCLE-ACTIVE (err u1014))
(define-constant ERR-BOUNTY-EXCEEDS-BALANCE (err u1015))

;; Security constants
(define-constant MAX-BOUNTY-PERCENTAGE u500)  ;; 5% maximum bounty (basis points)
(define-constant MIN-CYCLE-DURATION u100)     ;; Minimum blocks per cycle
(define-constant MAX-CYCLES u1000)            ;; Maximum number of cycles
(define-constant PERCENTAGE-DENOMINATOR u10000) ;; 100% in basis points
(define-constant MAX-BOUNTY-AMOUNT u1000000000) ;; Maximum bounty in microALEX

;; ============================================================================
;; DATA VARIABLES
;; ============================================================================

;; Track claimed cycles to prevent double-claim attacks
(define-map claimed-cycles
    { cycle-id: uint }
    { 
        claimed: bool,
        claimer: principal,
        claimed-at: uint,
        amount: uint,
        bounty-paid: uint
    }
)

;; Track user positions
(define-map user-positions
    { user: principal }
    { 
        staked-amount: uint,
        cycle-start: uint,
        cycle-end: uint,
        last-claim-cycle: uint,
        total-rewards: uint,
        position-created: uint
    }
)

;; Global state
(define-data-var current-cycle uint u0)
(define-data-var total-staked uint u0)
(define-data-var last-cycle-end uint u0)
(define-data-var total-claimed uint u0)
(define-data-var total-bounties-paid uint u0)
(define-data-var contract-owner principal tx-sender)

;; ============================================================================
;; PRIVATE FUNCTIONS
;; ============================================================================

;; @notice Validates that a cycle is eligible for claiming
;; @param cycle-id The cycle to validate
;; @param current-cycle The current cycle number
;; @returns (ok bool) if valid, (err error-code) otherwise
(define-private (validate-cycle-claim (cycle-id uint) (current-cycle uint))
    (begin
        (asserts! (>= current-cycle cycle-id) ERR-INVALID-CYCLE)
        (asserts! (> current-cycle cycle-id) ERR-CYCLE-ACTIVE)
        (ok true)
    )
)

;; @notice Calculates the reward for a given stake and cycle
;; @param staked-amount The amount staked
;; @param cycle-id The cycle number
;; @returns The calculated reward amount
(define-private (calculate-reward (staked-amount uint) (cycle-id uint))
    (let
        (
            (base-reward (/ (* staked-amount u100) PERCENTAGE-DENOMINATOR))
            (cycle-multiplier (if (> cycle-id u0) u2 u1))
        )
        (* base-reward cycle-multiplier)
    )
)

;; @notice Calculates the bounty for a given reward
;; @param reward The reward amount
;; @returns The calculated bounty amount
(define-private (calculate-bounty (reward uint))
    (let
        (
            (calculated-bounty (/ (* reward MAX-BOUNTY-PERCENTAGE) PERCENTAGE-DENOMINATOR))
        )
        (min calculated-bounty MAX-BOUNTY-AMOUNT)
    )
)

;; @notice Validates that a bounty amount is within acceptable limits
;; @param bounty The bounty to validate
;; @param reward The associated reward
;; @param balance The current balance
;; @returns (ok bool) if valid, (err error-code) otherwise
(define-private (validate-bounty (bounty uint) (reward uint) (balance uint))
    (begin
        (asserts! (<= bounty (* reward MAX-BOUNTY-PERCENTAGE)) ERR-BOUNTY-TOO-HIGH)
        (asserts! (<= bounty balance) ERR-BOUNTY-EXCEEDS-BALANCE)
        (ok true)
    )
)

;; @notice Updates user position after claiming
;; @param user The user principal
;; @param position The current position
;; @param reward The reward amount
;; @param bounty The bounty amount
;; @param current-cycle The current cycle
;; @returns (ok true) if successful
(define-private (update-position-after-claim (user principal) (position (tuple 
    (staked-amount uint)
    (cycle-start uint)
    (cycle-end uint)
    (last-claim-cycle uint)
    (total-rewards uint)
    (position-created uint)
)) (reward uint) (bounty uint) (current-cycle uint))
    (begin
        (map-set user-positions
            { user: user }
            { 
                staked-amount: (+ (get staked-amount position) (- reward bounty)),
                cycle-start: current-cycle,
                cycle-end: (+ current-cycle u1),
                last-claim-cycle: current-cycle,
                total-rewards: (+ (get total-rewards position) reward),
                position-created: (get position-created position)
            }
        )
        (ok true)
    )
)

;; @notice Emits a structured event for logging
;; @param event-name The event type
;; @param data The event data map
(define-private (emit-event (event-name (string-ascii 64)) (data (list 10 (tuple (key (string-ascii 32)) (value uint)))))
    (print {
        event: event-name,
        timestamp: block-height,
        data: data
    })
)

;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; @notice Claims and stakes rewards for a specific cycle
;; @dev This function is protected against double-claim attacks
;; @param cycle-id The cycle to claim rewards for
;; @returns (ok true) if successful, (err error-code) otherwise
(define-public (claim-and-stake (cycle-id uint))
    (let
        (
            (caller tx-sender)
            (current-cycle (var-get current-cycle))
            (claimed-status (map-get? claimed-cycles { cycle-id: cycle-id }))
            (balance (ft-get-balance? auto-alex-token (as-contract tx-sender)))
        )
        ;; Validate inputs
        (asserts! (is-eq cycle-id current-cycle) ERR-CYCLE-MISMATCH)
        (try! (validate-cycle-claim cycle-id current-cycle))
        
        ;; Check if cycle has already been claimed
        (asserts! 
            (not (default-to false (get claimed claimed-status)))
            ERR-CYCLE-ALREADY-CLAIMED
        )
        
        ;; Validate balance exists
        (asserts! (is-some balance) ERR-INSUFFICIENT-BALANCE)
        (let ((contract-balance (unwrap-panic balance)))
            (asserts! (> contract-balance u0) ERR-INSUFFICIENT-BALANCE)
            
            ;; Get user position
            (match (map-get? user-positions { user: caller })
                position
                (let
                    (
                        (staked-amount (get staked-amount position))
                        (cycle-end (get cycle-end position))
                    )
                    ;; Validate position
                    (asserts! (> staked-amount u0) ERR-POSITION-NOT-FOUND)
                    (asserts! (>= current-cycle cycle-end) ERR-CYCLE-NOT-ENDED)
                    
                    ;; Calculate reward and bounty
                    (let
                        (
                            (reward (calculate-reward staked-amount cycle-id))
                            (bounty (calculate-bounty reward))
                        )
                        ;; Validate bounty
                        (try! (validate-bounty bounty reward contract-balance))
                        
                        ;; Mark cycle as claimed (atomic operation)
                        (map-set claimed-cycles
                            { cycle-id: cycle-id }
                            { 
                                claimed: true,
                                claimer: caller,
                                claimed-at: block-height,
                                amount: reward,
                                bounty-paid: bounty
                            }
                        )
                        
                        ;; Transfer reward to user (minus bounty)
                        (try! (ft-transfer? auto-alex-token (- reward bounty) caller))
                        
                        ;; Transfer bounty to caller
                        (try! (stx-transfer? bounty (as-contract tx-sender) caller))
                        
                        ;; Update position
                        (try! (update-position-after-claim caller position reward bounty current-cycle))
                        
                        ;; Update global state
                        (var-set total-claimed (+ (var-get total-claimed) reward))
                        (var-set total-bounties-paid (+ (var-get total-bounties-paid) bounty))
                        
                        ;; Emit events
                        (emit-event "claim-and-stake" (list 
                            (tuple (key "cycle") (value cycle-id))
                            (tuple (key "user") (value (principal-to-uint? caller)))
                            (tuple (key "reward") (value reward))
                            (tuple (key "bounty") (value bounty))
                            (tuple (key "new-staked") (value (+ staked-amount (- reward bounty))))
                        ))
                        
                        (ok true)
                    )
                )
                (err ERR-POSITION-NOT-FOUND)
            )
        )
    )
)

;; @notice Stakes ALEX tokens into the protocol
;; @dev Validates amount and updates user position
;; @param amount The amount of ALEX tokens to stake
;; @returns (ok true) if successful, (err error-code) otherwise
(define-public (stake (amount uint))
    (let
        (
            (caller tx-sender)
            (current-cycle (var-get current-cycle))
            (existing-position (map-get? user-positions { user: caller }))
        )
        ;; Validate amount
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        (asserts! (<= amount u1000000000000) ERR-INVALID-PARAMETER) ;; Max 1M ALEX
        
        ;; Transfer tokens from user
        (try! (ft-transfer-from? auto-alex-token amount caller (as-contract tx-sender)))
        
        ;; Update or create position
        (match existing-position
            position
            (map-set user-positions
                { user: caller }
                { 
                    staked-amount: (+ (get staked-amount position) amount),
                    cycle-start: current-cycle,
                    cycle-end: (+ current-cycle u1),
                    last-claim-cycle: (get last-claim-cycle position),
                    total-rewards: (get total-rewards position),
                    position-created: (get position-created position)
                }
            )
            (map-set user-positions
                { user: caller }
                { 
                    staked-amount: amount,
                    cycle-start: current-cycle,
                    cycle-end: (+ current-cycle u1),
                    last-claim-cycle: u0,
                    total-rewards: u0,
                    position-created: block-height
                }
            )
        )
        
        ;; Update total staked
        (var-set total-staked (+ (var-get total-staked) amount))
        
        ;; Emit event
        (emit-event "stake" (list 
            (tuple (key "user") (value (principal-to-uint? caller)))
            (tuple (key "amount") (value amount))
            (tuple (key "cycle") (value current-cycle))
        ))
        
        (ok true)
    )
)

;; @notice Unstakes ALEX tokens from the protocol
;; @dev Validates position and transfers tokens back to user
;; @param amount The amount of ALEX tokens to unstake
;; @returns (ok true) if successful, (err error-code) otherwise
(define-public (unstake (amount uint))
    (let
        (
            (caller tx-sender)
            (position (unwrap! (map-get? user-positions { user: caller }) (err ERR-POSITION-NOT-FOUND)))
            (staked-amount (get staked-amount position))
            (current-cycle (var-get current-cycle))
            (cycle-end (get cycle-end position))
        )
        ;; Validate amount
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        (asserts! (>= staked-amount amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (>= current-cycle cycle-end) ERR-CYCLE-ACTIVE)
        
        ;; Update position
        (map-set user-positions
            { user: caller }
            { 
                staked-amount: (- staked-amount amount),
                cycle-start: current-cycle,
                cycle-end: (+ current-cycle u1),
                last-claim-cycle: (get last-claim-cycle position),
                total-rewards: (get total-rewards position),
                position-created: (get position-created position)
            }
        )
        
        ;; Transfer tokens back to user
        (try! (ft-transfer? auto-alex-token amount caller))
        
        ;; Update total staked
        (var-set total-staked (- (var-get total-staked) amount))
        
        ;; Emit event
        (emit-event "unstake" (list 
            (tuple (key "user") (value (principal-to-uint? caller)))
            (tuple (key "amount") (value amount))
            (tuple (key "cycle") (value current-cycle))
        ))
        
        (ok true)
    )
)

;; @notice Gets the current cycle number
;; @returns The current cycle number
(define-read-only (get-current-cycle)
    (ok (var-get current-cycle))
)

;; @notice Gets the total staked amount
;; @returns The total staked amount
(define-read-only (get-total-staked)
    (ok (var-get total-staked))
)

;; @notice Gets the total claimed rewards
;; @returns The total claimed rewards
(define-read-only (get-total-claimed)
    (ok (var-get total-claimed))
)

;; @notice Gets the total bounties paid
;; @returns The total bounties paid
(define-read-only (get-total-bounties-paid)
    (ok (var-get total-bounties-paid))
)

;; @notice Gets user position details
;; @param user The user principal
;; @returns (ok position) if found, (err error-code) otherwise
(define-read-only (get-user-position (user principal))
    (match (map-get? user-positions { user: user })
        position (ok position)
        (err ERR-POSITION-NOT-FOUND)
    )
)

;; @notice Checks if a cycle has been claimed
;; @param cycle-id The cycle to check
;; @returns (ok claimed-status) if found, (err error-code) otherwise
(define-read-only (is-cycle-claimed (cycle-id uint))
    (match (map-get? claimed-cycles { cycle-id: cycle-id })
        status (ok (get claimed status))
        (ok false)
    )
)

;; @notice Gets the claim details for a cycle
;; @param cycle-id The cycle to check
;; @returns (ok claim-details) if found, (err error-code) otherwise
(define-read-only (get-cycle-claim-details (cycle-id uint))
    (match (map-get? claimed-cycles { cycle-id: cycle-id })
        details (ok details)
        (err ERR-CYCLE-ALREADY-CLAIMED)
    )
)