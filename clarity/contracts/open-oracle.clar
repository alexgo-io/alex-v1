(impl-trait .trait-oracle.oracle-trait)


;; TODO :
;; 1. for every each 
;; 2. get public key for each source 
;; 3. request using contract-call , but should I locally deploy stacks-open-oracle to my clarinet? 

(define-map prices
  { oracle-src: (string-ascii 32),
    symbol: (string-ascii 32) }
  {
    price: uint
  }
)

;; oracle-src : Source of Oracle 
;; symbol : Token Symbol
(define-read-only (get-price (oracle-src (string-ascii 32)) (symbol (string-ascii 32)))
    
    ;;(contract-call? 'SPZ0RAC1EFTH949T4W2SYY6YBHJRMAF4ECT5A7DD.oracle-v1 get-price oracle-src symbol)

    (ok u0)

)

;;(contract-call? 'SPZ0RAC1EFTH949T4W2SYY6YBHJRMAF4ECT5A7DD.oracle-v1 get-price "coinbase" "BTC")
