(impl-trait .trait-oracle.oracle-trait)

;; Open-Oracle for local Clarinet and RegTest
;; Oracle-Owner is set to deployer. It is currently hard coded but need to change to 
;; Oracle Provider (On Test script) and Oracle Owner is both deployer for now.
;; Before calling token price through oracle, each test script should update price using 'update-price' function in oracle.
;; Oracle-Src needs to be kept same vaule (eg. alextestoracle ) during testing for now. 

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-TOKEN-NOT-IN-ORACLE (err u7001))
(define-constant ONE_8 u100000000) ;; 8 decimal places

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
;; @desc update-price
;; @restriced Oracle-Owner
;; @params symbol
;; @params oracle-src
;; @params price
;; @returns (response uint)
(define-public (update-price (symbol (string-ascii 32)) (oracle-src (string-ascii 32)) (price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-owner)) ERR-NOT-AUTHORIZED)
    (map-set prices { symbol: symbol, oracle-src: oracle-src } { last-price-in-cents: price, last-block: u0 })
    (ok price)
  )
)

;; oracle-src : Source of Oracle, lets keep for test-oracle for now. 
;; symbol : Token Symbol
;; @desc get-price
;; @params oracle-src
;; @params symbol
;; @returns (response uint)
(define-read-only (get-price (oracle-src (string-ascii 32)) (symbol (string-ascii 32)))
  (let
    (
      (price-map (unwrap! (map-get? prices {symbol: symbol, oracle-src: oracle-src }) ERR-TOKEN-NOT-IN-ORACLE))
      (last-price (get last-price-in-cents price-map))
    )
    (ok last-price)
  )
)

;; @desc div-down
;; @params a 
;; @params b
;; @returns uint
(define-read-only (div-down (a uint) (b uint))
  (if (is-eq a u0)
      u0
      (/ (* a ONE_8) b)
  )
)

;; @desc calculate-strike
;; @params oracle-src
;; @params token-symbol
;; @params collateral-symbol 
;; @returns (response uint)
(define-read-only (calculate-strike (oracle-src (string-ascii 32)) (token-symbol (string-ascii 32)) (collateral-symbol (string-ascii 32)))
  (ok (div-down (try! (get-price oracle-src token-symbol)) 
                (try! (get-price oracle-src collateral-symbol))
      )
  )
)