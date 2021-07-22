
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

const testWeightX = 50000000 //0.5
const testWeightY = 50000000 //0.5

/**
 * Fixed Weight Pool Test Cases  
 * 
 * 1. Create Pool, Add values to the pool and reduce values.
 * 
 * 2. Conduct Swapping 
 * 
 * 3. Set Platform fees and collecting
 * 
 */

Clarinet.test({
    name: "FWP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500000, 100000);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(gAlexTokenAddress, usdaTokenAddress,testWeightX, testWeightY);
        call.result.expectOk();

        // Add extra liquidity
        result = FWPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 500000, 100000);
        result.expectOk().expectBool(true);

        // Reduce liquidlity
        result = FWPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 10000);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(99990000);
            position['dy'].expectUint(99990000);
    },
});

Clarinet.test({
    name: "FWP : Swapping Token Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // deployer creates pool
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 50000, 10000);
        result.expectOk().expectBool(true);

        // check whether weighted equation returns an appropriate value.
        result = FWPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 1000);
        result.expectOk().expectUint(195097600)
        
        // deployer swaps alextoken with usda token
        result = FWPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, alexVaultAddress, 200);
        result.expectOk().expectList()[0].expectUint(200000000); 
        result.expectOk().expectList()[1].expectUint(38844200); 
        // TODO : Operation illustration

    },
});

Clarinet.test({
    name: "FWP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, alexVaultAddress, 50000, 10000);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = FWPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = FWPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY);
        result.expectOk().expectPrincipal(wallet_1.address);

        // // Collect Fees - TO BE IMPLEMENTED AFTER FEE COLLECTOR IMPLEMENTATION
        // result = FWPTest.collectFees(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY);
        // result.expectOk()
    },
});
