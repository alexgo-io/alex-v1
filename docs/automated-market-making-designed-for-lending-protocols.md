# Automated Market Making designed for lending protocols

Yield Token Pool facilitates trading of between Yield Token and its base Token, and uses an AMM logic similar to [Yield Space](https://yield.is/YieldSpace.pdf), but suitably modified to allow for capital efficiency from liquidity provision perspective.

The AMM formula is constructed such that its liquidity distribution is optimal for the trading between Yield Token and its base Token, hence allowing a better fungibility between Pool Tokens, i.e. the token representing the proportional ownership of the pool. ALEX does not at the moment support a custom liquidity provision \(except for the limit orders\).

![Liquidity Provider Use Case](https://yuml.me/diagram/scruffy/usecase/[Liquidity%20Provider]-%28Go%20to%20ayToken%20/%20Token%20Pool%29,%20%28Go%20to%20ayToken%20/%20Token%20Pool%29-%28Deposit%20ayToken%20&%20Token%29,%20%28Deposit%20ayToken%20&%20Token%29-%28Mint%20ayToken%20/%20Token%20Pool%20Token%29)

The key of the AMM is **invariant function**, as it dynamically adjusts the price and the balances of Token and ayToken. As described in [Yield Space](https://yield.is/YieldSpace.pdf), invariant function is solution to the differential equation $$-\frac{dy}{dx}=\left(\frac{y}{x} \right)^t$$. $$y$$and $$x$$can then be solved and expressed as ****$$x^{1-t}+y^{1-t}=L$$ .

## **Trading Formula**

The market transaction, which invovles exchange of Token and ayToken, satisfies the invariant function. Fee is not returned to the pool, therefore $$k$$remains constant.

### Out-Given-In

In order to purchase $$\Delta y$$ayToken from the pool, the buyer needs to deposit $$\Delta x$$Token, which can be expressed as 

$$\Delta y=y-\left[x^{1-t}+y^{1-t} - (x+\Delta x)^{1-t}\right]^{\frac{1}{1-t}}$$

### **In-Given-Out**

This is the opposite case to Out-Given-In. We are expressing $$\Delta x$$as a function of $$ \Delta y $$

$$\Delta x=  \left[x^{1-t}+y^{1-t} - (y-\Delta y)^{1-t}\right]^{\frac{1}{1-t}}-x $$

### In-Given-Price

Sometimes trader would like to adjust the price, perhaps due to deviation of AMM price to the market value. Denote $$p=\left( \frac{y}{x}\right)^t$$and $$p'=\left( \frac{y-\Delta y}{x + \Delta x}\right)^t$$pool price before and after the adjustment respectively,  we can then express $$\Delta x$$as

$$\Delta x=x\left[\left(\frac{1+p^{\frac{1-t}{t}}}{1+p'^{\frac{1-t}{t}}}\right)^{\frac{1}{1-t}}-1\right]$$

## Capital Efficiency - Concentrated Liquidity

