# Automated Market Making designed for lending protocols

Yield Token Pool facilitates trading of between Yield Token and its base Token, and uses an AMM logic similar to [Yield Space](https://yield.is/YieldSpace.pdf), but suitably modified to allow for capital efficiency from liquidity provision perspective.

The AMM formula is constructed such that its liquidity distribution is optimal for the trading between Yield Token and its base Token, hence allowing a better fungibility between Pool Tokens, i.e. the token representing the proportional ownership of the pool. ALEX does not at the moment support a custom liquidity provision \(except for the limit orders\).

<img alt="LP Use Case" src="https://yuml.me/diagram/scruffy/usecase/[Liquidity Provider]-(Go to ayToken / Token Pool), (Go to ayToken / Token Pool)-(Deposit ayToken & Token), (Deposit ayToken & Token)-(Mint ayToken / Token Pool Token)">
