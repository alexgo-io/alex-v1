# Overview

ALEX allows for implementation of arbitrary trading strategies and borrows heavily from [Balancer V2](https://docs.balancer.fi).

Equation abstracts rebalancing and market making logic, while Pool encapsulates the value of a strategy. Pool abstraction allows aggregation of the assets of all ALEX pools into a single vault, bringing many advantages over traditional DEX architecture.

## Equation

Equation triggers Pool rebalancing. This allows creation of any arbitrary rebalancing strategies to be deployed as a pool.

### Weighted Equation

Weighted Equation \("WE"\) is the most basic Equation of all and is a fork of [Balancer](https://balancer.fi/whitepaper.pdf), which generalised the constant product AMM popularised by Uniswap. We implement the following formula:

$$
V=\prod_{i}B_{i}^{w_{i}}
$$

Where $$V$$is a constant, $$B_{i}$$ is the balance of token i and $$w_{i}$$ is the weight of token i in the pool.

As the price of each token changes, arbitrageurs rebalance the pool by making trades. This maintains the desired weighting of the value held by each token whilst collecting trading fees from the traders.

### Yield Token Equation

Yield Token Equation \("YTE"\) drives [Yield Token Pool](automated-market-making-designed-for-lending-protocols.md). It follows [Yield Space](https://yield.is/YieldSpace.pdf) and is designed specifically to facilitate efficient trading between ayToken and Token. Our main contribution is to extend the model to allow for capital efficiency from liquidity provision perspective \(inspired by [Uniswap V3](https://uniswap.org/whitepaper-v3.pdf)\).

For example, if a pool is configured to trade between 0% and 10% APY, the capital efficiency can improve to 40x compared to when the yield can trade between $$-\infty$$ and $$+\infty$$.

## Pool

Pools handle the logic of dynamic trading strategies, whose token rebalancing are then handled by Vault. Rebalancing logic is driven by Equation. Pool issues Pool Token to liquidity providers. The number of Pool Tokens are determined based on a liquidity provider's relative contribution to the Pool. Pool Tokens thus represent proportional ownership of that Pool, or assets in that Pool.

### Fixed Weight Pool

Fixed Weight Pool \("FWP"\) is a fork of [Balancer Weighted Pool](https://docs.balancer.fi/core-concepts/protocol/pools#weighted-pools).

### Collateral Rebalancing Pool

Collateral Rebalancing Pool \("CRP"\) uses [Weighted Equation](platform-architecture-that-supports-ecosystem-development.md#weighted-equation) and dynamically rebalances between ayToken and Collateral. CRP dynamically rebalances collateral to ensure the ayToken minted \(i.e. the loan\) remains solvent especially in an adverse market environment \(i.e. the value of the loan does not exceed the value of collateral\).

### Yield Token Pool

Yield Token Pool \("YTP"\) uses[ Yield Token Equation](platform-architecture-that-supports-ecosystem-development.md#yield-token-equation) and is designed specifically to facilitate efficient trading between ayToken and Token.

### Liquidity Bootstrapping Pool

Liquidity Bootstrapping Pool \("LBP"\) uses [Weighted Equation](platform-architecture-that-supports-ecosystem-development.md#weighted-equation) and is designed to facilitate a capital efficient launch of a token \(the "Base Token"\) relative to another token \(the "Target Token"\).

LBP is used to initialise all Yield Token Pools \(with ayToken being the Base Token and Token being the Target Token\).

## Vault

Vault holds and manages the assets of all ALEX pools. The separation of pool and vault has many benefits including, among others, cheaper transaction costs for users and quicker learning curve for developers when building custom pools on ALEX.

