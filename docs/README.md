---
description: >-
  Did you know ALEX stands for Automated Liquidity Exchange, but actually comes
  from the name of one of our co-founder's son?
---

# What is ALEX?

## ALEX is an open-source DeFi development company built on Stacks Blockchain modelled on the world’s financial markets.

At ALEX, you can

* Lend your BTC and earn fixed or variable interest
* Borrow BTC without risk of liquidation
* Mitigate risk with BTC short positions
* Maximize upside with BTC leveraged long positions

## Think of us as [Compound](https://compound.finance) / [AAVE](https://aave.om) with underlying technology like [Balancer](https://balancer.finance), but user experience of [Robinhood](https://www.robinhood.com).

Our initial focus \(v1\) is

* Build DeFi primitives targeting developers looking to build ecosystem on Stacks, and
* Simplify the user experience going from\(to\) CeFi to\(from\) DeFi to attract non-developers, broadening the Stacks user base.

alex-v1 implements a number of Clarity smart contracts on the core concept of Yield Tokens \("ayTokens"\). Yield Tokens allow term lending with fixed APY.

## Lending at fixed yield for a fixed term

Buying of ayToken \(against Token\) equates to lending of Token at the rate implied by the price of ayToken until T. Holding ayToken until T allows the holder to accrue, with certainty, at a fixed rate \(as implied by the price at which holder bought ayToken\). Selling of ayToken before T could result in a profit or loss, depending on the prevailing price of ayToken.

ALEX provides a fixed schedule of maturities for each Token to allow liquidity aggregation. On a regular basis, a new ayToken is launched, whose liquidity is bootstrapped using Liquidity Bootstrapping Pool.

## Borrowing at fixed yield for a fixed term with no risk of liquidation

Minting of ayToken by adding eligible collateral to the pool and selling of ayToken against Token equates to the borrowing of Token at the rate implied by the price at which ayToken was sold. 

The collateral pool will dynamically rebalance between Token and eligible collateral to ensure the solvency of ayToken. The dynamic rebalancing of collateral is akin to a real-time margining of the loan, minimising counterparty risk.

For example, ayBTC / USD pool \(i.e. borrow BTC against USD\) will implement a dynamic hedging strategy against BTC upside \(i.e. sell USD and buy BTC as BTC spot goes up, and vice versa\). The resulting rebalancing between USD and BTC will be then executed by arbitrageurs participating in the pool pricing curve. See some illustration [here](https://docs.google.com/spreadsheets/d/1d_Pzl0hoRFsD5q3yl97OxHmo_pVBf9tIgTAG4dfzENo?authuser=alexd%40alexgo.io&usp=drive_fs). The borrower effectively is an LP \(and receives ayBTC as the PoolToken\) and the USD collateral provided will be automatically converted into a basket of USD and BTC.

* The main benefit is that we can be \(much\) more aggressive in LTV and remove liquidation entirely \(with appropriate LTV and reserve fund\). This also allows aggregation of all ayToken into a single pool \(rather than separate pool for each borrower\).
* The main drawback is that the collateral received at the time of repayment will not be same in USD value as the original value \(due to rebalancing\).

## Platform Architecture that supports ecosystem development

The platform architecture of ALEX allows for implementation of arbitrary trading strategies and borrows heavily from Balancer V2.

Equation abstracts rebalancing and market making logic, while Pool encapsulates the value of a strategy. Pool abstraction allows aggregation of the assets of all ALEX pools into a single vault, bringing many advantages over traditional DEX architecture.

### Equation

Equation triggers Pool rebalancing. This allows creation of any arbitrary rebalancing strategies to be deployed as a pool.

#### Weighted Equation

Weighted Equation \("WE"\) is the most basic Equation of all and is a fork of [Balancer Weighted Pool](https://docs.balancer.fi/core-concepts/protocol/pools#weighted-pools), which generalised the constant product AMM popularised by Uniswap. WE implements the following formula:

$$
V=\prod_{i}B_{i}^{w_{i}}
$$

Where $$V$$is a constant, $$B_{i}$$ is the balance of token i and $$w_{i}$$ is the weight of token i in the pool.

As the price of each token changes, arbitrageurs rebalance the pool by making trades. This maintains the desired weighting of the value held by each token whilst collecting trading fees from the traders.

#### Collateral Rebalancing Equation

Collateral Rebalancing Equation \("CRE"\) extends Weighted Equation and triggers ayToken / Collateral Pool rebalancing.

CRE dynamically rebalances collateral to ensure the ayToken minted \(i.e. the loan\) remain solvent especially in an adverse market environment \(i.e. the value of the loan does not exceed the value of collateral\). This dynamic rebalancing, together with a judicious choice of the key parameters \(including LTV and volatilty assumption\) allows ALEX to eliminate the needs for liquidation. Any residual gap risk \(which CRE cannot address entirely\) is addressed through maintaining a strong reserve fund.

When a Borrower mints ayToken by providing appropriate Collateral, the Collateral is converted into a basket of Collateral and Token, with the weights determined by CRE. CRE determines the weights based on the prevailing LTV and uses the following formula:

$$
w_{Token}=N\left(d_{1}\right)\\
w_{Collateral}=\left(1-w_{Token}\right)\\
d_{1}= \frac{1}{\sigma\sqrt{t}}\left[\ln\left(\frac{LTV_{t}}{LTV_{0}}\right) + t\times\left(APY_{Token}-APY_{Collateral} + \frac{\sigma^2}{2}\right)\right]
$$

Some readers may note the similarity of the above formula to the [Black & Scholes delta](https://en.wikipedia.org/wiki/Black–Scholes_model), because it is. CRE essentially implements a delta replicating strategy of a call option on Token / Collateral, buying more Token when LTV moves higher and vice versa.

#### Yield Token Equation

#### Liquidity Bootstrapping Equation

Liquidity Bootstrapping Equation \("LBE"\) extends Weighted Equation and is a dynamic rebalancing equation designed to facilitate a capital efficient launch of a token \(the "Base Token"\) relative to another token \(the "Target Token"\).

Initially, a bigger weight \(say 80%\) is assigned to Base Token, while the remaining \(say 20%\) is assigned to Target Token. The weights are gradually rebalanced to allow for the sale of Base Token and an efficient discovery of its price relative to the Target Token.

LBE is used to initialise all Yield Token Pools.

### Pool

Pools handle the logic of dynamic trading strategies, whose token rebalancing are then handled by Vault. Rebalancing logic is driven by Equation. Pool issues Pool Token to liquidity provider, representing a proportional ownership of that Pool.

### Vault

Vault holds and manages the assets of all ALEX pools. The separation of pool and vault has many benefits including, among others, cheaper transaction costs for users and quicker learning curve for developers when building custom pools on ALEX.

#### Flash Loan

Aggregating the assets of all ALEX pools into a single vault allows for the offering of Flash Loan, [popularized by AAVE](https://aave.com/flash-loans/).

Flash Loans are uncollateralized loans that must be repaid \(plus interest\) in the same transaction as it is borrowed. Since everything done with the loan must be completed in a single transaction, there are codified guarantees that make it impossible for borrowers to run away with the tokens.

Combining Flash Loan with Batch Swap allows arbitrageurs to take advantages of any price discrepancies in two or more pools without the needs for holding any input tokens.

### Oracle

## Liquidity Bootstrapping Pool

Liquidity Bootstrapping Pool \("LBP"\) was first offered by [Balancer](https://docs.balancer.fi/v/v1/guides/smart-pool-templates-gui/liquidity-bootstrapping-pool) in 2020 and can be an interesting alternative to ICOs, IDOs or IEOs to bootstrap liquidity with little initial investment from the team.

ALEX brings LBP to Stacks, allowing Stacks projects to build deep liquidity and find its price efficiently with low capital requirements.

LBPs can result in a significantly better-funded project whose governance tokens are more evenly distributed among the community. This means the tokens remain in the hands of those that are invested in the project in the long term, instead of speculators looking for quick profits.

For illustration, you may check out [LBP simulator](https://docs.google.com/spreadsheets/d/1t6VsMJF8lh4xuH_rfPNdT5DM3nY4orF9KFOj2HdMmuY/edit?usp=sharing). 

## Automated Market Making designed for lending protocols

Yield Token Pool facilitates trading of between Yield Token and its base Token, and uses an AMM logic similar to [Yield Space](https://yield.is/YieldSpace.pdf), but suitably modified to allow for capital efficiency from liquidity provision perspective.

The AMM formula is constructed such that its liquidity distribution is optimal for the trading between Yield Token and its base Token, hence allowing a better fungibility between Pool Tokens, i.e. the token representing the proportional ownership of the pool. ALEX does not at the moment support a custom liquidity provision \(except for the limit orders\).

## Yield Farming on ALEX

A high LTV \(even on a static collateral\) can be offered between ayTokens of different maturities. For example, ayToken-1y as collateral may achieve 90% LTV to mint ayToken-O/N \(similar to borrowing overnight to buy long-term asset\). This allows "yield farming" whereby you repeat the process of buying ayToken-1y, use it as collateral to mint and sell ayToken-O/N for Token \(to buy ayToken-1y\) to achieve a high APY \(assuming ayToken-1y APY &gt; ayToken-O/N APY\).

For example, 1. Rachel has 100 BTC. 2. Rachel spends 100 BTC and buys ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. 3. She sells the borrowed ayBTC-O/N \(from \(2\)\) and buys ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. 4. She repeats \(3\).

If 1y APY is 10% and O/N APY is 5%, the above "yield farming" results in APY approaching 55%.

Mathematically,

$$ r=\frac{1+r{1y}}{1-LTV}-\left(1+\frac{r{1d}}{365}\right)^{365}\left(\frac{LTV}{1-LTV}\right)-1 $$

An illustration is available [here](https://docs.google.com/spreadsheets/d/1L-52KHFl7O_h22Fg4gpZKczdPEXuAt5yAh2gX3BQP58?authuser=alexd%40alexgo.io&usp=drive_fs).

