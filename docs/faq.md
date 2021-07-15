# FAQ

## Why Stacks?

* Stacks is the layer 1 blockchain built on Bitcoin, which enables smart contract which was not possible before. 
* Back-of-envelope calculation tells us that the DeFi market on Bitcoin could be as big as $300bn. ALEX will be part of it.
* We are one of the first DeFi projects on Stacks. And we are building the DeFi primitives essential to more sophisticated DeFi projects.

For example, with ALEX on Stacks, Bitcoin holders will be able to lend and borrow Bitcoin with better user experience at a more competitive rate. Bitcoin traders can build sophisticated services and strategies on ALEX to provide liquidity and participate in yield farming across multiple pools available at ALEX. Start-ups can issue tokens and raise Bitcoin on ALEX to build better community-owned projects with low capital requirements from the team.

## How does Stacks allow much better DeFi user experience for Bitcoin holders?

Currently for a Bitcoin holders to use DeFi on ETH, he/she needs to “wrap” his/her Bitcoin.

This means:

1. The holder needs to find a WBTC merchant, 
2. Opens an account subject to KYC/AML,
3. Transfer BTC to the merchant,
4. The merchant then goes to a WBTC custodian,
5. Transfers BTC to the custodian,
6. The custodian mints/transfers WBTC to the custodian,
7. The custodian transfers WBTC to the holder,
8. Now the holder can use WBTC to use DeFi on ETH.

On Stacks, the same Bitcoin holder would do the following:

1. The holder uses BTC to use DeFi on Stacks.
2. \(and that’s it!\)

The key technical difference between Stacks and ETH to allow Stacks to do the above \(vs. ETH\) is that Stacks has a read access to Bitcoin blockchain state \(something not possible on ETH\).

So smart contracts written on Stacks can see BTC being locked and issue “wrapped” BTC, which can then be used freely on Stacks.

Such a “wrapping” of BTC on Stacks, however, is done by a smart contract and does not affect the holder’s user experience \(i.e. that process is invisible to him\).

So from the user experience perspective, you are almost natively accessing Bitcoin on Stacks.

Compared to using WBTC on ETH, a Bitcoin holder, therefore, is not subject to:

1. Intermediary risk \(of WBTC merchant and custodian\),
2. KYC/AML process \(duplicate/redundant for many, if not most, existing BTC holders\), and
3. Costs \(which can be expensive\) to convert from BTC to WBTC and vice versa.

## What other assets can and will ALEX support?

Stacks has SIP10, which is ERC20 equivalent. ALEX will be able to support all native/SIP10-compatible tokens on Stacks \(including those USDAs issued by Arkadiko and other NFTs too\).

## Who are the users and what is the strategy to onboard them?

* Stacks community and our cohort peers will be our first target audience.
* Developers/traders are highly encouraged to build on top of ALEX to, for example, leverage or mitigate risks.
* We are actively engaging and building communities in China, Korea and SEA where we have strong connection.
* We are actively researching on Tokenomics with a plan to progressive decentralisation and an incentives system for our community \(especially early adopters\).
* Last but not the least, we are working with crypto-natives and influencers to penetrate the internet hubs where crypto users are most active.

## How does it look like for users, step 1 to n?

For the Oct mainnet launch, we are building a minimal web interface modelled on our mobile prototype.

Technically, there are five actors on ALEX

* Lender: Go to Yield Token Pool =&gt; Sell Token / Buy ayToken
* Borrower: Go to Collateral Rebalancing Pool =&gt; Deposit Collateral =&gt; Mint ayToken =&gt; Go to Yield Token Pool =&gt; Sell ayToken / Buy Token
* Liquidity Provider: Go to Yield Token Pool =&gt; Deposit ayToken & Token =&gt; Mint Yield Token Pool Token
* Arbitrageur / Flash Loan User: Go to Vault =&gt; Create Flash Loan =&gt; Trade at Pools

## The collateralization ratio 

We are targeting a testnet launch by Aug and a mainnet launch by Oct, and are currently finalising the details. Our risk model indicates we can offer 1.25x collateralization ratio \(i.e. 80% LTV\) for BTC/stablecoin pair.

Further, our lending/borrowing products will not have liquidation risk.

Such a high LTV without the risk of liquidation is made possible by our collateral rebalancing pool, which dynamically rebalances between borrowed token and collateral to manage the default risk.

## Speed and cost

Given the design of our collateral rebalancing pool, we will require low transaction fee for the layer 1 blockchain. The transaction cost of Stacks at the moment is negligible.   
We believe with Stacks Microblocks implementation, the transaction speed will be faster \(if not far faster\) than that on Ethereum. Our risk model indicates that, with a low transaction fee, even 10min transaction confirmation time \(i.e. Bitcoin speed\) should be sufficient.

## How do you expand liquidity beyond Stacks 

We will provide cross chain capability at later stage. Our core architecture design is not tied to Stacks.

## What’s your borrowing rate right now?

We are targeting a testnet launch by Aug and a mainnet launch by Oct, and are currently finalising the details. Our lending and borrowing rates are market driven.

## What’s your killer user case? 

* High LTV with no risk of liquidation
* AMM driven yield curve to provide fixed yield for fixed terms

