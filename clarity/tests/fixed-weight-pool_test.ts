
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

Clarinet.test({
    name: "Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTestAgent = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTestAgent.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, "gALEX-USDA", 500, 100);
        result.expectOk().expectBool(true);

        // Check initial balances
        let call = await FWPTestAgent.getPoolDetails(gAlexTokenAddress, usdaTokenAddress,testWeightX, testWeightY);
        call.result.expectOk();

        // Add extra lquidity
        result = FWPTestAgent.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500, 100);
        result.expectOk().expectBool(true);

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

//     },
// });

