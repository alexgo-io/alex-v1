

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';  

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const keywbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-usda"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const ltv_0 = 0.8 * ONE_8
const conversion_ltv = 0.95 * ONE_8
const bs_vol = 0.8 * ONE_8
const moving_average = 0.95 * ONE_8

const wbtcPrice = 50000 * ONE_8
const usdaPrice = 1 * ONE_8

const weightX = 0.5 * ONE_8
const weightY = 0.5 * ONE_8

/**
 * Yield Token Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "CRP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"WBTC","nothing",wbtcPrice);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",usdaPrice);
        oracleresult.expectOk()
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcTokenAddress, usdaTokenAddress, testWeightX, testWeightY, fwpwbtcusdaTokenAddress, 10000*ONE_8, 500000000*ONE_8);
        result.expectOk().expectBool(true);

        result = YTPTest.createPool(deployer, yieldwbtcTokenAddress, wbtcTokenAddress, ytpyieldwbtcTokenAddress, 100*ONE_8, 100*ONE_8);        
        
        //Deployer creating a pool, initial tokens injected to the pool
        let result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, yieldwbtc59760Address, keywbtc59760Address, multisigAddress, ltv_0, conversion_ltv, bs_vol, moving_average, 100000*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['yield-supply'].expectUint(1000*ONE_8);
        position['key-supply'].expectUint(0);
        position['balance-x'].expectUint(1000*ONE_8);
        position['balance-y'].expectUint(1000*ONE_8);
        position['weight-x'].expectUint(0.54*ONE_8);
        position['weight-x'].expectUint(0.46*ONE_8);
    },    
});
