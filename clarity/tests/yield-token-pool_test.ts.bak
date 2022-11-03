

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';
import { YTPTestAgent1, } from './models/alex-tests-yield-token-pool.ts';
import { MS_YTP_YIELD_WBTC } from './models/alex-tests-multisigs.ts';
import { USDAToken, WBTCToken, YIELD_WBTC, YTP_YIELD_WBTC, SemiFungibleToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const yieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc"
const ytpyieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc"
const multisigytpyieldwbtc = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc"
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"

const ONE_8 = 100000000
const expiry = 59761
const wrongExpiry = 70000
const anotherExpiry = 80875

/**
 * Yield Token Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "yield-token-pool : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        const block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        let listed = 1;

        //Add extra liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1010*ONE_8);
        position['balance-token'].expectUint(1010*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1010*ONE_8);        
        
        // Remove all liquidlity
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1010*ONE_8);
        position['dy'].expectUint(0);
        
        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(0);
        position['balance-token'].expectUint(0);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(0);          

        // Add back some liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1000*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);     
        
        // check t
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(28418133)
        
        // zero actual yield-token, so must throw an error
        call = await YTPTest.getYgivenX(expiry, yieldwbtcAddress, 1*ONE_8);
        call.result.expectErr().expectUint(2016)
        
        // zero actual yield-token, so yield must be zero
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(5)

        // zero rate environment, so yield-token and token are (almost) at parity.
        call = await YTPTest.getXgivenY(expiry, yieldwbtcAddress, 2*ONE_8);
        call.result.expectOk().expectUint(199872507)

        // sell some yield-token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 2*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(199872507);
        position['dy'].expectUint(2*ONE_8);

        // yield-token now has "actual" balance
        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8 - 199872507);
        position['balance-yield-token'].expectUint(2*ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);         
            
        // now that yield token supply > token supply, yield is positive.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(113709);

        // buy back some yield token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position = result.expectOk().expectTuple()
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(100071173);        

        // attempt to sell more than max allowed yield token (50% of pool) must throw an error
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 501*ONE_8, 0);
        position =result.expectErr().expectUint(4001)

        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8 - 199872507 + ONE_8);
        position['balance-yield-token'].expectUint(2*ONE_8 - 100071173);
        position['balance-virtual'].expectUint(1000*ONE_8); 

        // after buying back some yield token, yield decreases.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(56801);

        // we sell close to maximum allowed of yield token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 29*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(2874654665);
        position['dy'].expectUint(29*ONE_8);                      

        // which moves yield substantially into the positive territory.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(1712580);   
        
        // simulate to be on half way to expiry
        chain.mineEmptyBlockUntil(Math.floor(expiry / 2) + 1);
        
        // check t == 0.5
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(14212396)

        // about half way, so yield should halve, just like zero coupon bond gets closer to par
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(852916);
        
        // sell some (a lot of) yield-token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 40*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(3943802321);
        position['dy'].expectUint(40*ONE_8);       
            
        // and see how it pushes the yield pretty high
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(2000275);   

        //buy back some yield token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 40*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(40*ONE_8);
        position['dy'].expectUint(4056653604);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(100000000000);
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(100000000000);   

        // Remove some liquidlity
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0.5*ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(48540835253);
        position['dy'].expectUint(1471637429);  
        
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(50000000000);
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(50000000000);   
        
        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(998528362206);        

        // Add back some liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1000*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(103006056000);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(3031751349);
        position['balance-virtual'].expectUint(103006056376);    
        
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(50000000000 + 103006056000);
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(50000000000 + 103006056000);

        // simulate to right before expiry
        chain.mineEmptyBlockUntil(expiry - 1);  
        
        // confirm t is almost zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(475)

        // nearly maturity, so yield should be close to zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(33);    
        
        // buy some yield-token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 19*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(19*ONE_8);
        position['dy'].expectUint(1900000000);

        // on expiry, the prices are back to parity.
        call = chain.callReadOnlyFn("yield-token-pool", "get-price", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005); // par       
        
        // simulate to after expiry
        chain.mineEmptyBlockUntil(expiry + 1);

        // on expiry, the prices are back to parity.
        call = chain.callReadOnlyFn("yield-token-pool", "get-price", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005); // par    
        
        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(50000000000 + 103006056000);
        position['balance-token'].expectUint(150440835254);
        position['balance-yield-token'].expectUint(2603389143);
        position['balance-virtual'].expectUint(153006056194);          
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(50000000000 + 103006056000);        

        // Remove all liquidlity
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(150440835254);
        position['dy'].expectUint(2603388035);        

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(0);
        position['balance-token'].expectUint(0);
        position['balance-yield-token'].expectUint(1108);
        position['balance-virtual'].expectUint(0);    
    },    
});

Clarinet.test({
    name: "yield-token-pool : trait check",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();

        //if non-deployer attempts to create a pool, throw an error.
        result = YTPTest.createPool(wallet_1, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectErr().expectUint(1000);

        const block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();        

        //if wrong pool token is supplied, then throw an error
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, wrongPooltokenAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        result.expectErr().expectUint(2026);

        // non-deployer can add liquidity
        result = YTPTest.addToPosition(wallet_1, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        result.expectOk();
        
        //if wrong pool token is supplied, throw an error
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, wrongPooltokenAddress, ONE_8);
        result.expectErr().expectUint(2026);        
        
    }
})

Clarinet.test({
    name: "yield-token-pool : get-x-given-price/yield, get-y-given-price/yield",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);        
        
        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        const block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });        

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);
        position['listed'].expectUint(10);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(5);
        
        // if current yield < target yield, then supply of yield-token needs to increase
        call = await YTPTest.getXgivenYield(expiry, yieldwbtcAddress, 0.01*ONE_8);
        call.result.expectErr().expectUint(2002);
        call = await YTPTest.getYgivenYield(expiry, yieldwbtcAddress, 0.01*ONE_8);          
        call.result.expectOk().expectUint(1746080000);

        // confirm t is almost zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(4)
            ], deployer.address);
        call.result.expectOk().expectUint(28419966)

        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 1745954000, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(1745954000);
        position['dx'].expectUint(1737321161);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(994936);

        // now let's try to reduce the yield
        call = await YTPTest.getYgivenYield(expiry, yieldwbtcAddress, 0.005*ONE_8);                  
        call.result.expectErr().expectUint(2002);
        call = await YTPTest.getXgivenYield(expiry, yieldwbtcAddress, 0.005*ONE_8);        
        call.result.expectOk().expectUint(860965800);      
        
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 861028697, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(867458569);
        position['dx'].expectUint(861028697);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(499965);

    },    
});

Clarinet.test({
    name: "yield-token-pool : fee setting using multisig ",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_2 = accounts.get("wallet_2")!;
        let contractOwner = accounts.get("deployer")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let MultiSigTest = new MS_YTP_YIELD_WBTC(chain, deployer);
        let ytpPoolToken = new YTP_YIELD_WBTC(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = wbtcToken.mintFixed(deployer, wallet_2.address, 10 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);
        result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();   
        result = usdaToken.mintFixed(deployer, wallet_2.address, 1000 * ONE_8);
        result.expectOk();      

        const feeRateX = 0.1*ONE_8; // 10%
        const feeRateY = 0.1*ONE_8;
        const feeRebate = 0.5*ONE_8;

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        const block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });        

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        result = YTPTest.addToPosition(wallet_2, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);   

        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(1000000000000);    
        call = chain.callReadOnlyFn(wbtcAddress, "get-balance-fixed", 
            [types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(9900000000000); 
        call = chain.callReadOnlyFn(wbtcAddress, "get-balance-fixed", 
            [types.principal(deployer.address + ".alex-vault")
            ], deployer.address);
        call.result.expectOk().expectUint(101000000000);           

        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(99955114);
        position['dy'].expectUint(ONE_8);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8 + 10*ONE_8 - 99955114);
        position['balance-yield-token'].expectUint(ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8 + 10*ONE_8);

        call = await ytpPoolToken.balanceOf(expiry, deployer.address);
        call.result.expectOk().expectUint(1000*ONE_8);    // u100000000000

        call = await ytpPoolToken.balanceOf(expiry, wallet_2.address);
        call.result.expectOk().expectUint(10*ONE_8);

        // Fee rate Setting Proposal of Multisig
        result = MultiSigTest.propose(expiry, 1000, " Fee Rate Setting to 10%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        // Deployer has 99 % of pool token
        let ROresult:any = ytpPoolToken.balanceOf(expiry, deployer.address);
        ROresult.result.expectOk().expectUint(1000*ONE_8);
        
        // Wallet_2 votes his 90% asset
        result = MultiSigTest.voteFor(wallet_2, ytpyieldwbtcAddress, 1, 1000000000 * 9 / 10 )
        result.expectOk().expectUint(900000000)

        // 90 % of existing tokens are voted for the proposal
        result = MultiSigTest.voteFor(deployer, ytpyieldwbtcAddress, 1, 100000000000 * 9 / 10 )
        result.expectOk().expectUint(90000000000)

        chain.mineEmptyBlock(1440);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true) // Success 
        
        // deployer (Contract owner) sets rebate rate
        result = YTPTest.setFeeRebate(contractOwner, expiry, yieldwbtcAddress, feeRebate);
        result.expectOk().expectBool(true)

        // Fee checking
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-yield-token'].expectUint(100000000);
        position['balance-token'].expectUint(1000*ONE_8 + 10*ONE_8 - 99955114);
        position['balance-virtual'].expectUint(1000*ONE_8 + 10*ONE_8);
        position['fee-rate-yield-token'].expectUint(0.1*ONE_8);
        position['fee-rate-token'].expectUint(0.1*ONE_8);
        position['fee-rebate'].expectUint(0.5*ONE_8);
    },    
});

Clarinet.test({
    name: "yield-token-pool : error test cases ",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_2 = accounts.get("wallet_2")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);
        result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_2.address, 10 * ONE_8);
        result.expectOk();  
        result = usdaToken.mintFixed(deployer, wallet_2.address, 1000 * ONE_8);
        result.expectOk();         

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        let block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });        

        // Duplicated Pool 
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectErr().expectUint(2000);   

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);
        
        // Attempts to inject zero liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0, Number.MAX_SAFE_INTEGER);
        position = result.expectErr().expectUint(2003)

        //Attempt to add extra liquidity but not enough balance
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1000000*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectErr().expectUint(3000)

        // Attempts for trivial reducing
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0);
        position =result.expectErr().expectUint(1)

        // Attempts for trivial reduce more than 100%
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 101*ONE_8);
        position =result.expectErr().expectUint(5000)

        // Another user attempts to reduce liquidity with not enough pool token 
        result = YTPTest.reducePosition(wallet_2, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1*ONE_8);
        position =result.expectErr().expectUint(1)

        // Deployer adds liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1000*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);     

        // Another User adds liquidity
        result = YTPTest.addToPosition(wallet_2, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);     

        // Another user attempts to reduce liquidity with zero value
        result = YTPTest.reducePosition(wallet_2, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0);
        position =result.expectErr().expectUint(1)

        // False swap value -- Filter added
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0, 0);
        position =result.expectErr().expectUint(2003)
        
        // Too small => < max-slippage
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0.00000001 * ONE_8, 0);
        position =result.expectErr().expectUint(2020);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(5);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(2010*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(2010*ONE_8);        

        // Fixed
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0.001 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(92014);
        position['dy'].expectUint(0.001 * ONE_8);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(2010*ONE_8 - 92014);
        position['balance-yield-token'].expectUint(0.001 * ONE_8);
        position['balance-virtual'].expectUint(2010*ONE_8);      

        // Attempt for Swapping
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(99968309);
        position['dy'].expectUint(ONE_8);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(28304);        

        // Attempts for zero value swapping
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0, 0);
        position =result.expectErr().expectUint(2003)

        // Attempts to swap more than available balance in the pool
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 100*ONE_8, 0);
        position =result.expectErr().expectUint(2016) 

        // Swap
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(100000000);

    },    
});

Clarinet.test({
    name: "yield-token-pool : buy-and-add-to-position",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);        

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        const block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });        

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(997157822);
        position['dy'].expectUint(10 * ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 997157822);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);  

        let listed = Number((position['listed'].replace(/\D/g, "")));        

        // make sure wallet_1 does not have any yield-token
        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance", 
            [types.uint(expiry), types.principal(wallet_1.address)
            ], wallet_1.address);
        call.result.expectOk().expectUint(0);            
        
        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(569228); 

        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
        [types.uint(expiry),
         types.uint(listed)
        ], deployer.address);
        call.result.expectOk().expectUint(28420301);

        //Add extra liquidity with secondary buying of yield-token
        result = YTPTest.buyAndAddToPosition(wallet_1, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(999761000);
        position['balance-token'].expectUint(989893318);
        position['balance-yield-token'].expectUint(9896124);
        position['balance-virtual'].expectUint(999761006);        

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(563427); 

        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance", 
            [types.uint(expiry), types.principal(wallet_1.address)
            ], wallet_1.address);
        call.result.expectOk().expectUint(254272);           
    }
});

Clarinet.test({
    name: "yield-token-pool : roll-position",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let yieldWBTC = new YIELD_WBTC(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens
        let result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk(); 
        result = yieldWBTC.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);      
        result = yieldWBTC.mintFixed(deployer, anotherExpiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);     

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple();

        let block = chain.mineBlock(
            [
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldwbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(wbtcAddress)], deployer.address),
                Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpyieldwbtcAddress)], deployer.address),
            ]
        );
        block.receipts.forEach(e => { e.result.expectOk() });        

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(997162661);
        position['dy'].expectUint(10 * ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 997162661);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);  

        // make sure wallet_1 does not have any yield-token
        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance", 
            [types.uint(expiry), types.principal(wallet_1.address)
            ], wallet_1.address);
        call.result.expectOk().expectUint(0);     
        
        // create another ytp
        result = YTPTest.createPool(deployer, anotherExpiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectTuple(); 

        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, anotherExpiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(996157142);
        position['dy'].expectUint(10 * ONE_8);     
        
        call = await YTPTest.getPoolDetails(anotherExpiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 996157142);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);          
        
        //Add extra liquidity with secondary buying of yield-token
        result = YTPTest.rollPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0.5*ONE_8, anotherExpiry);
        position = result.expectOk().expectTuple();     
    }
});

Clarinet.test({
    name: "yield-token : get-token-balance-owned works",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let YTPTest = new YTPTestAgent1(chain, deployer);
        let yieldToken = new SemiFungibleToken(chain, deployer, "yield-alex-v1");
        
        let call = yieldToken.getTokenBalanceOwned(deployer.address);
        assertEquals(call.result.expectList().length, 0);

        let result = yieldToken.mintFixed(deployer, expiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);      
        result = yieldToken.mintFixed(deployer, anotherExpiry, 10000 * ONE_8, deployer.address);
        result.expectOk().expectBool(true);  
        call = yieldToken.getTokenBalanceOwned(deployer.address);
        assertEquals(call.result.expectList().length, 2);
        
    }
});