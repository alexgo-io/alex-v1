
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const testbalanceX = 1000000000000    
const testbalanceY = 1000000000000     
const testTvalue = 50000000
Clarinet.test({
    name: " YIELD TOKEN EQUATION :  yield-token-equation test",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;

        let call = chain.callReadOnlyFn("yield-token-equation", "get-y-given-x", 
        [types.uint(testbalanceX),
            types.uint(testbalanceY),
            types.uint(testTvalue),
            types.uint(50000000)], wallet_1.address);
        call.result.expectOk().expectUint(200410892)


        call = chain.callReadOnlyFn("yield-token-equation", "get-x-given-price", 
        [types.uint(testbalanceX),
            types.uint(testbalanceY),
            types.uint(testTvalue),
            types.uint(50000000)], wallet_1.address);
        call.result.expectOk().expectUint(777658720000)
    
        call = chain.callReadOnlyFn("yield-token-equation", "get-token-given-position", 
        [types.uint(testbalanceX),
            types.uint(testbalanceY),
            types.uint(testTvalue),
            types.uint(200000000),
            types.uint(50000000)], wallet_1.address);
        let token:any= call.result.expectOk().expectTuple()
             token['dy'].expectUint(50000000);
             token['token'].expectUint(10000);

         call = chain.callReadOnlyFn("yield-token-equation", "get-position-given-mint", 
        [types.uint(testbalanceX),
            types.uint(testbalanceY),
            types.uint(testTvalue),
            types.uint(200000000),
            types.uint(50000000)], wallet_1.address);
        let position:any= call.result.expectOk().expectTuple()
            position['dx'].expectUint(250000000000);
            position['dy'].expectUint(250000000000);            

        call = chain.callReadOnlyFn("yield-token-equation", "get-position-given-burn", 
        [types.uint(testbalanceX),
            types.uint(testbalanceY),
            types.uint(testTvalue),
            types.uint(200000000),
            types.uint(50000000)], wallet_1.address);
            position= call.result.expectOk().expectTuple()
            position['dx'].expectUint(250000000000);
            position['dy'].expectUint(250000000000);  

    },
});


        Clarinet.test({
            name: " YIELD TOKEN EQUATION :  Error Testing ",
        
            async fn(chain: Chain, accounts: Map<string, Account>) {
                let deployer = accounts.get("deployer")!;
                let wallet_1 =accounts.get('wallet_1')!;
                
            // SubTraction overflow triggered by void value
            let call = chain.callReadOnlyFn("yield-token-equation", "get-x-given-y", 
            [types.uint(testbalanceX),
                types.uint(testbalanceY),
                types.uint(1000000),
                types.uint(1000000)], wallet_1.address);
            call.result.expectErr().expectUint(5004)
                
 
        
        
            },
        });
        