(impl-trait .trait-ownable.ownable-trait)

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-AVAILABLE-ALEX (err u20000))

(define-data-var contract-owner principal tx-sender)
(define-map approved-contracts principal bool)

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

(define-map user-balance principal uint)
(define-map user-stx principal uint)

(define-data-var total-balance uint u0)
(define-data-var total-stx uint u0)

(define-data-var available-alex uint u0)
(define-data-var borrowed-alex uint u0)

(define-read-only (get-user-balance-or-default (user principal))
    (default-to u0 (map-get? user-balance user))
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


(define-public (add-to-position (dx uint))
    (let 
        (
          (sender tx-sender)
          (positions (try! (contract-call? .fixed-weight-pool-v1-01 get-position-given-burn .token-wstx .age000-governance-token u50000000 u50000000 dx)))
          (stx (get dx positions))
          (alex (get dy positions))
          (atalex-to-return (try! (contract-call? .auto-alex get-token-given-position alex)))
          (alex-available (get-available-alex-or-default))
          (alex-borrowed (get-borrowed-alex-or-default))                        
        )
        (asserts! (>= alex-available alex) ERR-AVAILABLE-ALEX)

        (try! (contract-call? .fwp-wstx-alex-50-50-v1-01 transfer-fixed dx sender (as-contract tx-sender) none))
        (try! (contract-call? .age000-governance-token mint-fixed alex tx-sender))
        (try! (contract-call? .auto-alex add-to-position alex))
        (var-set available-alex (- alex-available alex))
        (var-set borrowed-alex (+ alex-borrowed alex))
        (map-set user-balance sender (+ (get-user-balance-or-default sender) dx))
        (map-set user-stx sender (+ (get-user-stx-or-default sender) stx))
        (var-set total-balance (+ (var-get total-balance) dx))
        (var-set total-stx (+ (var-get total-stx) stx))
        (print { object: "pool", action: "position-added", data: dx})
        (ok { dx: stx, dy: alex })
    )
)

(define-public (claim-and-stake (reward-cycle uint))
  (let 
    (      
      ;; claim all that's available to claim for the reward-cycle
      (claimed (and (> (as-contract (get-user-id)) u0) (is-ok (as-contract (claim-staking-reward reward-cycle)))))
      (alex-claimed (and (> (as-contract (get-alex-user-id)) u0) (is-ok (as-contract (claim-alex-staking-reward reward-cycle)))))
      (alex-balance (unwrap! (contract-call? .age000-governance-token get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (principal-balance (unwrap! (contract-call? .fwp-wstx-alex-50-50-v1-01 get-balance-fixed (as-contract tx-sender)) ERR-GET-BALANCE-FIXED-FAIL))
      (bounty (var-get bounty-in-fixed))
      (current-cycle (unwrap! (get-reward-cycle block-height) ERR-STAKING-NOT-AVAILABLE))
    )
    (asserts! (>= block-height (var-get start-block)) ERR-NOT-ACTIVATED)
    (asserts! (> current-cycle reward-cycle) ERR-REWARD-CYCLE-NOT-COMPLETED)
    (asserts! (> alex-balance bounty) ERR-INSUFFICIENT-BALANCE)
    (asserts! (>= (var-get end-cycle) current-cycle) ERR-STAKING-NOT-AVAILABLE)

    (let 
      (
        (sender tx-sender)
        (cycles-to-stake (if (>= (var-get end-cycle) (+ current-cycle u32)) u32 (- (var-get end-cycle) current-cycle)))
      )
      (and (> principal-balance u0) (> cycles-to-stake u0) (as-contract (try! (stake-tokens principal-balance cycles-to-stake))))
      (and (> cycles-to-stake u0) (as-contract (try! (stake-alex-tokens (- alex-balance bounty) cycles-to-stake))))
      (and (> bounty u0) (as-contract (try! (contract-call? .age000-governance-token transfer-fixed bounty tx-sender sender none))))
    
      (ok true)
    )
  )
)

(define-public (reduce-position)
  (let 
    (
      (sender tx-sender)
      (alex-borrowed (get-borrowed-alex-or-default sender))
      (supply (unwrap-panic (get-balance-fixed sender)))
      (total-supply (unwrap-panic (get-total-supply-fixed)))
      (share (div-down supply total-supply))
      (vault-reduced (as-contract (try! (contract-call? .auto-fwp-wstx-alex-120 reduce-position share))))
      (pool-reduced (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 reduce-position .token-wstx .age000-governance-token u50000000 u50000000 .fwp-wstx-alex-50-50-v1-01 share))))
      (alex-returned (+ (get dy pool-reduced) (get rewards vault-reduced)))
      (stx-returned (get dx pool-reduced))      
      (alex-to-buy (if (<= alex-borrowed alex-returned) u0 (mul-down (- alex-borrowed alex-returned) (var-get shortfall-coverage))))
      (stx-to-sell (if (is-eq alex-to-buy u0) u0 (try! (contract-call? .fixed-weight-pool-v1-01 get-wstx-in-given-y-out .age000-governance-token u50000000 alex-to-buy))))
      (alex-bought (if (is-eq stx-to-sell u0) u0 (get dy (as-contract (try! (contract-call? .fixed-weight-pool-v1-01 swap-wstx-for-y .age000-governance-token u50000000 stx-to-sell (some (- alex-borrowed alex-returned))))))))
      (alex-to-return (- (+ alex-returned alex-bought) alex-borrowed))
      (stx-to-return (- stx-returned stx-to-sell))
    )
    
    ;; (as-contract (try! (contract-call? .age000-governance-token transfer-fixed alex-borrowed tx-sender .executor-dao none)))
    (as-contract (try! (contract-call? .age000-governance-token burn-fixed alex-borrowed tx-sender)))
    (as-contract (try! (contract-call? .age000-governance-token transfer-fixed alex-to-return tx-sender sender none)))
    (as-contract (try! (contract-call? .token-wstx transfer-fixed stx-to-return tx-sender sender none)))

	(try! (ft-burn? auto-fwp-wstx-alex-120y (fixed-to-decimals supply) sender))
    (print { object: "pool", action: "position-reduced", data: supply })
    (ok { stx: stx-to-return, alex: alex-to-return })
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

;; contract initialisation
;; (set-contract-owner .executor-dao)