import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals, assertNotEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1, FWPTestAgent3 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';
import { USDAToken ,WBTCToken, ALEXToken, WBANToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token"
const wbanAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wban"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const fwpwstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50-v1-01"
const fwpwalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-wbtc-50-50"
const fwpwalexwbanAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-wban"
const multisigwstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-alex-50-50-v1-01"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50-v1-01"
const multisigalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-wbtc-50-50"
const multisigalexwbanAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-wban"
const yieldwstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wstx"
const yieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc"
const yieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const keywstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wstx-wbtc"
const keywstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wstx-alex"
const keywbtcalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-alex"
const keywbtcwbanAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-wban"
const keyusdaalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-alex"
const keyusdawstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wstx"
const ytpyieldwstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wstx"
const ytpyieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc"
const ytpyieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"
const multisigytpyieldwstx = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wstx"
const multisigytpyieldwbtc = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc"
const multisigytpyieldusda = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda"
const multisigncrpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wstx-wbtc"
const multisigncrpwstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wstx-alex"
const multisigncrpwbtcalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-alex"
const multisigncrpwbtcwbanAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-wban"
const multisigncrpusdaalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-alex"
const multisigncrpusdawstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-wstx"

const ONE_8 = 100000000
const expiry = 23040
const nextExpiry = 51840
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8
const token_to_maturity = 2100;

const quantity = 100e8

const weightX = 0.5e+8
const weightY = 0.5e+8

Clarinet.test({
    name: "collateral-rebalancing-pool-v1 margin : create / roll margin - ALEX",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest3 = new FWPTestAgent3(chain, deployer); //simple-weight-pool
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let alexToken = new ALEXToken(chain, deployer);
        let wbanToken = new WBANToken(chain, deployer);
        
        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbanToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();        
        result = wbtcToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk(); 
        result = alexToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbanToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk();        
        chain.mineEmptyBlock(3);

        result = FWPTest3.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest3.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);    
        result = CRPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = CRPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);                           
        
        result = FWPTest3.createPool(deployer, alexAddress, wbanAddress, fwpwalexwbanAddress, multisigalexwbanAddress, quantity, quantity);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setOracleEnabled(deployer, alexAddress, wbanAddress);
        result.expectOk().expectBool(true);          
        result = FWPTest3.setOracleAverage(deployer, alexAddress, wbanAddress, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setStartBlock(deployer, alexAddress, wbanAddress, 0);
        result.expectOk().expectBool(true);
        
        result = FWPTest3.createPool(deployer, alexAddress, wbtcAddress, fwpwalexwbtcAddress, multisigalexwbtcAddress, quantity, quantity);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setOracleEnabled(deployer, alexAddress, wbtcAddress);
        result.expectOk().expectBool(true);          
        result = FWPTest3.setOracleAverage(deployer, alexAddress, wbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);   
        result = FWPTest3.setStartBlock(deployer, alexAddress, wbtcAddress, 0);
        result.expectOk().expectBool(true);                    

        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, quantity, quantity);        
        result.expectOk().expectTuple();
        
        result = CRPTest.createPool(deployer, wbtcAddress, alexAddress, expiry, yieldwbtcAddress, keywbtcalexAddress, multisigncrpwbtcalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, wbtcAddress, wbanAddress, expiry, yieldwbtcAddress, keywbtcwbanAddress, multisigncrpwbtcwbanAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();        
      
        // check no key/yield tokens held by wallet_5
        let call = await FLTest.getBalanceSFT(keywbtcalexAddress, expiry, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(keywbtcwbanAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);        
        call = await FLTest.getBalanceSFT(yieldwbtcAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        const alex_balance = Number(call.result.expectOk().replace(/\D/g, ""));
        call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        const wbtc_balance = Number(call.result.expectOk().replace(/\D/g, ""));             
        call = await FLTest.getBalance(wbanAddress, wallet_5.address);
        const wban_balance = Number(call.result.expectOk().replace(/\D/g, ""));            
 
        const block = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcalexAddress),
                    types.uint(2 * ONE_8),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(wbanAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcwbanAddress),
                    types.uint(2 * ONE_8),
                    types.none()
                ], wallet_5.address),                
            ]
        );
        block.receipts[0].result.expectOk();        
        block.receipts[1].result.expectOk();          
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        assertEquals(true, alex_balance > Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalance(wbanAddress, wallet_5.address);
        assertEquals(true, wban_balance > Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        assertEquals(wbtc_balance, Number(call.result.expectOk().replace(/\D/g, "")));

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keywbtcalexAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(keywbtcwbanAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(yieldwbtcAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);    

        // let's test roll-borrow
        chain.mineEmptyBlockUntil(10000);
        // // trying to roll before maturity throws error
        const blockRoll = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(wbanAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcwbanAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                
            ]
        );
        blockRoll.receipts[0].result.expectErr().expectUint(2017);
        blockRoll.receipts[1].result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, nextExpiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, quantity, quantity);        
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, wbtcAddress, alexAddress, nextExpiry, yieldwbtcAddress, keywbtcalexAddress, multisigncrpwbtcalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();   
        result = CRPTest.createPool(deployer, wbtcAddress, wbanAddress, nextExpiry, yieldwbtcAddress, keywbtcwbanAddress, multisigncrpwbtcwbanAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();            
        
        // and now we just expired
        chain.mineEmptyBlockUntil(expiry + 1);

        const blockRoll2 = chain.mineBlock(
            [               
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wbtcAddress), 
                    types.principal(wbanAddress),
                    types.uint(expiry),
                    types.principal(yieldwbtcAddress),
                    types.principal(keywbtcwbanAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                          
            ]
        );
        blockRoll2.receipts[0].result.expectOk();        
        blockRoll2.receipts[1].result.expectOk();  

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keywbtcalexAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keywbtcalexAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(keywbtcwbanAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keywbtcwbanAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(yieldwbtcAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
    },    
});

Clarinet.test({
    name: "collateral-rebalancing-pool-v1 margin : create / roll margin - STX",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer); //fixed-weight-pool-v1-01
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let alexToken = new ALEXToken(chain, deployer);
        
        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk(); 
        result = alexToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk();
        chain.mineEmptyBlock(3);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);    
        result = CRPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = CRPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);                       
        
        result = FWPTest.createPool(deployer, wstxAddress, alexAddress, weightX, weightY, fwpwstxalexAddress, multisigwstxalexAddress, quantity, quantity);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, alexAddress, weightX, weightY);
        result.expectOk().expectBool(true);    
        result = FWPTest.setOracleAverage(deployer, wstxAddress, alexAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);    
        
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, quantity, quantity);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);    
        result = FWPTest.setOracleAverage(deployer, wstxAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);                       

        result = YTPTest.createPool(deployer, expiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, quantity, quantity);        
        result.expectOk().expectTuple();
        
        result = CRPTest.createPool(deployer, usdaAddress, alexAddress, expiry, yieldusdaAddress, keyusdaalexAddress, multisigncrpusdaalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, expiry, yieldusdaAddress, keyusdawstxAddress, multisigncrpusdawstxAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();
      
        // check no key/yield tokens held by wallet_5
        let call = await FLTest.getBalanceSFT(keyusdaalexAddress, expiry, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(keyusdawstxAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);        
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        const alex_balance = Number(call.result.expectOk().replace(/\D/g, ""));
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        const wstx_balance = Number(call.result.expectOk().replace(/\D/g, ""));             
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        const usda_balance = Number(call.result.expectOk().replace(/\D/g, ""));            
 
        const block = chain.mineBlock(
            [              
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(usdaAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdaalexAddress),
                    types.uint(ONE_8),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(usdaAddress), 
                    types.principal(wstxAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdawstxAddress),
                    types.uint(ONE_8),
                    types.none()
                ], wallet_5.address),                
            ]
        );
        block.receipts[0].result.expectOk();        
        block.receipts[1].result.expectOk();          
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        assertEquals(true, alex_balance > Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        assertEquals(true, wstx_balance > Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        assertEquals(usda_balance, Number(call.result.expectOk().replace(/\D/g, "")));

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keyusdaalexAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(keyusdawstxAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);    

        chain.mineEmptyBlockUntil(10000);
        // // trying to roll before maturity throws error
        const blockRoll = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(usdaAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdaalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(usdaAddress), 
                    types.principal(wstxAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdawstxAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                
            ]
        );
        blockRoll.receipts[0].result.expectErr().expectUint(2017);
        blockRoll.receipts[1].result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, nextExpiry, yieldusdaAddress, usdaAddress, ytpyieldusdaAddress, multisigytpyieldusda, quantity, quantity);        
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, usdaAddress, alexAddress, nextExpiry, yieldusdaAddress, keyusdaalexAddress, multisigncrpusdaalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();   
        result = CRPTest.createPool(deployer, usdaAddress, wstxAddress, nextExpiry, yieldusdaAddress, keyusdawstxAddress, multisigncrpusdawstxAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();            
        
        // and now we just expired
        chain.mineEmptyBlockUntil(expiry + 1);

        const blockRoll2 = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(usdaAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdaalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(usdaAddress), 
                    types.principal(wstxAddress),
                    types.uint(expiry),
                    types.principal(yieldusdaAddress),
                    types.principal(keyusdawstxAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                       
            ]
        );
        blockRoll2.receipts[0].result.expectOk();        
        blockRoll2.receipts[1].result.expectOk();  

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keyusdaalexAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keyusdaalexAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(keyusdawstxAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keyusdawstxAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(yieldusdaAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
    },    
});



Clarinet.test({
    name: "collateral-rebalancing-pool-v1 margin : create / roll margin - STX <=> ALEX",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_5 = accounts.get("wallet_5")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest3 = new FWPTestAgent3(chain, deployer); //simple-weight-pool
        let FWPTest = new FWPTestAgent1(chain, deployer); //fixed-weight-pool-v1-01
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);   
        let alexToken = new ALEXToken(chain, deployer);
        
        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, deployer.address, 100_000_000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk(); 
        result = alexToken.mintFixed(deployer, wallet_5.address, 100_000_000 * ONE_8);
        result.expectOk();
        chain.mineEmptyBlock(3);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest3.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);        
        result = CRPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = CRPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);                       
        
        result = FWPTest.createPool(deployer, wstxAddress, alexAddress, weightX, weightY, fwpwstxalexAddress, multisigwstxalexAddress, quantity, quantity);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wstxAddress, alexAddress, weightX, weightY);
        result.expectOk().expectBool(true);    
        result = FWPTest.setOracleAverage(deployer, wstxAddress, alexAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);     
        
        result = FWPTest3.createPool(deployer, alexAddress, wbtcAddress, fwpwalexwbtcAddress, multisigalexwbtcAddress, quantity, quantity);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setOracleEnabled(deployer, alexAddress, wbtcAddress);
        result.expectOk().expectBool(true);          
        result = FWPTest3.setOracleAverage(deployer, alexAddress, wbtcAddress, 0.95e8);
        result.expectOk().expectBool(true);  
        result = FWPTest3.setStartBlock(deployer, alexAddress, wbtcAddress, 0);   
        result.expectOk().expectBool(true);                        

        result = YTPTest.createPool(deployer, expiry, yieldwstxAddress, wstxAddress, ytpyieldwstxAddress, multisigytpyieldwstx, quantity, quantity);        
        result.expectOk().expectTuple();
        
        result = CRPTest.createPool(deployer, wstxAddress, alexAddress, expiry, yieldwstxAddress, keywstxalexAddress, multisigncrpwstxalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, wstxAddress, wbtcAddress, expiry, yieldwstxAddress, keywstxwbtcAddress, multisigncrpwstxwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk().expectTuple();    
      
        // check no key/yield tokens held by wallet_5
        let call = await FLTest.getBalanceSFT(keywstxalexAddress, expiry, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalanceSFT(keywstxwbtcAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);        
        call = await FLTest.getBalanceSFT(yieldwstxAddress, expiry, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        const alex_balance = Number(call.result.expectOk().replace(/\D/g, ""));
        call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        const wbtc_balance = Number(call.result.expectOk().replace(/\D/g, ""));             
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        const wstx_balance = Number(call.result.expectOk().replace(/\D/g, ""));            
 
        const block = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(wstxAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxalexAddress),
                    types.uint(ONE_8),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "create-margin-position", 
                [
                    types.principal(wstxAddress), 
                    types.principal(wbtcAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxwbtcAddress),
                    types.uint(ONE_8),
                    types.none()
                ], wallet_5.address),     
                Tx.contractCall("alex-vault", "add-approved-contract",
                [
                    types.principal(deployer.address + ".margin-helper")
                ], deployer.address),
                Tx.contractCall("margin-helper", "create-margin-position", 
                [
                    types.principal(wstxAddress), 
                    types.principal(wbtcAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxwbtcAddress),
                    types.uint(ONE_8),
                    types.none()
                ], wallet_5.address),                             
            ]
        );
        block.receipts[0].result.expectOk();        
        block.receipts[1].result.expectOk();          
        block.receipts[2].result.expectOk();
        
        call = await FLTest.getBalance(alexAddress, wallet_5.address);
        assertEquals(true, alex_balance > Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        assertEquals(true, wbtc_balance > Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalance(wstxAddress, wallet_5.address);
        assertEquals(wstx_balance, Number(call.result.expectOk().replace(/\D/g, "")));

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keywstxalexAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(keywstxwbtcAddress, expiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));
        call = await FLTest.getBalanceSFT(yieldwstxAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);    

        // let's test roll-borrow
        chain.mineEmptyBlockUntil(10000);
        // // trying to roll before maturity throws error
        const blockRoll = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wstxAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wstxAddress), 
                    types.principal(wbtcAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxwbtcAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                
            ]
        );
        blockRoll.receipts[0].result.expectErr().expectUint(2017);
        blockRoll.receipts[1].result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, nextExpiry, yieldwstxAddress, wstxAddress, ytpyieldwstxAddress, multisigytpyieldwstx, quantity, quantity);        
        result.expectOk().expectTuple();
        result = CRPTest.createPool(deployer, wstxAddress, alexAddress, nextExpiry, yieldwstxAddress, keywstxalexAddress, multisigncrpwstxalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();   
        result = CRPTest.createPool(deployer, wstxAddress, wbtcAddress, nextExpiry, yieldwstxAddress, keywstxwbtcAddress, multisigncrpwstxwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 1e+8);
        result.expectOk().expectTuple();            
        
        // and now we just expired
        chain.mineEmptyBlockUntil(expiry + 1);

        const blockRoll2 = chain.mineBlock(
            [
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wstxAddress), 
                    types.principal(alexAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxalexAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),
                Tx.contractCall("collateral-rebalancing-pool-v1", "roll-borrow", 
                [
                    types.principal(wstxAddress), 
                    types.principal(wbtcAddress),
                    types.uint(expiry),
                    types.principal(yieldwstxAddress),
                    types.principal(keywstxwbtcAddress),
                    types.uint(nextExpiry),
                    types.none()
                ], wallet_5.address),                           
            ]
        );
        blockRoll2.receipts[0].result.expectOk();        
        blockRoll2.receipts[1].result.expectOk();  

        // should see change in key token, but nothing with yield token
        call = await FLTest.getBalanceSFT(keywstxalexAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keywstxalexAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(keywstxwbtcAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
        call = await FLTest.getBalanceSFT(keywstxwbtcAddress, nextExpiry, wallet_5.address);
        assertNotEquals(0, Number(call.result.expectOk().replace(/\D/g, "")));        
        call = await FLTest.getBalanceSFT(yieldwstxAddress, expiry, wallet_5.address);
        call.result.expectOk().expectUint(0);  
    },    
});

