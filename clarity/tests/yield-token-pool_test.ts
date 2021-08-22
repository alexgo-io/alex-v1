

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    YTPTestAgent1,
  } from './models/alex-tests-yield-token-pool.ts';
  

// Deployer Address Constants 
const wBTCTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-alex-18530"
const ayUsdawBTCPoolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-ayusda-wbtc"
const ayUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-wbtc-4380"
const keyUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc-4380"

const ONE_8 = 100000000
const expiry = 4380 * ONE_8  // 1 month  
const testWeightX = 50000000 //0.5
const testWeightY = 50000000 //0.5
const testbsVol = 50000000

const testWBTCPrice = 40000*ONE_8
const testUSDAPrice = ONE_8
const testExpiry = 4380*ONE_8
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
        let result = YTPTest.createPool(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 10*ONE_8, 10*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(ayUsda4380TokenAddress);
        call.result.expectOk();

        //Add extra liquidity
        result = YTPTest.addToPosition(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 10*ONE_8);
        result.expectOk().expectBool(true);

        // Remove all liquidlity
        result = YTPTest.reducePosition(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 1*ONE_8);
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
        let result = YTPTest.createPool(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 10*ONE_8, 10*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(ayUsda4380TokenAddress);
        call.result.expectOk();

        // Get weight for testing swap - internal test
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(testExpiry)
            ], wallet_1.address);
        call.result.expectOk().expectUint(99999999)
        
        //Error due to prohibitting mining of ayToken
        result = YTPTest.getYgivenX(deployer, ayUsda4380TokenAddress,1000000);
        result.expectErr().expectUint(2016)
        
        // get Yield - internal
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(ayUsda4380TokenAddress)
            ], wallet_1.address);
        call.result.expectOk().expectUint(0)

        // Add additional liquidity
        result = YTPTest.addToPosition(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 100*ONE_8);
        result.expectOk().expectBool(true);

        // //Arbitrager swapping usda for ayusda 
        // result = YTPTest.swapYForX(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, 10*ONE_8);
        // result.expectOk().expectList()[0].expectUint(998844466)
        // result.expectOk().expectList()[1].expectUint(1000000000)
        
        // // Then now the yield is non-zero
        // call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
        // [types.principal(ayusdaAddress)
        // ], wallet_1.address);
        // call.result.expectOk().expectUint(18220598)

        // // Swapping with positive ayToken in the Pool
        // result = YTPTest.swapXForY(deployer, ayusdaAddress, usdaTokenAddress, 100000000);
        // result.expectOk().expectList()[0].expectUint(100000000)
        // result.expectOk().expectList()[1].expectUint(101202707)

    },
});

Clarinet.test({
    name: "YTP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        //Deployer creating a pool, initial tokens injected to the pool
        let result = YTPTest.createPool(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 10*ONE_8, 10*ONE_8);
        result.expectOk().expectBool(true);

    //     // Check pool details and print
    //     let call = await YTPTest.getPoolDetails(ayUsda4380TokenAddress);
    //     call.result.expectOk();
        
    //     // Add additional liquidity
    //     result = YTPTest.addToPosition(deployer, ayUsda4380TokenAddress, wBTCTokenAddress, ayUsdawBTCPoolTokenAddress, 100*ONE_8);
    //     result.expectOk().expectBool(true);

    //     // Fees will be transferred to wallet_1
    //     result = YTPTest.setFeetoAddress(deployer, ayUsda4380TokenAddress, wallet_1.address);
    //     result.expectOk().expectBool(true);
        
    //    // Check whether it is correctly settled
    //     result = YTPTest.getFeetoAddress(deployer, ayUsda4380TokenAddress);
    //     result.expectOk().expectPrincipal(wallet_1.address);

    //     result = YTPTest.setFeeRateToken(deployer, ayUsda4380TokenAddress, 5000000);
    //     result.expectOk().expectBool(true);

    //     result = YTPTest.setFeeRateayToken(deployer, ayUsda4380TokenAddress, 5000000);
    //     result.expectOk().expectBool(true);

        // //Arbitrager swapping usda for ayusda 
        // result = YTPTest.swapYForX(deployer, ayusdaAddress, usdaTokenAddress, 1000000000);
        // result.expectOk().expectList()[0].expectUint(998844466)
        // result.expectOk().expectList()[1].expectUint(1000000000)

        // // Then now the yield is non-zero
        // let call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
        // [types.principal(ayusdaAddress)
        // ], wallet_1.address);
        // call.result.expectOk().expectUint(18220598)

        // // Swapping with positive ayToken in the Pool
        // result = YTPTest.swapXForY(deployer, ayusdaAddress, usdaTokenAddress, 100000000);
        // result.expectOk().expectList()[0].expectUint(99088971)
        // result.expectOk().expectList()[1].expectUint(100291487)

        // // Collect Fees - Fee Collection Floating Point
        // result = YTPTest.collectFees(wallet_1, ayusdaAddress, usdaTokenAddress);
        // result.expectOk().expectList()[0].expectUint(0)
        // result.expectOk().expectList()[1].expectUint(911029)    
    },
});


// Clarinet.test({
//     name: "YTP : General Error Testing",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         let deployer = accounts.get("deployer")!;
//         let wallet_1 =accounts.get('wallet_1')!;
//         let wallet_2 =accounts.get('wallet_2')!;
//         let YTPTest = new YTPTestAgent1(chain, deployer);
        
//         //Deployer creating a pool, initial tokens injected to the pool
//         let result = YTPTest.createPool(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 1000000000, 100000000);
//         result.expectOk().expectBool(true);

//         // Create Pool Error : pool-already-exists
//         result = YTPTest.createPool(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 1000000000, 100000000);
//         result.expectErr().expectUint(2000);

//         // Reduce liquidlity math err - percent overflow
//         result = YTPTest.reducePosition(deployer, ayusdaAddress, usdaTokenAddress, ayUsdaPoolAddress, 100000000000);
//         let position:any =result.expectErr().expectUint(5000);

//         // Trying to mine when ayToken is zero balance
//         result = YTPTest.swapXForY(deployer, ayusdaAddress, usdaTokenAddress, 100000000);
//         result.expectErr().expectUint(1001)

//         //Zero Transfer
//         result = YTPTest.swapYForX(deployer, ayusdaAddress, usdaTokenAddress, 0);
//         result.expectErr().expectUint(1001)


//     },
// });