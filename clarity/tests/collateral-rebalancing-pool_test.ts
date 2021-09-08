
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    CRPTestAgent1,
  } from './models/alex-tests-collateral-rebalancing-pool.ts';
  
  import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';
  
  import { 
    OracleManager,
  } from './models/alex-tests-oracle-mock.ts';
import { 
    YTPTestAgent1 
    } from './models/alex-tests-yield-token-pool.ts';
  
  

// Deployer Address Constants 
 const wbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
 const yieldwbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
 const keywbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
 const ytpyieldwbtcTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
 const fwpwbtcusdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"

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
        let CRPTest = new CRPTestAgent1(chain, deployer);
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

        // // Reduce Liquidity
        // // Reduce 1% of total yield token. 
        // result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        //     position=result.expectOk().expectTuple();
        //     position['dx'].expectUint(238195975);
        //     position['dy'].expectUint(0);

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