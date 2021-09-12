(impl-trait .trait-oracle.oracle-trait)

;; Open-Oracle for local Clarinet and RegTest
;; Oracle-Owner is set to deployer. It is currently hard coded but need to change to 
;; Oracle Provider (On Test script) and Oracle Owner is both deployer for now.
;; Before calling token price through oracle, each test script should update price using 'update-price' function in oracle.
;; Oracle-Src needs to be kept same vaule (eg. alextestoracle ) during testing for now. 

;;(contract-call? 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.open-oracle get-price "alextestoracle" "USDA")

(define-constant not-authorized-err (err u1000))
(define-constant err-token-not-in-oracle (err u7001))

;; Let's keep oracle-owner to deployer for now.
(define-data-var oracle-owner principal tx-sender)

(define-map prices
  { oracle-src: (string-ascii 32),
    symbol: (string-ascii 32) }
  {
    last-price-in-cents: uint,
    last-block: uint
  }
)

;; For Testing Purpose, need for mocking oracle. 
;; price must be in fixed point integer
(define-public (update-price (symbol (string-ascii 32)) (oracle-src (string-ascii 32)) (price uint))
  (if (is-eq tx-sender (var-get oracle-owner))
    (begin
      (map-set prices { symbol: symbol, oracle-src: oracle-src } { last-price-in-cents: price, last-block: u0 })
      (ok price)
    )
    (err not-authorized-err)
  )
)

;; oracle-src : Source of Oracle, lets keep for test-oracle for now. 
;; symbol : Token Symbol
(define-read-only (get-price (oracle-src (string-ascii 32)) (symbol (string-ascii 32)))
  (let
    (
      (price-map (unwrap! (map-get? prices {symbol: symbol, oracle-src: oracle-src }) err-token-not-in-oracle))
      (last-price (get last-price-in-cents price-map))
      (last-block (get last-block price-map))
    )
    (ok last-price)
  )
)

;; TODO: On future when oracle owner in block chain can be controlled, implementing is required.
;; (define-public (set-oracle-owner (address principal))
;;   (begin
;;     (asserts! (is-eq tx-sender (var-get oracle-owner)) (err not-authorized-err))

;;     (ok (var-set oracle-owner address))
;;   )
;; )