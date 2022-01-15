import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { YCRPTestAgent1 } from './models/alex-tests-yield-collateral-rebalancing-pool.ts';
import {CRPTestAgent1} from './models/alex-tests-collateral-rebalancing-pool.ts' 
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { MS_CRP_WBTC_USDA } from './models/alex-tests-multisigs.ts';
import { USDAToken, WBTCToken, WSTXToken, YIELD_WBTC, YIELD_USDA, KEY_WBTC_USDA } from './models/alex-tests-tokens.ts';

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
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const yieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const ytpyieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"
const multisigytpyieldusda = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const expiry79760 = 79760 * ONE_8
const ltv_0 = 0.8 * ONE_8
const conversion_ltv = 0.95 * ONE_8
const bs_vol = 0.8 * ONE_8
const moving_average = 0 * ONE_8 // for testing only
const token_to_maturity = 1 * ONE_8 // for testing only

const wbtcPrice = 50000*ONE_8

const weightX = 0.5 * ONE_8
const weightY = 0.5 * ONE_8

const wbtcQ = 100*ONE_8

/**
 * Collateral Rebalancing Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "YCRP : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();        

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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);    

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let call = await YCRPTest.getPoolValueInToken(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(99938515);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await YCRPTest.getLtv(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80104740);

        // Check pool details and print
        call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(80055488);
        position['key-supply'].expectUint(80055488);
        position['weight-x'].expectUint(66532499);
        position['weight-y'].expectUint(ONE_8 - 66532499);        
        position['balance-x'].expectUint(3326624950000);
        position['balance-y'].expectUint(33474000);
        position['strike'].expectUint(4999999700000);
        position['ltv-0'].expectUint(ltv_0);
        position['bs-vol'].expectUint(bs_vol);
        position['conversion-ltv'].expectUint(conversion_ltv);
        position['moving-average'].expectUint(moving_average);
        
        // arbtrageur selling 100 usda for wbtc
        result = YCRPTest.swapXForY(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);
        position['dy'].expectUint(199140); 

        // arbtrageur selling 0.002 wbtc for usda
        result = YCRPTest.swapYForX(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 0.002 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(22258157913);
        position['dy'].expectUint(0.002 * ONE_8);        

        // borrow $5,000 more and convert to wbtc
        // remember, the first sell creates profit to LP
        result = YCRPTest.addToPositionAndSwitch(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 5000 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(7892273);        
        position['dx'].expectUint(7892442);

        // supply increased
        call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3552137557087);
        position['balance-y'].expectUint(38628405);                
        position['yield-supply'].expectUint(87947761);
        position['key-supply'].expectUint(87947761);      
        
        // pool value increases after adding positions
        call = await YCRPTest.getPoolValueInToken(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109523032);    
        
        call = await YCRPTest.getPoolValueInCollateral(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(5487593214550);
        
        // let's check what is the weight to wbtc (token)
        call = await YCRPTest.getWeightY(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(52704465);                     
        
        // simulate to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // but lender cannot yet redeem
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, 0.5 * ONE_8);
        result.expectErr().expectUint(2017);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)  
        
        call = await YCRPTest.getPoolValueInToken(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(109521083); 

        // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(80055488);

        // most of yield-token burnt, but key-token remains
        call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(9719759);                
        position['yield-supply'].expectUint(7892273);
        position['key-supply'].expectUint(87947761);
             
        // also remove all key tokens
        result = YCRPTest.reducePositionKey(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, keywbtcAddress, ONE_8);        
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(0);
        position['dy'].expectUint(1827485);     
        
        call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(7892273);
        position['key-supply'].expectUint(0);        
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(7892274);                
    },    
});

Clarinet.test({
    name: "YCRP : trait check",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();        

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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true); 

        // non-deployer creating a pool will throw an error
        result = YCRPTest.createPool(wallet_1, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectErr().expectUint(1000);

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);     
        
        // supplying a wrong pool-token throws an error
        result = YCRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, wrongPooltokenAddress, keywbtcAddress, 5000 * ONE_8);
        result.expectErr().expectUint(2023);   
        
        // same for key-token
        result = YCRPTest.addToPositionAndSwitch(wallet_1, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, wrongPooltokenAddress, 5000 * ONE_8);
        result.expectErr().expectUint(2023);        

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)

        // supplying a wrong pool-token throws an error
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress,yieldusdaAddress, usdaAddress, expiry, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2023);
        // same for key-token
        result = YCRPTest.reducePositionKey(deployer, wbtcAddress,yieldusdaAddress, usdaAddress, expiry, wrongPooltokenAddress, ONE_8);        
        result.expectErr().expectUint(2023);
                
        // remove all liquidity
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, ONE_8);        
        result.expectOk();        
        result = YCRPTest.reducePositionKey(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, keywbtcAddress, ONE_8);        
        result.expectOk();          
    }
});

Clarinet.test({
    name: "YCRP : multiple CRP pools created",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();   
        
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

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true); 

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 10000 * ONE_8);
        result.expectOk().expectBool(true);   

        // simulate to half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)

        // Deployer minting initial tokens
        result = yieldUSDA.mintFixed(deployer, expiry79760, 100000000 * ONE_8, deployer.address);
        result.expectOk();  

        result = YTPTest.createPool(deployer, expiry79760, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry79760, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry79760, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true); 

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry79760, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 10000 * ONE_8);
        result.expectOk().expectBool(true); 
    },    
});

Clarinet.test({
    name: "YCRP : testing get-x-given-price and get-y-given-price",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();      
        
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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true); 

        let moving_average_0 = 0.95e+8
        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average_0, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let call = await YCRPTest.getPoolValueInToken(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(99938515);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await YCRPTest.getLtv(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80104740);

        call = await YCRPTest.getXgivenPrice(wbtcAddress, yieldusdaAddress, expiry, (Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8))));
        call.result.expectOk().expectUint(107937635837);
        result = YCRPTest.swapXForY(deployer, wbtcAddress, yieldusdaAddress,usdaAddress, expiry, 107360750371, 0);
        let position:any = result.expectOk().expectTuple();
        position['dx'].expectUint(107360750371);
        position['dy'].expectUint(2048349);
        
        call = await YCRPTest.getYgivenPrice(wbtcAddress, yieldusdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 * 0.98/ ONE_8)));
        call.result.expectOk().expectUint(666395);
        result = YCRPTest.swapYForX(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 1223378, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(72305247430);
        position['dy'].expectUint(1223378);   
    },    
});  

Clarinet.test({
    name: "YCRP : testing pegged CRP (= yield-token collateralised by token)",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();      
        
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

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);        
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);        

        // sell some yield-token to create a positive yield
        result = YTPTest.swapYForX(deployer, expiry, yieldusdaAddress, usdaAddress, 5*ONE_8, 0);
        let position:any = result.expectOk().expectTuple();
        
        let call = await YTPTest.getPrice(expiry, yieldusdaAddress);
        call.result.expectOk().expectUint(100000019);        

        let ltv_00 = Math.round(ONE_8 * ONE_8 / 109095981);         //91662405
        let collateral = ONE_8;
        let conversion_ltv_0 = 0.98e+8;
        let bs_vol_0 = 0.1e+8;
        let moving_average_0 = 0.95e+8

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_00, conversion_ltv_0, bs_vol_0, moving_average_0, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);
    
        call = await YCRPTest.getPoolValueInToken(wbtcAddress, yieldusdaAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(2605482380998);

        call = await YCRPTest.getLtv(wbtcAddress, yieldusdaAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(91769857);

                // pegged CRP throws error if someone tries to swap
        call = await YCRPTest.getXgivenPrice(wbtcAddress, yieldusdaAddress, expiry, Math.round( ONE_8 / (wbtcPrice * 1.1 / ONE_8)));
        call.result.expectOk().expectUint(121812670656);
        result = YCRPTest.swapXForY(deployer, usdaAddress, yieldusdaAddress, wbtcAddress, expiry, 121812670656, 0);
        position = result.expectErr().expectUint(2001);
    },    
});              

Clarinet.test({
    name: "YCRP : ERR-POOL-AT-CAPACITY attempt to add position to exceed MAX_IN/OUT_RATIO of fixed-weight-pool throws error",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();      
        
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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);             

        let ltv_0_0 = 0.5 * ONE_8;
        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        // attempt to add position to exceed MAX_IN/OUT_RATIO of fixed-weight-pool throws error
        result = YCRPTest.addToPosition(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 0.11 * Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectErr().expectUint(1001);
    },    
});

Clarinet.test({
    name: "YCRP : error testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();        

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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);  

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        result = YCRPTest.addToPositionAndSwitch(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, 0);
        result.expectErr().expectUint(2003)

        result = YCRPTest.addToPositionAndSwitch(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, ONE_8 * ONE_8);//5000*ONE_8
        result.expectErr().expectUint(1001)

        // arbtrageur attepmts to swap zero value
        result = YCRPTest.swapXForY(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 0, 0);
        result.expectErr().expectUint(2003)

        // arbtrageur attepmts to swap in full value
        result = YCRPTest.swapXForY(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, ONE_8 * ONE_8, 0);
        result.expectErr().expectUint(4001) 

        // simulate to expiry + 1
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)    
        
        // arbtrageur attepmts to retreive back with zero value
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, 0);        
        result.expectErr().expectUint(3) 

        // arbitrageur attempts to retreuve back with small value
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, 0.001 * ONE_8);        
        result.expectOk().expectTuple();

        // arbtrageur attepmts to retreive back with full value
        result = YCRPTest.reducePositionYield(deployer, wbtcAddress,yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, 101*ONE_8);        
        result.expectErr().expectUint(5000) 
    },    
});        

Clarinet.test({
    name: 'YCRP : testing get-x-given-y and get-y-given-x',
    async fn (chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();        

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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);    

        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let call = await YCRPTest.getYgivenX(wbtcAddress, yieldusdaAddress, expiry, ONE_8);
        call.result.expectOk().expectUint(1997);

        call = await YCRPTest.getYgivenX(wbtcAddress, yieldusdaAddress, expiry, 0);
        call.result.expectOk().expectUint(0);

        call = await YCRPTest.getYgivenX(wbtcAddress, yieldusdaAddress, 0, ONE_8);
        call.result.expectErr().expectUint(2001);

        call = await YCRPTest.getXgivenY(wbtcAddress, yieldusdaAddress, expiry, 500);
        call.result.expectOk().expectUint(24750089);

        call = await YCRPTest.getXgivenY(wbtcAddress, yieldusdaAddress, expiry, 0);
        call.result.expectOk().expectUint(0);

        call = await YCRPTest.getXgivenY(wbtcAddress, yieldusdaAddress, 0, 500);
        call.result.expectErr().expectUint(2001)
    }
})


Clarinet.test({
    name: "YCRP : fee setting using multisig",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let contractOwner = deployer;
        let YCRPTest = new YCRPTestAgent1(chain, deployer);
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
        let yieldUSDA = new YIELD_USDA(chain, deployer);

        // Deployer minting initial tokens  
        let result = usdaToken.mintFixed(deployer, deployer.address, 500000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 500000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 500000 * ONE_8);
        result.expectOk();
        result = yieldUSDA.mintFixed(deployer, expiry, 100000000 * ONE_8, deployer.address);
        result.expectOk();        

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
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldwbtcAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldwbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, Math.round(wbtcPrice * wbtcQ / ONE_8 / 10), Math.round(wbtcPrice * wbtcQ / ONE_8 / 10));        
        result.expectOk().expectBool(true);    
        result = YTPTest.setOracleEnabled(deployer, expiry, yieldusdaAddress);
        result.expectOk().expectBool(true);
        result = YTPTest.setOracleAverage(deployer, expiry, yieldusdaAddress, 0.95e8);
        result.expectOk().expectBool(true);    
        
        //Deployer creating a pool, initial tokens injected to the pool
        result = YCRPTest.createPool(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true);

        let ROresult:any = YieldToken.totalSupply(expiry)
        ROresult.result.expectOk().expectUint(80055488);

        ROresult = YieldToken.balanceOf(expiry, deployer.address)
        ROresult.result.expectOk().expectUint(80055488);

        ROresult = KeyToken.totalSupply(expiry)
        ROresult.result.expectOk().expectUint(80055488);
        ROresult = KeyToken.balanceOf(expiry, deployer.address)
        ROresult.result.expectOk().expectUint(80055488);
        // Fee rate Setting Proposal of Multisig
        result = MultiSigTest.propose(deployer, expiry, 1000, " Fee Rate Setting to 10%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        result = MultiSigTest.voteFor(deployer, yieldwbtcAddress, 1, 79999040 * 9 / 10 )
        result.expectOk().expectUint(71999136)

        result = MultiSigTest.voteFor(deployer, keywbtcAddress, 1, 79999040 * 9 / 10 )
        result.expectOk().expectUint(71999136)

        // mint some more yield tokens for yes votes
        result = YieldToken.mintFixed(deployer, expiry, 79999040 * 10, deployer.address)
        result.expectOk().expectBool(true)

        // vote to reach the winning threshold
        result = MultiSigTest.voteFor(deployer, yieldwbtcAddress, 1, 694092346)
        result.expectOk().expectUint(694092346)

        chain.mineEmptyBlockUntil(2441)
        
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectBool(true); 

        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true)

        result = YCRPTest.setFeeRebate(contractOwner, wbtcAddress, yieldusdaAddress, expiry, feeRebate)
        result.expectOk().expectBool(true) // Success      
    
        // Swap
        result = YCRPTest.swapXForY(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        let position:any = result.expectOk().expectTuple();
        position['dx'].expectUint(100 * ONE_8);  // 10% of fee charged
        position['dy'].expectUint(199140);         

        // fee : 10 * ONE_8 
        // fee-rebate : 0.5 * ONE_8
        let call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3336624950000);    // 3326726300000 + 0.95 * 100* ONE_8
        position['balance-y'].expectUint(33274860); 

        result = YCRPTest.swapYForX(deployer, wbtcAddress, yieldusdaAddress, usdaAddress, expiry, 0.001 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(11293774764);
        position['dy'].expectUint(0.001 * ONE_8);    

        call = await YCRPTest.getPoolDetails(wbtcAddress, yieldusdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(3325331175236);  
        position['balance-y'].expectUint(33374860); 
    }
})