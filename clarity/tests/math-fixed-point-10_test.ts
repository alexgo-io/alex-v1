
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
  
const ONE_10 = 10000000000

/**
 * math-fixed-point-10
 * we are primarily concerned with pow-up and pow-down
 */

 Clarinet.test({
    name: "math-fixed-point-10: accumulate_division",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-10", "accumulate_division",
            [
                "{x_pre: 6400000000, a_pre: 6235149080811616882910000000, use_deci: false}",
                "{a: 50000000000, sum: 0}"
            ], deployer.address);
        assertEquals(call.result, "{a: 50000000000, sum: 0}")

        call = chain.callReadOnlyFn("math-log-exp-10", "accumulate_division",
            [
                "{x_pre: 3200000000, a_pre: 7896296018268069516100, use_deci: true}",
                "{a: 50000000000, sum: 50000000000}"
            ], deployer.address);
        assertEquals(call.result, "{a: 50000000000, sum: 50000000000}")

        call = chain.callReadOnlyFn("math-log-exp-10", "ln-priv",
            [
                "50000000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 16094379122)")

        call = chain.callReadOnlyFn("math-log-exp-10", "ln-priv",
            [
                "10000000000000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 138155105576)")
    }
})

Clarinet.test({
    name: "math-fixed-point-10: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-10", "pow-down",
            [
                types.uint(5*ONE_10),
                types.uint(5*ONE_10)
            ], deployer.address);
        call.result.expectUint(31249999945903); //

        call = chain.callReadOnlyFn("math-fixed-point-10", "pow-up",
            [
                types.uint(5*ONE_10),
                types.uint(5*ONE_10)
            ], deployer.address);
        call.result.expectUint(31249999970905);

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point-10", "pow-down",
            [
                types.uint(1000000*ONE_10),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(9999999995);  

        call = chain.callReadOnlyFn("math-fixed-point-10", "pow-up",
            [
                types.uint(1000000*ONE_10),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(10000000005);        
        
        call = chain.callReadOnlyFn("math-fixed-point-10", "pow-down",
            [
                types.uint(1000000*ONE_10),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(10000000007);  
        
        call = chain.callReadOnlyFn("math-fixed-point-10", "pow-up",
            [
                types.uint(1000000*ONE_10),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(10000000019);
    },
});