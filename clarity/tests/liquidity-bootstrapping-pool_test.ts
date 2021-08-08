

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    LBPTestAgent1,
  } from './models/alex-tests-liquidity-bootstrapping-pool.ts';
  

// Deployer Address Constants 
const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-usda-ayusda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"

const testWeightX0 = 50000000 //0.5
const testWeightX1 = 50000000 //0.5
const testExpiry = 100000000


Clarinet.test({
    name: "LBP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let LBPTest = new LBPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = LBPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX0, testWeightX1, testExpiry, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // Check Pool Details
        let call = await LBPTest.getPoolDetails(gAlexTokenAddress, usdaTokenAddress, testExpiry);
        call.result.expectOk();
        
        // Weight Unit Test Check
        call = LBPTest.getWeightX(gAlexTokenAddress, usdaTokenAddress, testExpiry)
        call.result.expectOk().expectUint(50000000);

        // Add extra liquidity - Private Function Checked. Keep this Commented. 
        // result = LBPTest.addtoPosition(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, ayUsdaPoolAddress, 1000000000);
        // result.expectOk().expectBool(true);        
        
        // Additional Block Mining
        let block = chain.mineBlock([]);
        assertEquals(block.height, 3);

        // Reduce liquidlity
        result = LBPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, ayUsdaPoolAddress, 1000000); // 1%
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(9999990);
            position['dy'].expectUint(9999990);
    },
});

Clarinet.test({
    name: "LBP : Swapping Token Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        
        let wallet_1 =accounts.get('wallet_1')!;
        let LBPTest = new LBPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = LBPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX0, testWeightX1, testExpiry, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // check whether weighted equation returns an appropriate value.
        result = LBPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 10000000); //0.1
        result.expectOk().expectUint(985138)
        
        // deployer swaps alextoken with usda token
        result = LBPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 200000000); //20
        result.expectOk().expectList()[0].expectUint(200000000); 
        result.expectOk().expectList()[1].expectUint(16662485); 
       

    },
});


Clarinet.test({
    name: "LBP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let LBPTest = new LBPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = LBPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX0, testWeightX1, testExpiry, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = LBPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = LBPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry);
        result.expectOk().expectPrincipal(wallet_1.address);

        result = LBPTest.setFeeRateX(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 5000000);
        result.expectOk().expectBool(true);

        result = LBPTest.setFeeRateY(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 5000000);
        result.expectOk().expectBool(true);

        result = LBPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 200000000); 
        result.expectOk().expectList()[0].expectUint(190000000); 
        result.expectOk().expectList()[1].expectUint(15962171); 

        result = LBPTest.swapYForX(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 10000000); 
        result.expectOk().expectList()[0].expectUint(151735080); 
        result.expectOk().expectList()[1].expectUint(9500000); 

        // Collect Fees - Fee Collection Floating Point
        result = LBPTest.collectFees(wallet_1, gAlexTokenAddress, usdaTokenAddress, testExpiry);
        result.expectOk().expectList()[0].expectUint(10000000)  
    },
});


Clarinet.test({
    name: "LBP : General Error Testing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let wallet_2 =accounts.get('wallet_2')!;
        let LBPTest = new LBPTestAgent1(chain, deployer);
        
        // Create Pool
        let result = LBPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX0, testWeightX1, testExpiry, ayUsdaPoolAddress, 1000000000, 100000000);
        result.expectOk().expectBool(true);

        // Create Pool Error : pool-already-exists
        let pool = LBPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX0, testWeightX1, testExpiry, ayUsdaPoolAddress, 1000000000, 100000000);
        pool.expectErr().expectUint(2000);


        // Mining Math Error
        result = LBPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, ayUsdaPoolAddress, 100000000000); 
        let position:any =result.expectErr().expectUint(2010)

        // Ratio Over 
        result = LBPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 100000000000); 
        result.expectErr().expectUint(4001)

        // Invalid Pool Error
        result = LBPTest.collectFees(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry+1);
        result.expectErr().expectUint(2001)

        // Not enough balance
        result = LBPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testExpiry, 200000000000); 
        result.expectErr().expectUint(1001)
    },
});