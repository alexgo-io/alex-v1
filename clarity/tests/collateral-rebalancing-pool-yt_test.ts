

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { CRPYTTestAgent } from './models/alex-tests-collateral-rebalancing-pool-yt.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { MS_CRP_WBTC_USDA_59760} from './models/alex-tests-multisigs.ts';
import { USDAToken,WBTCToken,YIELD_WBTC_59760,KEY_WBTC_59760_USDA, YIELD_USDA_59760 } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const yieldusda59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-59760"
const keywbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
const ytpyieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
// const keyusda80875Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-80875-wbtc"
// const multisigncrpusda80875Address = 
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
const collateralRebalancingPool = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.collateral-rebalancing-pool"

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
        let CRPTest = new CRPYTTestAgent(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let YIELDToken = new YIELD_USDA_59760(chain, deployer);
        
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

        result = YTPTest.createPool(deployer, yieldusda59760Address, usdaAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, wbtcQ / 10, wbtcQ / 10);        
        result.expectOk().expectBool(true);

        result = YTPTest.setOracleEnabled(deployer, yieldusda59760Address);
        result.expectOk().expectBool(true);   
        result = YTPTest.setOracleAverage(deployer, yieldusda59760Address, 0.95e8);
        result.expectOk().expectBool(true);  

        // //Deployer creating a pool, initial tokens injected to the pool
        // result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, yieldusda59760Address, keyusda59760Address, multisigncrpusda59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        // result.expectOk().expectBool(true);

        let Balance:any = YIELDToken.balanceOf(deployer.address);
        Balance.result.expectOk().expectBool(true);  
        //Deployer creating a pool, initial tokens injected to the pool
        // result = CRPTest.createPool(deployer, wbtcAddress, yieldusda59760Address, yieldwbtc59760Address, keywbtc59760Address, multisigncrpwbtc59760Address, ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);
        // result.expectOk().expectBool(true);

        // call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        // call.result.expectOk().expectUint(100089055);

        // // ltv-0 is 80%, but injecting liquidity pushes up LTV
        // call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        // call.result.expectOk().expectUint(80735461);

        // // Check pool details and print
        // call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        // position = call.result.expectOk().expectTuple();
        // position['yield-supply'].expectUint(80807360);
        // position['key-supply'].expectUint(80807360);
        // position['weight-x'].expectUint(66534526);
        // position['weight-y'].expectUint(ONE_8 - 66534526);        
        // position['balance-x'].expectUint(3326726300000);
        // position['balance-y'].expectUint(33576900);
        // position['strike'].expectUint(50000 * ONE_8);
        // position['ltv-0'].expectUint(ltv_0);
        // position['bs-vol'].expectUint(bs_vol);
        // position['conversion-ltv'].expectUint(conversion_ltv);
        // position['moving-average'].expectUint(moving_average);
        
        // // arbtrageur selling 100 usda for wbtc
        // result = CRPTest.swapXForY(deployer, wbtcAddress, usdaAddress, expiry, 100 * ONE_8, 0);
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(100 * ONE_8);
        // position['dy'].expectUint(199764); 

        // // arbtrageur selling 0.002 wbtc for usda
        // result = CRPTest.swapYForX(deployer, wbtcAddress, usdaAddress, expiry, 0.002 * ONE_8, 0);
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(22079184661);
        // position['dy'].expectUint(0.002 * ONE_8);        

        // // borrow $5,000 more and convert to wbtc
        // // remember, the first sell creates profit to LP
        // result = CRPTest.addToPositionAndSwitch(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, 5000 * ONE_8);
        // position = result.expectOk().expectTuple();
        // position['dy'].expectUint(8046279);        
        // position['dx'].expectUint(8046447);

        // // supply increased
        // call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        // position = call.result.expectOk().expectTuple();
        // position['balance-x'].expectUint(3553041375339);
        // position['balance-y'].expectUint(38776120);                
        // position['yield-supply'].expectUint(88853639);
        // position['key-supply'].expectUint(88853639);      
        
        // // pool value increases after adding positions
        // call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        // call.result.expectOk().expectUint(109786643);    
        
        // call = await CRPTest.getPoolValueInCollateral(wbtcAddress, usdaAddress, expiry);
        // call.result.expectOk().expectUint(5493220824349);
        
        // // let's check what is the weight to wbtc (token)
        // call = await CRPTest.getWeightY(wbtcAddress, usdaAddress, expiry, 50000 * ONE_8, bs_vol);
        // call.result.expectOk().expectUint(52411081);                     
        
        // // simulate to expiry
        // chain.mineEmptyBlockUntil((expiry / ONE_8)) 

        // // but lender cannot yet redeem
        // result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, 0.5 * ONE_8);
        // result.expectErr().expectUint(2017);        

        // // simulate to expiry + 1
        // chain.mineEmptyBlockUntil((expiry / ONE_8) + 1)  
        
        // call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        // call.result.expectOk().expectUint(109786643); 

        // // take away what was minted for testing to another address
        // let block = chain.mineBlock([
        //     Tx.contractCall("yield-wbtc-59760", "transfer", [
        //       types.uint(2000000000000),
        //       types.principal(deployer.address),
        //       types.principal(wallet_1.address),
        //       types.some(types.buff(new ArrayBuffer(10)))
        //     ], deployer.address),
        //   ]);
        // block.receipts[0].result.expectOk(); 

        // // deployer holds less than total supply because he sold some yield-wbtc for wbtc
        // result = CRPTest.reducePositionYield(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, ONE_8);        
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(0);
        // position['dy'].expectUint(80807360);

        // // most of yield-token burnt, but key-token remains
        // call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        // position = call.result.expectOk().expectTuple();
        // position['balance-x'].expectUint(0);
        // position['balance-y'].expectUint(9942230);                
        // position['yield-supply'].expectUint(8046279);
        // position['key-supply'].expectUint(88853639);
             
        // // also remove all key tokens
        // result = CRPTest.reducePositionKey(deployer, wbtcAddress, usdaAddress, keywbtc59760Address, ONE_8);        
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(0);
        // position['dy'].expectUint(1895950);     
        
        // call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        // position = call.result.expectOk().expectTuple();
        // position['yield-supply'].expectUint(8046279);
        // position['key-supply'].expectUint(0);        
        // position['balance-x'].expectUint(0);
        // position['balance-y'].expectUint(8046280);                
    },    
});
