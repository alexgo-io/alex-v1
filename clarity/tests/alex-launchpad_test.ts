import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { ALEXLaunchpad } from './models/alex-tests-launchpad.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
import { 
    USDAToken,
    WBTCToken,
    WSTXToken
  } from './models/alex-tests-tokens.ts';

const ONE_8 = 100000000
const ACTIVATION_DELAY = 1
const ACTIVATION_THRESHOLD = 1
const OWNER = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE"
const TOKEN_TRAIT_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const TICKET_TRAIT_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda" 
const FEE_TO_ADDRESS = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE"
// this contract address will be added to the approved contracts of Ticket-Trait
const APPROVED_CONTRACT = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-launchpad"
// This activation block will be updated later once the contract will be activated
// For testing purpose we have used a random value, same value needs to be used in contract as well
const ACTIVATION_BLOCK = 34

Clarinet.test({
    name: "ALP: Testing helper functions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let ALPTest = new ALEXLaunchpad(chain, deployer);

        let result = ALPTest.setOwner(OWNER);
        result.expectOk().expectBool(true);

        let result2 = ALPTest.getOwner();
        assertEquals(result2.result, "(ok ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)");

    }
})

Clarinet.test({
    name: "ALP: pool creation, adding values and reducing values",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let ALPTest = new ALEXLaunchpad(chain, deployer);

        let wbtcToken = new WBTCToken(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wstxToken = new WSTXToken(chain, deployer);

        usdaToken.mintFixed(deployer, deployer.address, 1000000000 * ONE_8);
        wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        wstxToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);

        // Deployer creating a pool, FEE_TO_ADDRESS will be the one that's getting added in the pool
        let result1 = ALPTest.createPool(TOKEN_TRAIT_ADDRESS , TICKET_TRAIT_ADDRESS, FEE_TO_ADDRESS, 100, 10, ACTIVATION_DELAY, ACTIVATION_THRESHOLD);
        result1.receipts[0].result.expectOk().expectBool(true); 
        
        let result2 = ALPTest.getActivationBlock(TOKEN_TRAIT_ADDRESS);
        // this line will be updated with the ACTIVATION_BLOCK when alex-launchpad contract will be activated
        assertEquals(result2.result, "(ok u34)");
        
        // we have 1 set as activation delay, so response should be u1
        let result3 = ALPTest.getActivationDelay(TOKEN_TRAIT_ADDRESS);
        assertEquals(result3.result, "(ok u1)");

        // we have 1 set as activation threshold, so response should be u1
        let result4 = ALPTest.getActivationThreshold(TOKEN_TRAIT_ADDRESS);
        assertEquals(result4.result, "(ok u1)");

        let result5 = ALPTest.addToPosition (TOKEN_TRAIT_ADDRESS, 1);
        result5.receipts[0].result.expectOk().expectBool(true);
        
        let result6 = ALPTest.register(TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS, 1)
        result6.expectOk().expectBool(true);

        // Contract should not register this same address again, and should throw 'already registered' error
        let result7 = ALPTest.register(TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS, 1)
        result7.expectErr().expectUint(10001);

        let result8 = ALPTest.getRegisteredUsersNonce(TOKEN_TRAIT_ADDRESS);
        // For now, the contract is keeping u0 in users-nonce, not updating the mapping
        assertEquals(result8.result, "(ok u0)");
        
        // mine a few blocks to test claim function
        chain.mineEmptyBlock(ACTIVATION_BLOCK + 2);
        // set ticket trait owner to contract, for burning the tokens once transfered
        let result_9 = ALPTest.setTicketTraitOwner (TICKET_TRAIT_ADDRESS, APPROVED_CONTRACT)
        result_9.receipts[0].result.expectOk().expectBool(true);

        let result_10 = ALPTest.getTicketTraitOwner (TICKET_TRAIT_ADDRESS);
        assertEquals(result_10.result, "(ok ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-launchpad)");

        let result_11 = ALPTest.claim (TOKEN_TRAIT_ADDRESS, TICKET_TRAIT_ADDRESS)
        result_11.receipts[0].result.expectOk();
    }
})