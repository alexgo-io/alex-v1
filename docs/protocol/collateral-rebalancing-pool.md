# Collateral Rebalancing Pool

Collateral Rebalancing Pool \("CRP"\) uses [Weighted Equation](https://docs.alexgo.io/protocol/platform-architecture-that-supports-ecosystem-development) and dynamically rebalances between Token and Collateral.

CRP dynamically rebalances collateral to ensure the ayToken minted \(i.e. the loan\) remain solvent especially in an adverse market environment \(i.e. the value of the loan does not exceed the value of collateral\). This dynamic rebalancing, together with a careful choice of the key parameters \(including LTV and volatilty assumption\) allows ALEX to eliminate the needs for liquidation. Any residual gap risk \(which CRP cannot address entirely\) is addressed through maintaining a strong reserve fund.

For example, ayBTC / USD pool \(i.e. borrow BTC against USD\) will implement a dynamic hedging strategy against BTC upside \(i.e. sell USD and buy BTC as BTC spot goes up, and vice versa\). The resulting rebalancing between USD and BTC will be then executed by arbitrageurs participating in the pool pricing curve. See some illustration [here](https://docs.google.com/spreadsheets/d/1nSg6L30iedpk_rLhq3E7Zv8ct3Myb_D8oWmgJzwtwtw/edit?usp=sharing). The borrower effectively is an LP \(and receives ayBTC as the Pool Token\) and the USD collateral provided will be automatically converted into a basket of USD and BTC.

The main benefit of such collateral rebalancing is that we can be \(much\) more aggressive in LTV and remove liquidation entirely \(with appropriate LTV and reserve fund\). This also allows aggregation of all ayToken into a single pool \(rather than separate pool for each borrower\).

The main drawback is that the collateral received at the time of repayment will not be same in USD value as the original value \(due to rebalancing\).

When a Borrower mints ayToken by providing appropriate Collateral, the Collateral is converted into a basket of Collateral and Token, with the weights determined by CRP. CRP determines the weights based on the prevailing LTV and uses the following formula:

$$
\begin{split}
&w_{Token}=N\left(d_{1}\right)\\
&w_{Collateral}=\left(1-w_{Token}\right)\\
&d_{1}= \frac{1}{\sigma\sqrt{t}}\left[\ln\left(\frac{LTV_{t}}{LTV_{0}}\right) + t\times\left(APY_{Token}-APY_{Collateral} + \frac{\sigma^2}{2}\right)\right]
\end{split}
$$

Some readers may note the similarity of the above formula to the [Black & Scholes delta](https://en.wikipedia.org/wiki/Black–Scholes_model), because it is. CRP essentially implements a delta replicating strategy of a call option on Token / Collateral, buying more Token when LTV moves higher and vice versa.

