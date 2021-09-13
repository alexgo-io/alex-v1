

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const keywbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const ytpyieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
const multisigncrpwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-usda"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const multisigytpyieldwbtc59760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-59760-wbtc"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const ltv_0 = 0.8 * ONE_8
const conversion_ltv = 0.95 * ONE_8
const bs_vol = 0.8 * ONE_8
const moving_average = 0 * ONE_8 // for testing only

const wbtcPrice = 50000
const usdaPrice = 1

const weightX = 0.5 * ONE_8
const weightY = 0.5 * ONE_8

const wbtcQ = 100*ONE_8

/**
 * Yield Token Pool Test Cases  
 * 
 *  TODO: test shortfall case with reserve-pool
 */

Clarinet.test({
    name: "CRP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, wbtcPrice * wbtcQ);
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(wbtcQ * wbtcPrice);


        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100110900);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80717843);

        // Check pool details and print
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(80807360);
        position['key-supply'].expectUint(80807360);
        position['weight-x'].expectUint(66534526);
        position['weight-y'].expectUint(33465474);        
        position['balance-x'].expectUint(3326726300000);
        position['balance-y'].expectUint(33576900);
        position['strike'].expectUint(50000 * ONE_8);
        position['ltv-0'].expectUint(ltv_0);
        position['bs-vol'].expectUint(bs_vol);
        position['conversion-ltv'].expectUint(conversion_ltv);
        position['moving-average'].expectUint(moving_average);

        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(199764);     

        // arbtrageur selling 0.002 wbtc for usda
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.002 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(40109352059);
        position['dy'].expectUint(0.002 * ONE_8);        

        // borrow $5,000 more and convert to wbtc
        // remember, the first sell creates profit to LP
        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 5000 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(8073663);        
        position['dx'].expectUint(8127823);

        // supply increased
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3629288282941);
        position['balance-y'].expectUint(36901635);                
        position['yield-supply'].expectUint(88881023);
        position['key-supply'].expectUint(88881023);      
        
        // pool value increases after adding positions
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109485635);    
        
        call = await CRPTest.getPoolValueInCollateral(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(5474288282941)
        
        // let's check what is the weight to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(33465993);          

        // wbtc (token) falls by 20% vs usda (collateral)
        oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice * 0.8);
        oracleresult.expectOk()

        // move forward by one day
        chain.mineEmptyBlockUntil(144);

        // with wbtc (token) falling, weight to wbtc (token) should decrease
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(25427001);              

        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(201315);         

        // swap triggers weight change
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(25427001);          
        position['weight-x'].expectUint(ONE_8 - 25427001);              
        position['yield-supply'].expectUint(88881023);
        position['key-supply'].expectUint(88881023);   
        
        // simulate to half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)    

        // wbtc rises then by 50%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice * 0.8 * 1.5);
        oracleresult.expectOk();

        // the rise shifts allocation to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(73683600);         
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(294164);       

        // swap triggers weight change - but not too much given moving average
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(73683600);            
        position['weight-x'].expectUint(ONE_8 - 73683600);            
        position['yield-supply'].expectUint(88881023);
        position['key-supply'].expectUint(88881023);  
        
        // simulate to 3 / 4 to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) * 3 / 4)    

        // what if wbtc rises then by another 10%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice * 0.8 * 1.5 * 1.1);
        oracleresult.expectOk();

        // we hold over 60% in usda, so pool value in wbtc goes down
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(91697065);

        // and ltv crossed conversion_ltv
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(96928972);   
        
        // crossing convertion_ltv triggers 100% allocation to collateral
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(99900000);
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(35562);

        // swap triggers weight change - once crossed conversion_ltv, all in token
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(99900000);          
        position['weight-x'].expectUint(ONE_8 - 99900000);              
        position['yield-supply'].expectUint(88881023);
        position['key-supply'].expectUint(88881023);  
        position['balance-x'].expectUint(3659288282941);
        position['balance-y'].expectUint(36370594);                       
        
        // simulate to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // but lender cannot yet redeem
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.5 * ONE_8);
        result.expectErr().expectUint(2017);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)         
        // swap is no longer allowed
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectErr().expectUint(2017);  

        // swap is no longer allowed
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectErr().expectUint(2017);   

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3659288282941);
        position['balance-y'].expectUint(36370594);                
        position['yield-supply'].expectUint(88881023);
        position['key-supply'].expectUint(88881023);     
        
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(91813018);        
        
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(96806558);

        // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(80807360);

        // most of yield-token burnt, but key-token remains
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(9951298);                
        position['yield-supply'].expectUint(8073663);
        position['key-supply'].expectUint(88881023);     

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(9951298);         
        
        call = await CRPTest.getPositionGivenBurnKey(wbtcAddress, usdaAddress, expiry, ONE_8);
        position = call.result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(2112526);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-balance", 
            [types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(88881023);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-total-supply", 
            [], deployer.address);
        call.result.expectOk().expectUint(88881023);  
             
        // also remove all key tokens
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(1877634);     
        
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(8073663);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(8073664);                
    },    
});
