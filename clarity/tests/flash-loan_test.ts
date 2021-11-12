

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';

// Deployer Address Constants 
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const yieldusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-23040"
const keyusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-23040-wbtc"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const ytpyieldusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda-23040-usda"
const multisigncrpusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-23040-wbtc"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const multisigytpyieldusda23040 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda-23040-usda"
const vaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
const reserveAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-reserve-pool"
const loanuserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-wbtc-usda-23040"

const ONE_8 = 100000000
const expiry = 23040e+8
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8

const wbtcPrice = 50000

const weightX = 0.5e+8
const weightY = 0.5e+8

/**
 * Flash Loan Test Cases  
 * 
 */

Clarinet.test({
    name: "Flash Loan: create margin trade",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        
        let call = await FLTest.getBalance(wbtcAddress, wallet_1.address);
        let position:any = call.result.expectOk().expectUint(2000000000000); // because this is the new amount minted
        call = await FLTest.getBalance(usdaAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(20000000000000);        
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, Math.round(50000000 * ONE_8 / wbtcPrice), 50000000e+8); // 50000000e+8/ONE_8
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);
        
        call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(Math.round(50000000 * ONE_8 / wbtcPrice)); //100,000,000,000 50000000e+8/ONE_8
        position['balance-y'].expectUint(50000000e+8);
        
        result = YTPTest.createPool(deployer, yieldusda23040Address, usdaAddress, ytpyieldusda23040Address, multisigytpyieldusda23040, 50000000e+8, 50000000e+8);        
        result.expectOk().expectBool(true);
        
        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, yieldusda23040Address, keyusda23040Address, multisigncrpusda23040Address, ltv_0, conversion_ltv, bs_vol, moving_average, 1e+8); // 1e+8*1e+8 gives error since we don't have enough dx
        result.expectOk().expectBool(true);
        
        call = await CRPTest.getSpot(usdaAddress, wbtcAddress);
        call.result.expectOk().expectUint(2000); //2008
        
        call = await CRPTest.getSpot(wbtcAddress, usdaAddress);
        call.result.expectOk().expectUint(4999802365602); // 4981337432709
        
        call = await CRPTest.getPoolValueInToken(usdaAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(4998848550000); // 4912705519920
        
        call = await CRPTest.getLtv(usdaAddress, wbtcAddress, expiry);
        call.result.expectOk().expectUint(79932807); // 74019490
        
        // sell some yield-token
        result = YTPTest.swapYForX(wallet_1, yieldusda23040Address, usdaAddress, 10000*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(998605393682); // 1000041600834
        position['dy'].expectUint(10000*ONE_8);
        
        call = await YTPTest.getPrice(yieldusda23040Address);
        call.result.expectOk().expectUint(100000115); // 100010963
        
        // remember ltv to be used for margin is:
        // ltv = (.collateral-rebalancing-pool get-ltv) / (.yield-token-pool get-price)
        let ltv:number = 79932807 / 100000115;
        let margin:number = 0.0000001 * ONE_8 * ONE_8; // the magic number 0.00001 is causing issues, dividing it by 1e2 solves it (error 3003 occurs)
        let amount:number = Math.round(margin / (1 - ltv));
        let borrow:number = amount - margin; //3983235170 - 1000000000
        
        call = await FLTest.getBalance(wbtcAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(2000000000000);
        call = await FLTest.getBalance(keyusda23040Address, wallet_1.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(yieldusda23040Address, wallet_1.address);
        position = call.result.expectOk().expectUint(199999999000000000000); // 1999999000000000000
        
        // result = FLTest.executeMarginUsdaWbtc59760(wallet_1, amount);
        // result.expectOk();
        
        result = FLTest.flashLoan(wallet_1, loanuserAddress, wbtcAddress, borrow);
        result.expectOk();
        
        // spent ~$231 to buy levered position (0.02 uints)
        call = await FLTest.getBalance(wbtcAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(1999121093959); //1999999998541
        call = await FLTest.getBalance(usdaAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(20998605393682); //1200041000000
        // should see change in key token
        call = await FLTest.getBalance(keyusda23040Address, wallet_1.address);
        position = call.result.expectOk().expectUint(189561622727560);// 133000000
        // but nothing with yield token
        call = await FLTest.getBalance(yieldusda23040Address, wallet_1.address);
        position = call.result.expectOk().expectUint(199999999000000000000); // 1999999000000000000
    },    
});
