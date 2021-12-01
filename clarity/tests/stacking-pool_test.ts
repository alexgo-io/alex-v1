import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";
import { StackingPool } from "./models/alex-tests-stacking-pool.ts";
import { ALEXToken } from "./models/alex-tests-tokens.ts";
  
const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex";
const stakedAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex";

const ACTIVATION_DELAY = 150
const rewardCycles: Array<string> = ["u1","u2","u3","u4","u5","u6","u7","u8","u9","u10","u11","u12","u13","u14","u15","u16","u17","u18","u19","u20","u21","u22","u23","u24","u25","u26","u27","u28","u29","u30","u31","u32"]

Clarinet.test({
    name: "STACKING POOL: Ensure that set-owner can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const notContractOwner = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;

        let block = chain.mineBlock([
        Tx.contractCall(
            "stacking-pool",
            "set-owner",
            [types.principal(wallet_2.address)],
            notContractOwner.address
        ),
        ]);

        block.receipts[0].result.expectErr().expectUint(1000);
    },
});

Clarinet.test({
    name: "STACKING POOL: Ensure that create-pool can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const notContractOwner = accounts.get("wallet_1")!;
        const stackingPool = new StackingPool(chain, notContractOwner)
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, [], stakedAlexAddress),
        ])
        stackingPoolBlock.receipts[0].result.expectErr().expectUint(1000);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only be called by valid token",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const stackingPool = new StackingPool(chain, deployer)
        
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress),
        ])
        stackingPoolBlock.receipts[0].result.expectErr().expectUint(2026);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only register new users",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const stackingPool = new StackingPool(chain, deployer);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.registerUser(alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress),
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress)
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)
        stackingPoolBlock.receipts[1].result.expectErr().expectUint(10001);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that stacking is available when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const stackingPool = new StackingPool(chain, deployer)
        const dx = 200*ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.registerUser(alexTokenAddress),
        ]);

        // creating a new pool
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress),
            stackingPool.addToPosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, dx)
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)
        stackingPoolBlock.receipts[1].result.expectErr().expectUint(2027);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that stacking is not in progress when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const stackingPool = new StackingPool(chain, deployer)
        const dx = 200*ONE_8

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.registerUser(alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, ["u0"], stakedAlexAddress),
            stackingPool.addToPosition(wallet_2, alexTokenAddress, alexTokenAddress, 0, stakedAlexAddress, dx)
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)
        stackingPoolBlock.receipts[1].result.expectErr().expectUint(2018);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that add-to-position works on a valid pool",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const stackingPool = new StackingPool(chain, deployer)
        const alexToken = new ALEXToken(chain, deployer)
        const dx = 200*ONE_8

        alexToken.mintFixed(deployer, wallet_2.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.registerUser(alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress),
            stackingPool.addToPosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, dx)
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)    
        stackingPoolBlock.receipts[1].result.expectOk().expectBool(true);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that reduce-position is called when stacking is not in progress",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const stackingPool = new StackingPool(chain, deployer)
        const alexToken = new ALEXToken(chain, deployer)
        
        //mint alex tokens
        alexToken.mintFixed(deployer, wallet_2.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.registerUser(alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, ["u1"], stakedAlexAddress),
            stackingPool.addToPosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, 200*ONE_8),
            stackingPool.reducePosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, 10)
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)    
        stackingPoolBlock.receipts[1].result.expectOk().expectBool(true);
        stackingPoolBlock.receipts[2].result.expectErr().expectUint(2018);
    }
})

Clarinet.test({
    name: "STACKING POOL: Ensure that deployer can create-pool, add-to-position and reduce-to-position",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const stackingPool = new StackingPool(chain, deployer)
        const alexToken = new ALEXToken(chain, deployer)
        
        //mint alex tokens
        alexToken.mintFixed(deployer, deployer.address, 200 * ONE_8);
        alexToken.mintFixed(deployer, wallet_2.address, 200 * ONE_8);

        // setting up a working stacking pool
        const setupBlock = chain.mineBlock([
            stackingPool.setActivationThreshold(1),
            stackingPool.addToken(alexTokenAddress),
            stackingPool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            stackingPool.registerUser(alexTokenAddress),
        ]);
        chain.mineEmptyBlockUntil(
            setupBlock.height + ACTIVATION_DELAY - 1
        );

        // creating a new pool
        const stackingPoolBlock = chain.mineBlock([
            stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress),
            stackingPool.addToPosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, 200*ONE_8),
        ]);
        stackingPoolBlock.receipts[0].result.expectOk().expectBool(true)    
        stackingPoolBlock.receipts[1].result.expectOk().expectBool(true);

        chain.mineEmptyBlockUntil(71553 + 1);

        const reducePosBlock = chain.mineBlock([
            stackingPool.reducePosition(wallet_2, alexTokenAddress, alexTokenAddress, 1, stakedAlexAddress, ONE_8)
        ]);

        let tuple:any = reducePosBlock.receipts[0].result.expectOk().expectTuple();
        tuple['poxl-token'].expectUint(200e8);
        tuple['reward-token'].expectUint(32 * ONE_8);
    }
})