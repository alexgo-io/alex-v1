import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { ALEXLaunchpad } from './models/alex-tests-launchpad.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
import { 
    TestALEXToken,
    TestALEXLottery,
    WSTXToken
  } from './models/alex-tests-tokens.ts';

const ONE_8 = 100000000
const ACTIVATION_DELAY = 1
const ACTIVATION_THRESHOLD = 1
const OWNER = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE"
const TOKEN_TRAIT_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-t-alex"
const TICKET_TRAIT_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lottery-t-alex" 
const FEE_TO_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE"

Clarinet.test({
    name: "ALP: Testing helper functions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let ALPTest = new ALEXLaunchpad(chain, deployer);

        let result = ALPTest.setOwner(deployer, OWNER);
        result.expectOk().expectBool(true);

        let result2 = ALPTest.getOwner();        
        assertEquals(result2.result, "(ok ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)");


    }
})

Clarinet.test({
    name: "ALP: pool creation, adding values and reducing values",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_2 = accounts.get("wallet_2")!;
        let ALPTest = new ALEXLaunchpad(chain, deployer);

        let wstxToken = new WSTXToken(chain, deployer);
        let lottery = new TestALEXLottery(chain, deployer);
        let talexToken = new TestALEXToken(chain, deployer);
        
        let result:any = talexToken.mintFixed(deployer, deployer.address, 100 * ONE_8);
        result.expectOk();
        result = wstxToken.mintFixed(wallet_1, wallet_1.address, 10000 * ONE_8);
        result.expectOk();
        result = lottery.mintFixed(deployer, wallet_1.address, 100 * ONE_8);
        result.expectOk();
        result = wstxToken.mintFixed(wallet_2, wallet_2.address, 1000 * ONE_8);
        result.expectOk();
        result = lottery.mintFixed(deployer, wallet_2.address, 10 * ONE_8);
        result.expectOk();        

        // Deployer creating a pool, FEE_TO_ADDRESS will be the one that's getting added in the pool
        result = ALPTest.createPool(deployer, TOKEN_TRAIT_ADDRESS , TICKET_TRAIT_ADDRESS, FEE_TO_ADDRESS, 100, 3e7, ACTIVATION_DELAY, ACTIVATION_THRESHOLD);
        result.receipts[0].result.expectOk().expectBool(true);
        // AV-7: please also check creating a pool by no contract-owner (i.e. wallet_1) fails.
        
        // we have 1 set as activation delay, so response should be u1
        result = ALPTest.getActivationDelay(TOKEN_TRAIT_ADDRESS);
        assertEquals(result.result, "(ok u1)");

        // we have 1 set as activation threshold, so response should be u1
        result = ALPTest.getActivationThreshold(TOKEN_TRAIT_ADDRESS);
        assertEquals(result.result, "(ok u1)");

        // AV-7: please also check adding position by non fee-to-address fails.
        result = ALPTest.addToPosition (deployer, TOKEN_TRAIT_ADDRESS, 1);
        result.receipts[0].result.expectOk().expectBool(true);
        
        // AV-7: please also check attempt to register more tickets than owned fails.
        result = ALPTest.register(wallet_1, TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS, 100)
        result.expectOk().expectBool(true);

        result = ALPTest.register(wallet_2, TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS, 10)
        result.expectOk().expectBool(true);

        // AV-7: please convert this to a test. It should check
        // ticket-balance = 10
        // tickets-won: 0
        // value-high: 110
        // value-low: 101
        console.log(await chain.callReadOnlyFn(
            "alex-launchpad",
            "get-subscriber-at-token-or-default",
            [
                types.principal(TOKEN_TRAIT_ADDRESS),
                types.uint(2)
            ],
            deployer.address
        ));

        // Contract should not register this same address again, and should throw 'already registered' error
        result = ALPTest.register(wallet_1, TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS, 1)
        result.expectErr().expectUint(10001);
        
        // AV-7: please conert this to a test. It should check
        // activation-block = 9
        // activation-delay = 1
        // activation-threshold = 1
        // amount-per-ticket = 100
        // fee-to-address = ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
        // last-random = 0
        // ticket = ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lottery-t-alex
        // tickets-won = 0
        // total-subscribed = 110
        // total-tickets = 1
        // users-nonce = 2
        // wstx-per-ticket-in-fixed = 30000000
        console.log((await chain.callReadOnlyFn(
            "alex-launchpad",
            "get-token-details",
            [
                types.principal(TOKEN_TRAIT_ADDRESS)
            ],
            wallet_1.address
        )).result);
        
        // mine a few blocks to test claim function
        chain.mineEmptyBlockUntil(9 + 2);

        // AV-7: please also check if you supply a wrong combiantion of TOKEN_TRAIT and TICKET_TRAIT, it fails
        result = ALPTest.claim(wallet_2, TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS)
        result.receipts[0].result.expectOk();     
        
        // AV-7: please add test cases against all asserts.

    }
})