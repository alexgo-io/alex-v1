
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
    name: "math-big-uint: ln-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        
        let call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "5",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 5', call.result);

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "500000",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 500000', call.result);

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "5000000000000000000",
            types.int(0),
        ], deployer.address);
        console.log('Result SN - 5000000000000000000', call.result);

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "5",
            types.int(-1),
        ], deployer.address);
        console.log('Result SN - 0.5', call.result);

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "1",
            types.int(-3),
        ], deployer.address);
        console.log('Result SN - 0.001', call.result);

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
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
    name: "math-big-uint: multiplication-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(25), 
                types.int(-1),
                types.int(4),
                types.int(0),
            ], deployer.address);
        let position: any = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(500000), 
                types.int(0),
                types.int(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(6000000), 
                types.int(0),
                types.int(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

    },
});

Clarinet.test({
    name: "math-big-uint: division-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(25),
                types.int(-1),
                types.int(4),
                types.int(0),
            ], deployer.address);
        let position: any = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
        [
            types.int(1122334455667788), 
            types.int(0),
            types.int(1122334455667788),
            types.int(0),
        ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)
        
        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(500000), 
                types.int(0),
                types.int(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(6000000), 
                types.int(0),
                types.int(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(8877665544332211), 
                types.int(0),
                types.int(1122334),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        console.log(position)

    },
});