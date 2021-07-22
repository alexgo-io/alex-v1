
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


const testWeightX = 50000000    //0.5
const testWeightY = 50000000    //0.5
const testPrice = 2000000000    //200

/**
 *  Weighted Equation Test Cases
 *  deno script syntax can be found here : https://deno.land/x/clarinet
 * 
 *  1. Checks whether equation is adequately returning the vaules. 
 * 
 */


Clarinet.test({
    name: " WEIGHTED EQUATION :  weighted-equation test",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;

        let call = chain.callReadOnlyFn("weighted-equation", "get-y-given-x", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(20000000)], wallet_1.address);
        call.result.expectOk().expectUint(16658325)

        call = chain.callReadOnlyFn("weighted-equation", "get-x-given-y", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(20000000)], wallet_1.address);
        call.result.expectOk().expectUint(25012494)
    
        call = chain.callReadOnlyFn("weighted-equation", "get-x-given-price", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(testPrice)], wallet_1.address);
        call.result.expectOk().expectUint(447258301)

        call = chain.callReadOnlyFn("weighted-equation", "get-token-given-position", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(100000000),       //total-supply
            types.uint(100000000),        //dX
            types.uint(100000000)], wallet_1.address);
        let token:any= call.result.expectOk().expectTuple()
            token['dy'].expectUint(100000000);
            token['token'].expectUint(100000000);

        call = chain.callReadOnlyFn("weighted-equation", "get-position-given-mint", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(200000000),   //total-supply
            types.uint(10000000)     //token
            ], wallet_1.address);
        let position:any= call.result.expectOk().expectTuple()
            position['dx'].expectUint(5000000);
            position['dy'].expectUint(5000000);

        call = chain.callReadOnlyFn("weighted-equation", "get-position-given-burn", [types.uint(100000000),
            types.uint(100000000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(200000000),   //total-supply
            types.uint(10000000)     //token
            ], wallet_1.address);
            position= call.result.expectOk().expectTuple()
            position['dx'].expectUint(5000000);
            position['dy'].expectUint(5000000);
    },
});



