

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';
import { WBTCToken, USDAToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const yieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda"
const keyusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-usda-wbtc"
const ytpyieldusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"
const multisigncrpusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-usda-wbtc"
const multisigytpyieldusda = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-usda"
const loanuserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-wbtc-usda"
const alexReservePoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-reserve-pool"

const ONE_8 = 100000000
const expiry = 23040e+8
const nextExpiry = 51840e+8
const ltv_0 = 0.8e+8
const conversion_ltv = 0.95e+8
const bs_vol = 0.8e+8
const moving_average = 0.95e+8

const wbtcPrice = 50000e+8

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

        // Deployer minting initial tokens
        usdaToken.mintFixed(deployer.address, 1000000000 * ONE_8);
        usdaToken.mintFixed(wallet_1.address, 200000 * ONE_8);
        wbtcToken.mintFixed(deployer.address, 10000 * ONE_8);
        wbtcToken.mintFixed(wallet_1.address, 10000 * ONE_8);
        
        wbtcToken.transferToken(ONE_8, deployer.address, wallet_5.address, new ArrayBuffer(30));        

        let call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        let position:any = call.result.expectOk().expectUint(1000000);
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, Math.round(500000e+8 * ONE_8 / wbtcPrice), 500000e+8);
        result.expectOk().expectBool(true);
        result = FWPTest.setOracleEnabled(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectBool(true);   
        result = FWPTest.setOracleAverage(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0.95e8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, expiry, yieldusda23040Address, usdaAddress, ytpyieldusda23040Address, multisigytpyieldusda23040, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, yieldusda23040Address, keyusda23040Address, multisigncrpusda23040Address, ltv_0, conversion_ltv, bs_vol, moving_average, 1e+8);
        result.expectOk().expectBool(true);
      
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(yieldusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);

        // Let's borrow 1 BTC to lever up
        result = FLTest.flashLoan(wallet_5, loanuser23040Address, wbtcAddress, ONE_8);
        result.expectOk();

        // spent ~$231 to buy levered position (0.02 uints)
        call = await FLTest.getBalance(wbtcAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(72374888);  
        call = await FLTest.getBalance(usdaAddress, wallet_5.address);
        position = call.result.expectOk().expectUint(0);            
        // should see change in key token
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(4094610000000);
        // but nothing with yield token
        call = await FLTest.getBalance(yieldusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);         

        // let's test roll-position from margin-helper

        chain.mineEmptyBlockUntil(10000);
        // trying to roll before maturity throws error
        result = FLTest.rollPosition(wallet_5, usdaAddress, wbtcAddress, keyusda23040Address, loanuser51840Address);
        result.expectErr().expectUint(2017);

        // but let's set up new pools
        result = YTPTest.createPool(deployer, expiry, yieldusda51840Address, usdaAddress, ytpyieldusda51840Address, multisigytpyieldusda51840, 500000e+8, 500000e+8);        
        result.expectOk().expectBool(true);
        result = CRPTest.createPool(deployer, usdaAddress, wbtcAddress, yieldusda51840Address, keyusda51840Address, multisigncrpusda51840Address, ltv_0, conversion_ltv, bs_vol, moving_average, 1e+8);
        result.expectOk().expectBool(true);        

        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);
        // roll right after expiry succeeds.
        result = FLTest.rollPosition(wallet_5, usdaAddress, wbtcAddress, keyusda23040Address, loanuser51840Address);
        result.expectOk();

        // key-usda-23040-wbtc should be zero, with non-zero positions in key-usda-51840
        call = await FLTest.getBalance(keyusda23040Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(keyusda51840Address, wallet_5.address);
        position = call.result.expectOk().expectUint(1793499000000);
        // but nothing with yield-usda-51840
        call = await FLTest.getBalance(yieldusda51840Address, wallet_5.address);
        position = call.result.expectOk().expectUint(0);
        
    },    
});
