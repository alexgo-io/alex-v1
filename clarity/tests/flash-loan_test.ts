

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  
import { FLTestAgent1 } from './models/alex-tests-flash-loan.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const keywbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const ytpyieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
const multisigncrpwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-usda"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const multisigytpyieldwbtc59760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-59760-wbtc"
const vaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
const reserveAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-reserve-pool"
const loanuserAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.flash-loan-user-margin-usda-wbtc-59760"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
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
 * Yield Token Pool Test Cases  
 * 
 *  TODO: test shortfall case with reserve-pool
 */

Clarinet.test({
    name: "Flash Loan: create margin trade",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        let FLTest = new FLTestAgent1(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",usdaPrice);
        oracleresult.expectOk()
        
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, wbtcQ, Math.round(wbtcPrice * wbtcQ / ONE_8));
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

        call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(100111426);

        // ltv-0 is 80%, but injecting liquidity pushes up LTV
        call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
        call.result.expectOk().expectUint(80717419);

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
        position['moving-average'].expectUint(moving_average);
        
        // sell some yield-token
        result = YTPTest.swapYForX(wallet_1, yieldwbtc59760Address, wbtcAddress, 0.5*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(52217711);
        position['dy'].expectUint(0.5*ONE_8);

        call = await YTPTest.getPrice(yieldwbtc59760Address);
        call.result.expectOk().expectUint(109095943);

        // remember ltv to be used for margin is:
        // ltv = (.collateral-rebalancing-pool get-ltv) / (.yield-token-pool get-price)
        let ltv:number = 0.739875533226749;
        let margin:number = 2000 * ONE_8;
        let amount:number = Math.round(margin / (1 - ltv));
        let borrow:number = amount - margin;

        call = await FLTest.getBalance(usdaAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(200000000000);
        call = await FLTest.getBalance(wbtcAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(2000052217711);        
        call = await FLTest.getBalance(keywbtc59760Address, wallet_1.address);
        position = call.result.expectOk().expectUint(0);
        call = await FLTest.getBalance(yieldwbtc59760Address, wallet_1.address);
        position = call.result.expectOk().expectUint(1999950000000);

        result = FLTest.executeMarginUsdaWbtc59760(wallet_1, amount);
        result.expectOk();

        result = FLTest.flashLoan(wallet_1, loanuserAddress, usdaAddress, borrow);
        result.expectOk();

        // spent ~$1935 to buy levered position (0.16 uints)
        call = await FLTest.getBalance(usdaAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(6455146405);  
        call = await FLTest.getBalance(wbtcAddress, wallet_1.address);
        position = call.result.expectOk().expectUint(2000052217711);            
        // should see change in key token
        call = await FLTest.getBalance(keywbtc59760Address, wallet_1.address);
        position = call.result.expectOk().expectUint(12347475);
        // but nothing with yield token
        call = await FLTest.getBalance(yieldwbtc59760Address, wallet_1.address);
        position = call.result.expectOk().expectUint(1999950000000);                
    },    
});
