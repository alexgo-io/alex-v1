
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

/**
 *  For equation testing
 *  deno script syntax can be found here : https://deno.land/x/clarinet
 */

const testWeightX = 50000000
const testWeightY = 50000000

Clarinet.test({
    name: "weighted-equation test",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;

        let call = chain.callReadOnlyFn("weighted-equation", "get-y-given-x", [types.uint(1000),
            types.uint(1000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(100)], wallet_1.address);
        call.result.expectOk().expectUint(90)

        call = chain.callReadOnlyFn("weighted-equation", "get-x-given-y", [types.uint(1000),
            types.uint(1000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(100)], wallet_1.address);
        call.result.expectOk().expectUint(112)
    
        // call = chain.callReadOnlyFn("weighted-equation", "get-x-given-price", [types.uint(1000),
        //     types.uint(1000),
        //     types.uint(testWeightX),
        //     types.uint(testWeightY),
        //     types.uint(100)], wallet_1.address);
        // call.result.expectOk().expectUint(0)

        call = chain.callReadOnlyFn("weighted-equation", "get-token-given-position", [types.uint(1000),
            types.uint(1000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(1000000),       //total-supply
            types.uint(100),        //dX
            types.uint(100)], wallet_1.address);
        let token:any= call.result.expectOk().expectTuple()
            token['dy'].expectUint(0);
            token['token'].expectUint(100000);

        call = chain.callReadOnlyFn("weighted-equation", "get-position-given-mint", [types.uint(1000),
            types.uint(1000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(2000),   //total-supply
            types.uint(100)     //token
            ], wallet_1.address);
        let position:any= call.result.expectOk().expectTuple()
            position['dx'].expectUint(50);
            position['dy'].expectUint(50);

        call = chain.callReadOnlyFn("weighted-equation", "get-position-given-burn", [types.uint(1000),
            types.uint(1000),
            types.uint(testWeightX),
            types.uint(testWeightY),
            types.uint(2000),   //total-supply
            types.uint(100)     //token
            ], wallet_1.address);
            position= call.result.expectOk().expectTuple()
            position['dx'].expectUint(50);
            position['dy'].expectUint(50);
    },
});



