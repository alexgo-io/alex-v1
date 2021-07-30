# Error Codes

## General Error

General error starts with 1000.

| Error | Code | Description |
| :--- | :---: | :---: |
| err-not-authorized | 1000 | Inappropriate principal accessing |

## Pool Error

Pool errors starts with 2000.

| Error | Code | Description |
| :--- | :---: | :---: |
| pool-already-exists-err | 2000 | Pool Already Existing |
| invalid-pool-err | 2001 | Accesing invalid Pool |
| no-liquidity-err | 2002 | Liquidity insufficient |
| invalid-liquidity-err | 2003 | Accesing Invalid Liquidity feature |
| too-many-pools-err | 2004 | Exceeded maximum number of pool |
| no-fee-x-err | 2005 | Insufficient fee for Token-X |
| no-fee-y-err | 2006 | Insufficient fee for Token-Y |
| invalid-token-err | 2007 | Accesing invalid Token |
| invalid-balance-err | 2008 | Accesing invalid balance |
| invalid-expiry-err | 2009 | expiry &gt; max-expiry |
| already-expiry-err | 2010 | current block-height &gt; expiry |
| get-price-fail-err | 2015 | get-price error |

## Vault Error

Vault errors starts with 3000.

| Error | Code | Description |
| :--- | :---: | :---: |
| transfer-failed-err | 3000 | General transfer failed |
| transfer-x-failed-err | 3001 | Transfer of Token-X failed |
| transfer-y-failed-err | 3002 | Transfer of Token-Y failed |
| insufficient-flash-loan-balance-err | 3003 | Insufficient Flash Loan balance |
| invalid-post-loan-balance-err | 3004 | Invalid Post loan balance |
| user-execute-err | 3005 | User execution error of Flashloan |
| transfer-one-by-one-err | 3006 | Error on Transfer flash loan |
| none-token-err | 3007 | Flash loan none token error |
| get-token-fail | 3008 | Token acquiring fail in flash loan |

## Equation Error

Equation error starts with 4000.

| Error | Code | Description |
| :--- | :---: | :---: |
| weight-sum-err | 4000 | Sum of weight should be always 1 |
| max-in-ratio-err | 4001 | In ratio Error |
| max-out-ratio-err | 4002 | Out ration Error |

## Math Error

Math error starts with 5000.

| Error | Code | Description |
| :--- | :---: | :---: |
| percent-greater-than-one | 5000 | percent value exceeded 1 |
| SCALE\_UP\_OVERFLOW | 5001 | scale up overflow error |
| SCALE\_DOWN\_OVERFLOW | 5002 | scale down overflow error |
| ADD\_OVERFLOW | 5003 | addition overflow |
| SUB\_OVERFLOW | 5004 | subtraction overflow |
| MUL\_OVERFLOW | 5005 | multiplication overflow |
| DIV\_OVERFLOW | 5006 | division overflow |
| POW\_OVERFLOW | 5007 | power operation overflow |
| MAX\_POW\_RELATIVE\_ERROR | 5008 | max pow relative error |
| X\_OUT\_OF\_BOUNDS | 5009 | parameter x out of bounds |
| Y\_OUT\_OF\_BOUNDS | 5010 | parameter y out of bounds |
| PRODUCT\_OUT\_OF\_BOUNDS | 5011 | product of x and y out of bounds |
| INVALID\_EXPONENT | 5012 | exponential error |
| OUT\_OF\_BOUNDS | 5013 | general out of bounds error |
| fixed-point-err | 5014 | catch-all for math-fixed-point errors |
|  |  |  |



