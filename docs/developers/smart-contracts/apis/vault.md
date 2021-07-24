---
description: >-
  Vault is smart contract that holds and manages the assets of all pools. It
  keeps assets managed by other external contracts such as pool. Also, users can
  trigger flash loan from vault.
---

# Vault

## ALEX-Vault

 Vault is responsible for managing assets of all ALEX pools. Transaction in all the existing pools can be found in [Vault Protocol](https://docs.alexgo.io/protocol/vault).

### **get-balance**

**Prototype:** 

`(define-read-only (get-balance (token)))`

**Input:** `principal`

**Output:** `bool | uint`

Get the balance of `tx-sender` of given token from vault. parameter "token'' should be an implemented token, which returns balance internally using `ft-get-balance`

```
$ Usage
```

### **get-balances**

**Prototype:** 

`(define-read-only (get-balances)`

**Input:** `void`

**Output:** `bool | uint`

Get the all the list of \(token, value\) object of `tx-sender`

```
$ Usage
```

### **flash-loan**

**Prototype:** 

`(define-public (flash-loan (flash-loan-user) (token1) (token2) (token3)) (amount1) (amount2) (amount3)) | (flash-loan (flash-loan-user) (token1) (token2) (amount1) (amount2))`

**Input:** `<ft-trait>, <ft-trait>, <ft-trait>, uint, uint, uint | <ft-trait>, <ft-trait>, uint, uint`

**Output:** `bool | uint`

Executes flash loan up to 3 tokens of amounts specified. User can only make 2 token inputs if executing in single pool, while can also make 3 token inputs for executing flash loan two different pools. It first transfers each tokens to user, then execute flash loan by triggering `execute` function. Validating the exact amount of returned loan is followed by execution. For the detailed use cases, check [Flash Loan Protocol](https://docs.alexgo.io/protocol/vault#flash-loan).

```
$ Usage
```

