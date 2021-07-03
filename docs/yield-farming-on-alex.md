# Yield Farming on ALEX

A high LTV \(even on a static collateral\) can be offered between ayTokens of different maturities. For example, ayToken-1y as collateral may achieve 90% LTV to mint ayToken-O/N \(similar to borrowing overnight to buy long-term asset\). This allows "yield farming" whereby you repeat the process of buying ayToken-1y, use it as collateral to mint and sell ayToken-O/N for Token \(to buy ayToken-1y\) to achieve a high APY \(assuming ayToken-1y APY &gt; ayToken-O/N APY\).

![Yield Farming Use Case](https://yuml.me/diagram/scruffy/usecase/[Liquidity%20Provider]-%28Mint%20ayToken%20/%20Token%20Pool%20Token%29,%20[Lender]-%28Buy%20ayToken%29,%20[Borrower]-%28Buy%20Token%29,%20[Lender]-%28Borrower/Lender%20fee%20rebate%20in%20gALEX%29,%20[Borrower]-%28Borrower/Lender%20fee%20rebate%20in%20gALEX%29,%20[Liquidity%20Provider]-%28LP%20reward%20in%20gALEX%29,%20[Borrower]-%28Mint%20ayToken%29,%20%28Mint%20ayToken%20/%20Token%20Pool%20Token%29<%28Yield%20Farming%29,%20%28Buy%20ayToken%29<%28Yield%20Farming%29,%20%28Buy%20Token%29<%28Yield%20Farming%29,%20%28Borrower/Lender%20fee%20rebate%20in%20gALEX%29<%28Yield%20Farming%29,%20%28LP%20reward%20in%20gALEX%29<%28Yield%20Farming%29,%20%28Mint%20ayToken%29<%28Yield%20Farming%29)

For example, 1. Rachel has 100 BTC. 2. Rachel spends 100 BTC and buys ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. 3. She sells the borrowed ayBTC-O/N \(from \(2\)\) and buys ayBTC-1y. She uses it as collateral to borrow ayBTC-O/N at 90% LTV. 4. She repeats \(3\).

If 1y APY is 10% and O/N APY is 5%, the above "yield farming" results in APY approaching 55%.

Mathematically,

$$r=\frac{1+r{1y}}{1-LTV}-\left(1+\frac{r{1d}}{365}\right)^{365}\left(\frac{LTV}{1-LTV}\right)-1$$

An illustration is available [here](https://docs.google.com/spreadsheets/d/1L-52KHFl7O_h22Fg4gpZKczdPEXuAt5yAh2gX3BQP58?authuser=alexd%40alexgo.io&usp=drive_fs).

