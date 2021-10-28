
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

const priceMax = 1.5 * ONE_8;
const priceMin = 0.1 * ONE_8;
const price0 = 1 * ONE_8;

const alexQty = 1000 * ONE_8;
const usdaQty = Math.round(price0 * alexQty * (ONE_8 - weightX1) / weightX1 / ONE_8);


Clarinet.test({
    name: "LBP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let LBPTest = new LBPTestAgent(chain, deployer);

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
        position['total-supply'].expectUint(80274141756);
        position['balance-x'].expectUint(alexQty);
        position['balance-y'].expectUint(usdaQty);
        position['weight-x-t'].expectUint(90000000);     

        result = LBPTest.setPoolMultisig(deployer, alexAddress, usdaAddress, expiry, deployer.address);
        result.expectOk();

        result = LBPTest.setPriceRange(deployer, alexAddress, usdaAddress, expiry, priceMin, priceMax);
        result.expectOk();

        call = await LBPTest.getPriceRange(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['min-price'].expectUint(priceMin);
        position['max-price'].expectUint(priceMax);     

        // implied price is 0.995064480178316
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(ONE_8);
        position['dx'].expectUint(100496000);   
        
        // swap triggers change in weight
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(89759760);       

        // half time passed
        chain.mineEmptyBlockUntil(500);

        // no swaps, so weight shouldn't have changed.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(89759760);          
        
        // buy some alex so it doesn't fall below min-price.
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, 30 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(30 * ONE_8);
        position['dx'].expectUint(3613023403);
        
        // after swap, weight now halves.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(50040041);          

        // implied price is now 0.14679128195479
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(ONE_8);
        position['dx'].expectUint(681239367);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(80274141756);
        position['balance-x'].expectUint(95605241230);
        position['balance-y'].expectUint(14311111111);         
        
        // launch not going well, so withdraw liquidity
        result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, poolTokenAddress, 0.5 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(47802620615);
        position['dy'].expectUint(7155555555);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(40137070878);
        position['balance-x'].expectUint(47802620615);
        position['balance-y'].expectUint(7155555556);        

        chain.mineEmptyBlockUntil(998);

        // no trades between blocks 500 and 998, so weight doesn't change, price doesn't change
        // until swap occurs.
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(ONE_8);
        position['dx'].expectUint(678606002);     
        
        // and weight now is at min.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(10160161);     

        // resulting in alex price falling below min-price, throwing error
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectErr().expectUint(2021);

        // all time passed
        chain.mineEmptyBlockUntil(1001);

        // already expired
        call = await LBPTest.getWeightX(alexAddress, usdaAddress, expiry);
        call.result.expectErr().expectUint(2011);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(40137070878);
        position['balance-x'].expectUint(47124014613);
        position['balance-y'].expectUint(7255555556);  

        // withdraw all remaining liquidity
        result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, poolTokenAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(47124014613);
        position['dy'].expectUint(7255555556);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(0);
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(0);             
    },
});

