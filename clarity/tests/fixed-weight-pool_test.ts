
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    FWPTestAgent1,
  } from './models/alex-tests-fixed-weight-pool.ts';

import { 
    MultiSigFWP,
} from './models/alex-tests-multisigs.ts';

import { 
    USDAToken,
    WBTCToken,
    FWPWBTCUSDA5050Token
  } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const fwpwbtcusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50"
const multisigAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50"
const fwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool"

const ONE_8 = 100000000

const weightX = 50000000 //0.5
const weightY = 50000000 //0.5

const wbtcPrice = 50000
const usdaPrice = 1

const wbtcQ = 100*ONE_8


Clarinet.test({
    name: "FWP : Pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        
        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigAddress, wbtcQ, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2236067605752);
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(wbtcQ*wbtcPrice);

        // Add extra liquidity (1/4 of initial liquidity)
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(2236067605752 / 4);
        position['dx'].expectUint(wbtcQ / 4);
        position['dy'].expectUint(wbtcQ*wbtcPrice / 4);

        // Check pool details and print
        call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2795084507190);
        position['balance-x'].expectUint(5/4 * wbtcQ);
        position['balance-y'].expectUint(5/4 * wbtcQ*wbtcPrice);        

        // Reduce all liquidlity
        result = FWPTest.reducePosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(5/4 * wbtcQ);
        position['dy'].expectUint(5/4 * wbtcQ * wbtcPrice);

        // Add back some liquidity
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ, wbtcQ*wbtcPrice);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(2236067605752);
        position['dx'].expectUint(wbtcQ);
        position['dy'].expectUint(wbtcQ*wbtcPrice);        

        // attempt to trade too much (> 2%) will be rejected
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 2*ONE_8);
        position = result.expectErr().expectUint(4001);

        // swap some wbtc into usda
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(4950465000000);    
        
        // swap some usda into wbtc
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, wbtcPrice*ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(103049997);
        position['dy'].expectUint(wbtcPrice*ONE_8);        

        // attempt to swap zero throws an error
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        result.expectErr().expectUint(2003);    
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        result.expectErr().expectUint(2003);               
    },
});



Clarinet.test({
    name: "FWP : Trading with fees and collecting with multisig.",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;

        let FWPTest = new FWPTestAgent1(chain, deployer);
        let MultiSigTest = new MultiSigFWP(chain, deployer, wallet_1);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        let fwpPoolToken = new FWPWBTCUSDA5050Token(chain, deployer);

        const feeRateX = 5000000; // 5%
        const feeRateY = 5000000;

        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigAddress, wbtcQ, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(wbtcAddress, usdaAddress,weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(2236067605752);
        position['balance-x'].expectUint(wbtcQ);
        position['balance-y'].expectUint(wbtcQ*wbtcPrice);

        // Add extra liquidity (1/4 of initial liquidity)
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(2236067605752 / 4);
        position['dx'].expectUint(wbtcQ / 4);
        position['dy'].expectUint(wbtcQ*wbtcPrice / 4);

        // Fee rate Setting Proposal of Multisig
        result = MultiSigTest.propose(1000, " Fee Rate Setting to 5%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
        
        // Block 1000 mining
        chain.mineEmptyBlock(1000);

        let ROresult:any = fwpPoolToken.balanceOf(deployer.address);
        ROresult.result.expectOk().expectUint(2795084507190);
        
        // 90 % of existing tokens are voted for the proposal
        result = MultiSigTest.voteFor(deployer, fwpwbtcusdaAddress, 1, 2795084507190 * 9 / 10 )
        result.expectOk().expectUint(2515576056471)

        // Block 1440 mining for ending proposal
        chain.mineEmptyBlock(1440);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectUint(10000) // Success 
       
        // Fee set to 5% 
        result = FWPTest.getFeeX(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectUint(5000000)
        result = FWPTest.getFeeY(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectUint(5000000)
        
        // Swapping 
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(95000000);    // 5% Fee Charged on ONE_8
        position['dy'].expectUint(4714125000000);    // Corresponding dy value
        
        // Swapping 
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8*wbtcPrice);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(97192466);    // Corresponding dx value
        position['dy'].expectUint(4750000000000);    // 5% Fee Charged on ONE_8*wbtcPrice
        
        // Fee Collected 
        ROresult = FWPTest.getPoolDetails(wbtcAddress, usdaAddress, weightX, weightY);
        position = ROresult.result.expectOk().expectTuple();
        position['fee-balance-x'].expectUint(5000000); 
        position['fee-balance-y'].expectUint(250000000000); 
        
        // Fee Collect - From pool to Multisig; TO DO after discussion
        
        
    },
});


Clarinet.test({
    name: "FWP : Error Testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTest = new FWPTestAgent1(chain, deployer);
        let MultiSigTest = new MultiSigFWP(chain, deployer, wallet_1);
        const feeRateX = 5000000; // 5%
        const feeRateY = 5000000;

        // Deployer creating a pool, initial tokens injected to the pool
        let result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigAddress, wbtcQ, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);
        
        // Duplicated pool creation
        result = FWPTest.createPool(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, multisigAddress, wbtcQ, wbtcQ*wbtcPrice);
        result.expectErr().expectUint(2000);
        
        // Tx-sender does not have enough balance
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ * 1000, wbtcQ*wbtcPrice * 1000);
        result.expectErr().expectUint(3001);

        // Tx-sender tries to add zero balance
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress,0, 0);
        result.expectErr().expectUint(2003);

        // Add liquidity
        result = FWPTest.addToPosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        let position:any = result.expectOk().expectTuple();

        // Reducing Liquidity more than 100%
        result = FWPTest.reducePosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, ONE_8+1);
        result.expectErr().expectUint(5000);

        // Reducing Liquidity of zero, Error caught on the code which tries to transfer zero balance from vault
        result = FWPTest.reducePosition(deployer, wbtcAddress, usdaAddress, weightX, weightY, fwpwbtcusdaAddress, 0);
        result.expectErr().expectUint(3001);

        // Swapping 
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(4960262500000);   

        // Attempts to trade more than limit
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8*ONE_8);
        result.expectErr().expectUint(4001); 

        // Zero swapping
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0);
        result.expectErr().expectUint(2003); 
       
        // Fee Setting
        result = MultiSigTest.propose(1000, " Fee Rate Setting to 5%", " https://docs.alexgo.io", feeRateX, feeRateY)
        result.expectOk().expectUint(1) // First Proposal
    
        // Attempt to vote before start 
        result = MultiSigTest.voteAgainst(deployer, fwpwbtcusdaAddress, 1, 4960262500000 * 9 / 10 )
        result.expectErr().expectUint(1000); 
        
        // Mine Block
        chain.mineEmptyBlock(1000);

        // Not enough balance for voting
        result = MultiSigTest.voteAgainst(deployer, fwpwbtcusdaAddress, 1, 4960262500000 * 9 / 10 )
        result.expectErr().expectUint(1); 

        result = MultiSigTest.voteAgainst(deployer, fwpwbtcusdaAddress, 1, 2960262500000 * 9 / 10 )
        result.expectOk().expectUint(10000); 

        // Attempt to end proposal before block height
        result = MultiSigTest.endProposal(1)
        result.expectErr().expectUint(8003) 

        // Mine Block
        chain.mineEmptyBlock(1440);

        // end proposal 
        result = MultiSigTest.endProposal(1)
        result.expectOk().expectUint(10000) 

        // Fee didn't change
        result = FWPTest.getFeeX(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectUint(0)

        result = FWPTest.getFeeY(deployer, wbtcAddress, usdaAddress, weightX, weightY);
        result.expectOk().expectUint(0)
    },
});
