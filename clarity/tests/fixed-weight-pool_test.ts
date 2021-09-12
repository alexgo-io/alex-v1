
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';
  

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"

const ONE_8 = 100000000

const weightX = 50000000 //0.5
const weightY = 50000000 //0.5

const wbtcPrice = 50000
const usdaPrice = 1

const wbtcQ = 100*ONE_8

/**
 * Fixed Weight Pool Test Cases  
 * 
 * 1. Create Pool, Add values to the pool and reduce values.
 * 
 * 2. Conduct Swapping 
 * 
 * 3. Set Platform fees and collecting
 * 
 */

Clarinet.test({
    name: "FWP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigAddress, wbtcQ, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2236067605752);
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(wbtcQ*wbtcPrice);

        // Add extra liquidity (1/4 of initial liquidity)
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(2236067605752 / 4);
        position['dx'].expectUint(wbtcQ / 4);
        position['dy'].expectUint(wbtcQ*wbtcPrice / 4);

        // Check pool details and print
        call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2795084507190);
        position['balance-x'].expectUint(5/4 * wbtcQ);
        position['balance-y'].expectUint(5/4 * wbtcQ*wbtcPrice);        

        // Reduce all liquidlity
        result = FWPTest.reducePosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(5/4 * wbtcQ);
        position['dy'].expectUint(5/4 * wbtcQ * wbtcPrice);

        // Add back some liquidity
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ, wbtcQ*wbtcPrice);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(2236067605752);
        position['dx'].expectUint(wbtcQ);
        position['dy'].expectUint(wbtcQ*wbtcPrice);        

        // attempt to trade too much (> 30%) will be rejected
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 50*ONE_8);
        position = result.expectErr().expectUint(4001);

        // swap some wbtc into usda
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(4950465000000);    
        
        // swap some usda into wbtc
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, wbtcPrice*ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(103049997);
        position['dy'].expectUint(wbtcPrice*ONE_8);        

        // attempt to swap zero throws an error
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        result.expectErr().expectUint(2003);    
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        result.expectErr().expectUint(2003);               
    },
});