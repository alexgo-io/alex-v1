
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
  
const ONE_12 = 1000000000000

/**
 * math-fixed-point-12
 * we are primarily concerned with pow-up and pow-down
 */

Clarinet.test({
    name: "math-fixed-point-12: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-12", "pow-down",
            [
                types.uint(5*ONE_12),
                types.uint(5*ONE_12)
            ], deployer.address);
        assertEquals(call.result, "u31249999945903")

        call = chain.callReadOnlyFn("math-fixed-point-12", "pow-up",
            [
                types.uint(5*ONE_12),
                types.uint(5*ONE_12)
            ], deployer.address);
        assertEquals(call.result, "u31249999970905")

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point-12", "pow-down",
            [
                types.uint(1000000*ONE_12),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(9999999995);  

        call = chain.callReadOnlyFn("math-fixed-point-12", "pow-up",
            [
                types.uint(1000000*ONE_12),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(10000000005);        
        
        call = chain.callReadOnlyFn("math-fixed-point-12", "pow-down",
            [
                types.uint(1000000*ONE_12),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(10000000007);  
        
        call = chain.callReadOnlyFn("math-fixed-point-12", "pow-up",
            [
                types.uint(1000000*ONE_12),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(10000000019);
    },
});