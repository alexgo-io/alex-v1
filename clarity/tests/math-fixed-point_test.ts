
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
  
const ONE_8 = 100000000

/**
 * math-fixed-point
 * we are primarily concerned with pow-up and pow-down
 */

Clarinet.test({
    name: "math-fixed-point: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        call.result.expectOk().expectUint(312499930206);

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(5*ONE_8),
                types.uint(5*ONE_8)
            ], deployer.address);
        call.result.expectOk().expectUint(312499955208);

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_8),
                types.uint(0)
            ], deployer.address);
        call.result.expectOk().expectUint(99999995);  

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(1000000*ONE_8),
                types.uint(0)
            ], deployer.address);
        call.result.expectOk().expectUint(100000005);        
        
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_8),
                types.uint(1)
            ], deployer.address);
        call.result.expectOk().expectUint(100000007);                         

        // // this is the upper limit
        // call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
        //     [
        //         types.uint(2*ONE_8),
        //         types.uint(73*ONE_8)
        //     ], deployer.address);
        // call.result.expectOk().expectUint(944470526444524944313634000869);            
    },
});