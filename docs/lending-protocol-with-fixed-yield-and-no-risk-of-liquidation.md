# Lending Protocol with fixed yield and no risk of liquidation

## Lending at fixed yield for a fixed term

Buying of ayToken \(against Token\) equates to lending of Token at the rate implied by the price of ayToken until T. Holding ayToken until T allows the holder to accrue, with certainty, at a fixed rate \(as implied by the price at which holder bought ayToken\). Selling of ayToken before T could result in a profit or loss, depending on the prevailing price of ayToken.

ALEX provides a fixed schedule of maturities for each Token to allow liquidity aggregation. On a regular basis, a new ayToken is launched, whose liquidity is bootstrapped using Liquidity Bootstrapping Pool.

![Lender Use Case](http://yuml.me/diagram/scruffy/usecase/[Lender]-%28Go%20to%20ayToken%20/%20Token%20Pool%29,%28Go%20to%20ayToken%20/%20Token%20Pool%29-%28Sell%20Token%29,%28Sell%20Token%29-%28Buy%20ayToken%29)

## Borrowing at fixed yield for a fixed term with no risk of liquidation

Minting of ayToken by adding eligible collateral to the pool and selling of ayToken against Token equates to the borrowing of Token at the rate implied by the price at which ayToken was sold.

![Borrower Use Case](http://yuml.me/diagram/scruffy/usecase/[Borrower]-%28Go%20to%20ayToken%20/%20Collateral%20Pool%29,%28Go%20to%20ayToken%20/%20Collateral%20Pool%29-%28Deposit%20Collateral%29,%28Deposit%20Collateral%29-%28Mint%20ayToken%29,%28Mint%20ayToken%29-%28Go%20to%20ayToken%20/%20Token%20Pool%29,%28Go%20to%20ayToken%20/%20Token%20Pool%29-%28Sell%20ayToken%29,%28Sell%20ayToken%29-%28Buy%20Token%29)

The collateral pool will dynamically rebalance between Token and eligible collateral to ensure the solvency of ayToken. The dynamic rebalancing of collateral is akin to a real-time margining of the loan, minimising counterparty risk.

For example, ayBTC / USD pool \(i.e. borrow BTC against USD\) will implement a dynamic hedging strategy against BTC upside \(i.e. sell USD and buy BTC as BTC spot goes up, and vice versa\). The resulting rebalancing between USD and BTC will be then executed by arbitrageurs participating in the pool pricing curve. See some illustration [here](https://docs.google.com/spreadsheets/d/1d_Pzl0hoRFsD5q3yl97OxHmo_pVBf9tIgTAG4dfzENo?authuser=alexd%40alexgo.io&usp=drive_fs). The borrower effectively is an LP \(and receives ayBTC as the PoolToken\) and the USD collateral provided will be automatically converted into a basket of USD and BTC.

* The main benefit is that we can be \(much\) more aggressive in LTV and remove liquidation entirely \(with appropriate LTV and reserve fund\). This also allows aggregation of all ayToken into a single pool \(rather than separate pool for each borrower\).
* The main drawback is that the collateral received at the time of repayment will not be same in USD value as the original value \(due to rebalancing\).

