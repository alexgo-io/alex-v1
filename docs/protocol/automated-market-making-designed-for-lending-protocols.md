# Yield Token Pool

Please refer to our [white paper](../whitepaper/automated-market-making-of-alex.md) for a more rigorous treatment on the subject.

## Lending and Borrowing Process

The key product that ALEX offers is essentially a zero coupon bond in conventional finance. Different from most loanable fund, prior to entering the loan contract, borrowers and lenders secure the interest rate and tenor on ALEX. The pre-determined terms remove one layer of uncertainty and assist participants with better financial planning.

In practise, borrows and sellers enter the loan by swapping a forward contract based token called "ayToken" with "Token" - the underlying asset. On one hand, purchaser obtains ayToken at a discount price to Token when contract starts and deposits Token in the pool. Upon expiration, purchaser redeems the underlying asset at value par. On the other hand, seller sells ayToken in exchange for Token initially. Token must be returned when contract ends. Although price of ayToken with respect to Token fluctuates all the time, it converges to Token price at maturity, as forward becomes spot.

As an example, Rachel has 100 USD. She wants to lend it out for a fixed term of three months. On ALEX, three month ayUSD is currently priced at 0.9 vs USD, meaning 1 ayUSD can be exchanged for 0.9 USD. This indicates an interest rate around 10%. Therefore, Rachael obtains around 110 ayUSD. In three months time, Rachel acquires 110 USD - a gain of 10 USD. Billy, who is the borrower, sells 110 ayUSD to Rachel in return for 100 USD at his disposal with a fixed interest rate and tenor. He returns 100 USD to Rachel when the contract expires.

In mathematical terms, interest rate r is calculated as $$p_{t}=\frac{1}{e^{rt}}$$, where $$p_{t}$$ is the spot price of ayToken and the interest rate is assumed to be compound. The formula utilises one of the most fundamentals in asset pricing that the present value is the discounted future value. In our example, $$t$$= 1 and $$r=\log\frac{1}{0.9}\approx10\%$$.

## Automated Market Making \(AMM\) Protocol

When designing AMM, ALEX believes in the following:

1. AMM is mathematically neat and reflects economic demand and supply. For example, price should increase when demand is high or supply is low; 
2. AMM is a type of mean, which remains constant during trading activities. This is adopted by some popular platform, such as _Uniswap_ which employs algorithmic mean; and 
3. AMM can be interpreted in modern finance theory. This would enable ALEX to grow and draw comparison with conventional finance.

After extensive research, our beliefs led us to the AMM firstly proposed by _YieldSpace_. While we appreciate the mathematical beauty of their derivation, we adapt it to be more suitable for ALEX. For instance, we replace simple interest rate by compound rate, which is more widely applied since Black-Scholes becomes the cornerstone in financial pricing and modelling. We also introduce capital efficiency scheme explained below.

In mathematical terms, our AMM is expressed as

$$
x^{1-t}+y^{1-t}=L
$$

where $$x$$, $$y$$, $$t$$ and $$L$$ is the balance of Token, balance of ayToken, time to maturity and a constant term when $$t$$ is fixed respectively. Interest rate $$r$$ is defined as $$r=\log\left(\frac{y}{x}\right)$$, i.e. natural logarithm of the ratio of balance between ayToken and Token, and price of ayToken with respect to Token is $$\left(\frac{y}{x}\right)^{t}$$

In response to our design, this AMM is a form of generalised mean. It makes economics sense because the shape of the curve is decreasing and convex. It incorporates time to maturity $$t$$, which is explicitly built in to derive ayToken spot price. We refer readers to our [white paper](../whitepaper/automated-market-making-of-alex.md) for detail.

## Liquidity Providers \(LP\) and Capital Efficiency

LP deposits both ayToken and Token to facilitate trading activities. While they are ready to make market on all possible scenarios of interest rate movement ranging from $$-\infty$$ to $$+\infty$$, part of the rates curve will never be considered by market participants such as negative interest rate. Although negative rate is introduced in the fiat world by central bankers as monetary policy tool, yield farmers in the crypto world is still longing everything positive. In ALEX, positive rate refers to spot price of ayToken not exceeding 1 and ayToken reserve is larger than Token.

Inspired by _Uniswap v3_, ALEX employs virtual tokens - part of the assets that will never be touched, hence is not required to be held by LP.

![Figure 1](../.gitbook/assets/cecjing.png)

Figure 1 illustrates an example of adopting virtual tokens in the event of positive interest rate. Blue line is the standard AMM. Blue dot represents equal balance of Token and ayToken of $$y_{v}$$ each, hence 0% interest rate. $$y_{v}$$ is the boundary amount, as any amount lower than it will never be touched by LP to avoid negative rate, which is represented by blue dashed line. Thus, $$y_{v}$$ is virtual token reserve. Effectively, LP is making market on red line, which shifts blue line lower by $$y_{v}$$. When ayToken is depleted as shown by red dashed line, trading activities are suspended.

In a numerical example, assume $$t$$= 0.5 and $$L$$= 20, when $$r$$= 10%, LP will deposit 95 token and 105 ayToken according to standard AMM. However, if the interest rate is floored at 0%, LP only needs to contribute 5 ayToken, as the rest 100 ayToken would be virtual. This is a decent saving more than 90%.

## Yield Curve and Yield Farming

By expressing interest rate as $$p_{t}=\frac{1}{e^{rt}}$$, i.e. $$r=-\frac{1}{t}\log p_{t}$$, we can obtain a series of interest rate from trading pool price with respect to various maturities, based on which we are able to build yield curve. Yield curve is the benchmark tool for modelling risk-free rate in conventional finance. The shape of the curve dictates expectation of future interest rate path, which benefits market participants understand market behaviour and trend. Currently we might be able to build Bitcoin yield curve from Bitcoin future listed on Chicago Mercantile Exchange \(CME\). However, not only is the exchange heavily regulated, its trading volume is skewed to the very short dated front end contracts lasting several months only. ALEX aims to offer future contracts up to 1y when the platform goes live and extend to longer tenors should market mature.

Yield farmers could benefit from understanding of the yield curve by purchasing ayToken whose tenor corresponds to high interest rate and selling ayToken whose tenor associates with low interest rate. This is a typical “carry" strategy.

Last but not least, based on the development of yield curve and solid foundation work of AMM, ALEX is able to provide more derivatives, including options and structured products, by referring to large amount of literatures and applications in conventional finance.

