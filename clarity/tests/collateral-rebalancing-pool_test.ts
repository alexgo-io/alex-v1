
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    CRPTestAgent1,
  } from './models/alex-tests-collateral-rebalancing-pool.ts';
  

/**
 * Collateral Rebalancing Pool Test Cases
 * 
 * 1. Borrower adds Liquidity to the pool : puts collateral and mint ayToken
 *      collateral : usda
 *      ayToken : 
 * 2. Set platform fee and collect
 */

 const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
 const ayTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-aytoken"
 const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
 const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
 const Wallet1VaultAddress = "ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK.alex-vault"
 

Clarinet.test({
    name: "collateral-rebalancing-pool Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let borrower =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        
        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayTokenAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

    },
});
