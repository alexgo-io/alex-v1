---
description: >-
  Equations are smart contracts which handles rebalancing of the Pool. It is the
  integral component of maintaining pool. It allows creation of any rebalancing
  strategies to be deployed as a pool.
---

# Equations

## Weighted Equation

 Weighted Equation is an implementation of pool maintaining logic, which balances the ration between two tokens one each pool with unique logic of ALEX. It is a basically fork of Balancer, which mainly uses constant product AMM but for ALEX, weight follows [Black & Scholes delta](https://en.wikipedia.org/wiki/Black–Scholes_model). Details can be found on our whitepaper and [here](https://docs.alexgo.io/protocol/platform-architecture-that-supports-ecosystem-development#weighted-equation). Developers can use `(contract-call?)` for using this weighted equation anywhere in the smart contract. 

### **get-y-given-x**

**Prototype:** 

`(define-read-only (get-y-given-x (balance-x) (balance-y) (weight-x) (weight-y) (dy))`

**Input:** `uint uint uint uint uint`

**Output:** `bool | uint`

Get the appropriate value of dy from given dx which maintains the balance of given pool.

```
$ Usage
```

### **get-x-given-y**

**Prototype:** 

`(define-read-only (get-x-given-y (balance-x) (balance-y) (weight-x) (weight-y) (dx))`

**Input:** `uint uint uint uint uint`

**Output:** `bool | uint`

Get the appropriate value of dx from given dy which maintains the balance of given pool.

```
$ Usage
```

### **get-**x-given-price

**Prototype:** 

`(define-read-only (get-x-given-price (balance-x) (balance-y) (weight-x) (weight-y) (price))`

**Input:** `uint uint uint uint uint`

**Output:** `bool | uint`

Get the appropriate value of dx from given price which maintains the balance of given pool.

```
$ Usage
```

### **get-**token-given-position

**Prototype:** 

`(define-read-only (get-token-given-position (balance-x) (balance-y) (weight-x) (weight-y) (total-supply) (dx) (dy))`

**Input:** `uint uint uint uint uint uint uint`

**Output:** `bool | uint`

Get the appropriate value of token from given parameters which maintains the balance of given pool.

```
$ Usage
```

### **get-**position-given-mint

**Prototype:** 

`(define-read-only (get-position-given-mint (balance-x) (balance-y) (weight-x) (weight-y) (total-supply) (token))`

**Input:** `uint uint uint uint uint`

**Output:** `bool | uint`

Get the appropriate position value \(dx and dy\) from given parameters such as minted amount and total supply which maintains the balance of given pool. 

```
$ Usage
```

### **get-**position-given-burn

**Prototype:** 

`(define-read-only (get-position-given-burn (balance-x) (balance-y) (weight-x) (weight-y) (total-supply) (token))`

**Input:** `uint uint uint uint uint`

**Output:** `bool | uint`

Identical to `get-position-given-mint` since it is reverse of calculation.

```
$ Usage
```



