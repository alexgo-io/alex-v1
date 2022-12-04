import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent3 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';
import { USDAToken ,WBTCToken, ALEXToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wusda"
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token"
const fwpalexusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-usda"
const fwpalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-wbtc-50-50"
const multisigalexusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-usda"
const multisigalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-wbtc-50-50"
const yieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const keyusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-alex"
const ytpyieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"
const multisigncrpusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-alex"
const multisigytpyieldusda = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda"
const loanuserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-alex-usda"
const keyusdawbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc"
const multisigncrpusdawbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-wbtc"
const loanuserwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-wbtc-usda"
const unauthorisedTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-unauthorised"
const unauthorisedFlashLoanUserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-unauthorised"

const ONE_8 = 100000000
const expiry = 23040 //5A00 => 23040
const expiryBuff = new Uint8Array([0x00,0x00,0x00,0x00,0x5A,0x00]).buffer
const nextExpiry = 51840
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8
const token_to_maturity = 2100;

const wbtcPrice = 50000e+8
const wbtcQ = 10e8

const weightX = 0.5e+8
const weightY = 0.5e+8

/**
 * Yield Token Pool Test Cases  
 * 
 *  TODO: test shortfall case with reserve-pool
 */

Clarinet.test({
    name: "flash-loan : create margin trade",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent3(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let alexToken = new ALEXToken(chain, deployer);
        
        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk(); 
        result = wbtcToken.mintFixed(deployer, wallet_5.address, 100000 * ONE_8);
        result.expectOk(); 
        result = alexToken.mintFixed(deployer, wallet_5.address, 200000 * ONE_8);
        result.expectOk();
        chain.mineEmptyBlock(3);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);             
        
        result = FWPTest.createPool(deployer, alexAddress, usdaAddress, fwpalexusdaAddress, multisigalexusdaAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), Math.round(wbtcPrice * wbtcQ / ONE_8));
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, alexAddress, wbtcAddress, fwpalexwbtcAddress, multisigalexwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), wbtcQ);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, alexAddress, usdaAddress);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, alexAddress, usdaAddress, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest.setOracleEnabled(deployer, alexAddress, wbtcAddress);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, alexAddress, wbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);    
        result = FWPTest.setStartBlock(deployer, alexAddress, usdaAddress, 0);   
        result.expectOk().expectBool(true);     
        result = FWPTest.setStartBlock(deployer, alexAddress, wbtcAddress, 0);   
        result.expectOk().expectBool(true);             

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, 500000e+8, 500000e+8);        
        result.expectOk().expectTuple();
        
        // let block = chain.mineBlock([   
        //     Tx.contractCall("collateral-rebalancing-pool-v1", "set-strike-multiplier",
        //         [types.uint(0.5e8)],
        //         deployer.address
        //     ),
        // ])
        // block.receipts.forEach(e => { e.result.expectOk() });    

        result = CRPTest.createPool(deployer, usdaAddress, alexAddress, expiry, yieldusdaAddress, keyusdaAddress, multisigncrpusdaAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 100*ONE_8);
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, expiry, yieldusdaAddress, keyusdawbtcAddress, multisigncrpusdawbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();        
      
        let call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
      
        call = await FLTest.getBalanceSFT(keyusdawbtcAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);        

        // Let's borrow 100 alex to lever up
        result = FLTest.flashLoan(wallet_5, loanuserAddress, alexAddress, 1000*ONE_8, expiryBuff);
        result.expectOk();
        result = FLTest.flashLoan(wallet_5, loanuserwbtcAddress, wbtcAddress, 0.1 * ONE_8, expiryBuff);
        result.expectOk();        

        // spent ~$231 to buy levered position (0.02 uints)
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(19981926742609);  
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(0);            
        // should see change in key token
        call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(99668821801);
        // but nothing with yield token
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);         

        // let's test roll-position from margin-helper

        chain.mineEmptyBlockUntil(10000);
        // trying to roll before maturity throws error
        result = FLTest.rollPosition(wallet_5, usdaAddress, alexAddress, keyusdaAddress, loanuserAddress, expiry, nextExpiry);
        result.expectErr().expectUint(2017);
        // but let's set up new pools
        result = YTPTest.createPool(deployer, nextExpiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, 500000e+8, 500000e+8);        
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, usdaAddress, alexAddress, nextExpiry, yieldusdaAddress, keyusdaAddress, multisigncrpusdaAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();    
        
        // and now we just expired
        chain.mineEmptyBlockUntil(expiry + 1);
        result = FLTest.rollPosition(wallet_5, usdaAddress, alexAddress, keyusdaAddress, loanuserAddress, expiry, nextExpiry);
        result.expectOk().expectUint(18977142351);

        // key-usda-alex should be zero, with non-zero positions in key-usda
        call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(keyusdaAddress, nextExpiry, wallet_5.address);
        position = call.result.expectOk().expectUint(18728435011);
        // but nothing with yield-usda
        call = await FLTest.getBalanceSFT(yieldusdaAddress, nextExpiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
    },    
});

Clarinet.test({
    name: "flash-loan : authorisation tests",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let FLTest = new FLTestAgent1(chain, deployer);

        // trying to call flash-loan with un-approved flash-loan-user throws an error.
        let result = FLTest.flashLoan(deployer, unauthorisedFlashLoanUserAddress, usdaAddress, 1000*ONE_8, expiryBuff);
        result.expectErr().expectUint(1000);

        result = FLTest.flashLoan(deployer, loanuserAddress, unauthorisedTokenAddress, 1000*ONE_8, expiryBuff);
        result.expectErr().expectUint(1000);        
    }
});