# Vault

Vault holds and manages the assets of all ALEX pools. The separation of pool and vault has many benefits including, among others, cheaper transaction costs for users and quicker learning curve for developers when building custom pools on ALEX.

![Vault Use Case](https://yuml.me/diagram/scruffy/usecase/[Arbitrageur]-%28Go%20to%20Vault%29,%20[Flash%20Loan%20User]-%28Go%20to%20Vault%29,%20%28Go%20to%20Vault%29-%28Create%20Flash%20Loan%29,%20%28Go%20to%20Vault%29-%28Create%20Swap%20/%20Batch%20Swap%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Create%20Flash%20Loan%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Sell%20Token%29,%20%28Create%20Swap%20/%20Batch%20Swap%29-%28Buy%20Token%29)

### Flash Loan

Aggregating the assets of all ALEX pools into a single vault allows for the offering of Flash Loan, [popularized by AAVE](https://aave.com/flash-loans/).

Flash Loans are uncollateralized loans that must be repaid \(plus interest\) in the same transaction as it is borrowed. Since everything done with the loan must be completed in a single transaction, there are codified guarantees that make it impossible for borrowers to run away with the tokens.

Combining Flash Loan with Batch Swap allows arbitrageurs to take advantages of any price discrepancies in two or more pools without the needs for holding any input tokens.

