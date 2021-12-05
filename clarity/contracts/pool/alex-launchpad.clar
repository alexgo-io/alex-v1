(impl-trait .trait-ownable.ownable-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

;; alex-launchpad

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TRANSFER-FAILED (err u3000))
(define-constant ERR-USER-ALREADY-REGISTERED (err u10001))
(define-constant ERR-USER-ID-NOT-FOUND (err u10003))
(define-constant ERR-ACTIVATION-THRESHOLD-REACHED (err u10004))
(define-constant ERR-CONTRACT-NOT-ACTIVATED (err u10005))
(define-constant ERR-INVALID-TOKEN (err u2026))
(define-constant ERR-INVALID-TICKET (err u2028))
(define-constant ERR-TICKET-TRANSFER-FAILED (err u2029))
(define-constant ERR_NO_VRF_SEED_FOUND (err u2030))
(define-constant ERR-CLAIM-NOT-AVAILABLE (err u2031))
(define-constant ERR-TOKEN-UNDER-SUBSCRIBED (err u2032))

(define-constant ONE_8 (pow u10 u8)) ;; 8 decimal places

(define-data-var CONTRACT-OWNER principal tx-sender)

(define-read-only (get-owner)
  (ok (var-get CONTRACT-OWNER))
)

(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ok (var-set CONTRACT-OWNER owner))
  )
)

(define-map listing 
  principal
  {    
    ticket: principal,
    fee-to-address: principal,
    total-tickets: uint,
    amount-per-ticket: uint,
    wstx-per-ticket-in-fixed: uint,
    total-subscribed: uint,
    activation-block: uint,
    activation-delay: uint,
    activation-threshold: uint,
    users-nonce: uint,
    last-random: uint,
    tickets-won: uint
  }
)

(define-map subscriber-at-token
  {
    token: principal,
    user-id: uint
  }
  {
    ticket-balance: uint,
    value-low: uint,
    value-high: uint
  }
)

;; store user principal by user id
(define-map users 
  {
    token: principal,
    user-id: uint
  }
  principal
)
;; store user id by user principal
(define-map user-ids 
  {
    token: principal,
    user: principal
  }
  uint
)

;; wstx-per-ticket-in-fixed => 8 decimal
;; all others => zero decimal
(define-public (create-pool (token-trait <ft-trait>) (ticket-trait <ft-trait>) (fee-to-address principal) (amount-per-ticket uint) (wstx-per-ticket-in-fixed uint) (activation-delay uint) (activation-threshold uint))
  (begin
    (asserts! (is-eq contract-caller (var-get CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (map-set listing 
      (contract-of token-trait)
      {        
        ticket: (contract-of ticket-trait), 
        fee-to-address: fee-to-address,
        amount-per-ticket: amount-per-ticket,
        wstx-per-ticket-in-fixed: wstx-per-ticket-in-fixed, 
        total-subscribed: u0,
        total-tickets: u0, 
        activation-block: u340282366920938463463374607431768211455,
        activation-delay: activation-delay,
        activation-threshold: activation-threshold,
        users-nonce: u0,
        last-random: u0,
        tickets-won: u0
      }
    )    
    (ok true)
  )
)

(define-public (add-to-position (token-trait <ft-trait>) (tickets uint))
  (let
    (
      (details (unwrap! (map-get? listing (contract-of token-trait)) ERR-INVALID-TOKEN)) 
    )
    (asserts! (is-eq (get fee-to-address details) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get activation-block details) u340282366920938463463374607431768211455) ERR-ACTIVATION-THRESHOLD-REACHED)
    (asserts! (> tickets u0) ERR-INVALID-TICKET)

    (map-set listing (contract-of token-trait) (merge details { total-tickets: (+ (get total-tickets details) tickets ) }))

    (unwrap! (contract-call? token-trait transfer-fixed (* (get amount-per-ticket details) tickets ONE_8) tx-sender (as-contract tx-sender) none) ERR-TRANSFER-FAILED)
    (ok true)
  )
)

;; returns Stacks block height registration was activated at plus activationDelay
(define-read-only (get-activation-block (token principal))
  (ok (get activation-block (unwrap! (map-get? listing token) ERR-INVALID-TOKEN)))
)

;; returns activation delay
(define-read-only (get-activation-delay (token principal))
  (ok (get activation-delay (unwrap! (map-get? listing token) ERR-INVALID-TOKEN)))
)

;; returns activation threshold
(define-read-only (get-activation-threshold (token principal))
  (ok (get activation-threshold (unwrap! (map-get? listing token) ERR-INVALID-TOKEN)))
)

(define-read-only (get-token-details (token principal))
  (map-get? listing token)
)

;; returns (some user-id) or none
(define-read-only (get-user-id (token principal) (user principal))
  (map-get? user-ids {token: token, user: user})
)

;; returns (some user-principal) or none
(define-read-only (get-user (token principal) (user-id uint))
  (map-get? users {token: token, user-id: user-id})
)

;; returns (some number of registered users), used for activation and tracking user IDs, or none
(define-read-only (get-registered-users-nonce (token principal))
  (ok (get users-nonce (unwrap! (map-get? listing token) ERR-INVALID-TOKEN)))
)

;; returns user ID if it has been created, or creates and returns new ID
(define-private (get-or-create-user-id (token principal) (user principal))
  (match
    (map-get? user-ids {token: token, user: user})
    value
    (ok value)
    (let
      (
        (new-id (+ u1 (try! (get-registered-users-nonce token))))
        (details (unwrap! (map-get? listing token) ERR-INVALID-TOKEN))
        (details-updated (merge details { users-nonce: new-id }))
      )
      (map-insert users {token: token, user-id: new-id} user)
      (map-insert user-ids {token: token, user: user} new-id)
      (map-set listing token details-updated)
      (ok new-id)
    )
  )
)

(define-public (register (token principal) (ticket-trait <ft-trait>) (ticket-amount uint))
  (begin
    (asserts! (is-none (get-user-id token tx-sender)) ERR-USER-ALREADY-REGISTERED)    
    (let
      (
        (details (unwrap! (map-get? listing token) ERR-INVALID-TOKEN))
        (user-id (try! (get-or-create-user-id token tx-sender)))
        (value-low (+ u1 (get total-subscribed details)))
        (value-high (- (+ value-low ticket-amount) u1))
        (details-updated (merge details { total-subscribed: value-high }))
      )
      (asserts! (and (is-eq (contract-of ticket-trait) (get ticket details)) (> ticket-amount u0)) ERR-INVALID-TICKET)

      (asserts! (< block-height (get activation-block details)) ERR-ACTIVATION-THRESHOLD-REACHED)
    
      (unwrap! (contract-call? ticket-trait transfer-fixed (* ticket-amount ONE_8) tx-sender (as-contract tx-sender) none) ERR-TICKET-TRANSFER-FAILED)
      (unwrap! (contract-call? .token-wstx transfer-fixed (* ticket-amount (get wstx-per-ticket-in-fixed details)) tx-sender (as-contract tx-sender) none) ERR-TRANSFER-FAILED)

      (map-set subscriber-at-token { token: token, user-id: user-id} { ticket-balance: ticket-amount, value-low: value-low, value-high: value-high })
      (map-set listing token details-updated)
      (and (is-eq user-id (try! (get-activation-threshold token))) (map-set listing token (merge details-updated { activation-block: (+ block-height (get activation-delay details)) })))      
      (ok true)
    )
  )
)

(define-read-only (get-subscriber-at-token-or-default (token principal) (user-id uint))
  (default-to { ticket-balance: u0, value-low: u0, value-high: u0 } (map-get? subscriber-at-token { token: token, user-id: user-id }))
)

(define-public (claim (token-trait <ft-trait>) (ticket-trait <ft-trait>))
  (begin
    (asserts! (>= (get total-subscribed (unwrap! (map-get? listing (contract-of token-trait)) ERR-INVALID-TOKEN)) (get total-tickets (unwrap! (map-get? listing (contract-of token-trait)) ERR-INVALID-TOKEN))) ERR-TOKEN-UNDER-SUBSCRIBED)
    (let
      (
        (token (contract-of token-trait))
        (details (unwrap! (map-get? listing token) ERR-INVALID-TOKEN))
        (user-id (unwrap! (get-user-id token tx-sender) ERR-USER-ID-NOT-FOUND))
        (sub-details (get-subscriber-at-token-or-default token user-id))
        (activation-block (get activation-block details))
        (total-tickets (get total-tickets details))
        (total-subscribed (get total-subscribed details))
        (tickets-won (get tickets-won details))
        (ticket-balance (get ticket-balance sub-details))
        (vrf-seed (unwrap! (get-random-uint-at-block activation-block) ERR_NO_VRF_SEED_FOUND))
        (last-random (if (is-eq (get last-random details) u0) (mod vrf-seed total-subscribed) (get last-random details)))
        (this-random (mod (get-next-random last-random) total-subscribed))
        (value-low (get value-low sub-details))
        (value-high (get value-high sub-details))
        (value-low-adjusted 
          (if (< value-low (/ total-tickets u2)) 
            u0 
            (if (> (+ value-high (/ total-tickets u2)) total-subscribed)
              (- (- total-subscribed total-tickets) (- value-high value-low))
              (- value-low (/ total-tickets u2))
            )
          )
        )
        (value-high-adjusted 
          (if (< value-low (/ total-tickets u2)) 
            (+ value-high (- total-tickets value-low)) 
            (if (> (+ value-high (/ total-tickets u2)) total-subscribed)
              total-subscribed
              (+ value-high (/ total-tickets u2))
            )
          )
        )                  
      )      
      (asserts! (> block-height activation-block) ERR-CONTRACT-NOT-ACTIVATED)
      (asserts! (is-eq (contract-of ticket-trait) (get ticket details)) ERR-INVALID-TICKET)
      (asserts! (> ticket-balance u0) ERR-CLAIM-NOT-AVAILABLE)    
      
      (map-set subscriber-at-token { token: token, user-id: user-id} (merge sub-details { ticket-balance: (- ticket-balance u1) }))      
      
      (if (and (<= tickets-won total-tickets) (>= this-random value-low-adjusted) (<= this-random value-high-adjusted))
        (begin
          (unwrap! (contract-call? token-trait transfer-fixed (* (get amount-per-ticket details) ONE_8) (as-contract tx-sender) tx-sender none) ERR-TRANSFER-FAILED)
          (unwrap! (contract-call? .token-wstx transfer-fixed (get wstx-per-ticket-in-fixed details) (as-contract tx-sender) (get fee-to-address details) none) ERR-TRANSFER-FAILED)
          (try! (contract-call? ticket-trait burn-fixed ONE_8 tx-sender))
          (map-set listing token (merge details { last-random: this-random, tickets-won: (+ tickets-won u1) }))          
          (ok true)
        )
        (begin
          (unwrap! (contract-call? .token-wstx transfer-fixed (get wstx-per-ticket-in-fixed details) (as-contract tx-sender) tx-sender none) ERR-TRANSFER-FAILED)
          (try! (contract-call? ticket-trait burn-fixed ONE_8 tx-sender))
          (map-set listing token (merge details { last-random: this-random }))
          (ok false)
        )
      )
    )
  )
)

;; implementation of Linear congruential generator following Numerical Recipes
(define-private (get-next-random (last-random uint))  
    (mod (+ (* u1664525 last-random) u1013904223) (pow u2 u32))
)

;; VRF

;; Read the on-chain VRF and turn the lower 16 bytes into a uint
(define-private (get-random-uint-at-block (stacksBlock uint))
  (let (
    (vrf-lower-uint-opt
      (match (get-block-info? vrf-seed stacksBlock)
        vrf-seed (some (buff-to-uint-le (lower-16-le vrf-seed)))
        none))
  )
  vrf-lower-uint-opt)
)

;; UTILITIES

;; lookup table for converting 1-byte buffers to uints via index-of
(define-constant BUFF_TO_BYTE (list 
    0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f
    0x10 0x11 0x12 0x13 0x14 0x15 0x16 0x17 0x18 0x19 0x1a 0x1b 0x1c 0x1d 0x1e 0x1f
    0x20 0x21 0x22 0x23 0x24 0x25 0x26 0x27 0x28 0x29 0x2a 0x2b 0x2c 0x2d 0x2e 0x2f
    0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37 0x38 0x39 0x3a 0x3b 0x3c 0x3d 0x3e 0x3f
    0x40 0x41 0x42 0x43 0x44 0x45 0x46 0x47 0x48 0x49 0x4a 0x4b 0x4c 0x4d 0x4e 0x4f
    0x50 0x51 0x52 0x53 0x54 0x55 0x56 0x57 0x58 0x59 0x5a 0x5b 0x5c 0x5d 0x5e 0x5f
    0x60 0x61 0x62 0x63 0x64 0x65 0x66 0x67 0x68 0x69 0x6a 0x6b 0x6c 0x6d 0x6e 0x6f
    0x70 0x71 0x72 0x73 0x74 0x75 0x76 0x77 0x78 0x79 0x7a 0x7b 0x7c 0x7d 0x7e 0x7f
    0x80 0x81 0x82 0x83 0x84 0x85 0x86 0x87 0x88 0x89 0x8a 0x8b 0x8c 0x8d 0x8e 0x8f
    0x90 0x91 0x92 0x93 0x94 0x95 0x96 0x97 0x98 0x99 0x9a 0x9b 0x9c 0x9d 0x9e 0x9f
    0xa0 0xa1 0xa2 0xa3 0xa4 0xa5 0xa6 0xa7 0xa8 0xa9 0xaa 0xab 0xac 0xad 0xae 0xaf
    0xb0 0xb1 0xb2 0xb3 0xb4 0xb5 0xb6 0xb7 0xb8 0xb9 0xba 0xbb 0xbc 0xbd 0xbe 0xbf
    0xc0 0xc1 0xc2 0xc3 0xc4 0xc5 0xc6 0xc7 0xc8 0xc9 0xca 0xcb 0xcc 0xcd 0xce 0xcf
    0xd0 0xd1 0xd2 0xd3 0xd4 0xd5 0xd6 0xd7 0xd8 0xd9 0xda 0xdb 0xdc 0xdd 0xde 0xdf
    0xe0 0xe1 0xe2 0xe3 0xe4 0xe5 0xe6 0xe7 0xe8 0xe9 0xea 0xeb 0xec 0xed 0xee 0xef
    0xf0 0xf1 0xf2 0xf3 0xf4 0xf5 0xf6 0xf7 0xf8 0xf9 0xfa 0xfb 0xfc 0xfd 0xfe 0xff
))

;; Convert a 1-byte buffer into its uint representation.
(define-private (buff-to-u8 (byte (buff 1)))
  (unwrap-panic (index-of BUFF_TO_BYTE byte))
)

;; Convert a little-endian 16-byte buff into a uint.
(define-private (buff-to-uint-le (word (buff 16)))
  (get acc
    (fold add-and-shift-uint-le (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15) { acc: u0, data: word })
  )
)

;; Inner fold function for converting a 16-byte buff into a uint.
(define-private (add-and-shift-uint-le (idx uint) (input { acc: uint, data: (buff 16) }))
  (let (
    (acc (get acc input))
    (data (get data input))
    (byte (buff-to-u8 (unwrap-panic (element-at data idx))))
  )
  {
    ;; acc = byte * (2**(8 * (15 - idx))) + acc
    acc: (+ (* byte (pow u2 (* u8 (- u15 idx)))) acc),
    data: data
  })
)

;; Convert the lower 16 bytes of a buff into a little-endian uint.
(define-private (lower-16-le (input (buff 32)))
  (get acc
    (fold lower-16-le-closure (list u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31) { acc: 0x, data: input })
  )
)

;; Inner closure for obtaining the lower 16 bytes of a 32-byte buff
(define-private (lower-16-le-closure (idx uint) (input { acc: (buff 16), data: (buff 32) }))
  (let (
    (acc (get acc input))
    (data (get data input))
    (byte (unwrap-panic (element-at data idx)))
  )
  {
    acc: (unwrap-panic (as-max-len? (concat acc byte) u16)),
    data: data
  })
)