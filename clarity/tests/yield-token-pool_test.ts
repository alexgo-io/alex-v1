

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    YTPTestAgent1,
  } from './models/alex-tests-yield-token-pool.ts';
  

// Deployer Address Constants 
const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-usda-ayusda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"

const testWeightX = 50000000 //0.5
const testWeightY = 50000000 //0.5
const testExpiry = 50000
/**
 * Yield Token Pool Test Cases  
 * 
 * 1. Create Pool, Add values to the pool and reduce values.
 * 
 * 2. Arbitrageurs Swapping 
 * 
 * 3. Set Platform fees and collecting
 * 
 */

Clarinet.test({
    name: "YTP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        //Deployer creating a pool, initial tokens injected to the pool
        let result = YTPTest.createPool(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(ayusdaAddress);
        call.result.expectOk();

        //Add extra liquidity
        result = YTPTest.addToPosition(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 1000000000);
        result.expectOk().expectBool(true);

        // Reduce liquidlity
        result = YTPTest.reducePosition(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 100000000);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(2000000000);
            position['dy'].expectUint(0);
    },
});

Clarinet.test({
    name: "YTP : Swapping",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        //Deployer creating a pool, initial tokens injected to the pool
        let result = YTPTest.createPool(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(ayusdaAddress);
        call.result.expectOk();


        // Get weight for testing swap - internal test
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(testExpiry)
            ], wallet_1.address);
        call.result.expectOk().expectUint(95129190)
        
        // Check whether internal weighted equation is working well - internal test
        result = YTPTest.getYgivenX(deployer, ayusdaAddress,1000000);
        result.expectOk().expectUint(1100192)
        
        // Arbitrager swapping usda for ayusda 
        // result = YTPTest.swapYForX(deployer, ayusdaAddress, usdaTokenAddress, 1000000);
        // result.expectOk().expectList()[0].expectUint(1000000); 
        // result.expectOk().expectList()[1].expectUint(1149871); 
    },
});
