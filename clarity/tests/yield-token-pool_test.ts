

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    YTPTestAgent1,
  } from './models/alex-tests-yield-token-pool.ts';
  

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const yieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760"
const ytpyieldwbtc59760Address = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc"
const multisigytpyieldwbtc59760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-59760-wbtc"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
/**
 * Yield Token Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "YTP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        
        //Deployer creating a pool, initial tokens injected to the pool
        let result = YTPTest.createPool(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, multisigytpyieldwbtc59760, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(yieldwbtc59760Address);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        let listed = 100000000;

        //Add extra liquidity
        result = YTPTest.addToPosition(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, 10*ONE_8);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(yieldwbtc59760Address);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1010*ONE_8);
        position['balance-token'].expectUint(1010*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(1010*ONE_8);        

        // Remove all liquidlity
        result = YTPTest.reducePosition(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, 1*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1010*ONE_8);
        position['dy'].expectUint(0);

        // Add back some liquidity
        result = YTPTest.addToPosition(deployer, yieldwbtc59760Address, wbtcAddress, ytpyieldwbtc59760Address, 1000*ONE_8);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);     
        
        // check t
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(85000000)
        
        // zero actual yield-token, so must throw an error
        result = YTPTest.getYgivenX(deployer, yieldwbtc59760Address, 1*ONE_8);
        result.expectErr().expectUint(2016)
        
        // zero actual yield-token, so yield must be zero
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(0)

        // zero rate environment, so yield-token and token are at parity.
        result = YTPTest.getXgivenY(deployer, yieldwbtc59760Address, 2*ONE_8);
        result.expectOk().expectUint(200212341)

        // sell some yield-token
        result = YTPTest.swapYForX(deployer, yieldwbtc59760Address, wbtcAddress, 2*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(200212341);
        position['dy'].expectUint(2*ONE_8);

        // yield-token now has "actual" balance
        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(99799787659);
        position['balance-aytoken'].expectUint(2*ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);         
            
        // now that yield token supply > token supply, yield is positive.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(400212); // 0.4%

        // buy back some yield token
        result = YTPTest.swapXForY(deployer, yieldwbtc59760Address, wbtcAddress, ONE_8);
        position = result.expectOk().expectTuple()
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(100352095);        

        // attempt to sell more than max allowed yield token (50% of pool) must throw an error
        result = YTPTest.swapYForX(deployer, yieldwbtc59760Address, wbtcAddress, 501*ONE_8);
        position =result.expectErr().expectUint(4002)

        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(99899787659);
        position['balance-aytoken'].expectUint(99647905);
        position['balance-virtual'].expectUint(1000*ONE_8); 

        // after buying back some yield token, yield decreases.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(199860); // 0.2%   

        // we sell close to maximum allowed of yield token
        result = YTPTest.swapYForX(deployer, yieldwbtc59760Address, wbtcAddress, 19*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1927749539);
        position['dy'].expectUint(19*ONE_8);       
                
        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(97972038120);
        position['balance-aytoken'].expectUint(1999647905);
        position['balance-virtual'].expectUint(1000*ONE_8);                 

        // which moves yield substantially into the positive territory.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(4028722); // 4%    
        
        // simulate to be on half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)      
        
        // check t == 0.5
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(50000000)        

        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(97972038120);
        position['balance-aytoken'].expectUint(1999647905);
        position['balance-virtual'].expectUint(1000*ONE_8); 

        // no transaction since then till now, so yield remains the same. Note yield is absolute, not annualised number.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(4028722); // 4%      
        
        // sell some (a lot of) yield-token
        result = YTPTest.swapYForX(deployer, yieldwbtc59760Address, wbtcAddress, 19*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1879746070);
        position['dy'].expectUint(19*ONE_8);

        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(96092292050);
        position['balance-aytoken'].expectUint(1999647905 + 19*ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);         
            
        // and see how it pushes the yield to crazy level.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(7811636); // 78%    

        //buy back some yield token
        result = YTPTest.swapXForY(deployer, yieldwbtc59760Address, wbtcAddress, 19*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(19*ONE_8);
        position['dy'].expectUint(1956741242);      

        // simulate to right before expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) - 1)      
        
        // confirm t is almost zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(1673)

        // no trade between half way and now, so yield should remain the same (again, yield is not annualised).
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(3952408); // 4%      
        
        // buy some yield-token
        result = YTPTest.swapXForY(deployer, yieldwbtc59760Address, wbtcAddress, 19*ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(19*ONE_8);
        position['dy'].expectUint(1900016846);

        // on expiry, the prices are back to parity.
        call = chain.callReadOnlyFn("yield-token-pool", "get-price", 
            [types.principal(yieldwbtc59760Address)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005); // par          

    },    
});
