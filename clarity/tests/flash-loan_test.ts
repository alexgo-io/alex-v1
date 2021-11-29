

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';
import { USDAToken ,WBTCToken, WSTXToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50"
const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50"
const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50"
const yieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const keyusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wstx"
const ytpyieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"
const multisigncrpusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-wstx"
const multisigytpyieldusda = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda"
const loanuserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-usda-wstx"
const keyusdawbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc"
const multisigncrpusdawbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-wbtc"
const loanuserwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-usda-wbtc"

const ONE_8 = 100000000
const expiry = 23040e+8 //0x0218711A0000 => 2304000000000
const expiryBuff = new Uint8Array([0x02,0x18,0x71,0x1A,0x00,0x00]).buffer
const nextExpiry = 51840e+8
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8
const token_to_maturity = 2100e8;

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
    name: "Flash Loan: create margin trade",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let wstxToken = new WSTXToken(chain, deployer);
        
        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wstxToken.mintFixed(wallet_1, wallet_1.address, 200000 * ONE_8);
        result.expectOk(); 
        result = wbtcToken.mintFixed(deployer, wallet_5.address, 100000 * ONE_8);
        result.expectOk(); 
        result = wstxToken.mintFixed(wallet_5, wallet_5.address, 200000 * ONE_8);
        result.expectOk();
        
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

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, expiry, yieldusdaAddress, keyusdaAddress, multisigncrpusdaAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 100*ONE_8);
        result.expectOk().expectBool(true);
        // result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, expiry, yieldusdaAddress, keyusdawbtcAddress, multisigncrpusdawbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        // result.expectOk().expectBool(true);        
      
        let call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
      
        // let call = await FLTest.getBalanceSFT(keyusdawbtcAddress, expiry, wallet_5.address);
        // let position:any = call.result.expectOk().expectUint(0);
        // call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        // position = call.result.expectOk().expectUint(0);        

        // Let's borrow 100 WSTX to lever up
        result = FLTest.flashLoan(wallet_5, loanuserAddress, wstxAddress, 1000*ONE_8, expiryBuff);
        result.expectOk();
        // result = FLTest.flashLoan(wallet_5, loanuserwbtcAddress, wbtcAddress, ONE_8, expiry);
        // result.expectOk();        

        // spent ~$231 to buy levered position (0.02 uints)
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(19975096511051);  
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(0);            
        // should see change in key token
        call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(99731912761);
        // but nothing with yield token
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);         

        // let's test roll-position from margin-helper

        chain.mineEmptyBlockUntil(10000);
        // trying to roll before maturity throws error
        result = FLTest.rollPosition(wallet_5, usdaAddress, wstxAddress, keyusdaAddress, loanuserAddress, expiry, nextExpiry);
        result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, nextExpiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, nextExpiry, yieldusdaAddress, keyusdaAddress, multisigncrpusdaAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectBool(true);        

        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);
        // roll right after expiry succeeds.
        result = FLTest.rollPosition(wallet_5, usdaAddress, wstxAddress, keyusdaAddress, loanuserAddress, expiry, nextExpiry);
        result.expectOk();

        // key-usda--wbtc should be zero, with non-zero positions in key-usda-51840
        call = await FLTest.getBalanceSFT(keyusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(keyusdaAddress, nextExpiry, wallet_5.address);
        position = call.result.expectOk().expectUint(25239477554);
        // but nothing with yield-usda-51840
        call = await FLTest.getBalanceSFT(yieldusdaAddress, nextExpiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
    },    
});
