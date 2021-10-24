

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { MS_YTP_WBT_79760} from './models/alex-tests-multisigs.ts';
import { USDAToken, WBTCToken, POOLTOKEN_YTP_WBTC_WBTC_79760} from './models/alex-tests-tokens.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';

// wallet_1 Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const yieldtokenwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-79760"
const pooltokenyieldwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-79760-wbtc"
const multisigytpyieldwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-79760-wbtc"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigfwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"


const ONE_8 = 100000000
const expiry = 79760 * ONE_8
const weightX = 0.5 * ONE_8
const weightY = 0.5 * ONE_8
const wbtcQ = 100*ONE_8
const wbtcPrice = 50000*ONE_8

Clarinet.test({
    name: "YTP : Fee Setting and Collection using Multisig ",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_2 = accounts.get("wallet_2")!;
        let FWPTest = new FWPTestAgent1(chain, wallet_1);
        let Oracle = new OracleManager(chain, wallet_1);
        let YTPTest = new YTPTestAgent1(chain, wallet_1);
        let MultiSigTest = new MS_YTP_WBT_79760(chain, wallet_1);
        let ytpPoolToken = new POOLTOKEN_YTP_WBTC_WBTC_79760(chain, wallet_1);
        let usdaToken = new USDAToken(chain, wallet_1);
        let wbtcToken = new WBTCToken(chain, wallet_1);
        const buffer = new ArrayBuffer(34)
        const feeRateX = 100000000; // 10%
        const feeRateY = 100000000;
        const alexPrice = 5*ONE_8;

        let oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",ONE_8);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"ALEX","coingecko",alexPrice);
        oracleresult.expectOk()

        // Transfer token from wallet_1 from wallet_2
        let money = usdaToken.transferToken(10*ONE_8,wallet_1.address,wallet_2.address, buffer);
        money = wbtcToken.transferToken(10*ONE_8,wallet_1.address,wallet_2.address, buffer);
        money.expectOk()

        let check = FWPTest.createPool(wallet_1, usdaAddress, yieldtokenwbtc79760, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, 10*ONE_8, 10*ONE_8);
        check.expectOk().expectBool(true);

        //wallet_1 creating a pool, initial tokens injected to the pool
        let result = YTPTest.createPool(wallet_1, yieldtokenwbtc79760, wbtcAddress, pooltokenyieldwbtc79760, multisigytpyieldwbtc79760, 1000*ONE_8, 1000*ONE_8);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        result = YTPTest.addToPosition(wallet_2, yieldtokenwbtc79760, wbtcAddress, pooltokenyieldwbtc79760, 10*ONE_8);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);   

        result = YTPTest.swapYForX(wallet_1, yieldtokenwbtc79760, wbtcAddress, ONE_8);
        position =result.expectOk().expectTuple();
        //position['dx'].expectUint(99978225);
        position['dy'].expectUint(ONE_8);

        call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        position = call.result.expectOk().expectTuple();
        //position['balance-token'].expectUint(100900021775); // u99900045311
        position['balance-aytoken'].expectUint(ONE_8);
        position['balance-virtual'].expectUint(1010*ONE_8);

        call = await ytpPoolToken.balanceOf(wallet_1.address);
        call.result.expectOk().expectUint(100000000000);    // u100000000000

        call = await ytpPoolToken.balanceOf(wallet_2.address);
        call.result.expectOk().expectUint(1000000000);

        // Fee rate Setting Proposal of Multisig, wallet_1 is proposing
        result = MultiSigTest.propose(1000, " Fee Rate Setting to 5%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        // wallet_1 has 99 % of pool token
        let ROresult:any = ytpPoolToken.balanceOf(wallet_1.address);
        ROresult.result.expectOk().expectUint(100000000000);
        
        // Wallet_2 votes his 90% asset
        result = MultiSigTest.voteFor(wallet_1, pooltokenyieldwbtc79760, 1, 1000000000 * 9 / 10 )
        result.expectOk().expectUint(900000000)

        // 90 % of existing tokens are voted for the proposal
        result = MultiSigTest.voteFor(wallet_1, pooltokenyieldwbtc79760, 1, 100000000000 * 9 / 10 )
        result.expectOk().expectUint(90000000000)

        chain.mineEmptyBlock(1440);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true) // Success 

        // Additional Swap after fee configuration
        result = YTPTest.swapYForX(wallet_1, yieldtokenwbtc79760, wbtcAddress, 5*ONE_8);
        position =result.expectOk().expectTuple();
        //position['dx'].expectUint(499971640);
        //position['dy'].expectUint(499990870);

        // Check that the fee has changed
        call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        position = call.result.expectOk().expectTuple();
        position['fee-rate-aytoken'].expectUint(feeRateX); 
        position['fee-rate-token'].expectUint(feeRateY);

        result = MultiSigTest.collectFees()
        result.expectOk().expectBool(true) // Success 

        
    },    
});