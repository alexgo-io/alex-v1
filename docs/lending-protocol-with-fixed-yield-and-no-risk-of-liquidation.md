# Lending and Borrowing at fixed yield with no risk of liquidation

## Lending at fixed yield for a fixed term

Buying of ayToken \(against Token\) equates to lending of Token at the rate implied by the price of ayToken until T. Holding ayToken until T allows the holder to accrue, with certainty, at a fixed rate \(as implied by the price at which holder bought ayToken\). Selling of ayToken before T could result in a profit or loss, depending on the prevailing price of ayToken.

ALEX provides a fixed schedule of maturities for each Token to allow liquidity aggregation. On a regular basis, a new ayToken is launched, whose liquidity is bootstrapped using Liquidity Bootstrapping Pool.

![Lender Use Case](http://yuml.me/diagram/scruffy/usecase/[Lender]-(Go to ayToken / Token Pool),(Go to ayToken / Token Pool)-(Sell Token),(Sell Token)-(Buy ayToken))

## Borrowing at fixed yield for a fixed term with no risk of liquidation

Minting of ayToken by adding eligible collateral to the pool and selling of ayToken against Token equates to the borrowing of Token at the rate implied by the price at which ayToken was sold.

![Borrower Use Case](http://yuml.me/diagram/scruffy/usecase/[Borrower]-(Go to ayToken / Collateral Pool),(Go to ayToken / Collateral Pool)-(Deposit Collateral),(Deposit Collateral)-(Mint ayToken),(Mint ayToken)-(Go to ayToken / Token Pool),(Go to ayToken / Token Pool)-(Sell ayToken),(Sell ayToken)-(Buy Token))

The collateral pool will dynamically rebalance between Token and eligible collateral to ensure the solvency of ayToken. The dynamic rebalancing of collateral is akin to a real-time margining of the loan, minimising counterparty risk.

For example, ayBTC / USD pool \(i.e. borrow BTC against USD\) will implement a dynamic hedging strategy against BTC upside \(i.e. sell USD and buy BTC as BTC spot goes up, and vice versa\). The resulting rebalancing between USD and BTC will be then executed by arbitrageurs participating in the pool pricing curve. See some illustration [here](https://docs.google.com/spreadsheets/d/1d_Pzl0hoRFsD5q3yl97OxHmo_pVBf9tIgTAG4dfzENo/edit?usp=sharing). The borrower effectively is an LP \(and receives ayBTC as the PoolToken\) and the USD collateral provided will be automatically converted into a basket of USD and BTC.

* The main benefit is that we can be \(much\) more aggressive in LTV and remove liquidation entirely \(with appropriate LTV and reserve fund\). This also allows aggregation of all ayToken into a single pool \(rather than separate pool for each borrower\).
* The main drawback is that the collateral received at the time of repayment will not be same in USD value as the original value \(due to rebalancing\).

To those interested in understanding the mathematics behind it, please refer to Collateral Rebalancing Equation under [Platform built for developers](platform-architecture-that-supports-ecosystem-development.md#collateral-rebalancing-equation).

