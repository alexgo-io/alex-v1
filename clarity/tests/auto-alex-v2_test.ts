import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.34.0/index.ts";
import { YieldVault } from "./models/alex-tests-auto.ts";
import { FWPTestAgent3 } from "./models/alex-tests-fixed-weight-pool.ts";
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const ACTIVATION_BLOCK = 20;
const BountyFixed = 0.1e8;

Clarinet.test({
    name: "auto-alex-v2 : ensure that privileged setters can only be called by contract owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        var notContractOwner = accounts.get("wallet_1")!;
        var wallet_2 = accounts.get("wallet_2")!;

        let block = chain.mineBlock([
            Tx.contractCall(
                "auto-alex-v2",
                "set-contract-owner",
                [types.principal(wallet_2.address)],
                notContractOwner.address
            ),
            Tx.contractCall(
                "auto-alex-v2",
                "set-start-cycle",
                [types.uint(0)],
                notContractOwner.address
            ),
            Tx.contractCall(
                "auto-alex-v2",
                "set-bounty-in-fixed",
                [types.uint(0)],
                notContractOwner.address
            ),
        ]);
        for (let i = 0; i < block.receipts.length; i++) {
            block.receipts[i].result.expectErr().expectUint(1000);
        }
    },
});

Clarinet.test({
    name: "auto-alex-v2 : ensure that contract is activated when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = 50000 * ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        const setupBlock = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8)
        ]);
        for (let i = 0; i < setupBlock.receipts.length; i++) {
            setupBlock.receipts[i].result.expectOk();
        }

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        const addBlock = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        addBlock.receipts[0].result.expectErr().expectUint(2043);; //ERR-NOT-ACTIVATED
    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that stacking is available when adding to position",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = 50000 * ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        const setupBlock = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0)
        ]);
        for (let i = 0; i < setupBlock.receipts.length; i++) {
            setupBlock.receipts[i].result.expectOk();
        }

        const addBlock = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        addBlock.receipts[0].result.expectErr().expectUint(10015);; //ERR-STACKING-NOT-AVAILABLE
    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that add-to-position works on a valid pool",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address)
        ]);
        for (let i = 0; i < block.receipts.length; i++) {
            block.receipts[i].result.expectOk();
        }

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-alex-v2"
        );

        // end of cycle 0
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

        result = alexToken.mintFixed(deployer, wallet_2.address, dx);
        result.expectOk();

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_2, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_2.address,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx / 2,
            wallet_2.address,
            "auto-alex-v2"
        );

        // end of cycle 1
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

        result = alexToken.mintFixed(deployer, wallet_2.address, dx);
        result.expectOk();

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_2, dx),
            yieldVault.claimAndStake(wallet_2, 1),
            yieldVault.claimAndStake(wallet_2, 1),
        ]);    
        block.receipts[0].result.expectOk().expectBool(true);   
        block.receipts[1].result.expectErr().expectUint(2045);         
        block.receipts[2].result.expectErr().expectUint(2045);

        // end of cycle 2
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1575);

        result = alexToken.mintFixed(deployer, wallet_2.address, dx);
        result.expectOk();

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_2, dx),
            yieldVault.claimAndStake(wallet_2, 2)
        ]);    
        block.receipts[0].result.expectOk().expectBool(true);      
        block.receipts[1].result.expectErr().expectUint(2045);
    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that claim-and-stake cannot claim future cycles",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address)            
        ]);
        for (let i = 0; i < block.receipts.length; i++) {
            block.receipts[i].result.expectOk();
        }

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        // console.log(block.receipts[0].events);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-alex-v2"
        );

        // end of cycle 0
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

        block = chain.mineBlock([
            yieldVault.claimAndStake(wallet_2, 2)
        ]);
        block.receipts[0].result.expectErr().expectUint(10017); //ERR-REWARD-CYCLE-NOT-COMPLETED
    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that claim-and-stake works with a valid cycle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address)            
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-alex-v2"
        );

        // end of cycle 1
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, ONE_8),
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(wallet_2, BountyFixed),
            yieldVault.claimAndStake(wallet_2, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectErr() });

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            yieldVault.claimAndStake(wallet_2, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[1].events.expectFungibleTokenMintEvent(
            ONE_8,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            BountyFixed,
            deployer.address + ".auto-alex-v2",
            wallet_2.address,
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            ONE_8 - BountyFixed,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );

    }
})

Clarinet.test({
    name: "auto-alex-v2 / dual-farming-pool-v1-01 : ensure that claim-staking-reward-by-auto-alex works with a valid cycle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address),
            Tx.contractCall('brc20-db20', 'mint-fixed', [types.uint(100e8), types.principal(deployer.address + '.dual-farming-pool-v1-01')], deployer.address),
            Tx.contractCall('dual-farming-pool-v1-01', 'add-token', [types.principal(deployer.address + '.age000-governance-token'), types.principal(deployer.address + '.brc20-db20'), types.uint(0.5e8), types.uint(1)], deployer.address)      
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([
            yieldVault.addToPosition(wallet_1, dx),
            // Tx.contractCall('dual-farming-pool-v1-01', 'claim-staking-reward-by-auto-alex', [types.principal(deployer.address + '.brc20-db20'), types.uint(0)], wallet_2.address)
        ]);
        block.receipts[0].result.expectOk();
        // block.receipts[1].result.expectErr().expectUint(1005);

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            wallet_1.address,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            dx,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenMintEvent(
            dx,
            wallet_1.address,
            "auto-alex-v2"
        );

        // chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);
        // block = chain.mineBlock([
        //     Tx.contractCall('dual-farming-pool-v1-01', 'claim-staking-reward-by-auto-alex', [types.principal(deployer.address + '.brc20-db20'), types.uint(0)], wallet_2.address)
        // ]);
        // block.receipts[0].result.expectErr().expectUint(1005);        

        // end of cycle 1
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, ONE_8),
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(wallet_2, BountyFixed),
            Tx.contractCall('dual-farming-pool-v1-01', 'claim-staking-reward-by-auto-alex', [types.principal(deployer.address + '.brc20-db20'), types.uint(1)], wallet_2.address)
            // yieldVault.claimAndStake(wallet_2, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectErr() });

        block = chain.mineBlock([
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('dual-farming-pool-v1-01', 'claim-staking-reward-by-auto-alex', [types.principal(deployer.address + '.brc20-db20'), types.uint(1)], wallet_2.address)
            // yieldVault.claimAndStake(wallet_2, 1)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[1].events.expectFungibleTokenMintEvent(
            ONE_8,
            deployer.address + ".auto-alex-v2",
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            BountyFixed,
            deployer.address + ".auto-alex-v2",
            wallet_2.address,
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            ONE_8 - BountyFixed,
            deployer.address + ".auto-alex-v2",
            deployer.address + ".alex-vault",
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            ONE_8 / 2,
            deployer.address + ".dual-farming-pool-v1-01",
            deployer.address + ".auto-alex-v2",
            "brc20-db20"
        );        

    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that claim-and-mint works with valid cycles",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const dx = ONE_8;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, 2 * dx);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(deployer, alexTokenAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexTokenAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, BountyFixed),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address)            
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);


        block = chain.mineBlock([
            Tx.contractCall("alex-reserve-pool", "stake-tokens",
                [
                    types.principal(alexTokenAddress),
                    types.uint(dx),
                    types.uint(32)
                ],
                wallet_1.address
            ),
            yieldVault.addToPosition(wallet_1, dx)
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });

        // end of cycle 3
        for (let cycle = 1; cycle <= 3; cycle++) {
            chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + (cycle + 1) * 525);
            block = chain.mineBlock([yieldVault.claimAndStake(wallet_2, cycle)]);
            block.receipts.forEach(e => { e.result.expectOk() });
        }

        block = chain.mineBlock([
            Tx.contractCall("auto-alex-v2", "claim-and-mint", [types.list([types.uint(0)])], wallet_1.address),
            Tx.contractCall("auto-alex-v2", "claim-and-mint", [types.list([types.uint(1), types.uint(2), types.uint(3)])], wallet_1.address)
        ]);
        // console.log(block.receipts[1].events);
        block.receipts[0].result.expectErr().expectUint(2003);
        block.receipts[1].result.expectOk();
    }
})

Clarinet.test({
    name: "auto-alex-v2 : ensure that reduce-position works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const yieldVault = new YieldVault(chain, "auto-alex-v2");
        const reservePool = new ReservePool(chain);
        const alexToken = new FungibleToken(
            chain,
            deployer,
            "age000-governance-token"
        );
        const dx = ONE_8;
        const end_cycle = 120;

        let result: any = alexToken.mintFixed(deployer, wallet_1.address, dx);
        result.expectOk();

        let block = chain.mineBlock([
            Tx.contractCall(
                "alex-vault",
                "add-approved-token",
                [types.principal(alexTokenAddress)],
                deployer.address
            ),
            reservePool.addToken(deployer, alexTokenAddress),
            reservePool.setActivationBlock(
                deployer,
                alexTokenAddress,
                ACTIVATION_BLOCK
            ),
            reservePool.setCoinbaseAmount(
                deployer,
                alexTokenAddress,
                ONE_8,
                ONE_8,
                ONE_8,
                ONE_8,
                ONE_8
            ),
            yieldVault.setStartCycle(deployer, 0),
            yieldVault.setBountyInFixed(deployer, 0),
            Tx.contractCall('auto-alex-v2', 'pause-create', [types.bool(false)], deployer.address),
            Tx.contractCall('auto-alex-v2', 'pause-redeem', [types.bool(false)], deployer.address)
        ]);
        block.receipts.forEach((e) => { e.result.expectOk() });

        block = chain.mineBlock([
            yieldVault.setEndCycle(wallet_1, end_cycle),
            yieldVault.setEndCycle(deployer, end_cycle)
        ]);
        block.receipts[0].result.expectErr().expectUint(1000);
        block.receipts[1].result.expectOk();

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

        block = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
        block.receipts.forEach((e) => { e.result.expectOk() });

        for (let cycle = 1; cycle < end_cycle; cycle++) {
            chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + (cycle + 1) * 525);
            block = chain.mineBlock([yieldVault.claimAndStake(wallet_2, cycle)]);
            block.receipts.forEach(e => { e.result.expectOk() });
        }
        // end of cycle
        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + (end_cycle + 1) * 525);

        block = chain.mineBlock([yieldVault.reducePosition(wallet_1, ONE_8)]);
        // console.log(block.receipts[0].events);
        block.receipts.forEach(e => { e.result.expectOk() });

        block.receipts[0].events.expectFungibleTokenTransferEvent(
            ONE_8 * end_cycle + dx,
            deployer.address + ".auto-alex-v2",
            wallet_1.address,
            "alex"
        );
        block.receipts[0].events.expectFungibleTokenBurnEvent(
            dx,
            wallet_1.address,
            "auto-alex-v2"
        )
    },
});

