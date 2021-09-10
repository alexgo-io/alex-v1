
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    CRPTestAgent1,
  } from './models/alex-tests-collateral-rebalancing-pool.ts';
  
  import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';

  import {
      YTPTestAgent1,
  } from './models/alex-tests-yield-token-pool.ts'
  
  import { 
    OracleManager,
  } from './models/alex-tests-oracle-mock.ts';
import { 
    YTPTestAgent1 
    } from './models/alex-tests-yield-token-pool.ts';
  
  

// Deployer Address Constants 
 const wbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
<<<<<<< HEAD
 const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-18530"
 const ayUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-yield-usda-4380-usda"
 const ayUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-4380"
 const keyUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc-4380"
 const yieldUsda4380UsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-yield-usda-4380-usda"

=======
 const yieldwbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
 const keywbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
 const ytpyieldwbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
 const fwpwbtcusdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
>>>>>>> hotfix/163

 const ONE_8 = 100000000
 const expiry = 4380 * ONE_8  // 1 month  
 const testWeightX = 50000000 //0.5
 const testWeightY = 50000000 //0.5
 const testbsVol = 50000000

 const testWBTCPrice = 50000*ONE_8
 const testUSDAPrice = ONE_8
/**
 * Collateral Rebalancing Pool Test Cases
 * 
 * 1. Borrower adds Liquidity to the pool : puts collateral and mint ayusda
 *      collateral : usda
 *      ayToken : ayUSDA
 * 
 * 2. Arbitrageurs using collateral rebalancing pool for trading
 * 
 * 3. Set platform fee and collect
 * 
 */

Clarinet.test({
    name: "CRP : Creating Pool and Borrower use case",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let CRPTest = new CRPTestAgent1(chain, deployer);
<<<<<<< HEAD
        let YTPTest = new YTPTestAgent1(chain, deployer);

        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",testWBTCPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",testUSDAPrice);
        oracleresult.expectOk()
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, testWeightX, testWeightY, ayUsdaPoolAddress, 5000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 1000*ONE_8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, ayUsda4380TokenAddress, usdaTokenAddress, yieldUsda4380UsdaPoolAddress, 1000*ONE_8, 1000*ONE_8)
        result.expectOk().expectBool(true);        

        // Initial Balance After Creation of Pool 
        // Rebalancing occurs based on internal logic.
        result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
        let position:any =result.expectOk().expectTuple();
            position['balance-x'].expectUint(52825248000);
            position['balance-y'].expectUint(8621517449);
        
        // Borrower adds liquidity to the pool and mint ayusda and keyusda, using wBTC as collateral
        // If attempt to add more than fixed weight pool has, it will throw an no-liquidity error
        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 0.1*ONE_8);
        position = result.expectOk().expectTuple();
        position['key-token'].expectUint(378600);
        position['yield-token'].expectUint(378600);

        result = CRPTest.addToPositionAndSwitch(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 1000*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(99040322);
        position['dy'].expectUint(122353982);


        // Liquidity Added to the pool
        result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
            position =result.expectOk().expectTuple();
            position['balance-x'].expectUint(58107772800);
            position['balance-y'].expectUint(9402609463);

        // Time machine to maturity
        chain.mineEmptyBlockUntil(4381)

        // Reduce Liquidity
        // Reduce 1% of total yield token. 
        result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
            position=result.expectOk().expectTuple();
            position['dx'].expectUint(2731180208);
            position['dy'].expectUint(0);

        // Manually Reduce 1& of total key token
        result = CRPTest.reducePositionKey(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
            position=result.expectOk().expectTuple();
            position['dx'].expectUint(2684734098);
            position['dy'].expectUint(0);

            // 1 % of each token and collateral has been removed. 
            result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
            position =result.expectOk().expectTuple();
            position['balance-x'].expectUint(57266791292);
            position['balance-y'].expectUint(8651584241);

        // Time machine to maturity
        chain.mineEmptyBlockUntil(4381)

        // Reduce Liquidity
        // Reduce 1% of total yield token. 
        result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
            position=result.expectOk().expectTuple();
            position['dx'].expectUint(238195975);
            position['dy'].expectUint(0);

        // Manually Reduce 1& of total key token
        result = CRPTest.reducePositionKey(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
            position=result.expectOk().expectTuple();
            position['dx'].expectUint(235671181);
            position['dy'].expectUint(0);



    },
});

Clarinet.test({
    name: "CRP : Arbitragers using CRP for commiting Swaps",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",testWBTCPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",testUSDAPrice);
        oracleresult.expectOk()

=======
>>>>>>> hotfix/163
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",testWBTCPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",testUSDAPrice);
        oracleresult.expectOk()

        
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcTokenAddress, usdaTokenAddress, testWeightX, testWeightY, fwpwbtcusdaTokenAddress, 10000*ONE_8, 500000000*ONE_8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, yieldwbtcTokenAddress, wbtcTokenAddress, ytpyieldwbtcTokenAddress, 100*ONE_8, 100*ONE_8);

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, wbtcTokenAddress, usdaTokenAddress, yieldwbtcTokenAddress, keywbtcTokenAddress, 100000*ONE_8);
        result.expectOk().expectBool(true);
        
        result = YTPTest.swapYForX(deployer, yieldwbtcTokenAddress, wbtcTokenAddress, 2*ONE_8);

        let call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtcTokenAddress)
            ], deployer.address);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(98*ONE_8);
        position['balance-aytoken'].expectUint(2*ONE_8);
        position['balance-virtual'].expectUint(100*ONE_8);

        // // Time machine to maturity
        // chain.mineEmptyBlockUntil(4381)

<<<<<<< HEAD
        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        let position:any = result.expectOk().expectTuple();
        position['key-token'].expectUint(378600);
        position['yield-token'].expectUint(378600);
=======
        // // Reduce Liquidity
        // // Reduce 1% of total yield token. 
        // result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        //     position=result.expectOk().expectTuple();
        //     position['dx'].expectUint(238195975);
        //     position['dy'].expectUint(0);
>>>>>>> hotfix/163

        // // Manually Reduce 1& of total key token
        // result = CRPTest.reducePositionKey(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        //     position=result.expectOk().expectTuple();
        //     position['dx'].expectUint(235671181);
        //     position['dy'].expectUint(0);

        //     // 1 % of each token and collateral has been removed. 
        //     result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
        //     position =result.expectOk().expectTuple();
        //     position['balance-x'].expectUint(10480947868);
        //     position['balance-y'].expectUint(1776947086);



    },
});