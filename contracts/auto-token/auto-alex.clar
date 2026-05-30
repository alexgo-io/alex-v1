clarity
;; =============================================================================
;; AutoALEX — Claim-and-stake with duplicate claim protection, atomicity, and
;; comprehensive validation.
;; =============================================================================
;;
;; Security-critical patch:
;;   - Prevents repeated bounty extraction in the same cycle by tracking claimed
;;     cycles in a map.
;;   - Marks a cycle as claimed only after all operations (claim, transfer, restake)
;;     succeed, ensuring atomicity.
;;   - Validates bounty > 0, cycle boundaries, and sufficiency of contract balance.
;;   - Checks the boolean returned by `claim-staking-reward` and reverts if false.
;;   - Uses SIP‑010 compliant token transfer with a memo argument.
;;   - All error paths return descriptive, unique error codes.
;;   - Emits print events for observability and debugging.
;;
;; Performance considerations:
;;   - Single map lookup per call; no iterators.
;;   - Inline `let` bindings minimise stack depth.
;;   - `try!` propagates errors immediately.
;;
;; Maintainability:
;;   - Each logical step is separated and commented.
;;   - Error codes are defined as constants for readability.
;;   - Read-only functions expose contract state (balance, claim status).
;;   - Events are logged for transparency.
;;
;; Usage:
;;   (contract-call? .auto-alex claim-and-stake u1000)   -> (ok true) | (err u200..u206)
;;   (contract-call? .auto-alex get-cycle-claimed u5)    -> (ok false) | (ok true)
;;   (contract-call? .auto-alex get-contract-alex-balance) -> (ok <uint>)
;; =============================================================================

;; =============================================================================
;; Error codes (prefixed with ERR- for clarity)
;; =============================================================================
(define-constant ERR-CYCLE-ALREADY-CLAIMED u200)   ;; Cycle was claimed in a previous invocation.
(define-constant ERR-CLAIM-RETURNED-FALSE  u201)   ;; Underlying vault's `claim-staking-reward` returned false.
(define-constant ERR-INSUFFICIENT-BALANCE  u202)   ;; AutoALEX ALEX balance <= bounty after claim.
(define-constant ERR-BOUNTY-ZERO           u203)   ;; Bounty must be greater than zero.
(define-constant ERR-TRANSFER-FAILED       u204)   ;; SIP‑010 transfer to caller failed.
(define-constant ERR-STAKE-EXTRA-FAILED    u205)   ;; Restaking of remaining balance failed.
(define-constant ERR-CYCLE-EXPIRED         u206)   ;; Current cycle is beyond the end cycle.

;; =============================================================================
;; Data structures
;; =============================================================================

;; Map from cycle number to boolean indicating whether the cycle has been
;; successfully claimed. Set only after the entire claim-and-stake operation
;; completes without error.
(define-map claimed-cycles ((cycle uint)) (claimed bool))

;; =============================================================================
;; Public functions
;; =============================================================================

;; @public
;; @param bounty (uint) — caller reward. Must be > 0 and ≤ contract balance.
;; @returns (response bool uint) — ok true on success, err with a specific code.
;; @description
;;   1. Checks that the current cycle has not already been claimed.
;;   2. Verifies bounty > 0 and that current cycle ≤ end cycle.
;;   3. Calls `claim-staking-reward` – reverts if the call returns false.
;;   4. Reads the contract’s total ALEX balance (post-claim).
;;   5. Checks balance ≥ bounty – reverts otherwise.
;;   6. Transfers `bounty` tokens to caller (SIP‑010).
;;   7. If cycles remain, restakes the remaining balance.
;;   8. Atomically marks the cycle as claimed in `claimed-cycles`.
;;   9. Emits print events for each major step.
(define-public (claim-and-stake (bounty uint))
  (let
    (
      ;; Fetch current and end cycles from the data contract.
      (current-cycle (try! (contract-call? .auto-alex-data get-current-cycle)))
      (end-cycle     (try! (contract-call? .auto-alex-data get-end-cycle)))

      ;; Check whether this cycle is already processed.
      (already-claimed (default-to false (map-get? claimed-cycles {cycle: current-cycle})))
    )
    ;; -------- Pre‑conditions --------
    (asserts! (not already-claimed) (err ERR-CYCLE-ALREADY-CLAIMED))
    (asserts! (> bounty u0)         (err ERR-BOUNTY-ZERO))
    (asserts! (>= end-cycle current-cycle) (err ERR-CYCLE-EXPIRED))

    ;; -------- Claim staking reward --------
    (let
      (
        (claim-success (try! (contract-call? .alex-vault claim-staking-reward current-cycle)))
      )
      (asserts! claim-success (err ERR-CLAIM-RETURNED-FALSE))
      (print {event: "claim-staking-reward-success", cycle: current-cycle})

      ;; -------- Validate balance and pay bounty --------
      (let
        (
          (contract-balance (ft-get-balance .alex-token (as-contract tx-sender)))
        )
        (asserts! (>= contract-balance bounty) (err ERR-INSUFFICIENT-BALANCE))

        ;; SIP‑010 transfer from this contract (as-contract tx-sender) to caller.
        (try! (contract-call? .alex-token transfer
                              bounty
                              (as-contract tx-sender)
                              tx-sender
                              none)
              (err ERR-TRANSFER-FAILED))
        (print {event: "bounty-paid", cycle: current-cycle, amount: bounty, recipient: tx-sender})

        ;; -------- Restake remaining balance if still in a staking window --------
        (let
          (
            (cycles-left (if (>= current-cycle end-cycle) u0 (- end-cycle current-cycle)))
          )
          (if (> cycles-left u0)
            (try! (contract-call? .alex-vault stake-extra cycles-left)
                  (err ERR-STAKE-EXTRA-FAILED))
            (ok true))
          (print {event: "restake-completed", cycle: current-cycle, cycles-left: cycles-left})
        )

        ;; -------- Mark cycle as claimed (atomicity point) --------
        ;; This map-set is reached only after all previous steps succeeded.
        (map-set claimed-cycles {cycle: current-cycle} true)
        (print {event: "cycle-marked-claimed", cycle: current-cycle})
        (ok true)
      )
    )
  )
)

;; =============================================================================
;; Read-only functions
;; =============================================================================

;; @public
;; @param cycle (uint) — cycle number to query.
;; @returns (response bool uint) — ok true if the cycle was successfully claimed,
;;                                ok false otherwise.
;; @description Allows anyone to check whether a given cycle has been processed.
;;              Useful for off-chain monitoring and front-end display.
(define-read-only (get-cycle-claimed (cycle uint))
  (ok (default-to false (map-get? claimed-cycles {cycle: cycle})))
)

;; @public
;; @returns (response uint uint) — ok <current ALEX balance of this contract>.
;; @description Returns the total ALEX token balance held by this contract.
;;              Helps verify bounty availability and detect anomalies.
(define-read-only (get-contract-alex-balance)
  (ok (ft-get-balance .alex-token (as-contract tx-sender)))
)

;; =============================================================================
;; Private helper functions (none required; kept for clarity)
;; =============================================================================