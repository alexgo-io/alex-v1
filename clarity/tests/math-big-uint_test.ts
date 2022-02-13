
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_16 = 10000000000000000
const ONE_8 = 100000000


Clarinet.test({
    name: "math-big-uint: max number",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-big-uint", "maximum-unsigned-integer",
            [
                types.uint(500*ONE_16), //20 digits
                types.uint(5000*ONE_16), //21 digits
            ], deployer.address);
        assertEquals(call.result, "u250000000000000000000000000000000000000") //39 digits MAX

        call = chain.callReadOnlyFn("math-big-uint", "maximum-integer",
            [
                types.int(500*ONE_16), //20 digits
                types.int(500*ONE_16), //20 digits
            ], deployer.address);
        assertEquals(call.result, "25000000000000000000000000000000000000") //38 digits MAX
    },
});

Clarinet.test({
    name: "math-log-exp-biguint: greater than equal to",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "greater-than-equal-to", 
        [
            types.tuple({x: 250, exp: -4}),
            types.tuple({x: 25, exp: -3})
        ], deployer.address
        );
        call.result.expectBool(true);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "greater-than-equal-to", 
        [
            types.tuple({x: 10, exp: 3}),
            types.tuple({x: 20, exp: 3})
        ], deployer.address
        );
        call.result.expectBool(false);
    },
});

Clarinet.test({
    name: "math-log-exp-biguint: ln",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 5, exp: 0}),
        ], deployer.address);
        let position: any = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "16094379124341004")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 500000, exp: 0}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "131223633774043286")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: "5000000000000000000", exp: 0}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "430559695863269224")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 5, exp: -1}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "-6931471805599458")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 1, exp: -3}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "-69077552789821370")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 112451252143, exp: 0}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "254457856503986790")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: -1, exp: 0}),
        ], deployer.address);
        call.result.expectErr().expectUint(5013)
        
        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 0, exp: 0}),
        ], deployer.address);
        call.result.expectErr().expectUint(5013)

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 25, exp: -1}),
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['x'], "9162907318741552")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 1, exp: 0}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        position['x'].expectInt(0);
        position['exp'].expectInt(-16);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 807319, exp: -3}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        assertEquals(position['x'], '66937188813649474');
        position['exp'].expectInt(-16);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: '5509092894629838567', exp: 9}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        assertEquals(position['x'], '638761974915274242');
        position['exp'].expectInt(-16);


        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x:'3356104534606482476944904305', exp: 0}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        assertEquals(position['x'], '633805784475307446');
        position['exp'].expectInt(-16);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 623, exp: 0}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        assertEquals(position['x'], '64345465187874532');
        position['exp'].expectInt(-16);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "ln-fixed",
            [
                types.tuple({x: 2117700, exp: -3}),
            ], deployer.address
        );
        position = call.result.expectOk().expectTuple();
        assertEquals(position['x'], '76580858730695360');
        position['exp'].expectInt(-16);
    },
});

Clarinet.test({
    name: "math-log-exp-biguint: multiplication-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: 25, exp: -1}),
                types.tuple({x: 4, exp: 0}),
            ], deployer.address);
        let position: any = call.result.expectTuple()
        assertEquals(position['x'], "100")
        assertEquals(position['exp'], "-1")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: 0}),
                types.tuple({x: "1122334455667788", exp: 0}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: 0}),
                types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: -16}),
                types.tuple({x: "1122334455667788", exp: 0}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: -16}),
                types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "-32")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: 16}),
                types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1259634630379109987517020812944")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: 500000, exp: 0}),
                types.tuple({x: 5, exp: -1}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "2500000")
        assertEquals(position['exp'], "-1")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "multiplication-with-scientific-notation",
            [
                types.tuple({x: 6000000, exp: 0}),
                types.tuple({x: 67, exp: -2}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "402000000")
        assertEquals(position['exp'], "-2")

    },
});

Clarinet.test({
    name: "math-log-exp-biguint: division-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;

        let call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: 25, exp: -1}),
                types.tuple({x: 4, exp: 0}),
            ], deployer.address);
        let position: any = call.result.expectTuple()
        assertEquals(position['x'], "62500000000000000")
        assertEquals(position['exp'], "-17")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
        [
            types.tuple({x: "1122334455667788", exp: 0}),
            types.tuple({x: "1122334455667788", exp: 0}),
        ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "10000000000000000")
        assertEquals(position['exp'], "-16")
        
        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: 0}),
            types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "10000000000000000")
        assertEquals(position['exp'], "0")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: -16}),
                types.tuple({x: "1122334455667788", exp: 0}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "10000000000000000")
        assertEquals(position['exp'], "-32")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: -16}),
            types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "10000000000000000")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: "1122334455667788", exp: 16}),
            types.tuple({x: "1122334455667788", exp: -16}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "10000000000000000")
        assertEquals(position['exp'], "16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: 500000, exp: 0}),
            types.tuple({x: 5, exp: -1}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "1000000000000000000000")
        assertEquals(position['exp'], "-15")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "division-with-scientific-notation",
            [
                types.tuple({x: 6000000, exp: 0}),
            types.tuple({x: 67, exp: -2}),
            ], deployer.address);
        position = call.result.expectTuple()
        assertEquals(position['x'], "895522388059701492537")
        assertEquals(position['exp'], "-14")

    },
});

Clarinet.test({
    name: "math-log-exp-biguint: exp-fixed",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get("deployer")!;
        // 0.0000005
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 5, exp: -7}),
        ], deployer.address);
        let result: any = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1000000500000125');
        result['exp'].expectInt(-15);

        // 0.02
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 2, exp: -2}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1020201340026755');
        result['exp'].expectInt(-15);

        //0.1
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 1, exp: -1}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1105170918075645661413597729825');
        result['exp'].expectInt(-30);

        //0.2
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 2, exp: -1}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1221402758160167647388990560686');
        result['exp'].expectInt(-30);

        //1
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 1, exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '271828182845904');
        result['exp'].expectInt(-14);

        // 4.5
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 45, exp: -1}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '900171313005218');
        result['exp'].expectInt(-13);

        // 51
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 51, exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '140934908242693');
        result['exp'].expectInt(8);

        //0
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 0, exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1000000000000000');
        result['exp'].expectInt(-15);

        //-1.01
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: -101, exp: -2}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '364218979571524181');
        result['exp'].expectInt(-18);

        // -36
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: -36, exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '231952283024357220');
        result['exp'].expectInt(-33);

        // 52
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed ",
        [
            types.tuple({x: 52, exp: 0}),
        ], deployer.address);
        result = call.result.expectErr().expectUint(5012);

    },
});

Clarinet.test({
    name: "math-big-uint: pow-priv",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get("deployer")!;

        // 0.0000005^0.6
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(50000000), exp: -14}),
            types.tuple({x: types.uint(6), exp: -1}),
        ], deployer.address);
        let result: any = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '104994678204640105');
        result['exp'].expectInt(-18);

        // 0.02^0.08
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(2), exp: -2}),
            types.tuple({x: types.uint(8), exp: -2}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '7662321819045797');
        result['exp'].expectInt(-16);

        //0.1^1
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(1), exp: -1}),
            types.tuple({x: types.uint(1), exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '102817675584246604');
        result['exp'].expectInt(-18);

        // 10^100
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(10), exp: 0}),
            types.tuple({x: types.uint(10), exp: 1}),
        ], deployer.address);
        result = call.result.expectErr().expectUint(5012);

        // 81^0
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(81), exp: 0}),
            types.tuple({x: types.uint(0), exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '1000000000000000');
        result['exp'].expectInt(-15);

        // 90 ^ 9
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(9), exp: 1}),
            types.tuple({x: types.uint(9), exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '387420489000000');
        result['exp'].expectInt(3);

        // 123 ^ 8
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: 'u12300000000', exp: -8}),
            types.tuple({x: types.uint(8), exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '523890944282627');
        result['exp'].expectInt(2);

        // 123 ^ 2.46
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: 'u12300000000', exp: -8}),
            types.tuple({x: 'u246000000000', exp: -11}),
        ], deployer.address);
        result = call.result.expectErr().expectUint(5012);

        // 21 ^ 0.0046
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: 'u210000', exp: -4}),
            types.tuple({x:  'u46000000000000000', exp: -19}),
        ], deployer.address);
        result = call.result.expectErr().expectUint(5012);

        //0 ^ 1
        call = chain.callReadOnlyFn("math-log-exp-biguint", "pow-priv ",
        [
            types.tuple({x: types.uint(0), exp: 0}),
            types.tuple({x:  types.uint(1), exp: 0}),
        ], deployer.address);
        result = call.result.expectOk().expectTuple();
        assertEquals(result['x'], '233672138547078697');
        result['exp'].expectInt(-19);

    },
});

Clarinet.test({
    name: "math-big-uint: scale-up",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-up",
            [
                types.int(57801110485800),
            ], deployer.address
        );
        assertEquals('578011104858000000000000000000', call.result);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-up",
            [
                types.int(0),
            ], deployer.address
        );
        call.result.expectInt(0);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-up",
            [
                types.int(-1234567891011121314),
            ], deployer.address
        );
        assertEquals('-12345678910111214000000000000000000', call.result);
    },
});

Clarinet.test({
    name: "math-big-uint: scale-down",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down",
            [
                '12345678890101112131415',
            ], deployer.address
        );
        call.result.expectInt(1234567);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down",
            [
                types.int(0),
            ], deployer.address
        );
        call.result.expectInt(0);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down",
            [
                '-9999999999999999999999999999999',
            ], deployer.address
        );
        call.result.expectInt(-999999999999999);
    },
});

Clarinet.test({
    name: "math-big-uint: scale-down-with-lost-precision",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down-with-lost-precision",
        [
                types.tuple({ x: '986883254124567890899991267', exp: -16 }),
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        result['x'].expectInt(98688325412);
        result['exp'].expectInt(0);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down-with-lost-precision",
            [
                types.tuple({ x: '-0489232256789909', exp: -16 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        result['x'].expectInt(0);
        result['exp'].expectInt(0);
    },
});

Clarinet.test({
    name: "math-big-uint: scale-down-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down-with-scientific-notation",
            [
                types.tuple({ x: 2980957987041728, exp: -32 }),
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        assertEquals('29809579870417280000000000000000', result['x']);
        result['exp'].expectInt(-64);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down-with-scientific-notation",
            [
                types.tuple({ x: 0, exp: 0 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        result['x'].expectInt(0);
        result['exp'].expectInt(-32);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "scale-down-with-scientific-notation",
            [
                types.tuple({ x: -5001500250003457, exp: -52 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '-50015002500034570000000000000000');
        result['exp'].expectInt(-84);
    },
});

Clarinet.test({
    name: "math-big-uint: addition-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "addition-with-scientific-notation",
            [
                types.tuple({ x: 320000000000000000, exp: -4 }),
                types.tuple({ x: 1600000000000000, exp: -15 }),
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        assertEquals(result['x'], '32000000000001600000000000000');
        result['exp'].expectInt(-15);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "addition-with-scientific-notation",
            [
                types.tuple({ x: '234932806661705911188785462338167591', exp: -35 }),
                types.tuple({ x: '-8088245021529212865977835549028607449', exp: -34}),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '-80647517408630422748589570027947906899');
        result['exp'].expectInt(-35);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "addition-with-scientific-notation",
            [
                types.tuple({ x: '4879050372792131586543547012911498289', exp: -11 }),
                types.tuple({ x: 0, exp: 0}),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '4879050372792131586543547012911498289');
        result['exp'].expectInt(-11);
    },
});

Clarinet.test({
    name: "math-big-uint: subtraction-with-scientific-notation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "subtraction-with-scientific-notation",
            [
                types.tuple({ x: '1407899272653447767215467463', exp: -12 }),
                types.tuple({ x: '17650706659942525608226366899', exp: -21 }),
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        assertEquals(result['x'], '1407899255002741107272941854773633101');
        result['exp'].expectInt(-21);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "subtraction-with-scientific-notation",
            [
                types.tuple({ x: '28191504282207712212364439220350', exp: -35 }),
                types.tuple({ x: '-12891104957000012549830113619842', exp: -31 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '128939241074282333210513500637640350');
        result['exp'].expectInt(-35);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "subtraction-with-scientific-notation",
            [
                types.tuple({ x: 0, exp: 0 }),
                types.tuple({ x: '4879050372792131586543547012911498289', exp: -18 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '-4879050372792131586543547012911498289');
        result['exp'].expectInt(-18);
    },
});

Clarinet.test({
    name: "math-big-uint: transform",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "transform",
            [
                types.tuple({ x: 11114936106354, exp: -8 }),
                types.int(-13)
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        result['x'].expectInt(1111493610635400000);
        result['exp'].expectInt(-13);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "transform",
            [
                
                types.tuple({ x:  '829487965402890273820142', exp: -5 }),
                types.int(-5)
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['x'], '829487965402890273820142');
        result['exp'].expectInt(-5);
    },
});

Clarinet.test({
    name: "math-big-uint: transform-generalized",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "transform-generalized",
            [
                types.int(111149361063549),
                types.int(-8),
                types.int(-13)
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        result['a'].expectInt(11114936106354900000);
        result['exp'].expectInt(-13);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "transform-generalized",
            [
                '829487965402890273820142',
                types.int(-5),
                types.int(-5),
            ], deployer.address
        );
        result = call.result.expectTuple();
        assertEquals(result['a'], '829487965402890273820142');
        result['exp'].expectInt(-5);

    },
});

Clarinet.test({
    name: "math-big-uint: transform-to-16",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "transform-to-16",
            [
                types.tuple({ x: 323335364641518960, exp: -22 }),
            ], deployer.address
        );
        let result: any = call.result.expectTuple();
        result['x'].expectInt(323335364641);
        result['exp'].expectInt(-16);

        call = chain.callReadOnlyFn("math-log-exp-biguint", "transform-to-16",
            [
                types.tuple({ x: 8131151895812, exp: -15 }),
            ], deployer.address
        );
        result = call.result.expectTuple();
        result['x'].expectInt(8131151895812);
        result['exp'].expectInt(-15);
    },
});