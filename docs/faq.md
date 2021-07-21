# FAQ

## Why Stacks?

Stacks makes Bitcoin programmable, enabling decentralized apps and smart contracts that inherit all of Bitcoin’s powers. Back-of-envelope calculation tells us that the DeFi market on Bitcoin could be as big as $300bn. ALEX will be part of it. We are one of the first DeFi projects on Stacks. And we are building the DeFi primitives essential to more sophisticated DeFi projects.

For example, with ALEX on Stacks, Bitcoin holders will be able to lend and borrow Bitcoin with better user experience at a more competitive rate. Bitcoin traders can build sophisticated services and strategies on ALEX to provide liquidity and participate in yield farming across multiple pools available at ALEX. Start-ups can issue tokens and raise Bitcoin on ALEX to build better community-owned projects with low capital requirements from the team.

## How does Stacks allow much better DeFi user experience for Bitcoin holders?

Currently for a Bitcoin holders to use DeFi on Ethereum, he/she needs to “wrap” his/her Bitcoin.

This means:

1. The Bitcoin holder needs to find a WBTC merchant, 
2. Opens an account subject to KYC/AML,
3. Transfer BTC to the merchant,
4. The merchant then goes to a WBTC custodian,
5. Transfers BTC to the custodian,
6. The custodian mints/transfers WBTC to the custodian,
7. The custodian transfers WBTC to the holder,
8. Now the holder can use WBTC to use DeFi on Ethereum.

On Stacks, the same Bitcoin holder would do the following:

1. The Bitcoin holder uses his/her BTC to use DeFi on Stacks.
2. \(and that’s it!\)

The key technical difference between Stacks and Ethereum, that allows Stacks to do the above, is that Stacks has a read access to Bitcoin blockchain state \(something not possible on Ethereum\).

So smart contracts written on Stacks can see BTC being locked and issue “wrapped” BTC, which can then be used freely on Stacks.

Such a “wrapping” of BTC on Stacks, however, is done by a smart contract and does not affect the holder’s user experience \(i.e. that process is invisible to him/her\).

So from the user experience perspective, you are almost natively accessing Bitcoin on Stacks.

Compared to using WBTC on ETH, a Bitcoin holder, therefore, is not subject to:

* Intermediary risk \(of WBTC merchant and custodian\),
* KYC/AML process \(duplicate/redundant for many, if not most, existing BTC holders\), and
* Costs \(which can be expensive\) to convert from BTC to WBTC and vice versa.

## What tokens can and will ALEX support?

ALEX will support all native/SIP10-compatible tokens on Stacks.

## Who are the key actors on ALEX?

There are five actors on ALEX:

* **Lender**: Go to Yield Token Pool =&gt; Sell Token / Buy ayToken
* **Borrower**: Go to Collateral Rebalancing Pool =&gt; Deposit Collateral =&gt; Mint ayToken =&gt; Go to Yield Token Pool =&gt; Sell ayToken / Buy Token
* **Liquidity Provider**: Go to Yield Token Pool =&gt; Deposit ayToken & Token =&gt; Mint Yield Token Pool Token
* **Arbitrageur / Flash Loan User**: Go to Vault =&gt; Create Flash Loan =&gt; Trade at Pools

See [Use Case]().

## What Collateralization Ratio \(or Loan-to-Value\) can we expect on ALEX?

While details are being finalized, we can expect, for example, a collateralization ratio of 1.25x \(i.e. 80% LTV\) for a BTC loan against USD stablecoin collateral.

Further, lending and borrowing on ALEX will not be subject to liquidation risk.

All of this is made possible by our [Collateral Rebalancing Pool](protocol/collateral-rebalancing-pool.md), which dynamically rebalances between borrowed token and collateral to manage the default risk.

## What kind of transaction fee and speed do you require?

The design of our [Collateral Rebalancing Pool](protocol/collateral-rebalancing-pool.md) requires low transaction fee. The transaction fee on Stacks at the moment is negligible.

The Bitcoin block time is too slow to support decentralized apps like ALEX. To work around Bitcoin's limited speed, Stacks uses microblocks that result in near-instant confirmation on the Stacks blockchain. At the rate of the Bitcoin block time, these blocks will settle from Stacks to Bitcoin to provide the finality and security of Bitcoin.

Scaling independently of Bitcoin ensures that Stacks transactions are fast enough for ALEX, while still benefiting from Bitcoin’s security and settlement.

## Will you provide cross chain capability?

Yes, we will develop cross chain capability in the future. Our [core architecture](protocol/platform-architecture-that-supports-ecosystem-development.md) is not tied to Stacks.

## What’s your borrowing rate right now?

Our lending and borrowing rates are [market driven](protocol/automated-market-making-designed-for-lending-protocols.md).

