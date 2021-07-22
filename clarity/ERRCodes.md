# This Document is for specifing error codes for development.

## General Error
 ### start with u1000
 - ERR-NOT-AUTHORIZED

## Pool Related Error
 ### start with u2000
 - pool-already-exists-err
 - invalid-pool-err
 - no-liquidity-err
 - invalid-liquidity-err
 - too-many-pools-err
 - no-fee-x-err
 - no-fee-y-err
 - invalid-token-err
 - invalid-balance-err
   
## Vault Related Error 
 ### start with u3000
 - transfer-failed-err
 - transfer-x-failed-err
 - transfer-y-failed-err
 - insufficient-flash-loan-balance-err 
 - invalid-post-loan-balance-err 
 - user-execute-err
 - transfer-one-by-one-err 
 - none-token-err 
 - get-token-fail 

## Equation Related Error 
 ### start with u4000
 - 

## Math Related Error
### start with u5000
- percent-greater-than-one
- SCALE_UP_OVERFLOW (err u10000)
- SCALE_DOWN_OVERFLOW (err u10001)
- ADD_OVERFLOW (err u10002)
- SUB_OVERFLOW (err u10003)
- MUL_OVERFLOW (err u10004)
- DIV_OVERFLOW (err u10005)
- POW_OVERFLOW (err u10006)
- MAX_POW_RELATIVE_ERROR (err u10000)
- X_OUT_OF_BOUNDS (err u10100)
- Y_OUT_OF_BOUNDS (err u10101)
- PRODUCT_OUT_OF_BOUNDS (err u10102)
- INVALID_EXPONENT (err u10103)
- OUT_OF_BOUNDS (err u10104)
