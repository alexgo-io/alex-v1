(impl-trait .trait-ownable.ownable-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-AVAILABLE-ALEX (err u20000))
(define-constant ERR-INVALID-LIQUIDITY (err u2003))
(define-constant ERR-REWARD-CYCLE-NOT-COMPLETED (err u10017))
(define-constant ERR-STAKING-NOT-AVAILABLE (err u10015))
(define-constant ERR-GET-BALANCE-FIXED-FAIL (err u6001))
(define-constant ERR-NOT-ACTIVATED (err u2043))
(define-constant ERR-ACTIVATED (err u2044))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2045))
(define-constant ERR-INVALID-PERCENT (err u5000))
(define-constant ERR-ALREADY-PROCESSED (err u1409))
(define-constant ERR-DISTRIBUTION (err u1410))

(define-constant ONE_8 u100000000)

(define-data-var end-cycle uint u32)
(define-data-var start-block uint u340282366920938463463374607431768211455)
(define-data-var open-to-all bool false)

(define-read-only (get-start-block)
  (var-get start-block)
)

(define-public (set-start-block (new-start-block uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set start-block new-start-block))
  )
)

(define-read-only (get-end-cycle)
  (var-get end-cycle)
)

(define-public (set-end-cycle (new-end-cycle uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set end-cycle new-end-cycle))
  )
)

(define-read-only (get-open-to-all)
  (var-get open-to-all)
)

(define-public (set-open-to-all (new-open-to-all bool))
  (begin
    (try! (check-is-owner))
    (ok (var-set open-to-all new-open-to-all))
  )
)

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)
(define-map processed-batches { cycle: uint, batch: uint } bool)

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner))
)

(define-public (set-contract-owner (owner principal))
  (begin
    (try! (check-is-owner))
    (ok (var-set contract-owner owner))
  )
)

(define-private (check-is-owner)
  (ok (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED))
)

(define-private (check-is-approved)
  (ok (asserts! (default-to false (map-get? approved-contracts tx-sender)) ERR-NOT-AUTHORIZED))
)

(define-public (add-approved-contract (new-approved-contract principal))
  (begin
    (try! (check-is-owner))
    (ok (map-set approved-contracts new-approved-contract true))
  )
)

(define-map user-balance-per-cycle { user: principal, cycle: uint } uint)
(define-map total-balance-per-cycle uint uint)

(define-map user-stx principal uint)
(define-data-var total-stx uint u0)

(define-data-var available-alex uint u0)
(define-data-var borrowed-alex uint u0)

(define-data-var shortfall-coverage uint u110000000) ;; 1.1x

(define-map distributable-per-cycle uint uint)
(define-map distributed-per-cycle uint uint)
(define-map user-distributed-per-cycle { user: principal, cycle: uint } bool)

(define-read-only (get-shortfall-coverage)
  (ok (var-get shortfall-coverage))
)

(define-public (set-shortfall-coverage (new-shortfall-coverage uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set shortfall-coverage new-shortfall-coverage))
  )
)

(define-read-only (get-user-balance-per-cycle-or-default (user principal) (cycle uint))
  (default-to u0 (map-get? user-balance-per-cycle { user: user, cycle: cycle }))
)

(define-read-only (get-total-balance-per-cycle-or-default (cycle uint))
  (default-to u0 (map-get? total-balance-per-cycle cycle))
)

(define-read-only (get-user-distributed-per-cycle-or-default (user principal) (cycle uint))
  (default-to false (map-get? user-distributed-per-cycle { user: user, cycle: cycle }))
)

(define-read-only (get-distributable-per-cycle-or-default (cycle uint))
  (default-to u0 (map-get? distributable-per-cycle cycle))
)

(define-read-only (get-distributed-per-cycle-or-default (cycle uint))
  (default-to u0 (map-get? distributed-per-cycle cycle))
)

(define-read-only (get-user-stx-or-default (user principal))
    (default-to u0 (map-get? user-stx user))
)

(define-public (set-available-alex (new-amount uint))
    (begin
        (try! (check-is-owner))
        (ok (var-set available-alex new-amount))
    )
)

(define-read-only (get-available-alex)
  (var-get available-alex)
)

(define-read-only (get-borrowed-alex)
  (var-get borrowed-alex)
)

(define-read-only (get-total-stx)
  (var-get total-stx)
)

(define-data-var bounty-in-fixed uint u1000000000) ;; 10 ALEX

(define-read-only (get-bounty-in-fixed)
  (ok (var-get bounty-in-fixed))
)

(define-public (set-bounty-in-fixed (new-bounty-in-fixed uint))
  (begin
    (try! (check-is-owner))
    (ok (var-set bounty-in-fixed new-bounty-in-fixed))
  )
)

;; private functions
;;
(define-private (get-alex-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .age000-governance-token (get-alex-user-id) reward-cycle)
)
(define-private (get-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staking-reward .fwp-wstx-alex-50-50-v1-01 (get-user-id) reward-cycle)
)
(define-private (get-alex-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .age000-governance-token reward-cycle (get-alex-user-id))
)
(define-private (get-staker-at-cycle (reward-cycle uint))
  (contract-call? .alex-reserve-pool get-staker-at-cycle-or-default .fwp-wstx-alex-50-50-v1-01 reward-cycle (get-user-id))
)
(define-private (get-alex-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .age000-governance-token tx-sender))
)
(define-private (get-user-id)
  (default-to u0 (contract-call? .alex-reserve-pool get-user-id .fwp-wstx-alex-50-50-v1-01 tx-sender))
)
(define-private (get-alex-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .age000-governance-token stack-height)
)
(define-private (get-reward-cycle (stack-height uint))
  (contract-call? .alex-reserve-pool get-reward-cycle .fwp-wstx-alex-50-50-v1-01 stack-height)
)
(define-private (stake-alex-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens .age000-governance-token amount-tokens lock-period)
)
(define-private (stake-tokens (amount-tokens uint) (lock-period uint))
  (contract-call? .alex-reserve-pool stake-tokens .fwp-wstx-alex-50-50-v1-01 amount-tokens lock-period)
)
(define-private (claim-alex-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .age000-governance-token reward-cycle)
)
(define-private (claim-staking-reward (reward-cycle uint))
  (contract-call? .alex-reserve-pool claim-staking-reward .fwp-wstx-alex-50-50-v1-01 reward-cycle)
)

(define-private (sum-claimed (claimed-response (response { entitled-token: uint, to-return: uint } uint)) (prior-response (response { entitled-token: uint, to-return: uint } uint)))
  (let
    (
      (claimed (try! claimed-response))
      (prior (try! prior-response))
    )
    (ok { entitled-token: (+ (get entitled-token claimed) (get entitled-token prior)), to-return: (+ (get to-return claimed) (get to-return prior)) })
  )
)

(define-public (claim-and-add-to-position-many (reward-cycles (list 50 uint)))
  (let
    (
      (claimed (map claim-staking-reward reward-cycles))
      (total-claimed (try! (fold sum-claimed claimed (ok { entitled-token: u0, to-return: u0 }))))
    )
    (try! (add-to-position-internal (get to-return total-claimed)))
    (try! (contract-call? .auto-alex add-to-position (get entitled-token total-claimed)))
    (ok claimed)
  )
)

(define-public (claim-and-add-to-position (reward-cycle uint))
  (let
    (
      (claimed (try! (claim-staking-reward reward-cycle)))
    )
    (try! (add-to-position-internal (get to-return claimed)))
    (contract-call? .auto-alex add-to-position (get entitled-token claimed))
  )
)

(define-public (add-to-position (dx uint))
  (begin
    (asserts! (var-get open-to-all) ERR-NOT-ACTIVATED)
    (add-to-position-internal dx)
  )
)

(define-private (update-balance-iter (cycle uint) (prior { user: principal, balance: uint, total-balance: uint }))
  (begin
    (map-set user-balance-per-cycle { user: (get user prior), cycle: cycle } (get balance prior))
    (map-set total-balance-per-cycle cycle (get total-balance prior))
    prior
  )
)

(define-private (add-to-position-internal (dx uint))
    (let
        (
          (sender tx-sender)
          (positions (try! (contract-call? .fixed-weight-pool-v1-01 get-position-given-burn .token-wstx .age000-governance-token u50000000 u50000000 dx)))
          (stx (get dx positions))
          (alex (get dy positions))
          (atalex-to-return (try! (contract-call? .auto-alex get-token-given-position alex)))
          (alex-available (get-available-alex))
          (alex-borrowed (get-borrowed-alex))
          (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
          (cycles-to-stake (if (> (var-get end-cycle) (+ current-cycle u32)) u32 (- (var-get end-cycle) current-cycle)))
        )
        (asserts! (> (var-get end-cycle) current-cycle) ERR-STAKING-NOT-AVAILABLE)
        (asserts! (>= block-height (var-get start-block)) ERR-NOT-ACTIVATED)
        (asserts! (> dx u0) ERR-INVALID-LIQUIDITY)
        (asserts! (>= alex-available alex) ERR-AVAILABLE-ALEX)

        (try! (contract-call? .fwp-wstx-alex-50-50-v1-01 transfer-fixed dx sender (as-contract tx-sender) none))
        (as-contract (try! (stake-tokens dx cycles-to-stake)))
        (as-contract (try! (contract-call? .age000-governance-token mint-fixed alex sender)))
        (try! (contract-call? .auto-alex add-to-position alex))
        (var-set available-alex (- alex-available alex))
        (var-set borrowed-alex (+ alex-borrowed alex))
        (fold
          update-balance-iter
          (get-reward-cycle-indexes (+ current-cycle u1))
          {
            user: sender,
            balance: (+ (get-user-balance-per-cycle-or-default sender (+ current-cycle u1)) dx),
            total-balance: (+ (get-total-balance-per-cycle-or-default (+ current-cycle u1)) dx)
          }
        )
        (map-set user-stx sender (+ (get-user-stx-or-default sender) stx))
        (var-set total-stx (+ (var-get total-stx) stx))
        (print { object: "pool", action: "position-added", data: dx })
        (ok { dx: stx, dy: alex })
    )
)

(define-read-only (is-cycle-bountiable (reward-cycle uint))
  (> (/ (as-contract (get-staking-reward reward-cycle)) u2) (var-get bounty-in-fixed))
)

(define-public (claim-and-stake (reward-cycle uint))
  (let
    (
      (sender tx-sender)
      (bounty (var-get bounty-in-fixed))
      (claimed (if (is-eq (as-contract (get-user-id)) u0) { to-return: u0, entitled-token: u0 } (as-contract (try! (claim-staking-reward reward-cycle)))))
      (alex-claimed (if (is-eq (as-contract (get-alex-user-id)) u0) { to-return: u0, entitled-token: u0 } (as-contract (try! (claim-alex-staking-reward reward-cycle)))))
      (principal-to-stake (get to-return claimed))
      (alex-to-distribute (/ (get entitled-token claimed) u2))
      (alex-to-stake (- (+ (get entitled-token claimed) (get to-return alex-claimed) (get entitled-token alex-claimed)) alex-to-distribute))
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
      (cycles-to-stake (if (>= (var-get end-cycle) (+ current-cycle u32)) u32 (if (<= (var-get end-cycle) current-cycle) u0 (- (var-get end-cycle) current-cycle))))
    )
    (asserts! (>= block-height (var-get start-block)) ERR-NOT-ACTIVATED)
    (asserts! (> current-cycle reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (> alex-to-distribute bounty) ERR-INSUFFICIENT-BALANCE)

    (and (> principal-to-stake u0) (> cycles-to-stake u0) (as-contract (try! (stake-tokens principal-to-stake cycles-to-stake))))
    (and (> alex-to-stake u0) (> cycles-to-stake u0) (as-contract (try! (stake-alex-tokens alex-to-stake cycles-to-stake))))
    (as-contract (try! (contract-call? .auto-alex add-to-position (- alex-to-distribute bounty))))
    (and (> bounty u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none))))
    (map-set distributable-per-cycle reward-cycle (try! (contract-call? .auto-alex get-token-given-position (- alex-to-distribute bounty))))
    (ok true)
  )
)


(define-private (distribute-iter (recipient principal) (prior (response { cycle: uint, atalex: uint, balance: uint, sum: uint } uint)))
  (let
    (
      (prior-unwrapped (try! prior))
      (cycle (get cycle prior-unwrapped))
      (sum (get sum prior-unwrapped))
      (atalex (get atalex prior-unwrapped))
      (balance (get balance prior-unwrapped))
      (shares (div-down (mul-down atalex (get-user-balance-per-cycle-or-default recipient cycle)) balance))
    )
    (if (get-user-distributed-per-cycle-or-default recipient cycle)
      ;; if the user already received distribution, then skip
      (ok { cycle: cycle, atalex: atalex, balance: balance, sum: sum })
      (begin
        (as-contract (try! (contract-call? .auto-alex transfer-fixed shares tx-sender recipient none)))
        (map-set user-distributed-per-cycle { user: recipient, cycle: cycle } true)
        (ok { cycle: cycle, atalex: atalex, balance: balance, sum: (+ sum shares) })
      )
    )
  )
)

(define-read-only (is-cycle-batch-processed (cycle uint) (batch uint))
  (default-to
    false
    (map-get? processed-batches { cycle: cycle, batch: batch })
  )
)

(define-public (distribute (cycle uint) (batch uint) (recipients (list 200 principal)))
	(begin
		(asserts! (or (is-ok (check-is-owner)) (is-ok (check-is-approved))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (is-cycle-batch-processed cycle batch) false) ERR-ALREADY-PROCESSED)
    (asserts! (> (get-distributable-per-cycle-or-default cycle) u0) ERR-DISTRIBUTION)
    (let
      (
        (output (try! (fold distribute-iter recipients (ok { cycle: cycle, atalex:  (get-distributable-per-cycle-or-default cycle), balance:  (get-total-balance-per-cycle-or-default cycle), sum: u0 }))))
      )
      (map-set processed-batches { cycle: cycle, batch: batch } true)
      (map-set distributed-per-cycle cycle (+ (get-distributed-per-cycle-or-default cycle) (get sum output)))

      (ok (get sum output))
    )
	)
)

(define-public (reduce-position)
  (begin
    (asserts! (>= block-height (var-get start-block)) ERR-NOT-ACTIVATED)
    (asserts! (> (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE) (var-get end-cycle)) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts!
      (and
        (> (get-distributable-per-cycle-or-default (var-get end-cycle)) u0)
        (is-eq (/ (get-distributable-per-cycle-or-default (var-get end-cycle)) ONE_8) (/ (get-distributed-per-cycle-or-default (var-get end-cycle)) ONE_8))
      )
      ERR-DISTRIBUTION
    )
    (let
      (
        (sender tx-sender)
        (user-balance (get-user-balance-per-cycle-or-default sender (var-get end-cycle)))
        (total-balance (get-total-balance-per-cycle-or-default (var-get end-cycle)))
        (percent (div-down user-balance total-balance))
        (alex-balance (mul-down percent (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL)))
        (pool-reduced (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 reduce-position .token-wstx .age000-governance-token u50000000 u50000000 .fwp-wstx-alex-50-50-v1-01 percent))))
        (stx-reduced (get dx pool-reduced))
        (alex-reduced (get dy pool-reduced))
        (stx-promised (get-user-stx-or-default sender))
        (stx-to-buy (if (<= stx-promised stx-reduced) u0 (mul-down (- stx-promised stx-reduced) (var-get shortfall-coverage))))
        (alex-available (+ alex-reduced alex-balance))
        (alex-to-sell-uncapped (if (is-eq stx-to-buy u0) u0 (try! (contract-call? .fixed-weight-pool-v1-01 get-y-in-given-wstx-out .age000-governance-token u50000000 stx-to-buy))))
        (alex-to-sell (if (<= alex-to-sell-uncapped alex-available) alex-to-sell-uncapped alex-available))
        (stx-bought (if (is-eq alex-to-sell u0) u0 (get dx (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 swap-y-for-wstx .age000-governance-token u50000000 alex-to-sell none))))))
        (stx-available (+ stx-reduced stx-bought))
        (stx-to-return (if (<= stx-available stx-promised) stx-available stx-promised))
        (alex-residual (- alex-available alex-to-sell))
        (stx-residual (- stx-available stx-to-return))
      )

      (map-set user-balance-per-cycle { user: sender, cycle: (var-get end-cycle) } u0)
      (map-set total-balance-per-cycle (var-get end-cycle) (- total-balance user-balance))
      (var-set total-stx (- (var-get total-stx) stx-promised))
      (map-set user-stx sender u0)

      (and (> stx-to-return u1000) (as-contract (try! (contract-call? .token-wstx transfer-fixed (* (/ stx-to-return u1000) u1000) tx-sender sender none))))
      (and (> stx-residual u1000) (as-contract (try! (contract-call? .token-wstx transfer-fixed (* (/ stx-residual u1000) u1000) tx-sender (var-get contract-owner) none))))
      (and (> alex-residual u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed alex-residual tx-sender (var-get contract-owner) none))))
      (print { object: "pool", action: "position-reduced", data: { dx: stx-reduced, dy: alex-reduced } })
      (ok { stx-to-return: stx-to-return, stx-residual: stx-residual, alex-residual: alex-residual })
    )
  )
)


(define-private (mul-down (a uint) (b uint))
    (/ (* a b) ONE_8)
)

(define-private (div-down (a uint) (b uint))
  (if (is-eq a u0)
    u0
    (/ (* a ONE_8) b)
  )
)

(define-constant REWARD-CYCLE-INDEXES (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31))

(define-private (get-reward-cycle-indexes (cycle uint))
  (map
    +
    REWARD-CYCLE-INDEXES
    (list
      cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle
      cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle
      cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle	cycle
      cycle	cycle
    )
  )
)

;; contract initialisation
;; (set-contract-owner .executor-dao)
