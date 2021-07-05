# Platform built for developers

The platform architecture of ALEX allows for implementation of arbitrary trading strategies and borrows heavily from [Balancer V2](https://docs.balancer.fi).

Equation abstracts rebalancing and market making logic, while Pool encapsulates the value of a strategy. Pool abstraction allows aggregation of the assets of all ALEX pools into a single vault, bringing many advantages over traditional DEX architecture.

## Equation

Equation triggers Pool rebalancing. This allows creation of any arbitrary rebalancing strategies to be deployed as a pool.

### Weighted Equation

Weighted Equation \("WE"\) is the most basic Equation of all and is a fork of [Balancer](https://balancer.fi/whitepaper.pdf), which generalised the constant product AMM popularised by Uniswap. WE implements the following formula:

$$
V=\prod_{i}B_{i}^{w_{i}}
$$

Where $$V$$is a constant, $$B_{i}$$ is the balance of token i and $$w_{i}$$ is the weight of token i in the pool.

As the price of each token changes, arbitrageurs rebalance the pool by making trades. This maintains the desired weighting of the value held by each token whilst collecting trading fees from the traders.

### Yield Token Equation

Yield Token Equation \("YTE"\) follows [Yield Space](https://yield.is/YieldSpace.pdf) and is designed specifically to facilitate efficient trading between ayToken and Token. Our main contribution is to extend the model to allow for capital efficiency from liquidity provision perspective \(inspired by [Uniswap V3](https://uniswap.org/whitepaper-v3.pdf)\).

For example, if a pool is configured to trade between 0% and 10% APY, the capital efficiency can improve to 40x compared to when the yield can trade between $$-\infty$$ and $$+\infty$$.

More details are available at [Automated Market Making designed for lending protocols](automated-market-making-designed-for-lending-protocols.md).

## Pool

Pools handle the logic of dynamic trading strategies, whose token rebalancing are then handled by Vault. Rebalancing logic is driven by Equation. Pool issues Pool Token to liquidity provider, representing a proportional ownership of that Pool.

### Fixed Weight Pool

Fixed Weight Pool \("FWP"\) is a fork of [Balancer Weighted Pool](https://docs.balancer.fi/core-concepts/protocol/pools#weighted-pools).

### Collateral Rebalancing Pool

Collateral Rebalancing Pool \("CRP"\) uses [Weighted Equation](platform-architecture-that-supports-ecosystem-development.md#weighted-equation) and dynamically rebalances between ayToken and Collateral.

CRP dynamically rebalances collateral to ensure the ayToken minted \(i.e. the loan\) remain solvent especially in an adverse market environment \(i.e. the value of the loan does not exceed the value of collateral\). This dynamic rebalancing, together with a careful choice of the key parameters \(including LTV and volatilty assumption\) allows ALEX to eliminate the needs for liquidation. Any residual gap risk \(which CRP cannot address entirely\) is addressed through maintaining a strong reserve fund.

When a Borrower mints ayToken by providing appropriate Collateral, the Collateral is converted into a basket of Collateral and Token, with the weights determined by CRP. CRP determines the weights based on the prevailing LTV and uses the following formula:

$$
\begin{split}
&w_{Token}=N\left(d_{1}\right)\\
&w_{Collateral}=\left(1-w_{Token}\right)\\
&d_{1}= \frac{1}{\sigma\sqrt{t}}\left[\ln\left(\frac{LTV_{t}}{LTV_{0}}\right) + t\times\left(APY_{Token}-APY_{Collateral} + \frac{\sigma^2}{2}\right)\right]
\end{split}
$$

Some readers may note the similarity of the above formula to the [Black & Scholes delta](https://en.wikipedia.org/wiki/Black–Scholes_model), because it is. CRP essentially implements a delta replicating strategy of a call option on Token / Collateral, buying more Token when LTV moves higher and vice versa.

### Yield Token Pool

Yield Token Pool \("YTP"\) uses[ Yield Token Equation](platform-architecture-that-supports-ecosystem-development.md#yield-token-equation) and is designed specifically to facilitate efficient trading between ayToken and Token.

Full details at [Automated Market Making designed for lending protocols](automated-market-making-designed-for-lending-protocols.md).

### Liquidity Bootstrapping Pool

Liquidity Bootstrapping Pool \("LBP"\) uses [Weighted Equation](platform-architecture-that-supports-ecosystem-development.md#weighted-equation) and is designed to facilitate a capital efficient launch of a token \(the "Base Token"\) relative to another token \(the "Target Token"\).

LBP is used to initialise all Yield Token Pools \(with ayToken being the Base Token and Token being the Target Token\).

Initially, a bigger weight \(say 80%\) is assigned to Base Token, while the remaining \(say 20%\) is assigned to Target Token. The weights are gradually rebalanced to allow for the sale of Base Token and an efficient discovery of its price relative to the Target Token.

LBP was first offered by [Balancer](https://docs.balancer.fi/v/v1/guides/smart-pool-templates-gui/liquidity-bootstrapping-pool) in 2020 and can be an interesting alternative to ICOs, IDOs or IEOs to bootstrap liquidity with little initial investment from the team.

ALEX brings LBP to Stacks, allowing Stacks projects to build deep liquidity and find its price efficiently with low capital requirements.

LBPs can result in a significantly better-funded project whose governance tokens are more evenly distributed among the community. This means the tokens remain in the hands of those that are invested in the project in the long term, instead of speculators looking for quick profits.

For illustration, you may check out [LBP simulator](https://docs.google.com/spreadsheets/d/1t6VsMJF8lh4xuH_rfPNdT5DM3nY4orF9KFOj2HdMmuY/edit?usp=sharing). 

## Vault

Vault holds and manages the assets of all ALEX pools. The separation of pool and vault has many benefits including, among others, cheaper transaction costs for users and quicker learning curve for developers when building custom pools on ALEX.

![Vault Use Case](https://yuml.me/diagram/scruffy/usecase/[Arbitrageur]-%28Go%20to%20Vault%29,%20[Flash%20Loan%20User]-%28Go%20to%20Vault%29,%20%28Go%20to%20Vault%29-%28Create%20Flash%20Loan%29,%20%28Go%20to%20Vault%29-%28Create%20Swap%20/%20Batch%20Swap%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Create%20Flash%20Loan%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Sell%20Token%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Buy%20Token%29)

### Flash Loan

Aggregating the assets of all ALEX pools into a single vault allows for the offering of Flash Loan, [popularized by AAVE](https://aave.com/flash-loans/).

Flash Loans are uncollateralized loans that must be repaid \(plus interest\) in the same transaction as it is borrowed. Since everything done with the loan must be completed in a single transaction, there are codified guarantees that make it impossible for borrowers to run away with the tokens.

Combining Flash Loan with Batch Swap allows arbitrageurs to take advantages of any price discrepancies in two or more pools without the needs for holding any input tokens.

## Oracle

