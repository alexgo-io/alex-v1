
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
    name: "math-fixed-point: accumulate_division",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-16", "ln-priv",
            [
                "50000000000000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 16081437978100062)")

        call = chain.callReadOnlyFn("math-log-exp", "ln-priv",
            [
                "10000000000000000000000"
            ], deployer.address);
        assertEquals(call.result, "(ok 3573755954)")
    }
})

//NOTE: THIS IS ONLY WORKING TILL ONE_10. GOING TO ONE_16 GIVES ARITHEMATIC OVERFLOW ERRORS
Clarinet.test({
    name: "math-fixed-point: pow-up and pow-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-fixed-point-16", "pow-up",
            [
                "u50000000000000000",
                "u50000000000000000"
            ], deployer.address);
        assertEquals(call.result, "u310484473737102606151")

        call = chain.callReadOnlyFn("math-fixed-point-16", "pow-down",
            [
                "u50000000000000000",
                "u50000000000000000"
            ], deployer.address);
        assertEquals(call.result, "u310484473737102109373")

        // anything ^ 0 = 1
        call = chain.callReadOnlyFn("math-fixed-point-16", "pow-down",
        [
            "u10000000000000000000000",
            "u0"
        ], deployer.address);
        assertEquals(call.result, "u9999999999999991")

        call = chain.callReadOnlyFn("math-fixed-point-16", "pow-up",
            [
                "u10000000000000000000000",
                "u0"
            ], deployer.address);
        assertEquals(call.result, "u10000000000000009")
        
        call = chain.callReadOnlyFn("math-fixed-point-16", "pow-down",
        [
            "u10000000000000000000000",
            "u1"
        ], deployer.address);
        assertEquals(call.result, "u10000000000000038")    
        
        call = chain.callReadOnlyFn("math-fixed-point-16", "pow-up",
            [
                "u10000000000000000000000",
                "u1"
            ], deployer.address);
        assertEquals(call.result, "u10000000000000058")   
    },
});