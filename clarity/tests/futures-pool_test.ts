import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";
import { FuturesPool } from "./models/alex-tests-futures-pool.ts";
import { ALEXToken } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const stakedAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.staked-alex";
const ACTIVATION_DELAY = 150

Clarinet.test({
    name: "STACKING POOL: Ensure that set-contract-owner can only be called by contract owner",
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
    name: "STACKING POOL: Ensure that create-pool can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var futuresPool = new FuturesPool(chain)
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(notContractOwner, alexTokenAddress, [], stakedAlexAddress),
        ])
        futuresPoolBlock.receipts[0].result.expectErr().expectUint(1000);
    }
})

// name: "STACKING POOL: Ensure that register-user can only be called by valid token"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only be called by valid token",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const futuresPool = new FuturesPool(chain)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]

        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress),
        ])
        futuresPoolBlock.receipts[0].result.expectErr().expectUint(2026); //ERR-INVALID-TOKEN
    }
})

// name: "STACKING POOL: Ensure that register-user can only register new users"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only register new users",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var deployer = accounts.get("deployer")!;
        const otherUser = accounts.get("wallet_2")!;
        const futuresPool = new FuturesPool(chain);
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.registerUser(otherUser, alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress),
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(10001); //ERR-USER-ALREADY-REGISTERED
    }
})

// name: "STACKING POOL: Ensure that pool doesn't exist when creating pool"
// Wont get 2000 error because I cannot create pool the same twice: Conflicting asserts of Contract owner and register-user

// name: "STACKING POOL: Ensure that stacking is available when adding to position"
Clarinet.test({
    name: "STACKING POOL: Ensure that stacking is available when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const futuresPool = new FuturesPool(chain)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const startCycle = 1;
        const dx = 50000 * ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.registerUser(deployer, alexTokenAddress),
        ]);

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress),
            futuresPool.addToPosition(deployer, alexTokenAddress, startCycle, stakedAlexAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(2027); //ERR-STACKING-NOT-AVAILABLE
    }
})

// name: "STACKING POOL: Ensure that stacking is not in progress when adding to position"
Clarinet.test({
    name: "STACKING POOL: Ensure that stacking is not in progress when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const futuresPool = new FuturesPool(chain)
        const dx = 50000 * ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.registerUser(deployer, alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, ["u0"], stakedAlexAddress),
            futuresPool.addToPosition(deployer, alexTokenAddress, 0, stakedAlexAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})

// name: "STACKING POOL: Ensure that add-to-position works on a valid pool"
Clarinet.test({
    name: "STACKING POOL: Ensure that add-to-position works on a valid pool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const futuresPool = new FuturesPool(chain)
        const alexToken = new ALEXToken(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]
        const dx = 200 * ONE_8

        alexToken.mintFixed(deployer, wallet_2.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.registerUser(wallet_2, alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress),
            futuresPool.addToPosition(wallet_2, alexTokenAddress, 1, stakedAlexAddress, dx)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectOk().expectBool(true);
    }
})

// name: "STACKING POOL: Ensure that reduce-position is called when stacking is not in progress"
Clarinet.test({
    name: "STACKING POOL: Ensure that reduce-position is called when stacking is not in progress",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const futuresPool = new FuturesPool(chain)
        const alexToken = new ALEXToken(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]

        //mint alex tokens
        alexToken.mintFixed(deployer, wallet_1.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.registerUser(wallet_1, alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, ["u1"], stakedAlexAddress),
            futuresPool.addToPosition(wallet_1, alexTokenAddress, 1, stakedAlexAddress, 200 * ONE_8),
            futuresPool.reducePosition(wallet_1, alexTokenAddress, 1, stakedAlexAddress, 10)
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectOk().expectBool(true);
        futuresPoolBlock.receipts[2].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})

// name: "STACKING POOL: Ensure that deployer can create-pool, add-to-position and reduce-to-position"
Clarinet.test({
    name: "STACKING POOL: Ensure that deployer can create-pool, add-to-position and reduce-to-position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const futuresPool = new FuturesPool(chain)
        const alexToken = new ALEXToken(chain, deployer)
        const rewardCycles: Array<string> = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19", "u20", "u21", "u22", "u23", "u24", "u25", "u26", "u27", "u28", "u29", "u30", "u31", "u32"]

        //mint alex tokens
        alexToken.mintFixed(deployer, deployer.address, 200 * ONE_8);
        alexToken.mintFixed(deployer, wallet_1.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            futuresPool.setActivationThreshold(deployer, 1),
            futuresPool.addToken(deployer, alexTokenAddress),
            futuresPool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            futuresPool.registerUser(deployer, alexTokenAddress),
            futuresPool.registerUser(wallet_1, alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const futuresPoolBlock = chain.mineBlock([
            futuresPool.createPool(deployer, alexTokenAddress, rewardCycles, stakedAlexAddress),
            futuresPool.addToPosition(wallet_1, alexTokenAddress, 1, stakedAlexAddress, 200 * ONE_8),
        ]);
        futuresPoolBlock.receipts[0].result.expectOk().expectBool(true)
        futuresPoolBlock.receipts[1].result.expectOk().expectBool(true);

        // console.log(futuresPool.getRewardCycleLength(deployer).result)
        // console.log(futuresPool.getFirstStacksBlockInRewardCycle(deployer, alexTokenAddress, 1 + 32).result) 
        // 71553

        // chain.mineEmptyBlockUntil(
        //     Number(futuresPool.getRewardCycleLength(deployer).result) +
        //     Number(futuresPool.getFirstStacksBlockInRewardCycle(deployer, alexTokenAddress, 1 + 32).result) +
        //      + 1);
        chain.mineEmptyBlockUntil(71553 + 1);

        const reducePosBlock = chain.mineBlock([
            futuresPool.reducePosition(wallet_1, alexTokenAddress, 1, stakedAlexAddress, ONE_8)
        ]);

        let tuple: any = reducePosBlock.receipts[0].result.expectOk().expectTuple();
        tuple['staked-token'].expectUint(200e8);
        tuple['reward-token'].expectUint(32 * ONE_8);
    }
})