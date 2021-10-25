
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    LBPTestAgent,
  } from './models/alex-tests-liquidity-bootstrapping-pool.ts';

import { 
    MS_FWP_WBTC_USDA_5050,
} from './models/alex-tests-multisigs.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';

import { 
    USDAToken,
    ALEXToken,
  } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"

const lbpalexusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lbp-alex-59760-usda"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-lbp-alex-59760-usda"

const ONE_8 = 100000000

const weightX1 = 50000000 //0.5
const weightX2 = 50000000 //0.5

const wbtcPrice = 50000
const usdaPrice = 1
const expiry = 59760 * ONE_8

const wbtcQ = 100*ONE_8


Clarinet.test({
    name: "LBP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let LBPTest = new LBPTestAgent(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = LBPTest.createPool(deployer, alexAddress, usdaAddress, weightX1, weightX2, expiry,lbpalexusdaAddress,multisigAddress,1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2236067605752);
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(wbtcQ*wbtcPrice);

        // // Add extra liquidity (1/4 of initial liquidity)
        // result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        // position = result.expectOk().expectTuple();
        // position['supply'].expectUint(2236067605752 / 4);
        // position['dx'].expectUint(wbtcQ / 4);
        // position['dy'].expectUint(wbtcQ*wbtcPrice / 4);

        // // Check pool details and print
        // call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        // position = call.result.expectOk().expectTuple();
        // position['total-supply'].expectUint(2795084507190);
        // position['balance-x'].expectUint(5/4 * wbtcQ);
        // position['balance-y'].expectUint(5/4 * wbtcQ*wbtcPrice);        

        // // Reduce all liquidlity
        // result = FWPTest.reducePosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, ONE_8);
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(12499622000);
        // position['dy'].expectUint(624981100000000);

        // // Add back some liquidity
        // result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ, wbtcQ*wbtcPrice);
        // position = result.expectOk().expectTuple();
        // position['supply'].expectUint(2235639947089);
        // position['dx'].expectUint(wbtcQ);
        // position['dy'].expectUint(499999999999878);        

        // // attempt to trade too much (> 90%) will be rejected
        // result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 91*ONE_8);
        // position = result.expectErr().expectUint(4001);

        // // swap some wbtc into usda
        // result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8);
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(ONE_8);
        // position['dy'].expectUint(4950462120393);    
        
        // // swap some usda into wbtc
        // result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, wbtcPrice*ONE_8);
        // position = result.expectOk().expectTuple();
        // position['dx'].expectUint(103049813);
        // position['dy'].expectUint(wbtcPrice*ONE_8);        

        // // attempt to swap zero throws an error
        // result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        // result.expectErr().expectUint(2003);    
        // result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        // result.expectErr().expectUint(2003);               
    },
});

