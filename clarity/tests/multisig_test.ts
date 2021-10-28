

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { MS_YTP_WBT_79760} from './models/alex-tests-multisigs.ts';
import { ALEXToken,USDAToken, WBTCToken, POOLTOKEN_YTP_WBTC_WBTC_79760, YIELDTOKEN_WBTC_79760} from './models/alex-tests-tokens.ts';
import { OracleManager } from './models/alex-tests-oracle-mock.ts';

/**
 * Purpose of this testcase is to check whether multisig collects the expected transaction fee and stakeholders to retrieve tokens.
 * 
 *  For each trade, designated fee are settled and collected.
 *  
 *  Step 1. Fee setting 
 *  - [Proposal] : Pool token holder, who has more than 10% of mint pool token can propose a amount of fee to be collected. 
 *  - [Vote] : Pool token holders has a right to vote, where the vote itself is amount of pool token
 *  - [Execute Vote] : When the vote on agreement is higher than the threshold, feerate of the pool is set to proposal
 *  - [Collect Fee] : Fee can be collected anytime. // - > Anyone can trigger for now
 *  - When Collect Fee is triggered, collect-fee in YTP swaps collected fee to USDA then swaps again to ALEX using alex-reserve pool
 *  
 *  
 *  - On alex-reserve pool, it converts USDA to ALEX token and sends to corresponding multisig
 *  - Pool token holders can retreive stored ALEX token proportional to their amount of pool token
 * 
 *  - After proposal ends (fee changed), Voters need to take votes by them selves. 
 */



const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const yieldtokenwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-79760"
const pooltokenyieldwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-79760-wbtc"
const multisigytpyieldwbtc79760 = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-79760-wbtc"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-usda-wbtc-79760-50-50"
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
        let yieldToken = new YIELDTOKEN_WBTC_79760(chain, wallet_1);
        let usdaToken = new USDAToken(chain, wallet_1);
        let wbtcToken = new WBTCToken(chain, wallet_1);
        let alexToken = new ALEXToken(chain, wallet_1);
        const buffer = new ArrayBuffer(34)
        const feeRateX = 1000000000; // 10%
        const feeRateY = 1000000000;
        const alexPrice = ONE_8;


        // Basic Token Initialization
        let oracleresult = Oracle.updatePrice(deployer,"USDA","coingecko",ONE_8);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"ALEX","coingecko",alexPrice);
        oracleresult.expectOk()

        // Transfer token from wallet_1 from wallet_2
        let money:any = usdaToken.transferToken(100*ONE_8,wallet_1.address,wallet_2.address, buffer);
        money = wbtcToken.transferToken(10*ONE_8,wallet_1.address,wallet_2.address, buffer);
        money.expectOk()
        money = await usdaToken.balanceOf(wallet_1.address)
        money.result.expectOk().expectUint(190000000000) //u190000000000
        money = await usdaToken.balanceOf(wallet_2.address)
        money.result.expectOk().expectUint(10000000000) // u1000000000
        money = await yieldToken.balanceOf(wallet_1.address)
        money.result.expectOk().expectUint(2000000000000)

        // Wallet 1 : 
        // Wallet 2 : 

        // Pool Initialization 
        let pools = FWPTest.createPool(wallet_1, usdaAddress, yieldtokenwbtc79760, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, 100*ONE_8, 100*ONE_8);
        pools.expectOk().expectBool(true);

        pools = FWPTest.createPool(wallet_1, usdaAddress, wbtcAddress, weightX, weightY, fwpwbtcusdaAddress, multisigfwpAddress, 100*ONE_8, 100*ONE_8);
        pools.expectOk().expectBool(true);
        
        pools = YTPTest.createPool(wallet_1, yieldtokenwbtc79760, wbtcAddress, pooltokenyieldwbtc79760, multisigytpyieldwbtc79760, 1000*ONE_8, 1000*ONE_8);
        pools.expectOk().expectBool(true);
        
        // Check pool details and print
        let call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-token'].expectUint(1000*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(1000*ONE_8);

        let result = YTPTest.addToPosition(wallet_2, yieldtokenwbtc79760, wbtcAddress, pooltokenyieldwbtc79760, 10*ONE_8);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(10*ONE_8);
        position['balance-token'].expectUint(10*ONE_8);
        position['balance-aytoken'].expectUint(0);
        position['balance-virtual'].expectUint(10*ONE_8);   

        money = await ytpPoolToken.balanceOf(wallet_1.address)
        money.result.expectOk().expectUint(1000*ONE_8)
        money = await ytpPoolToken.balanceOf(wallet_2.address)
        money.result.expectOk().expectUint(10*ONE_8)

        result = YTPTest.swapYForX(wallet_1, yieldtokenwbtc79760, wbtcAddress, ONE_8, 0);
        position =result.expectOk().expectTuple();
        //position['dx'].expectUint(99978225);
        position['dy'].expectUint(ONE_8);

        call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        position = call.result.expectOk().expectTuple();
        //position['balance-token'].expectUint(100900021775); // u99900045311
        position['balance-aytoken'].expectUint(ONE_8);
        position['balance-virtual'].expectUint(1010*ONE_8);

        call = await ytpPoolToken.balanceOf(wallet_1.address);
        call.result.expectOk().expectUint(1000*ONE_8);    // u100000000000

        call = await ytpPoolToken.balanceOf(wallet_2.address);
        call.result.expectOk().expectUint(10*ONE_8);
        

        // PoolToken Balance 
        // Wallet 1 : 1000*ONE_8 
        // Wallet 2 : 10*ONE_8

        // Fee rate Setting Proposal of Multisig, wallet_1 is proposing
        result = MultiSigTest.propose(1000, " Fee Rate Setting to 10%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        // wallet_1 has 99 % of pool token
        let ROresult:any = ytpPoolToken.balanceOf(wallet_1.address);
        ROresult.result.expectOk().expectUint(1000*ONE_8);
        
        // Wallet_2 votes his 90% asset
        result = MultiSigTest.voteFor(wallet_2, pooltokenyieldwbtc79760, 1, 1000000000 * 9 / 10 )
        result.expectOk().expectUint(9*ONE_8)

        // Wallet_1 votes his 90% asset; 90 % of existing tokens are voted for the proposal
        result = MultiSigTest.voteFor(wallet_1, pooltokenyieldwbtc79760, 1, 100000000000 * 9 / 10 )
        result.expectOk().expectUint(900*ONE_8)

        chain.mineEmptyBlock(1440);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectBool(true) // Success 

        // Check that the fee has changed
        call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        position = call.result.expectOk().expectTuple();
        position['fee-rate-aytoken'].expectUint(feeRateX); 
        position['fee-rate-token'].expectUint(feeRateY);
        
        // Retreive Pool Token
        result = MultiSigTest.returnVotes(pooltokenyieldwbtc79760,1,wallet_1.address)
        result = MultiSigTest.returnVotes(pooltokenyieldwbtc79760,1,wallet_2.address)

        // Additional Swap after fee configuration
        result = YTPTest.swapYForX(wallet_1, yieldtokenwbtc79760, wbtcAddress, 100*ONE_8, 0);
        position =result.expectOk().expectTuple();
        result = YTPTest.swapXForY(wallet_1, yieldtokenwbtc79760, wbtcAddress, 100*ONE_8, 0);
        position =result.expectOk().expectTuple();
        //position['dx'].expectUint(499971640);
        //position['dy'].expectUint(499990870);

        call = await ytpPoolToken.balanceOf(wallet_1.address);
        call.result.expectOk().expectUint(1000*ONE_8);    // 90 % of pool tokens were used for proposal

        call = await ytpPoolToken.balanceOf(wallet_2.address);
        call.result.expectOk().expectUint(10*ONE_8);   // 90 % of pool tokens were used for proposal

        call = await YTPTest.getPoolDetails(yieldtokenwbtc79760);
        position = call.result.expectOk().expectTuple();
        position['fee-balance-aytoken'].expectUint(1826000); 
        position['fee-balance-token'].expectUint(184693000);

        
        // call = await FWPTest.getPoolDetails(usdaAddress, yieldtokenwbtc79760,weightX, weightY);
        // position = call.result.expectErr().expectTuple();
        // position['total-supply'].expectUint(2795084507190);
        // position['balance-x'].expectUint(5/4 * wbtcQ);
        // position['balance-y'].expectUint(5/4 * wbtcQ*wbtcPrice);        

        
        // result = FWPTest.swapYForX(wallet_1, usdaAddress, yieldtokenwbtc79760, weightX, weightY, ONE_8);
        // position = result.expectOk().expectTuple();

        call = await ytpPoolToken.balanceOf(wallet_1.address);
        call.result.expectOk().expectUint(1000*ONE_8);    // 90 % of pool tokens were used for proposal

        // 50 % of corresponding alextoken was minted, owned by multisig.  
        // need to put multisig as account
        result = MultiSigTest.collectFees()
        // result.expectOk().expectUint(94086200*ONE_8) 

        // result = MultiSigTest.returnVotes(pooltokenyieldwbtc79760, 1, wallet_1.address)
        // result.expectOk()
        // result = MultiSigTest.returnVotes(pooltokenyieldwbtc79760, 1, wallet_2.address)
        // result.expectOk()

        // call = await ytpPoolToken.balanceOf(wallet_1.address);
        // call.result.expectOk().expectUint(1000*ONE_8);    // 90 % of pool tokens were used for proposal

        // call = await alexToken.balanceOf(wallet_1,multisigytpyieldwbtc79760);
        // call.result.expectErr()

        // result = MultiSigTest.retreiveRebates(wallet_1,pooltokenyieldwbtc79760,1000*ONE_8,1)
        // result.expectOk()

        
    },    
});