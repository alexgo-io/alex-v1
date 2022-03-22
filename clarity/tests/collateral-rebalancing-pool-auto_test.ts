import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent1, FWPTestAgent3 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens";

const ONE_8 = 100000000

const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const autoAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-alex";
const fwpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-autoalex";
const multisigFwpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-autoalex";
const ytpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-alex";
const multisigYtpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-alex";
const yieldAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-alex";
const keyAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-alex-autoalex";
const multisigCrpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-alex-autoalex";

const ACTIVATION_BLOCK = 20;
const BountyPercentage = 0.001;
const BountyCap = 10 * ONE_8;
const APOWER_MULTIPLIER = ONE_8;

const liquidity = 100 * ONE_8;

const ltv_0 = 0.5e8;
const conversion_ltv = 0.9e8;
const bs_vol = 1e8;
const moving_average = 0.95e8;
const token_to_maturity = 0e8;

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that privileged setters can only be called by contract owner",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         var notContractOwner = accounts.get("wallet_1")!;
//         var wallet_2 = accounts.get("wallet_2")!;

//         let block = chain.mineBlock([
//             Tx.contractCall(
//                 "yield-vault-alex",
//                 "set-contract-owner",
//                 [types.principal(wallet_2.address)],
//                 notContractOwner.address
//             ),
//             Tx.contractCall(
//                 "yield-vault-alex",
//                 "set-activated",
//                 [types.bool(true)],
//                 notContractOwner.address
//             ),      
//             Tx.contractCall(
//                 "yield-vault-alex",
//                 "set-claim-and-stake-bounty-in-fixed",
//                 [types.uint(0)],
//                 notContractOwner.address
//             ),                    
//             Tx.contractCall(
//                 "yield-vault-alex",
//                 "set-claim-and-stake-bounty-max-in-fixed",
//                 [types.uint(0)],
//                 notContractOwner.address
//             ),                             
//         ]);
//         for(let i = 0; i < block.receipts.length; i++){
//             block.receipts[i].result.expectErr().expectUint(1000);
//         }
//     },
// });

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that contract is activated when adding to position",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = 50000 * ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         const setupBlock = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8)            
//         ]);
//         for(let i = 0; i < setupBlock.receipts.length; i++){
//             setupBlock.receipts[i].result.expectOk();
//         }

//         const addBlock = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx)
//         ]);
//         addBlock.receipts[0].result.expectErr().expectUint(2043);; //ERR-NOT-ACTIVATED
//     }
// })

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that stacking is available when adding to position",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = 50000 * ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         const setupBlock = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
//             yieldVault.setActivated(deployer, true)   
//         ]);
//         for(let i = 0; i < setupBlock.receipts.length; i++){
//             setupBlock.receipts[i].result.expectOk();
//         }

//         const addBlock = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx)
//         ]);
//         addBlock.receipts[0].result.expectErr().expectUint(10015);; //ERR-STACKING-NOT-AVAILABLE
//     }
// })

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that add-to-position works on a valid pool",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const wallet_2 = accounts.get("wallet_2")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         let block = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
//             yieldVault.setActivated(deployer, true)   
//         ]);
//         for(let i = 0; i < block.receipts.length; i++){
//             block.receipts[i].result.expectOk();
//         }

//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

//         block = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             wallet_1.address,
//             deployer.address + ".yield-vault-alex",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             deployer.address + ".yield-vault-alex",
//             deployer.address + ".alex-vault",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             dx,
//             wallet_1.address,
//             "auto-alex"
//         );
        
//         // end of cycle 0
//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

//         result = alexToken.mintFixed(deployer, wallet_2.address, dx);
//         result.expectOk();        

//         block = chain.mineBlock([
//             yieldVault.addToPosition(wallet_2, dx)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             wallet_2.address,
//             deployer.address + ".yield-vault-alex",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             deployer.address + ".yield-vault-alex",
//             deployer.address + ".alex-vault",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             dx / 2,
//             wallet_2.address,
//             "auto-alex"
//         );
//     }
// })

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that claim-and-stake cannot claim future cycles",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const wallet_2 = accounts.get("wallet_2")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         let block = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
//             yieldVault.setActivated(deployer, true)   
//         ]);
//         for(let i = 0; i < block.receipts.length; i++){
//             block.receipts[i].result.expectOk();
//         }

//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

//         block = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             wallet_1.address,
//             deployer.address + ".yield-vault-alex",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             deployer.address + ".yield-vault-alex",
//             deployer.address + ".alex-vault",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             dx,
//             wallet_1.address,
//             "auto-alex"
//         );
        
//         // end of cycle 0
//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

//         block = chain.mineBlock([
//             yieldVault.claimAndStake(wallet_2, 2)
//         ]);
//         block.receipts[0].result.expectErr().expectUint(10017); //ERR-REWARD-CYCLE-NOT-COMPLETED
//     }
// })

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that claim-and-stake works with a valid cycle",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const wallet_2 = accounts.get("wallet_2")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         let block = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
//             yieldVault.setActivated(deployer, true)   
//         ]);
//         for(let i = 0; i < block.receipts.length; i++){
//             block.receipts[i].result.expectOk();
//         }

//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

//         block = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             wallet_1.address,
//             deployer.address + ".yield-vault-alex",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             deployer.address + ".yield-vault-alex",
//             deployer.address + ".alex-vault",
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             dx,
//             wallet_1.address,
//             "auto-alex"
//         );
        
//         // end of cycle 1
//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

//         block = chain.mineBlock([
//             yieldVault.claimAndStake(wallet_2, 1)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             ONE_8,
//             deployer.address + ".yield-vault-alex",
//             "alex"
//         );        
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             Math.min(BountyCap, ONE_8 * BountyPercentage),
//             deployer.address + ".yield-vault-alex",
//             wallet_2.address,
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             ONE_8 - Math.min(BountyCap, ONE_8 * BountyPercentage),
//             deployer.address + ".yield-vault-alex",
//             deployer.address + ".alex-vault",
//             "alex"
//         );

//     }
// })

// Clarinet.test({
//     name: "YIELD VAULT: Ensure that claim-staking-reward works",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet_1 = accounts.get("wallet_1")!;
//         const wallet_2 = accounts.get("wallet_2")!;
//         const yieldVault = new YieldVault(chain);
//         const reservePool = new ReservePool(chain);
//         const alexToken = new ALEXToken(chain, deployer);
//         const dx = ONE_8;

//         let result:any = alexToken.mintFixed(deployer, wallet_1.address, dx);
//         result.expectOk();

//         let block = chain.mineBlock([
//             reservePool.addToken(deployer, alexTokenAddress),
//             reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
//             reservePool.setApowerMultiplierInFixed(deployer, alexTokenAddress, APOWER_MULTIPLIER),
//             reservePool.addToken(deployer, autoAlexAddress),
//             reservePool.setActivationBlock(deployer, autoAlexAddress, ACTIVATION_BLOCK),
//             reservePool.setCoinbaseAmount(deployer, autoAlexAddress, 0, 0, 0, 0, 0),
//             reservePool.setApowerMultiplierInFixed(deployer, autoAlexAddress, APOWER_MULTIPLIER),
//             yieldVault.setActivated(deployer, true),
//             Tx.contractCall("token-apower", "add-approved-contract", [types.principal(alexVaultAddress)], deployer.address)   
//         ]);
//         for(let i = 0; i < block.receipts.length; i++){
//             block.receipts[i].result.expectOk();
//         }

//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

//         block = chain.mineBlock([
//             yieldVault.addToPosition(wallet_1, dx),
//             yieldVault.stakeTokens(wallet_1, dx, 1),
//             yieldVault.stakeTokens(wallet_2, dx, 1)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         block.receipts[1].result.expectOk().expectBool(true);
//         block.receipts[2].result.expectErr().expectUint(3000);
        
//         // end of cycle 1
//         chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

//         block = chain.mineBlock([            
//             yieldVault.claimStakingReward(wallet_1, 1),
//             yieldVault.claimStakingReward(wallet_2, 1)
//         ]);
//         block.receipts[0].result.expectOk().expectBool(true);
//         block.receipts[1].result.expectErr().expectUint(10003);
//         // console.log(block.receipts[0].events);

//         block.receipts[0].events.expectFungibleTokenMintEvent(
//             ONE_8,
//             wallet_1.address,
//             "apower"
//         );        
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             Math.min(BountyCap, ONE_8 * BountyPercentage),
//             deployer.address + ".yield-vault-alex",
//             wallet_1.address,
//             "alex"
//         );
//         block.receipts[0].events.expectFungibleTokenTransferEvent(
//             dx,
//             deployer.address + ".alex-vault",
//             wallet_1.address,
//             "auto-alex"
//         );

//     }
// })

Clarinet.test({
    name: "YIELD VAULT: Ensure that claim-staking-reward works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const reservePool = new ReservePool(chain);
        const CRPTest = new CRPTestAgent1(chain, deployer);
        const FWPTest = new FWPTestAgent3(chain, deployer);
        const YTPTest = new YTPTestAgent1(chain, deployer);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const autoAlexToken = new FungibleToken(chain, deployer, "auto-alex");

        const dx = ONE_8;

        let block = chain.mineBlock([
            alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8),
            alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8),
            autoAlexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8),
            autoAlexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8),
            FWPTest.setMaxInRatio(deployer, 0.3e8),
            FWPTest.setMaxOutRatio(deployer, 0.3e8),
            FWPTest.createPool(deployer, alexAddress, autoAlexAddress, fwpAlexAutoalexAddress, multisigFwpAlexAutoalexAddress, liquidity, liquidity),
            FWPTest.setStartBlock(deployer, alexAddress, autoAlexAddress, 0),
            FWPTest.setOracleEnabled(deployer, alexAddress, autoAlexAddress),
            FWPTest.setOracleAverage(deployer, alexAddress, autoAlexAddress, 0.95e8)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });      

        block = chain.mineBlock([
            reservePool.addToken(deployer, alexAddress),
            reservePool.setActivationBlock(deployer, alexAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.setApowerMultiplierInFixed(deployer, alexAddress, APOWER_MULTIPLIER)   
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        let expiry = chain.callReadOnlyFn("collateral-rebalancing-pool", "get-expiry", [types.principal(ytpAlexAddress)], deployer.address);
        console.log(expiry);
        
        block = chain.mineBlock([
            YTPTest.createPool(deployer, expiry, yieldAlexAddress, alexAddress, ytpAlexAddress, multisigYtpAlexAddress, liquidity, 0),
            CRPTest.createPool(deployer, alexAddress, autoAlexAddress, expiry, yieldAlexAddress, keyAlexAutoalexAddress, multisigCrpAlexAutoalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        ]);

        result = ;
        result.expectOk().expectTuple();

        //Deployer creating a pool, initial tokens injected to the pool
        result = CRPTest.createPool(deployer, wbtcAddress, usdaAddress, expiry, yieldwbtcAddress, keywbtcAddress, multisigncrpwbtcAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, 50000 * ONE_8);
        result.expectOk().expectTuple();          
    }
});

