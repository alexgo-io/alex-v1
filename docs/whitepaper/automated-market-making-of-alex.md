# Automated Market Making of ALEX

## TL;DR

ALEX aims to provide a fixed rate borrowing and lending service with pre-determined maturity in the world of decentralised finance \(DeFi\). We include forward contracts in our trading pool, with Automated Market Making \(AMM\) engine in association with generalised mean. While we formalise the trading practise swapping forward contracts with underlying asset, we incorporate the latest innovation in the industry - concentrated liquidity. Consequently, liquidity provider of ALEX can save decent amount of capital by making markets on a selected range of interest rate.

## Introduction

ALEX stands for **A**utomated **L**iquidity **EX**change. It is a hybrid of automated marketing making and on-chain loanable fund built on Stacks blockchain network. While lenders and borrowers can minimise uncertainty by securing the loan with fixed rate and tenor, liquidity providers are able to take advantage of our capital efficiency mechanism by imposing cap and floor on the interest rate. This allows liquidity to be offered on parts of the curve that contains majority of trading activities and leads to efficient capital management.

On ALEX, lending and borrowing activities are facilitated by a forward contract based token “ayToken”. It is similar to an OTC bilateral forward contract in the conventional financial market, which specifies underlying asset “Token” and expiry date. This paper assumes ayToken is minted and ready to be exchanged. Lenders purchase ayToken at a discount to the spot Token price when the contract is initiated and reclaim underlying asset upon expiration when forward price converges to spot price. Borrowers sell ayToken in return for Token on day one and return Token upon expiration. Implied interest rate depends on how much discount that the forward price is to the spot price at the time of transaction, which is executed on AMM.

Last but not least, ALEX hopes to bridge the gap between Defi and conventional finance by applying an AMM protocol derived from one of the basic instruments in fixed income market - zero coupon bond firstly proposed by [Yield Space](https://yield.is/YieldSpace.pdf). This empowers ALEX to learn from the fiat world and offer more decentralised financial products in the future.

This paper focuses on technical aspects of AMM and is the first of a series of ALEX papers unveiling all exciting features and applications of ALEX development.

## AMM and Invariant Function

ALEX AMM is built on three beliefs: \(i\) it is mathematically neat and reflect economic demand and supply; \(ii\) it is a type of mean, like other AMMs; and \(iii\) it is derived and can be interpreted in terms of yield and is somehow related to conventional finance, where research has been conducted for decades.

We will firstly review some desirable features of AMM that ALEX hopes to exhibit.

### Properties of AMM

AMM protocol, which provides liquidity algorithmically, is the core engine of Defi. In the liquidity pool, two or more assets are deposited and subsequently swapped resulting in both reserve and price movement. The protocol follows an invariant function $$f(X)=L$$, where $$X=\left(x_1,x_2,\dots,x_d\right)$$ is $$d$$ dimension representing $$d$$ assets and $$L$$ is constant. When $$d=2$$, which is the common practise by a range of protocols, AMM $$f(x_1,x_2)=L$$ can be expressed as $$x_2=g(x_1)$$. Although it is not always true, $$g$$ tends to be twice differentiable and satisfies the following

* monotonically decreasing, i.e. $$\frac{dg(x_1)}{dx_1}<0$$. This is because price is often defined as $$-\frac{dg(x_1)}{dx_1}$$. A decreasing function ensures price to be positive.
* convex, i.e. $$\frac{d^2g(x_1)}{dx_1^2} \geq 0$$. This is equivalent to say that $$-\frac{dg(x_1)}{dx_1}$$ is a non-increasing function of $$x_1$$. It is within the expectation of economic theory of demand and supply, as more reserve of $$x_1$$ means declining price.

Meanwhile, $$f$$ can usually be interpreted as a form of mean, for example, [mStable](https://docs.mstable.org) relates to arithmetic mean, where $$x_1+x_2=L$$ \(constant sum formula\); one of the most popular platforms [Uniswap](https://uniswap.org/whitepaper-v3.pdf) relates to geometric mean, where $$x_1 x_2=L$$ \(constant product formula\); [Balancer](https://balancer.fi/whitepaper.pdf), which our collateral rebalancing pool employs, applies weighted geometric mean. Its AMM is $$x_1^{w_1} x_2^{w_2}=L$$ where $$w_1$$ and $$w_2$$ are fixed weights. However, none of these three protocols consider time to maturity, which is essential in modern interest rate theory.

### ALEX AMM

After extensive research, we consider it possible for ALEX AMM to be connected to generalised mean defined as

$$
\left( \frac{1}{d} \sum _{i=1}^{d} x_i^p \right)^{\frac{1}{p}}
$$

where $$0 \leq p \leq 1$$. The expression might remind readers of $$p$$-norm when $$x_i \geq 0$$. It is however not true when $$p<1$$ as triangle inequality doesn't hold.

When $$d=2$$ and $$p$$ is fixed, the core component of generalised mean is assumed constant as below. 

$$
x_1^p+x_2^p=L
$$

This equation is regarded reasonable as AMM, because \(i\) function $$g$$ where $$x_2=g(x_1)$$ is monotonically decreasing and convex; and \(ii\) The boundary value of $$p=1$$ and $$p=0$$ corresponds to constant sum and constant product formula respectively. When $$p$$ increases from 0 to 1, price $$-\frac{dg(x_1)}{x_1}$$ gradually converges to 1. This is what ALEX hopes to achieve when forward becomes spot. This also means that $$p$$ is somehow related to time to maturity. Please refer to [Appendix 1](automated-market-making-of-alex.md#appendix-1-generalised-mean-when-d-2) for a detailed discussion.

In the benchmark research piece by [Yield Space](https://yield.is/YieldSpace.pdf), the invariant function above is formalised from the perspective of zero coupon bond. $$p$$ is replaced by $$1-t$$ where $$t$$ is time to maturity and $$L$$ is a function of $$t$$, so that

$$
x_1^{1-t}+x_2^{1-t}=L\left(t\right)
$$

This is derived by solving the following differential equation when $$t \neq 1$$

$$
-\frac{dx_2}{dx_1}=\left(\frac{x_2}{x_1} \right)^t
$$



In the rest of the paper, to be consistent with [Yield Space](https://yield.is/YieldSpace.pdf), we employ notations below

* $$x$$ : balance of the underlying Token
* $$y$$ : balance of ayToken
* $$r$$ : implied interest rate, defined as the natural logarithm of balance of ayToken and Token

$$
r=log \left( \frac{y}{x} \right)
$$

* $$p$$ : price of Token in terms of ayToken. The commonly quoted ayToken price is the inverse, i.e. $$\frac{1}{p}$$ 

$$
p=\left(\frac{y}{x} \right)^t=e^{rt}
$$

ALEX's implied interest rate is compound. Not only does the compound rate allow us to derive mathematical formulas throughout the paper, we can also conduct further research and offer more products by referring to vast amount of literatures and applications in conventional finance, which is largely built on Black-Scholes model with compound rate employed as the discounting factor.

Using notations above, the invariant function is rewritten as $$x^{1-t}+y^{1-t}=L$$ with the differential equation $$-\frac{dy}{dx}=\left(\frac{y}{x} \right)^t$$. Unless specified, we assume $$L$$ constant and call it invariant constant. This means that $$t$$ is fixed and there is no minting or burning coins. In practise, liquidity providers can add or reduce liquidity, and $$L$$ needs to be recalibrated daily when $$t$$ changes.

Though purely theoretical at this stage, [Appendix 2](automated-market-making-of-alex.md#appendix-2-liquidity-mapping-to-uniswap-v3) maps $$L$$ to the liquidity distribution of [Uniswap V3](https://uniswap.org/whitepaper-v3.pdf). This is motivated by an independent research from [Paradigm](https://www.paradigm.xyz/2021/06/uniswap-v3-the-universal-amm/).

## Trading Formulae

Market transaction, which involves exchange of Token and ayToken, satisfies the invariant function. While fee is deposited back to the liquidity pool in some protocols, such as _Uniswap V2_, resulting in slight increase of $$L$$ after each transaction, ALEX counts the fee separately. This is consistent with [Uniswap V3](https://uniswap.org/whitepaper-v3.pdf). Hence $$L$$ remains constant.

### Out-Given-In

In order to purchase $$\Delta y$$ amount of ayToken from the pool, the buyer needs to deposit $$\Delta x$$ amount of Token. $$\Delta x$$ and $$\Delta y$$ satisfy the following

$$
(x+\Delta x)^{1-t}+(y-\Delta y)^{1-t}=x^{1-t}+y^{1-t}
$$

After each transaction, balance is updated as below: $$x\rightarrow x+\Delta x$$ and $$y\rightarrow y-\Delta y$$. Balance of $$y$$ should not be less than that of $$x$$ to avoid negative interest rate, which will be discussed in detail later. Rearranging the formula results in

$$
\Delta y=y-\left[x^{1-t}+y^{1-t}-(x+\Delta x)^{1-t}\right]^{\frac{1}{1-t}}
$$

When transaction cost exists, the actual deposit to the pool is less than $$\Delta x$$. Assuming $$\lambda\Delta x$$ is the actual amount and $$(1-\lambda)\Delta x$$ is the fee, above can now be expressed as 

$$
\begin{split}
&(x+\lambda\Delta x)^{1-t}+(y-\Delta y)^{1-t}=x^{1-t}+y^{1-t}\\
&\Delta y=y-\left[x^{1-t}+y^{1-t}-(x+\lambda\Delta x)^{1-t}\right]^{\frac{1}{1-t}} 
\end{split}
$$

To keep $$L$$ constant, the updated balance is: $$x\rightarrow x+\lambda\Delta x$$ and $$y\rightarrow y-\Delta y$$.

### In-Given-Out

This is the opposite case to above. We are deriving $$\Delta x$$ from $$\Delta y$$.

$$
\Delta x=\frac{1}{\lambda}{\left[x^{1-t}+y^{1-t}-(y-\Delta y)^{1-t}\right]^{\frac{1}{1-t}}-x}
$$

### In-Given-Price / Yield

Sometimes, trader would like to adjust the price/yield, perhaps due to deviation of AMM price to the market value. Define $$p'$$ the AMM price after rebalancing the Token and ayToken in the pool

$$
p'=\left(\frac{y-\Delta y}{x+\lambda\Delta x}\right)^{t}
$$

Then, the added amount of $$\Delta x$$ can be calculated from the formula below 



$$
\begin{split}
&(x+\lambda\Delta x)^{1-t}+(y-\Delta y)^{1-t}=x^{1-t}+y^{1-t}\\
&1+\left(\frac{y}{x}\right)^{1-t}=\left(1+\lambda\frac{\Delta x}{x}\right)^{1-t}+(\frac{y-\Delta y}{x})^{1-t}\\
&1+p^{\frac{1-t}{t}}=\left(1+\lambda\frac{\Delta x}{x}\right)^{1-t}+p'^{\frac{1-t}{t}}\left(1+\lambda\frac{\Delta x}{x}\right)^{1-t}\\
&\Delta x=\frac{x}{\lambda}\left[\left(\frac{1+p^{\frac{1-t}{t}}}{1+p'^{\frac{1-t}{t}}}\right)^{\frac{1}{1-t}}-1\right]\\
\end{split}
$$

Denote $$r$$ and $$r'$$ the current and trader's target interest rate respectively. Because $$p=e^{rt}$$ and $$p'=e^{r't}$$, the above equation can also be rewritten as 

$$
\Delta x=\frac{x}{\lambda}\left[\left(\frac{1+e^{r(1-t)}}{1+e^{r'(1-t)}}\right)^{\frac{1}{1-t}}-1\right]
$$

### Transaction Cost on Notional and Yield

In the previous sections, fee is in proportion to the notional amount. This is consistent with AMM such as _Uniswap_. However, it could be hard to interpret in the yield space, as market participants tend to think of borrowing or lending activity in terms of rate.

The formula below expresses $$\lambda$$ regarding bid/offer imposed on interest rate $$r$$, so that conversion in between the two is possible. Denote $$r_m$$ as the mid rate calculated from AMM

$$
e^{r_m}=\frac{y-\Delta y}{x+\lambda\Delta x}
$$

However, trader deposits $$x+\Delta x$$ rather than $$x+\lambda\Delta x$$. Therefore, the bid rate $$r_b$$ when purchasing ayToken satisfies

$$
e^{r_b}=\frac{y-\Delta y}{x+\Delta x}
$$

$$\Delta r_b=r_m-r_b$$ is then the fee charged to the purchaser in the yield space, 

$$
e^{\Delta r_b}=\frac{x+\Delta x}{x+\lambda\Delta x}
$$

Hence, $$\lambda$$ can be expressed as a function of $$\Delta r_b$$ 

$$
\lambda=\frac{\Delta x+x(1-e^{\Delta r_b})}{\Delta xe^{\Delta r_b}}
$$

It can be shown that the above equality also holds when redeeming ayToken for Token, except $$\Delta r_b$$ replaced by $$\Delta r_o=r_o-r_m$$, where $$e^{r_m}=\frac{y+\lambda\Delta y}{x-\Delta x}$$ and $$e^{r_o}=\frac{y+\Delta y}{x-\Delta x}$$. Here, $$r_o$$ is the offer rate when selling ayToken and $$\Delta r_o$$ is the corresponding fee charged to the seller in the yield space.

## Concentrated Liquidity

In the current setting, liquidity provider can make market on any rate between $$-\infty$$ to $$+\infty$$. However, market participants might wish to impose certain constraint, for example no negative interest rate. One solution is to set up bounds on $$\frac{y}{x}$$, which are related to the rate. In the case of positive rate, this means balance of ayToken always larger than Token. Although it solves the problem, the amount of ayToken lower than Token would be excluded from trading activities in any means. We are proposing an alternative approach by introducing virtual tokens.

Virtual tokens constitute part of the trading pool reserve that would never be touched hence underutilised. Liquidity providers should not be required to maintain this part of the pool and we are therefore set them as virtual. For example, when rate is floored at 0%, $$t$$= 0.5 and $$L$$= 20, liquidity providers will never face the situation of ayToken balance falling below 100, which can then be regarded as virtual to save the actual capital cost.

The idea is inspired by concentrated liquidity in _Uniswap v3_.

### Pool with interest rate floored at zero

This section only allows liquidity on non-negative interest rate. Concentrated liquidity is achieved by introducing virtual token reserves $$y_v$$, which satisfies

$$
x^{1-t}+(y+y_{v})^{1-t}=L
$$

Figure 1 illustrates the example above of $$t$$= 0.5 and $$L$$= 20 by displaying two sets of curves: Invariant Function Curve \(“IFC"\) satisfying $$x^{1-t}+y^{1-t}=L$$ and Capital Efficiency Curve \(“CEC"\) satisfying $$x^{1-t}+(y+y_v)^{1-t}=L$$. Intuitively CEC is attained by lowering IFC by $$y_v$$= 100.

![Figure 1](../.gitbook/assets/cecjing.png)

#### Initialisation

Instead of contributing equal amount of Token and ayToken to initialise the pool with interest rate 0%, liquidity provider only needs to contribute x amount of Token. This is because virtual token $$y_v=x=\left(\frac{1}{2}L\right)^{\frac{1}{1-t}}$$.

#### Trading

Balance of Token and ayToken, including both actual and virtual, still satisfy the invariant function. However, once the actual ayToken is depleted and only Token is left in the pool, trading would be ceased until more ayToken is deposited.

#### Minting and Burning

Before liquidity expansion or reduction by minting or burning coins, assume that the old pool has Token $$x$$ and ayToken $$y$$ satisfying $$x^{1-t}+y^{1-t}=L$$, where $$y=y_a+y_v$$ and $$y_a$$ and $$y_v$$ are balance of actual and virtual ayToken respectively.

Minting and Burning should not affect price and interest rate. This means that newly added or withdrawn coins would be in proportion to x and y. Denote new amount of Token and ayToken as $$x'=kx$$ and $$y'=ky$$ respectively. $$y'=y'_a+y'_v$$ where $$y'_a$$ is actual whereas $$y'_v$$ virtual. They satisfy the following



$$
\begin{split}
&y'_a+y'_v=ky\\
&2y'^{1-t}_v=k^{1-t}L
\end{split}
$$

Solution to the above equations is



$$
\begin{split}
&y'_{a}=ky-y'_{v}\\y'_{v}
&=\left(\frac{1}{2}L\right)^{\frac{1}{1-t}}k
\end{split}
$$

This means $$y'_v=ky_v$$ and $$y'_a=ky_a$$.

#### Example

Assume $$t$$= 0.5. Rachel initialises a liquidity pool of 0% interest rate with 100 Token on CEC. Although there is no actual ayToken, 0% rate implies 100 virtual tokens and $$L$$= 20 on IFC.

Suppose Rachel then sells 50 ayToken to the pool on the same day. On IFC, this means ayToken amount of 150 \(50 actual and 100 virtual\) and the amount of 60.10 Token remaining on IFC.

Now suppose Billy wants to mint 10% of the liquidity pool. This means that Billy needs to deposit 6.01 \(10% of 60.10\) Token. Virtual balance is updated to $$\left(\frac{1}{2}\times20\right)^{\frac{1}{0.5}}\times1.1=110$$. Billy needs to deposit 5 ayToken \($$1.1\times150-110-50$$\), so that the summation of actual and virtual ayToken is 165. Interest rate remains the same before and after Billy's participation. Note that both actual and virtual ayToken balance increase by 10%, which is the same proportion as the growth of liquidity pool.

### Range-bound Pool

The above section can be extended to any constraint pool with upper interest rate $$r_{u}$$ and lower interest rate $$r_{l}$$. If interest rate falls out of \[$$r_{l} $$,$$r_{u}$$\], swapping would be suspended as one of the tokens would have been depleted.

Denote $$x_{a}$$, $$x_{v}$$, $$y_{a}$$ and $$y_{v}$$ balance of actual Token, virtual Token, actual ayToken and virtual ayToken respectively. They satisfy invariant function on IFC, i.e. $$(x{a}+x{v})^{1-t}+(y{a}+y{v})^{1-t}=L$$.

The amount of Token an ayToken can be expressed as a function of L and current interest rate $$r_{c}=\frac{y_{a}+y_{v}}{x_{a}+x_{v}}$$.

$$
\begin{split}
&x_{a}+x_{v}&=\left[\frac{L}{1+e^{(1-t)r_{c}}}\right]^{\frac{1}{1-t}}\\
&y_{a}+y_{v}&=\left[\frac{L}{1+e^{-(1-t)r_{c}}}\right]^{\frac{1}{1-t}}
\end{split}
$$

Intuitively, when $$r_{c}=r_{l}$$, ayToken is depleted; Similarly, when $$r_{c}=r_{u}$$, Token is used up. Therefore,



$$
\begin{split}
&x_{v}=\left[\frac{L}{1+e^{(1-t)r_{u}}}\right]^{\frac{1}{1-t}}\\
&y_{v}=\left[\frac{L}{1+e^{-(1-t)r_{l}}}\right]^{\frac{1}{1-t}}
\end{split}
$$

See [Appendix 3](automated-market-making-of-alex.md#appendix-3-derivation-of-actual-and-virtual-token-reserve) for a detailed derivation of virtual, as well as actual token reserve.

Similar to the case of 0% floor, minting or burning coins would result in invariant constant changing from $$L$$ to $$k^{1-t}L$$. Meanwhile, both actual and virtual Token and ayToken would grow proportionally by $$k$$, as they are linear function of $$L^{\frac{1}{1-t}}$$.

#### Example

We aim to show here how virtual token is able to assist liquidity providers to efficiently manage capital.

![Figure 2](../.gitbook/assets/cectable2%20%281%29.png)

In Figure 2, assume lower bound is 0%, whereas upper bound is 50%. We also set $$t$$= 0.5 and $$L$$= 20. If interest rate is 0%, $$L$$= 20 means holding equal amount of Token and ayToken of 100 each $$\left(100^{0.5}+100^{0.5}=20\right)$$. The figure compares actual holding of Token and ayToken with and without cap and floor.

According to the figure, when current implied interest rate is 10%, without capital efficiency, liquidity provider is required to deposit 95.06 Token and 105.06 ayToken. This is in comparison with 18.39 Token and 5.06 ayToken after imposing cap and floor. In this example, the capital saving is at least 77%.

## Appendix 1: Generalised Mean when d=2

ALEX's invariant function is $$f(x_{1},x_{2};p)=x{_1}^{p}+x_{2}^{p}=L.$$ It can be rearranged as $$x{2}=g(x_{1})=(L-x_{1}^{p})^{\frac{1}{p}}$$. $$x_{1}$$ and $$x_{2}$$ should both be positive meaning the liquidity pool contains both tokens.

#### Theorem

When $$0<p<1$$, $$g\left(x_{1}\right)$$ is monotonically decreasing and convex.

#### Proof

This is equivalent to prove $$\frac{dg(x_{1})}{dx_{1}}<0$$ and $$\frac{d^{2}g(x_{1})}{dx_{1}^{2}}\geq0$$.

$$
\begin{split}
&\frac{dg(x_{1})}{dx_{1}}=\frac{1}{p}(L-x_{1}^{p})^{\frac{1}{p}-1}\left(-px_{1}^{p-1}\right)=-\left(\frac{L-x_{1}^{p}}{x_{1}^{p}}\right)^{\frac{1-p}{p}}<0\\
&\frac{d^{2}g(x_{1})}{dx_{1}^{2}}=-\frac{1-p}{p}\left(\frac{L-x_{1}^{p}}{x_{1}^{p}}\right)^{\frac{1-2p}{p}}\left[\frac{-px_{1}^{p-1}x_{1}^{p}-(L-x_{1}^{p})px^{p-1}}{x_{1}^{2}p}\right]\\
&=L(1-p)\left(\frac{x_{2}}{x_{1}}\right)^{1-2p}x_{1}^{-p-1}\geq0
\end{split}
$$

The last inequality holds because each component is positive.

When $$p$$= 1, it is straightward to see that the invariant function is constant sum. To show that the invariant function converges to constant product when $$p$$= 0, we will show and prove an established result in a generalised $$d$$ dimensional setting.

#### Theorem

$$
\lim_{p\rightarrow0}\left(\frac{1}{d}\sum_{i=1}^{d}x_{i}^{p}\right)^{\frac{1}{p}}=({\prod_{i=1}^{d}x_{i}})^{\frac{1}{d}}
$$

#### Proof

$$\left(\frac{1}{d}\sum{i=1}^{d}x_{i}^{p}\right)^{\frac{1}{p}}=\text{exp}\left[\frac{\text{log}\left(\frac{1}{d}\sum{i=1}^{d}x_{i}^{p}\right)}{p}\right]$$. Applying _L'Hospital_ rule to the exponent,which is 0 in both denominator and nominator when $$p\rightarrow0$$, we have

$$
\lim_{p\rightarrow0}\frac{\text{log}\left(\frac{1}{d}\sum_{i=1}^{d}x_{i}^{p}\right)}{p}=\lim_{p\rightarrow0}\sum_{i=1}^{d}\frac{\text{log}(x_{i})}{\sum_{j=1}^{d}\left(\frac{x_{j}}{x_{i}}\right)^{p}}=\frac{\sum_{i=1}^{d}\text{log}(x_{i})}{d}
$$

Therefore

$$
\lim_{p\rightarrow0}\left(\frac{1}{d}\sum_{i=1}^{d}x_{i}^{p}\right)^{\frac{1}{p}}=\lim_{p\rightarrow0}\text{exp}\frac{\sum_{i=1}^{d}\text{log}(x_{i})}{d}=({\prod_{i=1}^{d}x_{i}})^{\frac{1}{d}}
$$

#### Corollary

When d = 2,

$$
x_{1}x_{2}=\lim_{p\rightarrow0}\left[\frac{1}{2}(x_{1}^{p}+x_{2}^{p})\right]^{\frac{2}{p}}
$$

Proof of the corollary is trivial, as it is a direct application of the theorem. It shows that generalised mean AMM implies constant product AMM when $$p\rightarrow0$$.

## Appendix 2: Liquidity Mapping to Uniswap v3

As Uniswap v3 is able to simulate liquidity curve of any AMM, we are interested in exploring the connection between ALEX's AMM and that of _Uniswap_'s. Interesting questions include: what is the shape of the liquidity distribution? Which point\(s\) has the highest liquidity? We acknowledge that the section is more of a theoretical study for now.

_Uniswap V3_ AMM can be expressed as a function of invariant constant $$L$$ with respect to price $$p$$, $$L_{\text{Uniswap}}=\frac{dy}{d\sqrt{p}}$$. In terms of ALEX, as price p=e^{rt}, where $$r$$ is the implied interest rate, we have

$$
L_{\text{Uniswap}}=\frac{dy}{d\sqrt{p}}=\frac{2}{t}e^{-\frac{1}{2}rt}\frac{dy}{dr}
$$

In the previous sections, we express $$y$$ as

$$
y=\left[\frac{L}{1+e^{-(1-t)r}}\right]^{\frac{1}{1-t}}
$$

Therefore

$$
\begin{split}
&\frac{dy}{dr}=L^{\frac{1}{1-t}}\frac{e^{-(1-t)r}}{(1+e^{-(1-t)r})^{\frac{2-t}{1-t}}}\\
&L_{\text{Uniswap}}=\frac{2}{t}L^{\frac{1}{1-t}}\left(e^{\frac{r(1-t)}{2}}+e^{\frac{-r(1-t)}{2}}\right)^{\frac{-2+t}{1-t}}\\
&=\frac{2}{t}L^{\frac{1}{1-t}}\big\{2\cosh\left[\frac{r(1-t)}{2}\right]\big\}^{\frac{-2+t}{1-t}}
\end{split}
$$

![Figure 3](../.gitbook/assets/liquidity%20%282%29.png)

Figure 3 plots $$L_{\text{Uniswap}}$$ against interest rate $$r$$ regarding various levels of $$t$$. When $$0<t<1$$, $$L_{\text{Uniswap}}$$ is symmetric around 0% at which the maximum reaches . This is because

1. $$\cosh\left[(\frac{r(1-t)}{2})\right]$$ is symmetric around $$r$$= 0% with minimum at 0% and the minimum value 1; 
2. $$x^z$$ is a decreasing function of $$x$$ when $$x$$ is positive and power $$z$$ is negative. In our case, we have $$z=-2+t1-t<-1$$. Therefore, it is the maximum rather than minimum that $$L_{\text{Uniswap}}$$ achieves at 0. 

Furthermore, the higher the $$t$$, the flatter the liquidity distribution is. When $$t$$ approaches 1, i.e. AMM converges to the constant product formula, the liquidity distribution is close to a flat line. When $$t$$ approaches 0, the distribution concentrates around 0%. This makes sense, as forward price starts to converge to spot price upon expiration.

## Appendix 3: Derivation of Actual and Virtual Token Reserve

On CEC, there are two boundary points \($$x_{b}$$,0\) and \(0,$$y_{b}$$\) corresponding to the lower and upper bound of interest rate $$r_{l}$$ and $$r_{u}$$ respectively. We assume $$L$$ is pre-determined, as liquidity provider knows the pool size. We aim to find $$x_{b}$$, $$y_{b}$$, $$x_{v}$$ and $$y_{v}$$ which satisfy the following equations



$$
\begin{split}
&(x_{b}+x_{v})^{1-t}+y_{v}^{1-t}=L\\
&x_{v}^{1-t}+(y_{b}+y_{v})^{1-t}=L\\
&\frac{y_{v}}{x_{b}+x_{v}}=e^{r_{l}}\\
&\frac{y_{b}+y_{v}}{x_{v}}=e^{r_{u}}
\end{split}
$$

As there are four unknown variables with four equations, solutions can be expressed as below



$$
\begin{split}
&x_{v}=\left[\frac{L}{1+e^{(1-t)r_{u}}}\right]^{\frac{1}{1-t}}\\
&y_{v}=\left[\frac{L}{1+e^{-(1-t)r_{l}}}\right]^{\frac{1}{1-t}}\\
&x_{b}=y_{v}e^{-r_{l}}-x_{v}=\left[\frac{L}{1+e^{r_{l}(1-t)}}\right]^{\frac{1}{1-t}}-\left[\frac{L}{1+e^{r_{u}(1-t)}}\right]^{\frac{1}{1-t}}\\
&y_{b}=x_{v}e^{r_{u}}-y_{v}=\left[\frac{L}{1+e^{-r_{u}(1-t)}}\right]^{\frac{1}{1-t}}-\left[\frac{L}{1+e^{-r_{l}(1-t)}}\right]^{\frac{1}{1-t}}
\end{split}
$$

When $$r_{l}=0$$, the pool is floored at 0%. This means that $$x_{v}=0$$, $$y_{v}=\left(\frac{1}{2}L\right)^{\frac{1}{1-t}}$$, $$x_{b}=y_{v}$$.

When the current interest rate $$r_{c}$$ is known and $$r_{c}\in[r_{l},r_{u}]$$, we can calculate $$x_{a}$$ and $$y_{a}$$ satisfying the following equations. When $$r_{c} \notin[r_{l},r_{u}]$$, only one token exists and swapping activities are suspended.



$$
\begin{split}
&(x_{v}+x_{a})^{1-t}+(y_{v}+y_{a})^{1-t}=L\\
&\frac{y_{v}+y_{a}}{x_{v}+x_{a}}=e^{r_{c}}
\end{split}
$$

Solution to above is



$$
\begin{split}
&x_{a}=\left[\frac{L}{1+e^{r_{c}(1-t)}}\right]^{\frac{1}{1-t}}-x_{v}=\left[\frac{L}{1+e^{r_{c}(1-t)}}\right]^{\frac{1}{1-t}}-\left[\frac{L}{1+e^{r_{u}(1-t)}}\right]^{\frac{1}{1-t}}\\
&y_{a}=\left[\frac{L}{1+e^{-r_{c}(1-t)}}\right]^{\frac{1}{1-t}}-y_{v}=\left[\frac{L}{1+e^{-r_{c}(1-t)}}\right]^{\frac{1}{1-t}}-\left[\frac{L}{1+e^{-r_{l}(1-t)}}\right]^{\frac{1}{1-t}}
\end{split}
$$

At the boundary points, when $$r_{c}=r_{l}$$, $$x_{a}=x_{b}$$ and $$y_{a}=0$$; when $$r_{c}=r_{u}$$, $$x_{a}=0$$ and $$y_{a}=y_{b}$$.

