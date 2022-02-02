
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_16 = 10000000000000000

/*
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
        let position: any = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "16094379124341004")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "500000",
            types.int(0),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "131223633774043286")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "5000000000000000000",
            types.int(0),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "430559695863269224")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "5",
            types.int(-1),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "-6931471805599458")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "1",
            types.int(-3),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "-69077552789821370")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "112451252143",
            types.int(0),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "254457856503986790")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "-1",
            types.int(0),
        ], deployer.address);
        call.result.expectErr().expectUint(5013)
        
        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "0",
            types.int(0),
        ], deployer.address);
        call.result.expectErr().expectUint(5013)

        call = chain.callReadOnlyFn("math-big-uint", "ln-with-scientific-notation",
            [
            "25",
            types.int(-1),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "9162907318741552")
        assertEquals(position['exp'], "-16")
    },
});
*/
Clarinet.test({
    name: "math-big-uint: exp (0 -> 1)",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "0",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "10000000000000000")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "0",
            "0"
        ], deployer.address);
        console.log("RESULT SN: "+call.result.expectOk());

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "1000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "11051709180756472")
        // RESULT SN: {a: 11051709180756472, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "2000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "12214027581601695")
        // RESULT SN: {a: 12214027581601695, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "3000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "13498588075760028")
        // RESULT SN: {a: 13498588075760028, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "4000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "14918246976412698")
        // RESULT SN: {a: 14918246976412698, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "5000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "16487212707001282")
        // RESULT SN: {a: 16487212707001282, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "6000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "18221188003905083")
        // RESULT SN: {a: 18221188003905083, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "7000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "20137527074704760")
        // RESULT SN: {a: 20137527074704760, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "8000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "22255409284924672")
        // RESULT SN: {a: 22255409284924661, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "9000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "24596031111569487")
        // RESULT SN: {a: 24596031111569487, exp: -16}

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed",
            [
            "10000000000000000",
        ], deployer.address);
        assertEquals(call.result.expectOk(), "27182818284590452")
        // RESULT SN: {a: 27182818284590452, exp: -16}

    },
});

/*
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
        assertEquals(position['a'], "100")
        assertEquals(position['exp'], "-1")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-32")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(500000), 
                types.int(0),
                types.int(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "2500000")
        assertEquals(position['exp'], "-1")

        call = chain.callReadOnlyFn("math-big-uint", "multiplication-with-scientific-notation",
            [
                types.int(6000000), 
                types.int(0),
                types.int(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "402000000")
        assertEquals(position['exp'], "-2")

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
        assertEquals(position['a'], "62500000000000000")
        assertEquals(position['exp'], "-17")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
        [
            types.int(1122334455667788), 
            types.int(0),
            types.int(1122334455667788),
            types.int(0),
        ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "10000000000000000")
        assertEquals(position['exp'], "-16")
        
        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(0),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "10000000000000000")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "10000000000000000")
        assertEquals(position['exp'], "-32")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(-16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "10000000000000000")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(1122334455667788), 
                types.int(16),
                types.int(1122334455667788),
                types.int(-16),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "10000000000000000")
        assertEquals(position['exp'], "16")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(500000), 
                types.int(0),
                types.int(5),
                types.int(-1),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "1000000000000000000000")
        assertEquals(position['exp'], "-15")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(6000000), 
                types.int(0),
                types.int(67),
                types.int(-2),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "895522388059701492537")
        assertEquals(position['exp'], "-14")

        call = chain.callReadOnlyFn("math-big-uint", "division-with-scientific-notation",
            [
                types.int(8877665544332211), 
                types.int(0),
                types.int(1122334),
                types.int(0),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['a'], "79100032114613038542893648")
        assertEquals(position['exp'], "-16")

    },
});
*/