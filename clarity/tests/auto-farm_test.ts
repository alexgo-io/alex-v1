import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { YieldVaultFarm } from "./models/alex-tests-auto.ts";
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const fwpTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01";
const ACTIVATION_BLOCK = 20;
const BountyFixed = 0.1e8;

Clarinet.test({
    name: "auto-farm : ensure that privileged setters can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var wallet_2 = accounts.get("wallet_2")!;

        let block = chain.mineBlock([
            Tx.contractCall(
                "auto-farm",
                "set-contract-owner",
                [types.principal(wallet_2.address)],
                notContractOwner.address
            ),
            Tx.contractCall(
                "auto-farm",
                "set-activated",
                [
                    types.principal(fwpTokenAddress),
                    types.bool(true)
                ],
                notContractOwner.address
            ),      
            Tx.contractCall(
                "auto-farm",
                "set-bounty-in-fixed",
                [
                    types.principal(fwpTokenAddress),
                    types.uint(0)
                ],
                notContractOwner.address
            ),                                              
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1000); });
    },
});

Clarinet.test({
    name: "auto-farm : ensure that contract is activated when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const yieldVault = new YieldVaultFarm(chain);
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const fwpToken = new FungibleToken(chain, deployer, "fwp-wstx-alex-50-50-v1-01")
        const dx = 50000 * ONE_8;

        let result:any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        const setupBlock = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.addToken(deployer, fwpTokenAddress),
            reservePool.setActivationBlock(deployer, fwpTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, fwpTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8)                 
        ]);
        setupBlock.receipts.forEach(e => { e.result.expectOk(); });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        const addBlock = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, fwpTokenAddress, dx)
        ]);
        addBlock.receipts[0].result.expectErr().expectUint(2043);; //ERR-NOT-ACTIVATED
    }
})

Clarinet.test({
    name: "auto-farm : ensure that stacking is available when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const yieldVault = new YieldVaultFarm(chain);
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const fwpToken = new FungibleToken(chain, deployer, "fwp-wstx-alex-50-50-v1-01");
        const dx = 50000 * ONE_8;

        let result:any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        const setupBlock = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.addToken(deployer, fwpTokenAddress),
            reservePool.setActivationBlock(deployer, fwpTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, fwpTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),            
            yieldVault.addToken(deployer, fwpTokenAddress),
            yieldVault.setActivated(deployer, fwpTokenAddress, true)   
        ]);
        setupBlock.receipts.forEach(e => { e.result.expectOk(); });     

        const addBlock = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, fwpTokenAddress, dx)
        ]);
        addBlock.receipts[0].result.expectErr().expectUint(10015);; //ERR-STACKING-NOT-AVAILABLE
    }
})

Clarinet.test({
    name: "auto-farm : ensure that add-to-position works on a valid pool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVaultFarm(chain);
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const fwpToken = new FungibleToken(chain, deployer, "fwp-wstx-alex-50-50-v1-01");
        const dx = ONE_8;

        let result:any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.addToken(deployer, fwpTokenAddress),
            reservePool.setActivationBlock(deployer, fwpTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, fwpTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),            
            yieldVault.addToken(deployer, fwpTokenAddress),
            yieldVault.setActivated(deployer, fwpTokenAddress, true)   
        ]);
        block.receipts.forEach(e => { e.result.expectOk(); });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([            
            yieldVault.addToPosition(wallet_1, fwpTokenAddress, dx),
            yieldVault.addToPosition(wallet_1, alexTokenAddress, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(2043);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-farm",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-farm",
            deployer.address + ".alex-vault",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-farm"
        );     
        
        // end of cycle 0
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

        result = fwpToken.mintFixed(deployer, wallet_2.address, dx);
        result.expectOk();
        
        let call:any = chain.callReadOnlyFn(
            "auto-farm",
            "get-token-given-position",
            [   
                types.principal(fwpTokenAddress),
                types.uint(dx)
            ],
            wallet_2.address
          );

        result = alexToken.mintFixed(
            deployer, 
            wallet_2.address, 
            Number(call.result.expectOk().expectTuple()['rewards'].replace(/\D/g, ""))
            );

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_2, fwpTokenAddress, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_2.address,
            deployer.address + ".auto-farm",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-farm",
            deployer.address + ".alex-vault",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_2.address,
            "auto-farm"
        );
    }
})

Clarinet.test({
    name: "auto-farm : ensure that claim-and-stake cannot claim future cycles",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVaultFarm(chain);
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const fwpToken = new FungibleToken(chain, deployer, "fwp-wstx-alex-50-50-v1-01");
        const dx = ONE_8;

        let result:any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.addToken(deployer, fwpTokenAddress),
            reservePool.setActivationBlock(deployer, fwpTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, fwpTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),            
            yieldVault.addToken(deployer, fwpTokenAddress),
            yieldVault.setActivated(deployer, fwpTokenAddress, true)   
        ]);
        
        block.receipts.forEach(e => { e.result.expectOk(); });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, fwpTokenAddress, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-farm",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-farm",
            deployer.address + ".alex-vault",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-farm"
        );
        
        // end of cycle 0
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

        block = chain.mineBlock([
            yieldVault.claimAndStake(wallet_2, fwpTokenAddress, 2)
        ]);
        block.receipts[0].result.expectErr().expectUint(10017); //ERR-REWARD-CYCLE-NOT-COMPLETED
    }
})

Clarinet.test({
    name: "auto-farm : ensure that claim-and-stake works with a valid cycle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVaultFarm(chain);
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const fwpToken = new FungibleToken(chain, deployer, "fwp-wstx-alex-50-50-v1-01");
        const dx = ONE_8;

        let result:any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.addToken(deployer, fwpTokenAddress),
            reservePool.setActivationBlock(deployer, fwpTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, fwpTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),                
            yieldVault.addToken(deployer, fwpTokenAddress),
            yieldVault.setActivated(deployer, fwpTokenAddress, true),
            yieldVault.setBountyInFixed(deployer, fwpTokenAddress, BountyFixed)   
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, fwpTokenAddress, dx)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-farm",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-farm",
            deployer.address + ".alex-vault",
            "fwp-wstx-alex-50-50-v1-01"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-farm"
        );
        
        // end of cycle 1
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, fwpTokenAddress, ONE_8),
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block = chain.mineBlock([
            yieldVault.claimAndStake(deployer, alexTokenAddress, 1),
            yieldVault.setBountyInFixed(wallet_2, fwpTokenAddress, BountyFixed),
            yieldVault.claimAndStake(wallet_2, fwpTokenAddress, 1),
            yieldVault.claimAndStake(wallet_2, alexTokenAddress, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectErr() });

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, fwpTokenAddress, BountyFixed),
            yieldVault.claimAndStake(wallet_2, fwpTokenAddress, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[1].events.expectFungibleTokenMintEvent(
            ONE_8,
            deployer.address + ".auto-farm",
            "alex"
        );        
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            BountyFixed,
            deployer.address + ".auto-farm",
            wallet_2.address,
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            ONE_8 - BountyFixed,
            deployer.address + ".auto-farm",
            deployer.address + ".alex-vault",
            "alex"
        );
    }
})

