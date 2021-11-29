import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";
import { StackingPool } from "./models/alex-tests-stacking-pool.ts";
  
const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex";
const stakedAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex";

Clarinet.test({
    name: "STACKING POOL: Ensure that set-owner can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var wallet_2 = accounts.get("wallet_2")!;

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
        var notContractOwner = accounts.get("wallet_1")!;
        var stackingPool = new StackingPool(chain, notContractOwner)
        var result = stackingPool.createPool(alexTokenAddress, alexTokenAddress, [], stakedAlexAddress)
        result.expectErr().expectUint(1000);
    }
})

// name: "STACKING POOL: Ensure that register-user can only be called by valid token"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only be called by valid token",
    async fn(chain: Chain, accounts: Map<string, Account>){
        const deployer = accounts.get("deployer")!;
        const user = accounts.get("wallet_4")!;
        const stackingPool = new StackingPool(chain, deployer)
        const rewardCycles = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32]
        
        // setting up a working stacking pool
        var result = stackingPool.setActivationThreshold(1)
        result.expectOk().expectBool(true)
        result = stackingPool.addToken(alexTokenAddress, 1)
        result.expectOk().expectBool(true)
        result = stackingPool.registerUser(alexTokenAddress, "")
        result.expectOk().expectBool(true)
        
        var result = stackingPool.createPool(alexTokenAddress, alexTokenAddress, rewardCycles, stakedAlexAddress)
        result.expectErr().expectUint(2026); //ERR-INVALID-TOKEN
    }
})

/*
// name: "STACKING POOL: Ensure that register-user can only register new users"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only register new users",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var result = createPool(deployer, poxlTokenTraitAddress, rewardTokenTraitAddress, [], yieldTokenAddress, chain)
        result.expectErr().expectUint(10001); //ERR-USER-ALREADY-REGISTERED
        // var rewardCycles = []
        // let block = chain.mineBlock([
        //     Tx.contractCall(
        //         "stacking-pool",
        //         "create-pool",
        //         [
        //             types.principal(poxlTokenTraitAddress),
        //             types.principal(rewardTokenTraitAddress),
        //             types.list(rewardCycles),
        //             types.principal(yieldTokenAddress),
        //             types.principal(multisigAddress),
        //         ],
        //         deployer.address
        //     ),
        // ]);
    
        // block.receipts[0].result.expectErr().expectUint(10001); //ERR-USER-ALREADY-REGISTERED
    }
})

// name: "STACKING POOL: Ensure that register-user can only succeed if activation threshold is not reached"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only succeed if activation threshold is not reached",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var result = createPool(deployer, poxlTokenTraitAddress, rewardTokenTraitAddress, [], yieldTokenAddress, chain)
        result.expectErr().expectUint(10004); //ERR-ACTIVATION-THRESHOLD-REACHED

        // var rewardCycles = []
        // let block = chain.mineBlock([
        //     Tx.contractCall(
        //         "stacking-pool",
        //         "create-pool",
        //         [
        //             types.principal(poxlTokenTraitAddress),
        //             types.principal(rewardTokenTraitAddress),
        //             types.list(rewardCycles),
        //             types.principal(yieldTokenAddress),
        //             types.principal(multisigAddress),
        //         ],
        //         deployer.address
        //     ),
        // ]);
    
        // block.receipts[0].result.expectErr().expectUint(10004); //ERR-ACTIVATION-THRESHOLD-REACHED
    }
})

// name: "STACKING POOL: Ensure that pool doesn't exist when creating pool"
Clarinet.test({
    name: "STACKING POOL: Ensure that register-user can only succeed if activation threshold is not reached",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var result = createPool(deployer, poxlTokenTraitAddress, rewardTokenTraitAddress, [], yieldTokenAddress, chain)
        result.expectErr().expectUint(2000); //ERR-POOL-ALREADY-EXISTS
        
        // var rewardCycles = []
        // let block = chain.mineBlock([
        //     Tx.contractCall(
        //         "stacking-pool",
        //         "create-pool",
        //         [
        //             types.principal(poxlTokenTraitAddress),
        //             types.principal(rewardTokenTraitAddress),
        //             types.list(rewardCycles),
        //             types.principal(yieldTokenAddress),
        //             types.principal(multisigAddress),
        //         ],
        //         deployer.address
        //     ),
        // ]);
    
        // block.receipts[0].result.expectErr().expectUint(2000); //ERR-POOL-ALREADY-EXISTS
    }
})

// name: "STACKING POOL: Ensure that stacking is not in progress when adding to position"
Clarinet.test({
    name: "STACKING POOL: Ensure that stacking is not in progress when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})

// name: "STACKING POOL: Ensure that stake-tokens can only be called by valid token"
Clarinet.test({
    name: "STACKING POOL: Ensure that stake-tokens can only be called by valid token",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(2026); //ERR-INVALID-TOKEN
    }
})

// name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when contract is activated"
Clarinet.test({
    name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when contract is activated",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(10005); //ERR-CONTRACT-NOT-ACTIVATED
    }
})

// name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when lock-period is in range"
Clarinet.test({
    name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when lock-period is in range",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(10016); //ERR-CANNOT-STAKE
    }
})

// name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when amount-token is more than zero"
Clarinet.test({
    name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when lock-period is in range",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(10016); //ERR-CANNOT-STAKE
    }
})

// name: "STACKING POOL: Ensure that add-to-balance is called by approved contracts only"
Clarinet.test({
    name: "STACKING POOL: Ensure that stake-tokens-at-cycle is called when lock-period is in range",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var dx = 50000*ONE_8
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "add-to-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(dx),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(1000); //ERR-NOT-AUTHORIZED
    }
})

// name: "STACKING POOL: Ensure that reduce-position is called when stacking is not in progress"
Clarinet.test({
    name: "STACKING POOL: Ensure that reduce-position is called when stacking is not in progress",
    async fn(chain: Chain, accounts: Map<string, Account>){
        var deployer = accounts.get("deployer")!;
        var startCycle = 0;
        var percent = 10
        let block = chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "reduce-position",
                [
                    types.principal(poxlTokenTraitAddress),
                    types.principal(rewardTokenTraitAddress),
                    types.uint(startCycle),
                    types.principal(yieldTokenAddress),
                    types.uint(percent),
                ],
                deployer.address
            ),
        ]);
    
        block.receipts[0].result.expectErr().expectUint(2018); //ERR-STACKING-IN-PROGRESS
    }
})
*/