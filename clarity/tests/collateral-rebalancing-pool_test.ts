
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
    name: "CRP : Creating Pool and Borrower use case",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let expiry = 52560; //  1 year

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayTokenAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Borrower adds collateral to the pool and mint ayToken
        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, ayTokenAddress,alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Check Borrower's Token status of gained ayToken and reduced Collateral.

    },
});

Clarinet.test({
    name: "CRP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let expiry = 52560; //  1 year

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayTokenAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = CRPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = CRPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectPrincipal(wallet_1.address);

        // // Collect Fees - TO BE IMPLEMENTED AFTER FEE COLLECTOR IMPLEMENTATION
        
    },
});