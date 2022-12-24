
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.34.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.166.0/testing/asserts.ts';

import { SSPTestAgent1 } from './models/alex-tests-stable-swap-pool.ts';
import { 
    USDAToken,
    WBTCToken,
    WXUSDToken
  } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = ".token-wbtc"
const usdaAddress = ".token-wusda"
const wxusdAddress = ".token-wxusd"
const fwpwstxusdaAddress = ".fwp-wstx-usda-50-50-v1-01"
const fwpwstxwbtcAddress = ".fwp-wstx-wbtc-50-50-v1-01"
const daoAddress = ".executor-dao"

const factor = 0.0001e8; // the smaller, the lower the slippage
const balance = 10e8;

Clarinet.test({
    name: "stable-swap-pool : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let SSPTest = new SSPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let wxusdToken = new WXUSDToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000e8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000e8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000e8);
        result.expectOk();
        result = wxusdToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();
        result = wxusdToken.mintFixed(deployer, wallet_1.address, 200000e8);
        result.expectOk();      
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, deployer.address + fwpwstxusdaAddress, deployer.address + daoAddress, balance, balance);
        result.expectOk().expectBool(true);
        result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, deployer.address + fwpwstxwbtcAddress, deployer.address + daoAddress, balance, balance);
        result.expectOk().expectBool(true);

        result = SSPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = SSPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);    
        result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 0);   
        result.expectOk().expectBool(true);     
        result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, 0);   
        result.expectOk().expectBool(true);                

        let call :any= chain.callReadOnlyFn("stable-swap-pool", "get-token-given-position",
        [
          types.principal(deployer.address + wxusdAddress),
          types.principal(deployer.address + wbtcAddress),
          types.uint(factor),
          types.uint(balance),
          types.none()
        ], wallet_1.address);  
        const initial_supply = call.result.expectOk().expectTuple().token.replace(/\D/g, "");

        // Check pool details and print
        call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor);
        let position:any = call.result.expectOk().expectTuple();        

        position['total-supply'].expectUint(initial_supply);
        position['balance-x'].expectUint(balance);
        position['balance-y'].expectUint(balance);

        // Add extra liquidity (1/4 of initial liquidity)
        result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, deployer.address + fwpwstxwbtcAddress, balance / 4, balance / 4);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(Math.round(initial_supply / 4));
        position['dy'].expectUint(balance / 4);
        position['dx'].expectUint(balance / 4);

        // Check pool details and print
        call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(Math.round(5/4 * initial_supply));
        position['balance-y'].expectUint(5/4 * balance);
        position['balance-x'].expectUint(5/4 * balance);        

        // Reduce all liquidlity
        result = SSPTest.reducePosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, deployer.address + fwpwstxwbtcAddress, 1e8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(5/4 * balance);
        position['dx'].expectUint(5/4 * balance);

        // Add back some liquidity
        result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, deployer.address + fwpwstxwbtcAddress, balance, balance);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(initial_supply);
        position['dy'].expectUint(balance);
        position['dx'].expectUint(balance);        

        // attempt to trade too much (> 90%) will be rejected
        result = SSPTest.swapXForY(deployer, deployer.address + wbtcAddress, deployer.address + usdaAddress, factor, 91*1e8, 0);
        position = result.expectErr().expectUint(4001);

        // swap some wbtc into usda
        result = SSPTest.swapXForY(deployer, deployer.address + wbtcAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(1e8);
        position['dy'].expectUint(99799847);    
        
        // swap some usda into wbtc
        result = SSPTest.swapYForX(deployer, deployer.address + wbtcAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(100199803);
        position['dy'].expectUint(1e8);        

        // attempt to swap zero throws an error
        result = SSPTest.swapYForX(deployer, deployer.address + wbtcAddress, deployer.address + usdaAddress, factor, 0, 0);
        result.expectErr().expectUint(2003);    
        result = SSPTest.swapXForY(deployer, deployer.address + wbtcAddress, deployer.address + usdaAddress, factor, 0, 0);
        result.expectErr().expectUint(2003);               
    },
});

Clarinet.test({
    name: "stable-swap-pool : testing get-x-given-price and get-y-given-price",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let SSPTest = new SSPTestAgent1(chain, deployer);     
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let wxusdToken = new WXUSDToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000e8);
        result.expectOk();
        result = wxusdToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();                 

        result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, deployer.address + fwpwstxusdaAddress, deployer.address + daoAddress, balance, balance);
        result.expectOk().expectBool(true);

        result = SSPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = SSPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);      
        result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 0);   
        result.expectOk().expectBool(true);                  

        // Check pool details and print
        let call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(balance);
        position['balance-y'].expectUint(balance);      
        
        // let's do some arb
        const PT = 1.003e8; 
        const decimals = 3;
        call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, PT);
        const yToSell = Number(call.result.expectOk().replace(/\D/g, ""));
        result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, yToSell, 0)
        position = result.expectOk().expectTuple();

        // now pool price implies PT
        call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor);
        position = call.result.expectOk().expectTuple();
        const newBalX = position['balance-x'].replace(/\D/g, "");
        const newBalY = position['balance-y'].replace(/\D/g, "");
        assertEquals(Math.round((newBalY / newBalX) ** (factor / 1e8) * (10 ** decimals)) * 1e8 / (10 ** decimals), PT);  
        
        // let's do some arb
        const newPT = 0.999e8;    
        // but calling get-y-given-price throws an error
        call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
        call.result.expectErr().expectUint(2002);
        // we need to call get-x-given-price
        call = await SSPTest.getXgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
        const xToSell = Number(call.result.expectOk().replace(/\D/g, ""));
        result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, xToSell, 0)
        position = result.expectOk().expectTuple();
        
        call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor);
        position = call.result.expectOk().expectTuple();
        const newBalX2 = position['balance-x'].replace(/\D/g, "");
        const newBalY2 = position['balance-y'].replace(/\D/g, "");
        assertEquals(Math.round((newBalY2 / newBalX2) ** (factor / 1e8) * (10 ** decimals)) * 1e8 / (10 ** decimals), newPT);         
    },
});          
        

Clarinet.test({
    name: "stable-swap-pool : check start-block and end-block",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let SSPTest = new SSPTestAgent1(chain, deployer);     
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let wxusdToken = new WXUSDToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000e8);
        result.expectOk();     
        result = wxusdToken.mintFixed(deployer, deployer.address, 100000000e8);
        result.expectOk();                      

        result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, deployer.address + fwpwstxusdaAddress, deployer.address + daoAddress, balance, balance);
        result.expectOk().expectBool(true);

        result = SSPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = SSPTest.setMaxOutRatio(deployer, 0.3e8);        
        result.expectOk().expectBool(true);

        const startBlock = 100;
        result = SSPTest.setStartBlock(wallet_1, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, startBlock);
        result.expectErr().expectUint(1000);        
        result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, startBlock);
        result.expectOk().expectBool(true);
        
        result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectErr().expectUint(1000);
        result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectErr().expectUint(1000);        

        chain.mineEmptyBlockUntil(startBlock);

        result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectOk().expectTuple();
        result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectOk().expectTuple();        

        const endBlock = 200;
        result = SSPTest.setEndBlock(wallet_1, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, endBlock);
        result.expectErr().expectUint(1000);        
        result = SSPTest.setEndBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, endBlock);
        result.expectOk().expectBool(true);

        chain.mineEmptyBlockUntil(endBlock + 1);

        result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectErr().expectUint(1000);
        result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
        result.expectErr().expectUint(1000);        
        
    },       
});       
