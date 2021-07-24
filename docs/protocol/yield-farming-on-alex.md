# Yield Farming on ALEX

A high LTV \(even on a static collateral\) can be offered between ayTokens of different maturities. For example, ayToken-1y as collateral may achieve 90% LTV to mint ayToken-O/N \(similar to borrowing overnight to buy long-term asset\). This allows "yield farming" whereby you repeat the process of buying ayToken-1y, use it as collateral to mint and sell ayToken-O/N for Token \(to buy ayToken-1y\) to achieve a high APY \(assuming ayToken-1y APY &gt; ayToken-O/N APY\).

![Yield Farming Use Case](https://raw.githubusercontent.com/alexgo-io/alex-v1/main/diagrams/use-case-yield-farming.svg)

For example, Rachel spends 100 BTC and buys ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. She then sells the borrowed ayBTC-O/N and buys more ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. She repeats this process.

If 1y APY is 10% and O/N APY is 5%, the above "yield farming" results in APY approaching 55%.

Mathematically,

$$r=\frac{1+r{1y}}{1-LTV}-\left(1+\frac{r{1d}}{365}\right)^{365}\left(\frac{LTV}{1-LTV}\right)-1$$

An illustration is available [here](https://docs.google.com/spreadsheets/d/1L-52KHFl7O_h22Fg4gpZKczdPEXuAt5yAh2gX3BQP58/edit?usp=sharing).

