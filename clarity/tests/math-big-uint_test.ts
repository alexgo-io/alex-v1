
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_16 = 10000000000000000

Clarinet.test({
    name: "math-big-uint: greater than equal to",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "greater-than-equal-to", 
        [
            types.int(250),
            types.int(-4),
            types.int(25),
            types.int(-3)
        ], deployer.address
        );
        call.result.expectBool(true);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "greater-than-equal-to", 
        [
            types.int(10),
            types.int(3),
            types.int(20),
            types.int(3)
        ], deployer.address
        );
        call.result.expectBool(false);
    },
});

Clarinet.test({
    name: "math-big-uint: ln-priv-16",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-priv-16",
            [
            "5",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 5', call.result);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-priv-16",
            [
            "500000",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 500000', call.result);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-priv-16",
            [
            "5000000000000000000",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 5000000000000000000', call.result);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-priv-16",
            [
            "1",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 1', call.result);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-priv-16",
            [
            "112451252143",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 112451252143', call.result);
    },
});

Clarinet.test({
    name: "math-big-uint: max number",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "maximum-integer",
            [
                types.uint(500*ONE_16), //19 digits
                types.uint(5000*ONE_16), //20 digits
            ], deployer.address);
        assertEquals(call.result, "u250000000000000000000000000000000000000") //39 digits MAX
    },
});

Clarinet.test({
    name: "math-big-uint: mul",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "mul",
            [
                types.uint(5),
                types.uint(5),
            ], deployer.address);
        call.result.expectUint(25*ONE_16)
    },
});


Clarinet.test({
    name: "math-big-uint: div",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "div",
            [
                types.uint(5),
                types.uint(5)
            ], deployer.address);
        call.result.expectUint(1*ONE_16)

        call = chain.callReadOnlyFn("math-big-uint", "div",
            [
                types.uint(25123124213),
                types.uint(4125312513461)
            ], deployer.address);
        call.result.expectUint(60899929716894)
    },
});


Clarinet.test({
    name: "math-big-uint: mul-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(25), 
                types.int(-1),
                // this number becomes 25*10^-1=2.5
                types.uint(4),
                types.int(0),
                // this number becomes 4*10^0=4
            ], deployer.address);
        let position: any = call.result.expectTuple()
        position['result'].expectUint(100)
        position['exponent'].expectInt(-1)
        // the answer is 100*10^-1 = 10

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(0),
                types.uint(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1259634630379109987517020812944")
        position['exponent'].expectInt(0)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(0),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1259634630379109987517020812944")
        position['exponent'].expectInt(-16)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(-16),
                types.uint(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1259634630379109987517020812944")
        position['exponent'].expectInt(-16)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(-16),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1259634630379109987517020812944")
        position['exponent'].expectInt(-32)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(16),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1259634630379109987517020812944")
        position['exponent'].expectInt(0)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(500000), 
                types.int(0),
                types.uint(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u2500000")
        position['exponent'].expectInt(-1)

        call = chain.callReadOnlyFn("math-big-uint", "mul-with-scientific-notation",
            [
                types.uint(6000000), 
                types.int(0),
                types.uint(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u402000000")
        position['exponent'].expectInt(-2)

    },
});

Clarinet.test({
    name: "math-big-uint: div-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(25),
                types.int(-1),
                // this number becomes 25*10^-1=2.5
                types.uint(4),
                types.int(0),
                // this number becomes 4*10^0=4
            ], deployer.address);
        let position: any = call.result.expectTuple()
        position['result'].expectUint(6.25*ONE_16)
        position['exponent'].expectInt(-17)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        [
            types.uint(1122334455667788), 
            types.int(0),
            types.uint(1122334455667788),
            types.int(0),
        ], deployer.address);
        position = call.result.expectTuple()
        position['result'].expectUint(1*ONE_16)
        position['exponent'].expectInt(-16)
        
        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(0),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        position['result'].expectUint(1*ONE_16)
        position['exponent'].expectInt(0)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(-16),
                types.uint(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        position['result'].expectUint(1*ONE_16)
        position['exponent'].expectInt(-32)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(-16),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        position['result'].expectUint(1*ONE_16)
        position['exponent'].expectInt(-16)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(1122334455667788), 
                types.int(16),
                types.uint(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        position['result'].expectUint(1*ONE_16)
        position['exponent'].expectInt(16)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(500000), 
                types.int(0),
                types.uint(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u1000000000000000000000") // 1,000,000 * ONE_16
        position['exponent'].expectInt(-15)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(6000000), 
                types.int(0),
                types.uint(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u895522388059701492537") //8,955,223.88059701492537
        position['exponent'].expectInt(-14)

        call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
            [
                types.uint(8877665544332211), 
                types.int(0),
                types.uint(1122334),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['result'], "u79100032114613038542893648") //7,910,003,211.38542893648
        position['exponent'].expectInt(-16)

    },
});