
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_16 = 10000000000000000

// Clarinet.test({
//     name: "math-big-uint: max number",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
        
//         let deployer = accounts.get("deployer")!;

//         let call = chain.callReadOnlyFn("math-big-uint", "maximum-integer",
//             [
//                 types.uint(500*ONE_16), //19 digits
//                 types.uint(5000*ONE_16), //20 digits
//             ], deployer.address);
//         assertEquals(call.result, "u250000000000000000000000000000000000000") //39 digits MAX
//     },
// });

// Clarinet.test({
//     name: "math-big-uint: mul",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
        
//         let deployer = accounts.get("deployer")!;

//         let call = chain.callReadOnlyFn("math-big-uint", "mul",
//             [
//                 "u5000000000000000000000",
//                 "u5000000000000000000000"
//             ], deployer.address);
//         assertEquals(call.result, "u2500000000000000000000000000")
//     },
// });


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


// Clarinet.test({
//     name: "math-big-uint: div-with-scientific-notation",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
        
//         let deployer = accounts.get("deployer")!;

//         let call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
//             [
//                 types.uint(25),
//                 types.int(-1),
//                 // this number becomes 25*10^-1=2.5
//                 types.uint(4),
//                 types.int(0),
//                 // this number becomes 4*10^0=4
//             ], deployer.address);
//         let position: any = call.result.expectTuple()
//         position['result'].expectUint(625)
//         position['exponent'].expectInt(-3)
        // the answer is 100*10^-1 = 10

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(1122334455667788), 
        //         types.int(0),
        //         types.uint(1122334455667788),
        //         types.int(0),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u1259634630379109987517020812944")
        // position['exponent'].expectInt(0)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(1122334455667788), 
        //         types.int(0),
        //         types.uint(1122334455667788),
        //         types.int(-16),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u1259634630379109987517020812944")
        // position['exponent'].expectInt(-16)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(1122334455667788), 
        //         types.int(-16),
        //         types.uint(1122334455667788),
        //         types.int(0),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u1259634630379109987517020812944")
        // position['exponent'].expectInt(-16)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(1122334455667788), 
        //         types.int(-16),
        //         types.uint(1122334455667788),
        //         types.int(-16),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u1259634630379109987517020812944")
        // position['exponent'].expectInt(-32)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(1122334455667788), 
        //         types.int(16),
        //         types.uint(1122334455667788),
        //         types.int(-16),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u1259634630379109987517020812944")
        // position['exponent'].expectInt(0)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(500000), 
        //         types.int(0),
        //         types.uint(5),
        //         types.int(-1),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u2500000")
        // position['exponent'].expectInt(-1)

        // call = chain.callReadOnlyFn("math-big-uint", "div-with-scientific-notation",
        //     [
        //         types.uint(6000000), 
        //         types.int(0),
        //         types.uint(67),
        //         types.int(-2),
        //     ], deployer.address);
        // position = call.result.expectTuple()
        // assertEquals(position['result'], "u402000000")
        // position['exponent'].expectInt(-2)

//     },
// });


// Clarinet.test({
//     name: "math-big-uint: mul-16",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
        
//         let deployer = accounts.get("deployer")!;

//         // Following multiplication tells 50 and 5 with one decimal to the left
//         // making it 5 and 0.5
//         let call = chain.callReadOnlyFn("math-big-uint", "mul-16",
//             [
//                 types.uint(5), //50000000000000000 
//                 types.uint(16),
//                 types.uint(5), //5000000000000000
//                 types.uint(15),
//             ], deployer.address);
//         let position: any = call.result.expectTuple()
//         position['result'].expectUint(25)
//         position['decimals'].expectUint(1)

//         call = chain.callReadOnlyFn("math-big-uint", "mul-16",
//             [
//                 types.uint(25), 
//                 types.uint(16),
//                 types.uint(25),
//                 types.uint(14),
//             ], deployer.address);
//         position = call.result.expectTuple()
//         position['result'].expectUint(625)
//         position['decimals'].expectUint(2)

//         call = chain.callReadOnlyFn("math-big-uint", "mul-16",
//             [
//                 types.uint(25), 
//                 types.uint(14),
//                 types.uint(25),
//                 types.uint(16),
//             ], deployer.address);
//         position = call.result.expectTuple()
//         position['result'].expectUint(625)
//         position['decimals'].expectUint(2)

//         call = chain.callReadOnlyFn("math-big-uint", "mul-16",
//             [
//                 types.uint(500000), 
//                 types.uint(16),
//                 types.uint(5),
//                 types.uint(15),
//             ], deployer.address);
//         position = call.result.expectTuple()
//         position['result'].expectUint(2500000)
//         position['decimals'].expectUint(1)
//     },
// });

// Clarinet.test({
//     name: "math-big-uint: div",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
        
//         let deployer = accounts.get("deployer")!;

//         let call = chain.callReadOnlyFn("math-big-uint", "div",
//             [
//                 "u500000000000000000000000",
//                 "u500000000000000000000000"
//             ], deployer.address);
//         assertEquals(call.result, "u10000000000000000")
//     },
// });
