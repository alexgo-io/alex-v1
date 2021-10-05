

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const keywbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
const ytpyieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
const multisigncrpwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-usda"
const multisigytpyieldwbtc59760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-59760-wbtc"
const yieldwbtc79760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-79760"
const keywbtc79760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-79760-usda"
const ytpyieldwbtc79760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-79760-wbtc"
const multisigncrpwbtc79760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-79760-usda"
const multisigytpyieldwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-79760-wbtc"
const vaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
const reserveAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-reserve-pool"
const keywbtc59760wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-wbtc"
const multisigncrpwbtc59760wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-wbtc"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const expiry79760 = 79760 * ONE_8
const ltv_0 = 0.8 * ONE_8
const conversion_ltv = 0.95 * ONE_8
const bs_vol = 0.8 * ONE_8
const moving_average = 0 * ONE_8 // for testing only

const wbtcPrice = 50000*ONE_8
const usdaPrice = 1*ONE_8

const weightX = 0.5 * ONE_8
const weightY = 0.5 * ONE_8

const wbtcQ = 100*ONE_8

/**
 * Collateral Rebalancing Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "CRP : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice);
        oracleresult.expectOk()
        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100111426);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80717419);

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
        position['dx'].expectUint(22007078006);
        position['dy'].expectUint(0.002 * ONE_8);        

        // borrow $5,000 more and convert to wbtc
        // remember, the first sell creates profit to LP
        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 5000 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(8044367);        
        position['dx'].expectUint(8044549);

        // supply increased
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3575918101994);
        position['balance-y'].expectUint(38322648);                
        position['yield-supply'].expectUint(88851727);
        position['key-supply'].expectUint(88851727);      
        
        // pool value increases after adding positions
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109841010);    
        
        call = await CRPTest.getPoolValueInCollateral(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(5492050501994)
        
        // let's check what is the weight to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(47760285);          

        // wbtc (token) falls by 20% vs usda (collateral)
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko", Math.round(wbtcPrice * 0.8));
        oracleresult.expectOk()

        // move forward by one day
        chain.mineEmptyBlockUntil(144);

        // with wbtc (token) falling, weight to wbtc (token) should decrease
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(10056633);              

        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(116875);         

        // swap triggers weight change
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(10056633);          
        position['weight-x'].expectUint(ONE_8 - 10056633);              
        position['yield-supply'].expectUint(88851727);
        position['key-supply'].expectUint(88851727);   
        
        // simulate to half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)    

        // wbtc rises then by 50%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice * 0.8 * 1.5);
        oracleresult.expectOk();      

        // the rise shifts allocation to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(92358839);         
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(939812);       

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(92358839);            
        position['weight-x'].expectUint(ONE_8 - 92358839);            
        position['yield-supply'].expectUint(88851727);
        position['key-supply'].expectUint(88851727);  
        
        // simulate to 3 / 4 to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) * 3 / 4)    

        // what if wbtc rises then by another 10%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko", Math.round(wbtcPrice * 0.8 * 1.5 * 1.1));
        oracleresult.expectOk();

        // we hold over 60% in usda, so pool value in wbtc goes down
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(91749568);

        // and ltv crossed conversion_ltv
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(96841575);   
        
        // crossing convertion_ltv triggers 100% allocation to collateral
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(99900000);
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(8558);

        // swap triggers weight change - once crossed conversion_ltv, all in token
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-y'].expectUint(99900000);          
        position['weight-x'].expectUint(ONE_8 - 99900000);              
        position['yield-supply'].expectUint(88851727);
        position['key-supply'].expectUint(88851727);  
        position['balance-x'].expectUint(3605918101994);
        position['balance-y'].expectUint(37257403);                       
        
        // simulate to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // but lender cannot yet redeem
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.5 * ONE_8);
        result.expectErr().expectUint(2017);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)         
        // // swap is no longer allowed
        // result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        // position = result.expectErr().expectUint(2017);  

        // // swap is no longer allowed
        // result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8);
        // position = result.expectErr().expectUint(2017);   

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3605918101994);
        position['balance-y'].expectUint(37257403);                
        position['yield-supply'].expectUint(88851727);
        position['key-supply'].expectUint(88851727);     
        
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(91892525);        
        
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(96690919);

        // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(80807360);

        // most of yield-token burnt, but key-token remains
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(9899567);                
        position['yield-supply'].expectUint(8044367);
        position['key-supply'].expectUint(88851727);     

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(9899567);         
        
        call = await CRPTest.getPositionGivenBurnKey(wbtcAddress, usdaAddress, expiry, ONE_8);
        position = call.result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(2087972);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-balance", 
            [types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(88851727);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-total-supply", 
            [], deployer.address);
        call.result.expectOk().expectUint(88851727);  
             
        // also remove all key tokens
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(1855199);     
        
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(8044367);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(8044368);                
    },    
});

Clarinet.test({
    name: "CRP : multiple CRP pools created",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        // simulate to half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)    

        // wbtc rises then by 50%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko", Math.round(wbtcPrice * 0.8 * 1.5));
        oracleresult.expectOk();

        result = YTPTest.createPool(deployer, yieldwbtc79760Address, wbtcAddress, ytpyieldwbtc79760Address, multisigytpyieldwbtc79760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc79760Address, keywbtc79760Address, multisigncrpwbtc79760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);          
    },    
});

Clarinet.test({
    name: "CRP : working with reserve pool",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_3 = accounts.get("wallet_3")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcQ*wbtcPrice/ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ*wbtcPrice/ONE_8));

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 4000 * ONE_8);
        result.expectOk().expectBool(true);

        let block = chain.mineBlock([
                Tx.contractCall("token-usda", "transfer", [
                  types.uint(2000e+8),
                  types.principal(deployer.address),
                  types.principal(wallet_3.address),
                  types.some(types.buff(new ArrayBuffer(10)))
                ], deployer.address),
              ]);
        block.receipts[0].result.expectOk();        

        call = await CRPTest.getBalance("token-usda", wallet_3.address);
        call.result.expectOk().expectUint(200000000000)

        result = CRPTest.addToPosition(wallet_3, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 1000 * ONE_8);
        result.expectOk().expectTuple();

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(9998773); 

        // wbtc (token) rises by 50% vs usda (collateral)
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice * 1.5);
        oracleresult.expectOk()    
        
        call = await Oracle.getPrice("coingecko", "WBTC");
        call.result.expectOk().expectUint(wbtcPrice * 1.5);

        // now pool price still implies $50,000 per wbtc
        call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(9996654679);
        position['balance-y'].expectUint(500167327370000);         
        
        // let's do some arb
        call = await FWPTest.getYgivenPrice(wbtcAddress, usdaAddress, weightX, weightY, Math.round(wbtcPrice * 1.25));
        call.result.expectOk().expectUint(52654365137886);         
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 52654365137886)      
        call = await FWPTest.getYgivenPrice(wbtcAddress, usdaAddress, weightX, weightY, Math.round(wbtcPrice * 1.25 * 1.2));
        call.result.expectOk().expectUint(47460820304103);         
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 47460820304103)                           

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)    
        
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(7780956);        
        
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(102872667);

        call = await CRPTest.getBalance("token-usda", reserveAddress);
        call.result.expectOk().expectUint(10000000000000)

        // let's burn some yield token
        result = CRPTest.reducePositionYield(wallet_3, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(1599997);

        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(6404480);        

        // ltv > 100%, so we dip into reserve pool
        // you see reserve balance decreases
        call = await CRPTest.getBalance("token-usda", reserveAddress);
        call.result.expectOk().expectUint(9982919000000)

        // most of yield-token burnt, but key-token remains
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(0);                
        position['yield-supply'].expectUint(0);
        position['key-supply'].expectUint(8004477);     

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(0);         
        
        call = await CRPTest.getPositionGivenBurnKey(wbtcAddress, usdaAddress, expiry, ONE_8);
        position = call.result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(0);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-balance", 
            [types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(6404480);

        call = chain.callReadOnlyFn("key-wbtc-59760-usda", "get-total-supply", 
            [], deployer.address);
        call.result.expectOk().expectUint(8004477);  
             
        // also remove all key tokens
        result = CRPTest.reducePositionKey(wallet_3, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(0);     

        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(0);          
        
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(0);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(0);                
    },    
});

Clarinet.test({
    name: "CRP : testing get-x-given-price and get-y-given-price",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice);
        oracleresult.expectOk()
        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        let moving_average_0 = 0.95e+8
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average_0, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100111426);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80717419);

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
        position['moving-average'].expectUint(moving_average_0);

        // WBTC rises by 10%
        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice * 1.1);
        oracleresult.expectOk()
        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()

        call = await CRPTest.getXgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(111379129197);
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 111379129197);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(111379129197);
        position['dy'].expectUint(2127973);

        oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice * 1.1 * 0.98);
        oracleresult.expectOk()
        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()  
        
        call = await CRPTest.getYgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 * 0.98/ ONE_8)));
        call.result.expectOk().expectUint(1223378);
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 1223378);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(256645012356);
        position['dy'].expectUint(1223378);   
    },    
});  

Clarinet.test({
    name: "CRP : testing pegged CRP (= yield-token collateralised by token)",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC", "coingecko", wbtcPrice);
        oracleresult.expectOk()

        let result = YTPTest.createPool(wallet_1, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ, wbtcQ);        
        result.expectOk().expectBool(true);

        // sell some yield-token to create a positive yield
        result = YTPTest.swapYForX(wallet_1, yieldwbtc59760Address, wbtcAddress, 5*ONE_8);
        let position:any = result.expectOk().expectTuple();
        
        let call = await YTPTest.getPrice(yieldwbtc59760Address);
        call.result.expectOk().expectUint(100071160);        

        let ltv_00 = Math.round(ONE_8 * ONE_8 / 109095981);
        let conversion_ltv_0 = 0.98e+8;
        let bs_vol_0 = 0.1e+8;
        let collateral = ONE_8;
        let moving_average_0 = 0.95e+8
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(wallet_1, wbtcAddress, wbtcAddress, yieldwbtc59760Address, keywbtc59760wbtcAddress, multisigncrpwbtc59760wbtcAddress, ltv_00, conversion_ltv_0, bs_vol_0, moving_average_0, collateral);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(ONE_8);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(ltv_00);

        // Check pool details and print
        call = await CRPTest.getPoolDetails(wbtcAddress, wbtcAddress, expiry);
        position = call.result.expectOk().expectTuple(); 
        position['yield-supply'].expectUint(91662405); //about 1 / 1.09
        position['key-supply'].expectUint(91662405);
        position['weight-x'].expectUint(52269481);
        position['weight-y'].expectUint(ONE_8 - 52269481);        
        position['balance-x'].expectUint(52269481);
        position['balance-y'].expectUint(ONE_8 - 52269481);
        position['strike'].expectUint(ONE_8);
        position['ltv-0'].expectUint(ltv_00);
        position['bs-vol'].expectUint(bs_vol_0);
        position['conversion-ltv'].expectUint(conversion_ltv_0);
        position['moving-average'].expectUint(moving_average_0);

        // WBTC rises by 10%
        oracleresult = Oracle.updatePrice(deployer,"WBTC", "coingecko", wbtcPrice * 1.1);
        oracleresult.expectOk()

        // pegged CRP throws error if someone tries to swap
        call = await CRPTest.getXgivenPrice(wbtcAddress, wbtcAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(9516775442);
        result = CRPTest.swapXForY(wallet_1, wbtcAddress, wbtcAddress, expiry, 9516775442);
        position = result.expectErr().expectUint(2001);
    },    
});        


Clarinet.test({
    name: "CRP : Error Testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","coingecko",wbtcPrice);
        oracleresult.expectOk()
        oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100111426);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80717419);

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


        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 0);
        position = result.expectErr().expectUint(2003)

        // TODO : Bug  - If the balance is below 1 usd, error occurs. 
        // result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 0.1 * ONE_8);
        // position = result.expectOk().expectTuple();

        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, ONE_8 * ONE_8);
        position = result.expectErr().expectUint(4002)

        // arbtrageur attepmts to swap zero value
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 0);
        position = result.expectErr().expectUint(2003)

        // arbtrageur attepmts to swap small value
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 0.1* ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0.1* ONE_8);
        position['dy'].expectUint(198);

        // arbtrageur attepmts to swap in full value
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, ONE_8 * ONE_8);
        position = result.expectErr().expectUint(4001)
        
        // arbtrageur attepmts to swap zero value
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0);
        position = result.expectErr().expectUint(2003)  

        // arbtrageur attepmts to swap small value
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.000001 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(10545754);
        position['dy'].expectUint(0.000001 * ONE_8);

        // arbtrageur attepmts to swap in full value
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, ONE_8 * ONE_8);
        position = result.expectErr().expectUint(4002)  

        // arbtrageur selling 0.01 wbtc for usda
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.01 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(111855897259);
        position['dy'].expectUint(0.01 * ONE_8);     

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)    
        
        // arbtrageur attepmts to retreive back with zero value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0);        
        position = result.expectErr().expectUint(3000) 

        // arbitrageur attempts to retreuve back with small value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.001 * ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(80807); 

        // arbtrageur attepmts to retreive back with full value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 101*ONE_8);        
        position = result.expectErr().expectUint(5000) 
    },    
});        
