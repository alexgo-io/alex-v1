
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';
  

// Deployer Address Constants 
const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"

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
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 500000, 100000);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(gAlexTokenAddress, usdaTokenAddress,testWeightX, testWeightY);
        call.result.expectOk();

        // Add extra liquidity
        result = FWPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 500000, 100000);
        result.expectOk().expectBool(true);

        // Reduce liquidlity
        result = FWPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 10000);
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
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 50000, 10000);
        result.expectOk().expectBool(true);

        // check whether weighted equation returns an appropriate value.
        result = FWPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 1000); //100
        result.expectOk().expectUint(195587000)
        
        // deployer swaps alextoken with usda token
        result = FWPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 200); //20
        result.expectOk().expectList()[0].expectUint(200000000); 
        result.expectOk().expectList()[1].expectUint(39341400); 
        // TODO : Operation illustration

    },
});


Clarinet.test({
    name: "FWP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 50000, 10000); // Internally 1M multiplied
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = FWPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = FWPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY);
        result.expectOk().expectPrincipal(wallet_1.address);

        result = FWPTest.setFeeRateX(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 5000000);
        result.expectOk().expectBool(true);

        result = FWPTest.setFeeRateY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 5000000);
        result.expectOk().expectBool(true);

        result = FWPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 200); //2
        result.expectOk().expectList()[0].expectUint(190000000); 
        result.expectOk().expectList()[1].expectUint(37356800); 


        // // Collect Fees - TO BE IMPLEMENTED AFTER FEE COLLECTOR IMPLEMENTATION
        // result = FWPTest.collectFees(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY);
        // result.expectOk()
    },
});


Clarinet.test({
    name: "FWP : General Error Testing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let wallet_2 =accounts.get('wallet_2')!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Create Pool
        let result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 50000, 10000);
        result.expectOk().expectBool(true);

        // Create Pool Error : pool-already-exists
        result = FWPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 50000, 10000);
        result.expectErr().expectUint(2000);

        // Add to Position : Invalid Pool Access
        result = FWPTest.addToPosition(deployer, ayusdaAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 500000, 100000);
        result.expectErr().expectUint(2001);

        // Add to Liquidity
        result = FWPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 500000, 100000);
        result.expectOk().expectBool(true);

        // Invalid Liquidity - Edge case
        result = FWPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 0, 0);
        result.expectErr().expectUint(2003);

        // Invalid Liquidity for checking assertion of dy, doesnt matter because it passes eqation and outputs new-dy.
        result = FWPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 1, 0);
        result.expectOk();

        // Transfer Error due to lack of balance on sender
        result = FWPTest.addToPosition(wallet_2, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 500000, 100000);
        result.expectErr().expectUint(3001);

        // Math calling error 
        // Used to be math calling error but on the update version of clarinet, it seems like it can find the error of math call, which is percent greater than one.
        result = FWPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 1000000000000);
        result.expectErr().expectUint(5000);

        result = FWPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, gAlexUsdaPoolAddress, 99999);
        result.expectOk();

        // Internal Function call error due to max ratio error in weighted equation.
        result = FWPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 2000000);
        result.expectErr().expectUint(1001);
        
        // Transfer Fails because ft-transfer blocks if the balance is 0
        result = FWPTest.swapYForX(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 0);
        result.expectErr().expectUint(2003);

        // result = FWPTest.swapYFor(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY, 0);
        // result.expectOk().expectUint(2003);

    },
});