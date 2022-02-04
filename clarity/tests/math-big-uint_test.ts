
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
    name: "math-log-exp-biguint: exp-16",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "0","0"
        ], deployer.address);
        let position: any = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "1000000000000000")
        assertEquals(position['exp'], "-15")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
            [
            "0"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "100000000")

        console.log("RESULT TTMATH: 1")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "51","0"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "140934908242693")
        assertEquals(position['exp'], "8")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
            [
            "5100000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "14093490834298401095131234655")

        console.log("RESULT TTMATH: 1.4093490824269387964")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "-36","0"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "231952283024357220")
        assertEquals(position['exp'], "-33")
        
        console.log("RESULT TTMATH: 2.319522830243569388e-16")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "-18","0"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "152299797447126310")
        assertEquals(position['exp'], "-25")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
        [
            "-1800000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "1")
        
        console.log("RESULT TTMATH: 0.00000001522997974471262843613")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "1","0"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "271828182845904")
        assertEquals(position['exp'], "-14")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
        [
        "100000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "271828183")

        console.log("RESULT TTMATH: 2.718281828459045235360")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "-1","0"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "367879441171443030")
        assertEquals(position['exp'], "-18")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
        [
        "-100000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "36787944")

        console.log("RESULT TTMATH: 0.36787944117144232159552377")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "1","-1"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "1105170918075645661413597729825")
        assertEquals(position['exp'], "-30")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
            [
            "10000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "110517090")

        console.log("RESULT TTMATH: 1.105170918075647624")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "-1","-1"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "9048374180359612")
        assertEquals(position['exp'], "-16")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
            [
            "-10000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "90483743")

        console.log("RESULT TTMATH: 0.904837418035959573")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "1","1"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "220264657948067")
        assertEquals(position['exp'], "-10")

        call = chain.callReadOnlyFn("math-log-exp", "exp-fixed",
            [
            "1000000000"
        ], deployer.address);
        assertEquals(call.result.expectOk(), "2202646579798")

        console.log("RESULT TTMATH: 22026.46579480671651695790")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "2","-2"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "1020201340026755")
        assertEquals(position['exp'], "-15")
        console.log("RESULT TTMATH: 1.02020134002675581016")

        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-fixed-16",
            [
            "2","-3"
        ], deployer.address);
        position = call.result.expectOk().expectTuple()
        assertEquals(position['a'], "1002002001334000")
        assertEquals(position['exp'], "-15")
        console.log("RESULT TTMATH: 1.002002001334000266755")

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


Clarinet.test({
    name: "math-big-uint: exp-pos",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get("deployer")!;
        let call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos",
        [
            '5000000000',
        ], deployer.address);
        console.log('5e-7 in 16 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp", "exp-pos-8",
        [
            '50',
        ], deployer.address);
        console.log('5e-7 in 8 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos-16",
        [
            '5',
            types.int(-7)
        ], deployer.address);
        console.log('5e-7 in SN format', call.result+"\n\n");

        call = chain.callReadOnlyFn("math-log-exp", "exp-pos-8",
        [
            '2000000',
        ], deployer.address);
        console.log('0.02 in 8 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos",
        [
            '200000000000000',
        ], deployer.address);
        console.log('0.02 in 16 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos-16",
        [
            '002',
            types.int(-2)
        ], deployer.address);
        console.log('0.02 in SN format', call.result + "\n\n");
        
        call = chain.callReadOnlyFn("math-log-exp", "exp-pos-8",
        [
            '550000000',
        ], deployer.address);
        console.log('5.5 in 8 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos",
        [
            '55000000000000000',
        ], deployer.address);
        console.log('5.5 in 16 format', call.result);
        call = chain.callReadOnlyFn("math-log-exp-biguint", "exp-pos-16",
        [
            '5500000000000',
            types.int(-12)
        ], deployer.address);
        console.log('5.5 in SN format', call.result+"\n\n");
    },
});
*/