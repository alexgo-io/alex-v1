
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { LBPTestAgent } from './models/alex-tests-liquidity-bootstrapping-pool.ts';

// Deployer Address Constants
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const poolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lbp-alex-usda-90-10"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-lbp-alex-usda-90-10"

const ONE_8 = 1e+8;

const weightX1 = 0.9 * ONE_8;
const weightX2 = 0.1 * ONE_8;
const expiry = 1000 * ONE_8;

const priceMax = 1 * ONE_8;
const priceMin = 0.2 * ONE_8;

const alexQty = 10000 * ONE_8;
const usdaQty = Math.round(priceMax * alexQty * (ONE_8 - weightX1) / weightX1 / ONE_8);


Clarinet.test({
    name: "LBP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let LBPTest = new LBPTestAgent(chain, deployer);

        console.log('alex qty: ', alexQty / ONE_8, 'usda qty: ', usdaQty / ONE_8);

        let call = chain.callReadOnlyFn("token-alex", "get-balance", 
            [types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(10000 * ONE_8);         
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = LBPTest.createPool(deployer, alexAddress, usdaAddress, weightX1, weightX2, expiry, poolTokenAddress, multisigAddress, alexQty, usdaQty);
        result.expectOk().expectBool(true);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(802741422430);
        position['balance-x'].expectUint(alexQty);
        position['balance-y'].expectUint(usdaQty);

        result = LBPTest.setPoolMultisig(deployer, alexAddress, usdaAddress, expiry, deployer.address);
        result.expectOk();
        
        result = LBPTest.setPriceRange(deployer, alexAddress, usdaAddress, expiry, priceMin, priceMax);
        result.expectOk();

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

