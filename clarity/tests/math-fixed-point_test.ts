
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';
  
const ONE_8 = 100000000

/**
 * math-fixed-point
 * we are primarily concerned with pow-up and pow-down
 */


 Clarinet.test({
    name: "math-fixed-point : mul-up mul-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point", "mul-down",
            [
                types.uint(500000*ONE_8),
                types.uint(5*ONE_8),
            ], deployer.address);
        call.result.expectUint(2500000*ONE_8)
            
        call = chain.callReadOnlyFn("math-fixed-point", "mul-up",
            [
                types.uint(500000*ONE_8),
                types.uint(5*ONE_8),
            ], deployer.address);
        call.result.expectUint(2500000*ONE_8)

        call = chain.callReadOnlyFn("math-fixed-point", "mul-up",
        [
            types.uint(5*ONE_8),
            types.uint(0.5*ONE_8),
        ], deployer.address);
        call.result.expectUint(2.5*ONE_8)
        },

        
    });
    
Clarinet.test({
    name: "math-fixed-point : pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        assertEquals(call.result, "u312499930206"); //

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        assertEquals(call.result, "u312499955208"); //

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(5000*ONE_8),
                types.uint(0.5*ONE_8)
            ], deployer.address);
        assertEquals(call.result, "u7071067955"); //

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
        call.result.expectUint(100000007);  
        
        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(1000000*ONE_8),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(100000019); 
    },
});