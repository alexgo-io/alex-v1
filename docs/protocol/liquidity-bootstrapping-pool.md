# Liquidity Bootstrapping Pool

Liquidity Bootstrapping Pool \("LBP"\) uses [Weighted Equation](platform-architecture-that-supports-ecosystem-development.md#weighted-equation) and is designed to facilitate a capital efficient launch of a token \(the "Base Token"\) relative to another token \(the "Target Token"\).

LBP is used to initialise all Yield Token Pools \(with ayToken being the Base Token and Token being the Target Token\).

Initially, a bigger weight \(say 80%\) is assigned to Base Token, while the remaining \(say 20%\) is assigned to Target Token. The weights are gradually rebalanced to allow for the sale of Base Token and an efficient discovery of its price relative to the Target Token.

LBP was first offered by [Balancer](https://docs.balancer.fi/v/v1/guides/smart-pool-templates-gui/liquidity-bootstrapping-pool) in 2020 and can be an interesting alternative to ICOs, IDOs or IEOs to bootstrap liquidity with little initial investment from the team.

ALEX brings LBP to Stacks, allowing Stacks projects to build deep liquidity and find its price efficiently with low capital requirements.

LBPs can result in a significantly better-funded project whose governance tokens are more evenly distributed among the community. This means the tokens remain in the hands of those that are invested in the project in the long term, instead of speculators looking for quick profits.

