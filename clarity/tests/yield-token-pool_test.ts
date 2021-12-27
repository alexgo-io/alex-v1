

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { YTPTestAgent1, } from './models/alex-tests-yield-token-pool.ts';

import { MS_YTP_YIELD_WBTC } from './models/alex-tests-multisigs.ts';

import { USDAToken, WBTCToken, YIELD_WBTC, YTP_YIELD_WBTC } from './models/alex-tests-tokens.ts';


// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const yieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc"
const ytpyieldwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc"
const multisigytpyieldwbtc = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc"
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-usda"

const ONE_8 = 100000000
const expiry = 59760 * ONE_8
const wrongExpiry = 70000 * ONE_8
const anotherExpiry = 80875 * ONE_8

/**
 * Yield Token Pool Test Cases  
 * 
 */

Clarinet.test({
    name: "YTP : pool creation, adding values and reducing values",

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
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        let listed = 100000000;

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
        call.result.expectOk().expectUint(710521)
        
        // zero actual yield-token, so must throw an error
        call = await YTPTest.getYgivenX(expiry, yieldwbtcAddress, 1*ONE_8);
        call.result.expectErr().expectUint(2016)
        
        // zero actual yield-token, so yield must be zero
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(5)

        // zero rate environment, so yield-token and token are at parity.
        call = await YTPTest.getXgivenY(expiry, yieldwbtcAddress, 2*ONE_8);
        call.result.expectOk().expectUint(199971366)

        // sell some yield-token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 2*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(199971366);
        position['dy'].expectUint(2*ONE_8);

        // yield-token now has "actual" balance
        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(99800028634);
        position['balance-yield-token'].expectUint(2*ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);         
            
        // now that yield token supply > token supply, yield is positive.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(2847);

        // buy back some yield token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position = result.expectOk().expectTuple()
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(100028858);        

        // attempt to sell more than max allowed yield token (50% of pool) must throw an error
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 501*ONE_8, 0);
        position =result.expectErr().expectUint(4002)

        call = chain.callReadOnlyFn("yield-token-pool", "get-pool-details", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(99900028634);
        position['balance-yield-token'].expectUint(99971142);
        position['balance-virtual'].expectUint(1000*ONE_8); 

        // after buying back some yield token, yield decreases.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(1426);

        // we sell close to maximum allowed of yield token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 29*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(2900528265);
        position['dy'].expectUint(29*ONE_8);                      

        // which moves yield substantially into the positive territory.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(42659);   
        
        // simulate to be on half way to expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) / 2)      
        
        // check t == 0.5
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(355308)

        // about half way, so yield should halve, just like zero coupon bond gets closer to par
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(21334);
        
        // sell some (a lot of) yield-token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 100*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(10001386469);
        position['dy'].expectUint(100*ONE_8);       
            
        // and see how it pushes the yield pretty high
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(92959);   

        //buy back some yield token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 100*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(100*ONE_8);
        position['dy'].expectUint(10005727560);

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
        position['dx'].expectUint(48499056950);
        position['dy'].expectUint(1497121749);  
        
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
        call.result.expectOk().expectUint(998502878167);        

        // Add back some liquidity
        result = YTPTest.addToPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 1000*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(103094788000);
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(3086908988);
        position['balance-virtual'].expectUint(103094788085);    
        
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(50000000000 + 103094788000);
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(50000000000 + 103094788000);

        // simulate to right before expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) - 1);  
        
        // confirm t is almost zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-t", 
            [types.uint(expiry),
             types.uint(listed)
            ], deployer.address);
        call.result.expectOk().expectUint(11)

        // nearly maturity, so yield should be close to zero.
        call = chain.callReadOnlyFn("yield-token-pool", "get-yield", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(5);    
        
        // buy some yield-token
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 19*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(19*ONE_8);
        position['dy'].expectUint(1900033901);

        // on expiry, the prices are back to parity.
        call = chain.callReadOnlyFn("yield-token-pool", "get-price", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005); // par       
        
        // simulate to after expiry
        chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);

        // on expiry, the prices are back to parity.
        call = chain.callReadOnlyFn("yield-token-pool", "get-price", 
            [types.uint(expiry), types.principal(yieldwbtcAddress)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005); // par    
        
        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(153094788000);
        position['balance-token'].expectUint(150399056950);
        position['balance-yield-token'].expectUint(2683996920);
        position['balance-virtual'].expectUint(153094788043);          
        
        call = chain.callReadOnlyFn(ytpyieldwbtcAddress, "get-balance-fixed", 
            [types.uint(expiry), types.principal(deployer.address)
            ], deployer.address);
        call.result.expectOk().expectUint(153094788000);        

        // Remove all liquidlity
        result = YTPTest.reducePosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, ONE_8);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(150399056950);
        position['dy'].expectUint(2683996806);        

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(0);
        position['balance-token'].expectUint(0);
        position['balance-yield-token'].expectUint(114);
        position['balance-virtual'].expectUint(0);    
    },    
});

Clarinet.test({
    name: "YTP : trait check",

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

        //Deployer creating a pool, initial tokens injected to the pool
        result = YTPTest.createPool(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);        

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
    name: "YTP : get-x-given-price/yield, get-y-given-price/yield",

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
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(5);
        
        // if current yield < target yield, then supply of yield-token needs to increase
        call = await YTPTest.getXgivenYield(expiry, yieldwbtcAddress, 0.001*ONE_8);
        call.result.expectErr().expectUint(2002);
        call = await YTPTest.getYgivenYield(expiry, yieldwbtcAddress, 0.001*ONE_8);          
        call.result.expectOk().expectUint(7020011000);

        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 7020011000, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(7020011000);
        position['dx'].expectUint(7023489240);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(100006);

        // now let's try to reduce the yield
        call = await YTPTest.getYgivenYield(expiry, yieldwbtcAddress, 0.0005*ONE_8);                  
        call.result.expectErr().expectUint(2002);
        call = await YTPTest.getXgivenYield(expiry, yieldwbtcAddress, 0.0005*ONE_8);        
        call.result.expectOk().expectUint(3504541306);      
        
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 3504541306, 0);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(3507192811);
        position['dx'].expectUint(3504541306);

        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(50003);

    },    
});

Clarinet.test({
    name: "YTP : fee setting using multisig ",

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
        result.expectOk().expectBool(true);

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
        position['dx'].expectUint(99973386);
        position['dy'].expectUint(ONE_8);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(100900026614);
        position['balance-yield-token'].expectUint(ONE_8);
        position['balance-virtual'].expectUint(1010*ONE_8);

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
        position['balance-token'].expectUint(100900026614);
        position['balance-virtual'].expectUint(101000000000);
        position['fee-rate-yield-token'].expectUint(0.1*ONE_8);
        position['fee-rate-token'].expectUint(0.1*ONE_8);
        position['fee-rebate'].expectUint(0.5*ONE_8);
        
        call = await YTPTest.getYield(expiry, yieldwbtcAddress);
        call.result.expectOk().expectUint(1355);

        // fee-yield = yield * fee-rate-token = 1355 * 0.1*ONE_8 = 135 (round-down) // (contract-call? .math-fixed-point mul-down 1335 u10000000)
        // lambda = ONE_8 - fee-yield = ONE_8 - 135 = 9999865 (non-floating point)
        // dy-net-fees = dy * lambda = 199999730    // (contract-call? .math-fixed-point mul-down u99999867 u200000000)
        // fee = dy - dy-net-fess = 200000000 - 199999730 = 270
        // fee-rebate = 270 * 0.5 = 135
        
        // sell some yield-token
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 2*ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(199972901);
        position['dy'].expectUint(199999730);

        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['balance-yield-token'].expectUint(100000000 + 199999730 + 135); //before + after + fee-rebate
        position['balance-token'].expectUint(100900026614 - 199972901);
        position['balance-virtual'].expectUint(101000000000);
    },    
});

Clarinet.test({
    name: "YTP : error test cases ",

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
        result.expectOk().expectBool(true);

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
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0.0000001 * ONE_8, 0);
        position =result.expectErr().expectUint(2020);

        // Fixed
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0.001 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(34327);
        position['dy'].expectUint(0.001 * ONE_8);

        // Attempt for Swapping
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(99946497);
        position['dy'].expectUint(ONE_8);

        // Attempts for zero value swapping
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0, 0);
        position =result.expectErr().expectUint(2003)

        // Attempts to swap more than available balance in the pool
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 100*ONE_8, 0);
        position =result.expectErr().expectUint(2016) 

        // Swap
        result = YTPTest.swapXForY(deployer, expiry, yieldwbtcAddress, wbtcAddress, 0.1 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(0.1 * ONE_8);
        position['dy'].expectUint(10047818);

    },    
});

Clarinet.test({
    name: "YTP : buy-and-add-to-position",

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
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1000041873);
        position['dy'].expectUint(10 * ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 1000041873);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);  

        // make sure wallet_1 does not have any yield-token
        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance", 
            [types.uint(expiry), types.principal(wallet_1.address)
            ], wallet_1.address);
        call.result.expectOk().expectUint(0);            
        
        //Add extra liquidity with secondary buying of yield-token
        result = YTPTest.buyAndAddToPosition(wallet_1, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 10*ONE_8, Number.MAX_SAFE_INTEGER);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(909188000);
        position['balance-token'].expectUint(900996827);
        position['balance-yield-token'].expectUint(8191409);
        position['balance-virtual'].expectUint(909188003);
    }
});

Clarinet.test({
    name: "YTP : roll-position",

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
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-yield-token'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, expiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1000037034);
        position['dy'].expectUint(10 * ONE_8);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 1000037034);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);  

        // make sure wallet_1 does not have any yield-token
        call = chain.callReadOnlyFn(yieldwbtcAddress, "get-balance", 
            [types.uint(expiry), types.principal(wallet_1.address)
            ], wallet_1.address);
        call.result.expectOk().expectUint(0);     
        
        // create another ytp
        result = YTPTest.createPool(deployer, anotherExpiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, multisigytpyieldwbtc, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);       
        // inject some yield-token to pool
        result = YTPTest.swapYForX(deployer, anotherExpiry, yieldwbtcAddress, wbtcAddress, 10 * ONE_8, 0);
        position =result.expectOk().expectTuple();
        position['dx'].expectUint(1000063164);
        position['dy'].expectUint(10 * ONE_8);     
        
        call = await YTPTest.getPoolDetails(anotherExpiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8);
        position['balance-token'].expectUint(1000*ONE_8 - 1000063164);
        position['balance-yield-token'].expectUint(10 * ONE_8);
        position['balance-virtual'].expectUint(1000*ONE_8);          
        
        //Add extra liquidity with secondary buying of yield-token
        result = YTPTest.rollPosition(deployer, expiry, yieldwbtcAddress, wbtcAddress, ytpyieldwbtcAddress, 0.5*ONE_8, anotherExpiry);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(50354657000);
        position['balance-token'].expectUint(49900930281);
        position['balance-yield-token'].expectUint(453674708);
        position['balance-virtual'].expectUint(50354657156);

        // Check pool details and print
        call = await YTPTest.getPoolDetails(anotherExpiry, yieldwbtcAddress);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(1000*ONE_8 + 50354657000);
        // a bit more than 148900862764 = 1000*ONE_8 - 1000067035 + 49900926876, due to buy-and-add-to-position
        position['balance-token'].expectUint(148999867325); 
        // a bit less then 1453675742 = 0 + 10 * ONE_8 + 453674699, due to buy-and-add-to-position
        position['balance-yield-token'].expectUint(1354633808);
        position['balance-virtual'].expectUint(1000*ONE_8 + 50354657156);          
    }
});