
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
  
const ONE_8 = 100000000

/**
 * math-fixed-point
 * we are primarily concerned with pow-up and pow-down
 */

 Clarinet.test({
    name: "math-fixed-point: accumulate_division",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-log-exp", "ln-priv",
            [
                "500000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 160814372)")

        call = chain.callReadOnlyFn("math-log-exp", "ln-priv",
            [
                "100000000000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 375639734)")
    }
})

Clarinet.test({
    name: "math-fixed-point: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        assertEquals(call.result, "u3104843376593135944"); //

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        assertEquals(call.result, "u3104843624980616010"); //

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_8),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(99999995);  

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(1000000*ONE_8),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(100000005);        
        
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_8),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(99999997);  
        
        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(1000000*ONE_8),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(100000009); 
    },
});