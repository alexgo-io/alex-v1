

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { MS_CRP_WBTC_USDA_59760} from './models/alex-tests-multisigs.ts';
import { USDAToken,WBTCToken,YIELD_WBTC_59760,KEY_WBTC_59760_USDA } from './models/alex-tests-tokens.ts';

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
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-59760"

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
        let wallet_1 = accounts.get("wallet_1")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);

        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));

        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100089055);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80735461);

        // Check pool details and print
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(80807360);
        position['key-supply'].expectUint(80807360);
        position['weight-x'].expectUint(66534526);
        position['weight-y'].expectUint(ONE_8 - 66534526);        
        position['balance-x'].expectUint(3326726300000);
        position['balance-y'].expectUint(33576900);
        position['strike'].expectUint(50000 * ONE_8);
        position['ltv-0'].expectUint(ltv_0);
        position['bs-vol'].expectUint(bs_vol);
        position['conversion-ltv'].expectUint(conversion_ltv);
        position['moving-average'].expectUint(moving_average);
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(199764); 

        // arbtrageur selling 0.002 wbtc for usda
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.002 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(22079184661);
        position['dy'].expectUint(0.002 * ONE_8);        

        // borrow $5,000 more and convert to wbtc
        // remember, the first sell creates profit to LP
        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 5000 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(8046279);        
        position['dx'].expectUint(8046447);

        // supply increased
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3553041375339);
        position['balance-y'].expectUint(38776120);                
        position['yield-supply'].expectUint(88853639);
        position['key-supply'].expectUint(88853639);      
        
        // pool value increases after adding positions
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109786643);    
        
        call = await CRPTest.getPoolValueInCollateral(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(5493220824349);
        
        // let's check what is the weight to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        call.result.expectOk().expectUint(52411081);                     
        
        // simulate to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // but lender cannot yet redeem
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.5 * ONE_8);
        result.expectErr().expectUint(2017);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)  
        
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109786643); 

        // take away what was minted for testing to another address
        let block = chain.mineBlock([
            Tx.contractCall("yield-wbtc-59760", "transfer", [
              types.uint(2000000000000),
              types.principal(deployer.address),
              types.principal(wallet_1.address),
              types.some(types.buff(new ArrayBuffer(10)))
            ], deployer.address),
          ]);
        block.receipts[0].result.expectOk(); 

        // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(80807360);

        // most of yield-token burnt, but key-token remains
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(9942230);                
        position['yield-supply'].expectUint(8046279);
        position['key-supply'].expectUint(88853639);
             
        // also remove all key tokens
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(1895950);     
        
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(8046279);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(8046280);                
    },    
});

Clarinet.test({
    name: "CRP : trait check",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);        

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        // non-deployer creating a pool will throw an error
        result = CRPTest.createPool(wallet_1, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectErr().expectUint(1000);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);     
        
        // supplying a wrong pool-token throws an error
        result = CRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, usdaAddress, wrongPooltokenAddress, keywbtc59760Address, 5000 * ONE_8);
        result.expectErr().expectUint(2023);   
        
        // same for key-token
        result = CRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, usdaAddress, yieldwbtc59760Address, wrongPooltokenAddress, 5000 * ONE_8);
        result.expectErr().expectUint(2023);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)

        // supplying a wrong pool-token throws an error
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2023);
        // same for key-token
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2023);

        // take away what was minted for testing to another address
        let block = chain.mineBlock([
            Tx.contractCall("yield-wbtc-59760", "transfer", [
              types.uint(2000000000000),
              types.principal(deployer.address),
              types.principal(wallet_1.address),
              types.some(types.buff(new ArrayBuffer(10)))
            ], deployer.address),
          ]);
        block.receipts[0].result.expectOk(); 
                
        // remove all liquidity
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        result.expectOk();        
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        result.expectOk();          
    }
});

Clarinet.test({
    name: "CRP : multiple CRP pools created",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
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

        result = YTPTest.createPool(deployer, yieldwbtc79760Address, wbtcAddress, ytpyieldwbtc79760Address, multisigytpyieldwbtc79760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc79760Address, keywbtc79760Address, multisigncrpwbtc79760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);      
        
        
    },    
});

Clarinet.test({
    name: "CRP : testing get-x-given-price and get-y-given-price",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
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
        call.result.expectOk().expectUint(100089055);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80735461);

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

        call = await CRPTest.getXgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(111379129197);
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 111379129197, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(111379129197);
        position['dy'].expectUint(2127973);
        
        call = await CRPTest.getYgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 * 0.98/ ONE_8)));
        call.result.expectOk().expectUint(666732);
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 1223378, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(72310370911);
        position['dy'].expectUint(1223378);   
    },    
});  

Clarinet.test({
    name: "CRP : testing pegged CRP (= yield-token collateralised by token)",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);

        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);              

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ, wbtcQ);        
        result.expectOk().expectBool(true);        

        // sell some yield-token to create a positive yield
        result = YTPTest.swapYForX(deployer, yieldwbtc59760Address, wbtcAddress, 5*ONE_8, 0);
        let position:any = result.expectOk().expectTuple();
        
        let call = await YTPTest.getPrice(yieldwbtc59760Address);
        call.result.expectOk().expectUint(100071157);        

        let ltv_00 = Math.round(ONE_8 * ONE_8 / 109095981);
        let conversion_ltv_0 = 0.98e+8;
        let bs_vol_0 = 0.1e+8;
        let collateral = ONE_8;
        let moving_average_0 = 0.95e+8
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, wbtcAddress, yieldwbtc59760Address, keywbtc59760wbtcAddress, multisigncrpwbtc59760wbtcAddress, ltv_00, conversion_ltv_0, bs_vol_0, moving_average_0, collateral);
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
        position['weight-x'].expectUint(52269439);
        position['weight-y'].expectUint(ONE_8 - 52269439);        
        position['balance-x'].expectUint(52269439);
        position['balance-y'].expectUint(ONE_8 - 52269439);
        position['strike'].expectUint(ONE_8);
        position['ltv-0'].expectUint(ltv_00);
        position['bs-vol'].expectUint(bs_vol_0);
        position['conversion-ltv'].expectUint(conversion_ltv_0);
        position['moving-average'].expectUint(moving_average_0);

        // pegged CRP throws error if someone tries to swap
        call = await CRPTest.getXgivenPrice(wbtcAddress, wbtcAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(9516811587);
        result = CRPTest.swapXForY(deployer, wbtcAddress, wbtcAddress, expiry, 9516811587, 0);
        position = result.expectErr().expectUint(2001);
    },    
});        


Clarinet.test({
    name: "CRP : error testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 0);
        result.expectErr().expectUint(2003)

        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, ONE_8 * ONE_8);
        result.expectErr().expectUint(4002)

        // arbtrageur attepmts to swap zero value
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 0, 0);
        result.expectErr().expectUint(2003)

        // arbtrageur attepmts to swap in full value
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, ONE_8 * ONE_8, 0);
        result.expectErr().expectUint(4001) 

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)    
        
        // arbtrageur attepmts to retreive back with zero value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0);        
        result.expectErr().expectUint(3000) 

        // arbitrageur attempts to retreuve back with small value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.001 * ONE_8);        
        result.expectOk().expectTuple();

        // arbtrageur attepmts to retreive back with full value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 101*ONE_8);        
        result.expectErr().expectUint(5000) 
    },    
});        

Clarinet.test({
    name: 'CRP : testing get-x-given-y and get-y-given-x',
    async fn (chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);        

        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, expiry, ONE_8);
        result.expectOk().expectUint(2003);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, expiry, 0);
        result.expectOk().expectUint(0);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, 0, ONE_8);
        result.expectErr().expectUint(2001);

        result = await CRPTest.getXgivenY(deployer, wbtcAddress, usdaAddress, expiry, 500);
        result.expectOk().expectUint(24684357);

        result = await CRPTest.getXgivenY(deployer, wbtcAddress, usdaAddress, expiry, 0);
        result.expectOk().expectUint(0);

        result = await CRPTest.getXgivenY(deployer, wbtcAddress, usdaAddress, 0, 500);
        result.expectErr().expectUint(2001)
    }
})


Clarinet.test({
    name: "CRP : fee setting using multisig",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let contractOwner = deployer;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let MultiSigTest = new MS_CRP_WBTC_USDA_59760(chain, deployer);
        let YieldToken = new YIELD_WBTC_59760(chain, deployer);
        let KeyToken = new KEY_WBTC_59760_USDA(chain, deployer);
        const feeRateX = 0.1*ONE_8; // 10%
        const feeRateY = 0.1*ONE_8;
        const feeRebate = 0.5*ONE_8;
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
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

        let ROresult:any = YieldToken.totalSupply()
        ROresult.result.expectOk().expectUint(2000080807360);

        // take away what was minted for testing to another address
        let block = chain.mineBlock([
            Tx.contractCall("yield-wbtc-59760", "transfer", [
              types.uint(2000000000000),
              types.principal(deployer.address),
              types.principal(wallet_1.address),
              types.some(types.buff(new ArrayBuffer(10)))
            ], deployer.address),
          ]);
        block.receipts[0].result.expectOk(); 

        ROresult = YieldToken.balanceOf(deployer.address)
        ROresult.result.expectOk().expectUint(80807360);

        ROresult = KeyToken.totalSupply()
        ROresult.result.expectOk().expectUint(80807360);
        ROresult = KeyToken.balanceOf(deployer.address)
        ROresult.result.expectOk().expectUint(80807360);

        // Fee rate Setting Proposal of Multisig
        result = MultiSigTest.propose(wallet_1,1000, " Fee Rate Setting to 10%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Block 1000 mining
        chain.mineEmptyBlock(1000);
        
        // deployer and wallet_1 votes for 90 % of his token
        result = MultiSigTest.voteFor(wallet_1, yieldwbtc59760Address, 1, 2000000000000 * 9 / 10 )
        result.expectOk().expectUint(1800000000000)

        result = MultiSigTest.voteFor(deployer, yieldwbtc59760Address, 1, 80807360 * 9 / 10 )
        result.expectOk().expectUint(72726624)

        // Block 1440 mining for ending proposal
        chain.mineEmptyBlock(1440);
        
        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true) // Success 

        result = CRPTest.setFeeRebate(contractOwner, wbtcAddress, usdaAddress, expiry, feeRebate)
        result.expectOk().expectBool(true) // Success 

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3326726300000);
        position['balance-y'].expectUint(33576900);                
        position['yield-supply'].expectUint(80807360);
        position['key-supply'].expectUint(80807360);  
        position['fee-rate-x'].expectUint(0.1*ONE_8);  
        position['fee-rate-y'].expectUint(0.1*ONE_8);
        position['fee-rebate'].expectUint(0.5*ONE_8);      
        
        // Swap
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(90 * ONE_8);  // 10% of fee charged
        position['dy'].expectUint(179869);         

        // fee : 10 * ONE_8 
        // fee-rebate : 0.5 * ONE_8
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3336226300000);    // 3326726300000 + 0.95 * 100* ONE_8
        position['balance-y'].expectUint(33397031); 

        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.001 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(9866889282);
        position['dy'].expectUint(0.0009 * ONE_8);    

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3326359410718);  
        position['balance-y'].expectUint(33492031); // 33397031 + 0.95 * 0.001* ONE_8
    }
})