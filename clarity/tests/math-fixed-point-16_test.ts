
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
  
const ONE_16 = 10000000000000000

 Clarinet.test({
    name: "math-fixed-point-16: scale-up and scale-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-16", "scale-up",
            [
                types.uint(5),
            ], deployer.address);
        call.result.expectUint(5*ONE_16);

        call = chain.callReadOnlyFn("math-fixed-point-16", "scale-down",
            [
                types.uint(5*ONE_16),
            ], deployer.address);
        call.result.expectUint(5);
    },
});

Clarinet.test({
    name: "math-fixed-point-16: mul-up and mul-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-16", "mul-up",
            [
                types.uint(5*ONE_16),
                types.uint(5*ONE_16),
            ], deployer.address);
        call.result.expectUint(25*ONE_16);

        call = chain.callReadOnlyFn("math-fixed-point-16", "mul-down",
            [
                types.uint(5*ONE_16),
                types.uint(5*ONE_16),
            ], deployer.address);
        call.result.expectUint(25*ONE_16);
    },
});

Clarinet.test({
    name: "math-fixed-point-16: div-up and div-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-16", "div-up",
            [
                types.uint(10*ONE_16),
                types.uint(5*ONE_16),
            ], deployer.address);
        call.result.expectUint(2*ONE_16);

        call = chain.callReadOnlyFn("math-fixed-point-16", "div-down",
            [
                types.uint(10*ONE_16),
                types.uint(5*ONE_16),
            ], deployer.address);
        call.result.expectUint(2*ONE_16);
    },
});


Clarinet.test({
    name: "math-fixed-point: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(5*ONE_16),
                types.uint(5*ONE_16)
            ], deployer.address);
        call.result.expectUint(312499930206); //

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(5*ONE_16),
                types.uint(5*ONE_16)
            ], deployer.address);
        call.result.expectUint(312499955208);

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_16),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(99999995);  

        call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
            [
                types.uint(1000000*ONE_16),
                types.uint(0)
            ], deployer.address);
        call.result.expectUint(100000005);        
        
        call = chain.callReadOnlyFn("math-fixed-point", "pow-down",
            [
                types.uint(1000000*ONE_16),
                types.uint(1)
            ], deployer.address);
        call.result.expectUint(100000007);                         

        // // this is the upper limit
        // call = chain.callReadOnlyFn("math-fixed-point", "pow-up",
        //     [
        //         types.uint(2*ONE_16),
        //         types.uint(73*ONE_16)
        //     ], deployer.address);
        // call.result.expectOk().expectUint(944470526444524944313634000869);            
    },
});