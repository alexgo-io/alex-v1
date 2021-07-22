
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"

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
        let block = chain.mineBlock([
            /* 
             * Add transactions with: 
             * Tx.contractCall(...)
            */
        ]);
        assertEquals(block.receipts.length, 0);
        assertEquals(block.height, 2);

    },
});
