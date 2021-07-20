
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';
  

const gAlexTokenAddress = "STSTW15D618BSZQB85R058DS46THH86YQQY6XCB7.token-alex"
const usdaTokenAddress = "STSTW15D618BSZQB85R058DS46THH86YQQY6XCB7.token-usda"
const gAlexUsdaPoolAddress = "STSTW15D618BSZQB85R058DS46THH86YQQY6XCB7.pool-token-alex-usda"
const alexVaultAddress = "STSTW15D618BSZQB85R058DS46THH86YQQY6XCB7.alex-vault"

const testWeightX = 0.5
const testWeightY = 0.5

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

        // Add extra lquidity
        result = FWPTestAgent.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500, 100);
        result.expectOk().expectBool(true);

        // Reduce liquidlity
        result = FWPTestAgent.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 100);
        result.expectOk().expectList()[0].expectUint(1000000000);
        // result.expectOk().expectList()[1].expectUint(200000000);
        // Recheck pool details
    },
});

// Clarinet.test({
//     name: "Swapping Token Test",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         let deployer = accounts.get("deployer")!;
//         let wallet_1 =accounts.get('wallet_1')!;
//         let FWPTestAgent = new FWPTestAgent1(chain, deployer);
        
//         let result = FWPTestAgent.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, 0.5,0.5, gAlexUsdaPoolAddress, alexVaultAddress, "gALEX-USDA", 500, 100);
//         result.expectOk().expectBool(true);

//         // Swap
//         result = FWPTestAgent.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 200);
//         result.expectOk().expectList()[0].expectUint(200000000); 
//         // K = 1000 * 5000 = 5,000,000
//         // y = K / 5200 = 961.53
//         // So user would get: 1000 - 961.53 = 38.46
//         // Minus 0.3% fees
//         // result.expectOk().expectList()[1].expectUint(38350578); 

//     },
// });

