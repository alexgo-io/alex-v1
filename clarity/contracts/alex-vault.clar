(impl-trait .trait-vault.vault-trait)

(use-trait ft-trait .trait-sip-010.sip-010-trait)
(use-trait flash-loan-user-trait .trait-flash-loan-user.flash-loan-user-trait)

(define-map token-data-map
  { token : principal }
  {
    shares-total: uint,
    balance: uint,
    fee-balance: uint,
    fee-to-address: principal,
    swap-token: principal,
    name: (string-ascii 32),
  }
)

;; returns the balance of token
(define-read-only (get-balance (token <ft-trait>))
  ;;use https://docs.stacks.co/references/language-functions#ft-get-balance
  ;;(ft-get-balance token tx-sender)
   (ok u0)
)

;; returns list of {token, balance}
(define-read-only (get-balances)
  ;;Clarity doesn't support loop, so we need to maintain a list of tokens to apply map to get-balance
  ;;See get-pool-contracts and get-pools in fixed-weight-pool
  (ok (list {token: "nothing", balance: u0}))
)


;; flash loan to flash loan user up to 3 tokens of amounts specified
(define-public (flash-loan (flash-loan-user <flash-loan-user-trait>) (tokens (list 3 <ft-trait>)) (amounts (list 3 uint)))
  ;; get the requested tokens
  ;; call execute of flash-loan-user
  ;; if all good, then return true, otherwise, roll back and return false
  (ok true)
)
