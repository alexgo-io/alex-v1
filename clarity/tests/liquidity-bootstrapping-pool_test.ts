
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { LBPTestAgent } from './models/alex-tests-liquidity-bootstrapping-pool.ts';
import { USDAToken, ALEXToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token"
const poolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lbp-alex-usda-90-10"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-lbp-alex-usda-90-10"
const wrongPoolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50"

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
    name: "LBP : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let LBPTest = new LBPTestAgent(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let alexToken = new ALEXToken(chain, deployer);

        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();        
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = LBPTest.createPool(deployer, alexAddress, usdaAddress, weightX1, weightX2, expiry, poolTokenAddress, multisigAddress, priceMin, priceMax, alexQty, usdaQty);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(80274141756);
        position['balance-x'].expectUint(alexQty);
        position['balance-y'].expectUint(usdaQty);
        position['weight-x-t'].expectUint(90000000);     

        chain.mineEmptyBlock(2);

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
        position['weight-x-t'].expectUint(89759279);       

        // half time passed
        chain.mineEmptyBlockUntil(500);

        // no swaps, so weight shouldn't have changed.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(89759279);          
        
        // buy some alex so it doesn't fall below min-price.
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, 30 * ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(30 * ONE_8);
        position['dx'].expectUint(3613216209);
        
        // after swap, weight now halves.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(50120362);          

        // implied price is now 0.14679128195479
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(ONE_8);
        position['dx'].expectUint(679045564);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(80274141756);
        position['balance-x'].expectUint(95607242227);
        position['balance-y'].expectUint(14311111111);         
        
        // launch not going well, so withdraw liquidity
        result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, poolTokenAddress, 0.5 * ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(47803621113);
        position['dy'].expectUint(7155555555);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(40137070878);
        position['balance-x'].expectUint(47803621114);
        position['balance-y'].expectUint(7155555556);        

        chain.mineEmptyBlockUntil(998);

        // no trades between blocks 500 and 998, so weight doesn't change, price doesn't change
        // until swap occurs.
        result = LBPTest.swapYForX(deployer, alexAddress, usdaAddress, expiry, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(ONE_8);
        position['dx'].expectUint(676432711);     
        
        // and weight now is at min.
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['weight-x-t'].expectUint(10160482);     

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
        position['balance-x'].expectUint(47127188403);
        position['balance-y'].expectUint(7255555556);  

        // withdraw all remaining liquidity
        result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, poolTokenAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(47127188403);
        position['dy'].expectUint(7255555556);

        // Check pool details and print
        call = await LBPTest.getPoolDetails(alexAddress, usdaAddress, expiry);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(0);
        position['balance-x'].expectUint(0);
        position['balance-y'].expectUint(0);             
    },
});

Clarinet.test({
  name: "LBP : trait check",

  async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet_1 = accounts.get("wallet_1")!;
      let LBPTest = new LBPTestAgent(chain, deployer);    
      let usdaToken = new USDAToken(chain, deployer);
      let alexToken = new ALEXToken(chain, deployer);

      let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
      result.expectOk();
      result = alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
      result.expectOk();       
      
      // non-deployer creating a pool will throw an error
      result = LBPTest.createPool(wallet_1, alexAddress, usdaAddress, weightX1, weightX2, expiry, poolTokenAddress, multisigAddress, 0, 0, alexQty, usdaQty);
      result.expectErr().expectUint(1000);

      // Deployer creating a pool, initial tokens injected to the pool
      result = LBPTest.createPool(deployer, alexAddress, usdaAddress, weightX1, weightX2, expiry, poolTokenAddress, multisigAddress, 0, 0, alexQty, usdaQty);
      result.expectOk().expectBool(true);

      // all time passed
      chain.mineEmptyBlockUntil(1001);

      // supplying a wrong pool token throws an error
      result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, wrongPoolTokenAddress, ONE_8);
      result.expectErr().expectUint(2026);
      
      // withdraw all remaining liquidity
      result = LBPTest.reducePosition(deployer, alexAddress, usdaAddress, expiry, poolTokenAddress, ONE_8);
      result.expectOk();           
  },
});

