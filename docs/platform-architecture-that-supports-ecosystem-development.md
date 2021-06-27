# Platform Architecture that supports ecosystem development

The platform architecture of ALEX allows for implementation of arbitrary trading strategies and borrows heavily from [Balancer V2](https://docs.balancer.fi).

Equation abstracts rebalancing and market making logic, while Pool encapsulates the value of a strategy. Pool abstraction allows aggregation of the assets of all ALEX pools into a single vault, bringing many advantages over traditional DEX architecture.

## Equation

Equation triggers Pool rebalancing. This allows creation of any arbitrary rebalancing strategies to be deployed as a pool.

### Weighted Equation

Weighted Equation \("WE"\) is the most basic Equation of all and is a fork of [Balancer Weighted Pool](https://docs.balancer.fi/core-concepts/protocol/pools#weighted-pools), which generalised the constant product AMM popularised by Uniswap. WE implements the following formula:

$$
V=\prod_{i}B_{i}^{w_{i}}
$$

Where $$V$$is a constant, $$B_{i}$$ is the balance of token i and $$w_{i}$$ is the weight of token i in the pool.

As the price of each token changes, arbitrageurs rebalance the pool by making trades. This maintains the desired weighting of the value held by each token whilst collecting trading fees from the traders.

### Collateral Rebalancing Equation

Collateral Rebalancing Equation \("CRE"\) extends Weighted Equation and triggers ayToken / Collateral Pool rebalancing.

CRE dynamically rebalances collateral to ensure the ayToken minted \(i.e. the loan\) remain solvent especially in an adverse market environment \(i.e. the value of the loan does not exceed the value of collateral\). This dynamic rebalancing, together with a judicious choice of the key parameters \(including LTV and volatilty assumption\) allows ALEX to eliminate the needs for liquidation. Any residual gap risk \(which CRE cannot address entirely\) is addressed through maintaining a strong reserve fund.

When a Borrower mints ayToken by providing appropriate Collateral, the Collateral is converted into a basket of Collateral and Token, with the weights determined by CRE. CRE determines the weights based on the prevailing LTV and uses the following formula:

$$
w_{Token}=N\left(d_{1}\right)\\
w_{Collateral}=\left(1-w_{Token}\right)\\
d_{1}= \frac{1}{\sigma\sqrt{t}}\left[\ln\left(\frac{LTV_{t}}{LTV_{0}}\right) + t\times\left(APY_{Token}-APY_{Collateral} + \frac{\sigma^2}{2}\right)\right]
$$

Some readers may note the similarity of the above formula to the [Black & Scholes delta](https://en.wikipedia.org/wiki/Black–Scholes_model), because it is. CRE essentially implements a delta replicating strategy of a call option on Token / Collateral, buying more Token when LTV moves higher and vice versa.

### Yield Token Equation

### Liquidity Bootstrapping Equation

Liquidity Bootstrapping Equation \("LBE"\) extends Weighted Equation and is a dynamic rebalancing equation designed to facilitate a capital efficient launch of a token \(the "Base Token"\) relative to another token \(the "Target Token"\).

Initially, a bigger weight \(say 80%\) is assigned to Base Token, while the remaining \(say 20%\) is assigned to Target Token. The weights are gradually rebalanced to allow for the sale of Base Token and an efficient discovery of its price relative to the Target Token.

LBE is used to initialise all Yield Token Pools.

## Pool

Pools handle the logic of dynamic trading strategies, whose token rebalancing are then handled by Vault. Rebalancing logic is driven by Equation. Pool issues Pool Token to liquidity provider, representing a proportional ownership of that Pool.

## Vault

Vault holds and manages the assets of all ALEX pools. The separation of pool and vault has many benefits including, among others, cheaper transaction costs for users and quicker learning curve for developers when building custom pools on ALEX.

### Flash Loan

Aggregating the assets of all ALEX pools into a single vault allows for the offering of Flash Loan, [popularized by AAVE](https://aave.com/flash-loans/).

Flash Loans are uncollateralized loans that must be repaid \(plus interest\) in the same transaction as it is borrowed. Since everything done with the loan must be completed in a single transaction, there are codified guarantees that make it impossible for borrowers to run away with the tokens.

Combining Flash Loan with Batch Swap allows arbitrageurs to take advantages of any price discrepancies in two or more pools without the needs for holding any input tokens.

## Oracle

