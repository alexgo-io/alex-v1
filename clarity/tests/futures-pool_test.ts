import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.31.1/index.ts";
import { assertEquals } from "https://deno.land/std@0.113.0/testing/asserts.ts";
import { FuturesPool } from "./models/alex-tests-futures-pool.ts";
import { FWP_WSTX_ALEX_5050 } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const poolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01";
const stakedTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.staked-fwp-wstx-alex-50-50-v1-01";
const futuresPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.futures-pool";
const ACTIVATION_BLOCK = 20

Clarinet.test({
    name: "futures-pool : ensure that set-contract-owner can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var wallet_2 = accounts.get("wallet_2")!;

        let block = chain.mineBlock([
            Tx.contractCall(
                "futures-pool",
                "set-contract-owner",
                [types.principal(wallet_2.address)],
                notContractOwner.address
            ),
        ]);

        block.receipts[0].result.expectErr().expectUint(1000);
    },
});

Clarinet.test({
    name: "futures-pool : ensure that create-pool can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var futuresPool = new FuturesPool(chain)
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(notContractOwner, alexTokenAddress, [], stakedTokenAddress),
        ])
        futuresPoolBlock.receipts[0].result.expectErr().expectUint(1000);
    }
})

// name: "futures-pool : ensure that stacking is available when adding to position"
Clarinet.test({
    name: "futures-pool : ensure that stacking is available when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const futuresPool = new FuturesPool(chain)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 50000 * ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
        ]);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, poolTokenAddress, rewardCycles, stakedTokenAddress),
            futuresPool.addToPosition(deployer, poolTokenAddress, startCycle, stakedTokenAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(2027); //ERR-STACKING-NOT-AVAILABLE
    }
})

// name: "futures-pool : ensure that stacking is not in progress when adding to position"
Clarinet.test({
    name: "futures-pool : ensure that stacking is not in progress when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const futuresPool = new FuturesPool(chain)
        const dx = 50000 * ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
        ]);
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, poolTokenAddress, ["u0"], stakedTokenAddress),
            futuresPool.addToPosition(deployer, poolTokenAddress, 0, stakedTokenAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})

// name: "futures-pool : ensure that add-to-position works on a valid pool"
Clarinet.test({
    name: "futures-pool : ensure that add-to-position works on a valid pool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const futuresPool = new FuturesPool(chain)
        const token = new FWP_WSTX_ALEX_5050(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 200 * ONE_8;

        token.mintFixed(deployer, wallet_2.address, dx);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
            futuresPool.createPool(deployer, poolTokenAddress, rewardCycles, stakedTokenAddress)
        ]);
        setupBlock.receipts[4].result.expectOk().expectBool(true);

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([    
            futuresPool.addToPosition(wallet_2, poolTokenAddress, startCycle, stakedTokenAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true);
        
    }
})

// name: "futures-pool : ensure that reduce-position is called when stacking is not in progress"
Clarinet.test({
    name: "futures-pool : ensure that reduce-position is called when stacking is not in progress",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const futuresPool = new FuturesPool(chain)
        const token = new FWP_WSTX_ALEX_5050(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 200 * ONE_8;


        //mint alex tokens
        token.mintFixed(deployer, wallet_1.address, dx);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
            futuresPool.createPool(deployer, poolTokenAddress, rewardCycles, stakedTokenAddress),
        ]);
        setupBlock.receipts[4].result.expectOk().expectBool(true);        
        
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([            
            futuresPool.addToPosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, dx),
            futuresPool.reducePosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, ONE_8)
        ]);
        
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true);
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})

// name: "futures-pool : ensure that deployer can create-pool, add-to-position and reduce-to-position"
Clarinet.test({
    name: "futures-pool : ensure that deployer can create-pool, add-to-position and reduce-to-position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const futuresPool = new FuturesPool(chain)
        const token = new FWP_WSTX_ALEX_5050(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 200 * ONE_8;

        //mint alex tokens
        token.mintFixed(deployer, deployer.address, dx);
        token.mintFixed(deployer, wallet_1.address, dx);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
            futuresPool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            futuresPool.setCoinbaseAmount(deployer, poolTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            futuresPool.createPool(deployer, poolTokenAddress, rewardCycles, stakedTokenAddress),
        ]);
        setupBlock.receipts[6].result.expectOk().expectBool(true);        

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([            
            futuresPool.addToPosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, dx),
        ]);        
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true);

        const reward_cycle_length = Number((futuresPool.getRewardCycleLength(deployer).result.replace(/\D/g, "")));
        const first_block = Number((futuresPool.getFirstStacksBlockInRewardCycle(deployer, poolTokenAddress, 32).result.replace(/\D/g, "")));
        
        chain.mineEmptyBlockUntil(first_block + reward_cycle_length + 1);

        const reducePosBlock = chain.mineBlock([
            futuresPool.reducePosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, ONE_8)
        ]);
        // console.log(reducePosBlock.receipts);
        let tuple: any = reducePosBlock.receipts[0].result.expectOk().expectTuple();
        tuple['staked-token'].expectUint(dx);
        tuple['reward-token'].expectUint(32 * ONE_8);
    }
})

Clarinet.test({
    name: "futures-pool : ensure that deployer can create-pool, add-to-position, claim-and-stake, and reduce-to-position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const futuresPool = new FuturesPool(chain)
        const token = new FWP_WSTX_ALEX_5050(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 200 * ONE_8;

        //mint alex tokens
        token.mintFixed(deployer, deployer.address, dx);
        token.mintFixed(deployer, wallet_1.address, dx);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([            
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            futuresPool.addToken(deployer, poolTokenAddress),
            futuresPool.setActivationBlock(deployer, poolTokenAddress, ACTIVATION_BLOCK),
            futuresPool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            futuresPool.setCoinbaseAmount(deployer, poolTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            futuresPool.createPool(deployer, poolTokenAddress, rewardCycles, stakedTokenAddress),
        ]);
        setupBlock.receipts[6].result.expectOk().expectBool(true);

        const reward_cycle_length = Number((futuresPool.getRewardCycleLength(deployer).result.replace(/\D/g, "")));

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([            
            futuresPool.addToPosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, dx),
        ]);        
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true);        
                
        let first_block = Number((futuresPool.getFirstStacksBlockInRewardCycle(deployer, poolTokenAddress, 2).result.replace(/\D/g, "")));
        
        chain.mineEmptyBlockUntil(first_block);
        const claimStakeBlock = chain.mineBlock([
            futuresPool.claimAndStake(wallet_1, poolTokenAddress, startCycle)
        ]);
        claimStakeBlock.receipts[0].result.expectOk().expectBool(true);

        first_block = Number((futuresPool.getFirstStacksBlockInRewardCycle(deployer, poolTokenAddress, 32).result.replace(/\D/g, "")));       

        chain.mineEmptyBlockUntil(first_block + reward_cycle_length + 1);
        const reducePosBlock = chain.mineBlock([
            futuresPool.reducePosition(wallet_1, poolTokenAddress, startCycle, stakedTokenAddress, ONE_8)
        ]);
        // console.log(reducePosBlock.receipts);
        let tuple: any = reducePosBlock.receipts[0].result.expectOk().expectTuple();
        tuple['staked-token'].expectUint(dx);
        tuple['reward-token'].expectUint(32 * ONE_8 - 0.01 * ONE_8 + 30 * ONE_8);
    }
})