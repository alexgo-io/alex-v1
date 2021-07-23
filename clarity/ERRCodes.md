# This Document is for specifing error codes for development.

## General Error
 ### start with u1000

 | Error        | Code         | Reference  |
| ------------- |:-------------:| :-----:|
| err-not-authorized    | 1000 | Inappropriate principal accessing  |

## Pool Related Error
 ### start with u2000
 | Error        | Code         | Reference  |
| ------------- |:-------------:| :-----:|
| pool-already-exists-err    | 2000 | Pool Already Existing |
| invalid-pool-err     | 2001      |  Accesing invalid Pool  |
| no-liquidity-err | 2002      |   Liquidity insufficient |
| invalid-liquidity-err | 2003      |  Accesing Invalid Liquidity feature |
| too-many-pools-err | 2004      |  Exceeded maximum number of pool |
| no-fee-x-err | 2005      |   Insufficient fee for Token-X  |
| no-fee-y-err | 2006      |   Insufficient fee for Token-Y |
| invalid-token-err | 2007      |  Accesing invalid Token |
| invalid-balance-err | 2008      |  Accesing invalid balance |

   
## Vault Related Error 
 ### start with u3000
 
 | Error        | Code         | Reference  |
| ------------- |:-------------:| :-----:|
| transfer-failed-err    | 3000 | Transfer failed  |
| transfer-x-failed-err     | 3001      |  Transfer of Token-X failed  |
| transfer-y-failed-err | 3002      |   Transfer of Token-Y failed |
| insufficient-flash-loan-balance-err  | 3003      |  Insufficient Flash Loan balance |
| invalid-post-loan-balance-err  | 3004      |  Invalid Post loan balance |
| user-execute-err | 3005      |   User execution error of Flashloan  |
| transfer-one-by-one-err | 3006      |   Error on Transfer flash loan |
| none-token-err  | 3007      |  Flash loan none token error |
| get-token-fail | 3008      |  Token acquiring fail in flash loan |

 

## Equation Related Error 
 ### start with u4000
  | Error        | Code         | Reference  |
| ------------- |:-------------:| :-----:|
| transfer-failed-err    | 4000 | Transfer failed  |

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
