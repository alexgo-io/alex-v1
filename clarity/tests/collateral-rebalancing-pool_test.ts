

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { MS_CRP_WBTC_USDA } from './models/alex-tests-multisigs.ts';
import { USDAToken, WBTCToken, WSTXToken, YIELD_WBTC, KEY_WBTC_USDA } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50"
const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50"
const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50"
const yieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc"
const keywbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-usda"
const ytpyieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc"
const multisigncrpwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-usda"
const multisigytpyieldwbtc = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc"
const keywbtcwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-wbtc"
const multisigncrpwbtcwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-wbtc"
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
// conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const expiry79760 = 79760 * ONE_8
const ltv_0 = 0.8 * ONE_8
const conversion_ltv = 0.95 * ONE_8
const bs_vol = 0.8 * ONE_8
const moving_average = 0 * ONE_8 // for testing only
const token_to_maturity = 1 * ONE_8 // for testing only

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
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        // result = wstxToken.mintFixed(wallet_1, wallet_1.address, 200000 * ONE_8);
        // result.expectOk();  
        chain.mineEmptyBlock(2);

        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
    
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);

        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);          

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let call = await CRPTest.getSpot(wbtcAddress, usdaAddress);
        call.result.expectOk();
        
        let spot = Number((call.result.replace(/\D/g, "")));
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(99928977);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80055898);

        // Check pool details and print
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(79999040);
        position['key-supply'].expectUint(79999040);
        position['weight-x'].expectUint(66533020);
        position['weight-y'].expectUint(ONE_8 - 66533020);        
        position['balance-x'].expectUint(3326651000000);
        position['balance-y'].expectUint(33465520);
        position['strike'].expectUint(50000 * ONE_8);
        position['ltv-0'].expectUint(ltv_0);
        position['bs-vol'].expectUint(bs_vol);
        position['conversion-ltv'].expectUint(conversion_ltv);
        position['moving-average'].expectUint(moving_average);
        
        // arbtrageur selling 100 usda for wbtc
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(199093); 

        // arbtrageur selling 0.002 wbtc for usda
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.002 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(22269275905);
        position['dy'].expectUint(0.002 * ONE_8);        

        // borrow $5,000 more and convert to wbtc
        // remember, the first sell creates profit to LP
        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 5000 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(7890937);
        position['dx'].expectUint(7891094);

        // supply increased
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3552123214095);
        position['balance-y'].expectUint(38623324);
        position['yield-supply'].expectUint(87889977);
        position['key-supply'].expectUint(87889977)

        // pool value increases after adding positions
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109514119);
        
        call = await CRPTest.getPoolValueInCollateral(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(5487421094631);
        
        // let's check what is the weight to wbtc (token)
        call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(52716714);                     
        
        // simulate to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // but lender cannot yet redeem
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, 0.5 * ONE_8);
        result.expectErr().expectUint(2017);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)  
        
        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109514119)

        // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(79999040);

        // most of yield-token burnt, but key-token remains
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(28308470);
        position['yield-supply'].expectUint(7890937);
        position['key-supply'].expectUint(87889977);
    
        // also remove all key tokens
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, expiry, keywbtcAddress, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(20417533)
        
        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(7890937);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(7890937);                
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
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        // result = wstxToken.mintFixed(wallet_1, wallet_1.address, 200000 * ONE_8);
        // result.expectOk();        
        chain.mineEmptyBlock(2);
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);         

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        // non-deployer creating a pool will throw an error
        result = CRPTest.createPool(wallet_1, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectErr().expectUint(1000);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);     
        
        // supplying a wrong pool-token throws an error
        result = CRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, usdaAddress, expiry, wrongPooltokenAddress, keywbtcAddress, 5000 * ONE_8);
        result.expectErr().expectUint(2026);   
        
        // same for key-token
        result = CRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, wrongPooltokenAddress, 5000 * ONE_8);
        result.expectErr().expectUint(2026);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)

        // supplying a wrong pool-token throws an error
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2026);
        // same for key-token
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, expiry, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2026);
                
        // remove all liquidity
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, ONE_8);        
        result.expectOk();        
        result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, expiry, keywbtcAddress, ONE_8);        
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
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        chain.mineEmptyBlock(1);
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);          

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        // simulate to half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)

        result = YTPTest.createPool(deployer, expiry79760, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry79760, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
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
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk(); 
        chain.mineEmptyBlock(1);    
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        let moving_average_0 = 0.95e+8
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average_0, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let call = await CRPTest.getSpot(wbtcAddress,usdaAddress)
        call.result.expectOk();
        let spot = Number((call.result.replace(/\D/g, "")));

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(99929048);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80055841);

        call = await CRPTest.getXgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(107361307607);
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 107361307607, 0);
        let position:any = result.expectOk().expectTuple();
        position['dx'].expectUint(107361307607);
        position['dy'].expectUint(2047874);
        
        call = await CRPTest.getYgivenPrice(wbtcAddress, usdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 * 0.98/ ONE_8)));
        call.result.expectOk().expectUint(666208);
        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 666208, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(38841132995);
        position['dy'].expectUint(666208);   
    },    
});  

Clarinet.test({
    name: "CRP : testing pegged CRP (= yield-token collateralised by token)",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);  
        chain.mineEmptyBlock(1);

        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);              

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ, wbtcQ);        
        result.expectOk().expectBool(true);        

        // sell some yield-token to create a positive yield
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 5*ONE_8, 0);
        let position:any = result.expectOk().expectTuple();
        
        let call = await YTPTest.getPrice(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(100071149);        

        let ltv_00 = 0.8e+8;
        let conversion_ltv_0 = 0.98e+8;
        let bs_vol_0 = 0.1e+8;
        let collateral = ONE_8;
        let moving_average_0 = 0.95e+8

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, wbtcAddress, expiry, yieldwbtcAddress, keywbtcwbtcAddress, multisigncrpwbtcwbtcAddress, ltv_00, conversion_ltv_0, bs_vol_0, moving_average_0, token_to_maturity, collateral);
        result.expectOk().expectBool(true);

        call = await CRPTest.getSpot(wbtcAddress,usdaAddress)
        call.result.expectOk();
        let spot = Number((call.result.replace(/\D/g, "")));

        call = await CRPTest.getPoolValueInToken(wbtcAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(collateral);
        
        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(ltv_00);

        // pegged CRP throws error if someone tries to swap
        call = await CRPTest.getXgivenPrice(wbtcAddress, wbtcAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(9657868729);
        result = CRPTest.swapXForY(deployer, wbtcAddress, wbtcAddress, expiry, 9657868729, 0);
        position = result.expectErr().expectUint(2001);
    },    
});        

Clarinet.test({
    name: "CRP : ERR-POOL-AT-CAPACITY attempt to add position to exceed MAX_IN/OUT_RATIO of fixed-weight-pool throws error",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);  
        chain.mineEmptyBlock(1);
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);      

        let ltv_0_0 = 0.5 * ONE_8;
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 0.2 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);

        // attempt to add position to exceed MAX_IN/OUT_RATIO of fixed-weight-pool throws error
        result = CRPTest.addToPosition(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 0.11 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectErr().expectUint(2027);
    },    
});

Clarinet.test({
    name: "CRP : error testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();  
        chain.mineEmptyBlock(1);   
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);    

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 0);
        result.expectErr().expectUint(2003)

        result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, ONE_8 * ONE_8);
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
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, 0);        
        result.expectErr().expectUint(3000) 

        // arbitrageur attempts to retreuve back with small value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, 0.001 * ONE_8);        
        result.expectOk().expectTuple();

        // arbtrageur attepmts to retreive back with full value
        result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, 101*ONE_8);        
        result.expectErr().expectUint(5000) 
    },    
});        

Clarinet.test({
    name: 'CRP : testing get-x-given-y and get-y-given-x',
    async fn (chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();  
        chain.mineEmptyBlock(1);     
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);     

        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, expiry, ONE_8);
        result.expectOk().expectUint(1996);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, expiry, 0);
        result.expectOk().expectUint(0);

        result = await CRPTest.getYgivenX(deployer, wbtcAddress, usdaAddress, 0, ONE_8);
        result.expectErr().expectUint(2001);

        result = await CRPTest.getXgivenY(deployer, wbtcAddress, usdaAddress, expiry, 500);
        result.expectOk().expectUint(24750477);

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
        let contractOwner = deployer;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let MultiSigTest = new MS_CRP_WBTC_USDA(chain, deployer);
        let YieldToken = new YIELD_WBTC(chain, deployer);
        let KeyToken = new KEY_WBTC_USDA(chain, deployer);
        const feeRateX = 0.1*ONE_8; // 10%
        const feeRateY = 0.1*ONE_8;
        const feeRebate = 0.5*ONE_8;

        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();  
        chain.mineEmptyBlock(1);    
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);         

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let ROresult:any = YieldToken.totalSupply(expiry)
        ROresult.result.expectOk().expectUint(79999040);

        ROresult = YieldToken.balanceOf(expiry, deployer.address)
        ROresult.result.expectOk().expectUint(79999040);

        ROresult = KeyToken.totalSupply(expiry)
        ROresult.result.expectOk().expectUint(79999040);
        ROresult = KeyToken.balanceOf(expiry, deployer.address)
        ROresult.result.expectOk().expectUint(79999040);

        // Fee rate Setting Proposal of Multisig
        result = MultiSigTest.propose(deployer, expiry, 1000, " Fee Rate Setting to 10%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        result = MultiSigTest.voteFor(deployer, yieldwbtcAddress, 1, 79999040 * 9 / 10 )
        result.expectOk().expectUint(71999136)
        result = MultiSigTest.voteFor(deployer, keywbtcAddress, 1, 79999040 * 9 / 10 )
        result.expectOk().expectUint(71999136)

        // Block 1440 mining for ending proposal
        chain.mineEmptyBlockUntil(2441);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true) // Success 

        result = CRPTest.setFeeRebate(contractOwner, wbtcAddress, usdaAddress, expiry, feeRebate)
        result.expectOk().expectBool(true) // Success      
        
        // Swap
        result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        let position:any = result.expectOk().expectTuple();
        position['dx'].expectUint(90 * ONE_8);  // 10% of fee charged
        position['dy'].expectUint(179264);         

        // fee : 10 * ONE_8 
        // fee-rebate : 0.5 * ONE_8
        let call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3336170600000);
        position['balance-y'].expectUint(33285936); 

        result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.001 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(9952530857);
        position['dy'].expectUint(0.0009 * ONE_8);    

        call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3336170600000 - 9952530857);
        position['balance-y'].expectUint(33285936 + 0.00095 * ONE_8);
    }
})