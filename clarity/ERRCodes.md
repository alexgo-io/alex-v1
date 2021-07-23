# This Document is for specifing error codes for development.

## General Error
 ### start with u1000

 | Error        | Code         | Description  |
| ------------- |:-------------:| :-----:|
| err-not-authorized    | 1000 | Inappropriate principal accessing  |

## Pool Related Error
 ### start with u2000
 | Error        | Code         | Description  |
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
 
 | Error        | Code         | Description  |
| ------------- |:-------------:| :-----:|
| transfer-failed-err    | 3000 | General transfer failed  |
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
  | Error        | Code         | Description  |
| ------------- |:-------------:| :-----:|
| weight-sum-err    | 4000 | Sum of weight should be always 1  |
| max-in-ratio-err    | 4001 | In ratio Error  |
| max-out-ratio-err    | 4002 | Out ration Error |


## Math Related Error
### start with u5000
  | Error        | Code         | Description  |
| ------------- |:-------------:| :-----:|
| percent-greater-than-one    | 5000 | percent value exceeded 1  |
| SCALE_UP_OVERFLOW    | 5001 | scale up overflow error  |
| SCALE_DOWN_OVERFLOW    | 5002 | scale down overflow error |
| ADD_OVERFLOW    | 5003 | addition overflow  |
| SUB_OVERFLOW   | 5004 | subtraction overflow  |
| MUL_OVERFLOW    | 5005 | multiplication overflow |
| DIV_OVERFLOW    | 5006 | division overflow  |
| POW_OVERFLOW    | 5007 | power operation overflow  |
| MAX_POW_RELATIVE_ERROR   | 5008 | max pow relative error |
| X_OUT_OF_BOUNDS     | 5009 | parameter x out of bounds |
| Y_OUT_OF_BOUNDS    | 5010 | parameter y out of bounds  |
| PRODUCT_OUT_OF_BOUNDS    | 5011 | product of x and y out of bounds  |
| INVALID_EXPONENT   | 5012 | exponential error |
| OUT_OF_BOUNDS   | 5003 | general out of bounds error |

