
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';
  

// Deployer Address Constants 
const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
const Wallet1VaultAddress = "ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK.alex-vault"

const testWeightX = 50000000
const testWeightY = 50000000

/**
 * Test Case Scenario 
 * 
 * 1. Create Pool, Add values to the pool and reduce values.
 * 
 * 2. Conduct Swapping 
 * 
 * 3. Set Platform fees and collecting
 * 
 */

Clarinet.test({
    name: "Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTestAgent = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTestAgent.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500, 100);
        result.expectOk().expectBool(true);

        // Check pool details
        let call = await FWPTestAgent.getPoolDetails(gAlexTokenAddress, usdaTokenAddress,testWeightX, testWeightY);
        call.result.expectOk();

        // Add extra liquidity
        result = FWPTestAgent.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500, 100);
        result.expectOk().expectBool(true);

        // Reduce liquidlity
        result = FWPTestAgent.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 100);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(990);
            position['dy'].expectUint(990);
    },
});

Clarinet.test({
    name: "Swapping Token Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTestAgent = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTestAgent.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500, 100);
        result.expectOk().expectBool(true);

        // default pool balance should be added first. Error thrown with zero balance
        result = FWPTestAgent.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 1000);
        result.expectErr().expectUint(63)
        
        // // Swap
        // result = FWPTestAgent.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, alexVaultAddress, 200);
        // result.expectOk().expectList()[0].expectUint(200000000); 
        // // TODO : Operation illustration

    },
});

