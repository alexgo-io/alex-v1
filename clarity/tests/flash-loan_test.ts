

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';
import { WBTCToken, WSTXToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50"
const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50"
const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50"
const yieldusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-23040"
const keyusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-23040-wstx"
const ytpyieldusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda-23040-usda"
const multisigncrpusda23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-23040-wstx"
const multisigytpyieldusda23040 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda-23040-usda"
const loanuser23040Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-wstx-usda-23040"
const yieldusda51840Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-51840"
const keyusda51840Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-51840-wstx"
const ytpyieldusda51840Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda-51840-usda"
const multisigncrpusda51840Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-51840-wstx"
const multisigytpyieldusda51840 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda-51840-usda"
const loanuser51840Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-wstx-usda-51840"

const ONE_8 = 100000000
const expiry = 23040e+8
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8

const wbtcPrice = 50000e+8
const wbtcQ = 100*ONE_8

const weightX = 0.5e+8
const weightY = 0.5e+8

/**
 * Yield Token Pool Test Cases  
 * 
 *  TODO: test shortfall case with reserve-pool
 */

Clarinet.test({
    name: "Flash Loan: create margin trade",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let wstxToken = new WSTXToken(chain, deployer);  
        
        wbtcToken.transferToken(ONE_8, deployer.address, wallet_5.address, new ArrayBuffer(30));        
        wstxToken.transferToken(100*ONE_8, deployer.address, wallet_5.address, new ArrayBuffer(30));

        let call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(ONE_8);
        
        let result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8));
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

        result = YTPTest.createPool(deployer, yieldusda23040Address, usdaAddress, ytpyieldusda23040Address, multisigytpyieldusda23040, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, yieldusda23040Address, keyusda23040Address, multisigncrpusda23040Address, ltv_0, conversion_ltv, bs_vol, moving_average, 10000*ONE_8);
        result.expectOk().expectBool(true);    
      
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(yieldusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);

        // Let's borrow 100 WSTX to lever up
        result = FLTest.flashLoan(wallet_5, loanuser23040Address, wstxAddress, 100*ONE_8);
        result.expectOk();

        // spent ~$231 to buy levered position (0.02 uints)
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(7500000000);  
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(0);            
        // should see change in key token
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(7970000000);
        // but nothing with yield token
        call = await FLTest.getBalance(yieldusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);         

        // let's test roll-position from margin-helper

        chain.mineEmptyBlockUntil(10000);
        // trying to roll before maturity throws error
        result = FLTest.rollPosition(wallet_5, usdaAddress, wstxAddress, keyusda23040Address, loanuser51840Address);
        result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, yieldusda51840Address, usdaAddress, ytpyieldusda51840Address, multisigytpyieldusda51840, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, yieldusda51840Address, keyusda51840Address, multisigncrpusda51840Address, ltv_0, conversion_ltv, bs_vol, moving_average, 10000*ONE_8);
        result.expectOk().expectBool(true);        

        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);
        // roll right after expiry succeeds.
        result = FLTest.rollPosition(wallet_5, usdaAddress, wstxAddress, keyusda23040Address, loanuser51840Address);
        result.expectOk();

        // key-usda-23040-wstx should be zero, with non-zero positions in key-usda-51840
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(keyusda51840Address, wallet_5.address);
        position = call.result.expectOk().expectUint(1793499000000);
        // but nothing with yield-usda-51840
        call = await FLTest.getBalance(yieldusda51840Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        
    },    
});
