# What is ALEX?

## ALEX is an open-source DeFi development company built on Stacks Blockchain modelled on the world’s financial markets.

At ALEX, you can

* Lend your BTC and earn
* Borrow BTC
* Mitigate risk with BTC short positions
* Maximize upside with BTC leveraged long positions

![](https://user-images.githubusercontent.com/443225/120918450-15c66280-c6e7-11eb-9950-5ccab7f2c0d5.png)

## Think of us as [Compound](https://compound.finance) / [AAVE](https://aave.om) with underlying technology like [Balancer](https://balancer.finance), but user experience of [Robinhood](https://www.robinhood.com).

Our initial focus \(v1\) is

* Build DeFi primitives targeting developers looking to build ecosystem on Stacks, and
* Simplify the user experience going from\(to\) CeFi to\(from\) DeFi to attract non-developers, broadening the Stacks user base.

alex-v1 implements a number of Clarity smart contracts on the core concept of Yield Tokens \("ayTokens"\). Yield Tokens allow term lending with fixed APY.

![](https://user-images.githubusercontent.com/443225/121769437-2028a680-cb96-11eb-8289-ea87fb49491d.png)

## Lending at fixed yield for a fixed term

* Buying of ayToken \(against Token\) equates to lending of Token at the rate implied by the price of ayToken until T.
* Holding ayToken until T allows the holder to accrue, with certainty, at a fixed rate \(as implied by the price at which holder bought ayToken\).
* Selling of ayToken before T could result in a profit or loss, depending on the prevailing price of ayToken.

![](https://user-images.githubusercontent.com/443225/120918675-27f4d080-c6e8-11eb-99a7-7a2b9b398123.png)

## Borrowing at fixed yield for a fixed term

* Minting of ayToken against collateral assets and selling of ayToken against Token equates to the borrowing of Token at the rate implied by the price at which ayToken was sold.
* Loan-to-Value \(“LTV”\) is the ratio of the value of the tokens borrowed and the value of the collateral assets.
* Liquidation occurs if the LTV of a loan reaches the Maximum Loan-to-Value \(“Max LTV”\).

![](https://user-images.githubusercontent.com/443225/120918869-4ad3b480-c6e9-11eb-9d29-6b946489becf.png)

## Automated Market Making designed for lending / borrowing protocols

The borrow rates embedded in ayTokens are determined using an automated market making formula, for example using the constant power sum formula between the balance of the Yield Tokens and that of collateral asset, following [Yield Space](https://yield.is/YieldSpace.pdf), suitably modified to allow for capital efficiency following [Uniswap v3](https://uniswap.org/whitepaper-v3.pdf).

