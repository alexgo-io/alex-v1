
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
  
  

// Deployer Address Constants 
 const wBTCTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
 const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-18530"
 const ayUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-yield-usda-4380-usda"
 const ayUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-4380"
 const keyUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc-4380"
 const yieldUsda4380UsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-yield-usda-4380-usda"


 const ONE_8 = 100000000
 const expiry = 4380 * ONE_8  // 1 month  
 const testWeightX = 50000000 //0.5
 const testWeightY = 50000000 //0.5
 const testbsVol = 50000000

 const testWBTCPrice = 40000*ONE_8
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
<<<<<<< HEAD
            position['balance-x'].expectUint(52825248000);
            position['balance-y'].expectUint(8621517449);
=======
            position['balance-x'].expectUint(4717475200);
            position['balance-y'].expectUint(1045463537);
>>>>>>> 5e3a5f6 (working..)
        
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

<<<<<<< HEAD

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
=======
        // // Liquidity Added to the pool
        // result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
        //     position =result.expectOk().expectTuple();
        //     position['balance-x'].expectUint(9434950600);
        //     position['balance-y'].expectUint(2069294167);

        // // Time machine to maturity
        // chain.mineEmptyBlockUntil(4381)

        // // Reduce Liquidity
        // // Reduce 1% of total yield token. 
        // result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        //     position=result.expectOk().expectTuple();
        //     position['dx'].expectUint(258137417);
        //     position['dy'].expectUint(0);

        // // Manually Reduce 1& of total key token
        // result = CRPTest.reducePositionKey(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        //     position=result.expectOk().expectTuple();
        //     position['dx'].expectUint(255368272);
        //     position['dy'].expectUint(0);

        //     // 1 % of each token and collateral has been removed. 
        //     result = CRPTest.getBalances(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
        //     position =result.expectOk().expectTuple();
        //     position['balance-x'].expectUint(9359844452);
        //     position['balance-y'].expectUint(1985191962);
>>>>>>> 5e3a5f6 (working..)



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

        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a FWP pool
        let result = FWPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, testWeightX, testWeightY, ayUsdaPoolAddress, 5000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        result.expectOk().expectBool(true);

        
        // Get weight for testing swap - internal test
        let call = chain.callReadOnlyFn("collateral-rebalancing-pool", "get-weight-x", 
            [types.principal(usdaTokenAddress),
            types.principal(wBTCTokenAddress),
            types.uint(expiry),
            types.uint(5000),
            types.uint(testbsVol)
            ], wallet_1.address);
        call.result.expectOk().expectUint(42784)
        
        // Check whether internal weighted equation is working well - internal test
        result = CRPTest.getYgivenX(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 10*ONE_8);
        result.expectOk().expectUint(164926218)
        
        // Arbitrager swapping usda for wBTC
        result = CRPTest.swapXForY(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 10*ONE_8);
        let position:any =result.expectOk().expectTuple();
          position['dx'].expectUint(10*ONE_8);
          position['dy'].expectUint(164926218);

    },
});

Clarinet.test({
    name: "CRP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",testWBTCPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",testUSDAPrice);
        oracleresult.expectOk()

        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a FWP pool
        let result = FWPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, testWeightX, testWeightY, ayUsdaPoolAddress, 5000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = CRPTest.setFeetoAddress(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, wallet_1.address);
        result.expectOk().expectBool(true);

        // Set X fee rate to 5%
        result = CRPTest.setFeeRateX(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 5000000); // 0.05 
        result.expectOk().expectBool(true);

        // Set Y fee rate to 5%
        result = CRPTest.setFeeRateY(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 5000000); // 0.05
        result.expectOk().expectBool(true);  
        
        // Swapping actions
        result = CRPTest.swapXForY(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 10*ONE_8);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(950000000); // 5% Removed

       //Check whether it is correctly collected
        result = CRPTest.collectFees(deployer, usdaTokenAddress, wBTCTokenAddress, expiry);
        position =result.expectOk().expectTuple();
        position['fee-x'].expectUint(50000000);
        position['fee-y'].expectUint(0);
        
    },
});

Clarinet.test({
    name: "CRP : General Error Testing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let wallet_2 =accounts.get('wallet_2')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);

        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",40000*ONE_8);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",ONE_8);
        oracleresult.expectOk()

        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, testWeightX, testWeightY, ayUsdaPoolAddress, 5000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        result.expectOk().expectBool(true);

        // Existing Pool
        result = CRPTest.createPool(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        result.expectErr().expectUint(2000);

        // Invalid Pool Access
        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayusdaAddress, keyUsda4380TokenAddress, 100*ONE_8);
        result.expectErr().expectUint(2001);

        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 100*ONE_8);
        let position:any = result.expectOk().expectTuple();
        position['key-token'].expectUint(378600);
        position['yield-token'].expectUint(378600);

        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 0);
        result.expectErr().expectUint(2003);

        // Minimum value is regarded as zero, which throws an error. 
        result = CRPTest.addToPosition(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, keyUsda4380TokenAddress, 1);
        result.expectErr().expectUint(2002);

        // Attempt to reduce liquidity before expiry
        result = CRPTest.reducePositionYield(deployer, usdaTokenAddress, wBTCTokenAddress, ayUsda4380TokenAddress, 1000000);
        result.expectErr().expectUint(1001);

        // Attempt to swap zero value
        result = CRPTest.swapXForY(deployer, usdaTokenAddress, wBTCTokenAddress, expiry, 0);
        result.expectErr().expectUint(2003);


        
    },
});