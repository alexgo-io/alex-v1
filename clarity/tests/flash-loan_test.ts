
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';


const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
const testFlashLoanUser = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.test-flash-loan-user"
/**
 * Flash Loan Testing in Vault implementation.
 * 
 * 1. User using Flashloan for 2 tokens
 * 
 * 2. User using Flashloan for 3 tokens (two different pools)
 */

Clarinet.test({
    name: "VAULT : Flash Loan Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let block = chain.mineBlock([
            Tx.contractCall("alex-vault", "flash-loan", [
                types.principal(testFlashLoanUser),
                types.principal(gAlexTokenAddress),
                types.principal(usdaTokenAddress),
                types.none(),
                types.uint(10000),
                types.uint(10000),
                types.none()
              ], deployer.address)
            
        ]);
        block.receipts[0].result.expectOk()

    },
});
