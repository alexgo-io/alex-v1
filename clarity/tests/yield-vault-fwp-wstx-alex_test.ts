import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { YieldVault } from "./models/alex-tests-yield-vault.ts";
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000;

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const fwpTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01";
const autoAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-fwp-wstx-alex";
const vaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-vault-fwp-wstx-alex";
const ACTIVATION_BLOCK = 20;
const BountyFixed = 0.1e8;

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that privileged setters can only be called by contract owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    var notContractOwner = accounts.get("wallet_1")!;
    var wallet_2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "yield-vault-fwp-wstx-alex",
        "set-contract-owner",
        [types.principal(wallet_2.address)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "yield-vault-fwp-wstx-alex",
        "set-activated",
        [types.bool(true)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "yield-vault-fwp-wstx-alex",
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
  name: "yield-vault-fwp-wstx-alex : ensure that contract is activated when adding to position",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = 50000 * ONE_8;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    const setupBlock = chain.mineBlock([
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
    ]);
    setupBlock.receipts.forEach((e) => {
      e.result.expectOk();
    });

    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

    const addBlock = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    addBlock.receipts[0].result.expectErr().expectUint(2043); //ERR-NOT-ACTIVATED
  },
});

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that stacking is available when adding to position",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = 50000 * ONE_8;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    const setupBlock = chain.mineBlock([
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
      yieldVault.setActivated(deployer, true),
    ]);
    setupBlock.receipts.forEach((e) => {
      e.result.expectOk();
    });

    const addBlock = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    addBlock.receipts[0].result.expectErr().expectUint(10015); //ERR-STACKING-NOT-AVAILABLE
  },
});

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that add-to-position works on a valid pool",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = ONE_8;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    let block = chain.mineBlock([
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
      yieldVault.setActivated(deployer, true),
    ]);
    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

    block = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    block.receipts[0].result.expectOk().expectBool(true);
    // console.log(block.receipts[0].events);

    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      wallet_1.address,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenMintEvent(
      dx,
      wallet_1.address,
      "auto-fwp-wstx-alex"
    );

    // end of cycle 0
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

    result = fwpToken.mintFixed(deployer, wallet_2.address, dx);
    result.expectOk();

    let call: any = chain.callReadOnlyFn(
      "yield-vault-fwp-wstx-alex",
      "get-token-given-position",
      [types.uint(dx)],
      wallet_2.address
    );

    result = alexToken.mintFixed(
      deployer,
      wallet_2.address,
      Number(call.result.expectOk().expectTuple()["rewards"].replace(/\D/g, ""))
    );

    block = chain.mineBlock([yieldVault.addToPosition(wallet_2, dx)]);
    block.receipts[0].result.expectOk().expectBool(true);
    // console.log(block.receipts[0].events);

    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      wallet_2.address,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenMintEvent(
      dx,
      wallet_2.address,
      "auto-fwp-wstx-alex"
    );
  },
});

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that claim-and-stake cannot claim future cycles",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = ONE_8;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    let block = chain.mineBlock([
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
      yieldVault.setActivated(deployer, true),
    ]);

    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

    block = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    block.receipts[0].result.expectOk().expectBool(true);
    // console.log(block.receipts[0].events);

    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      wallet_1.address,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenMintEvent(
      dx,
      wallet_1.address,
      "auto-fwp-wstx-alex"
    );

    // end of cycle 0
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

    block = chain.mineBlock([yieldVault.claimAndStake(wallet_2, 2)]);
    block.receipts[0].result.expectErr().expectUint(10017); //ERR-REWARD-CYCLE-NOT-COMPLETED
  },
});

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that claim-and-stake works with a valid cycle",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = ONE_8;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    let block = chain.mineBlock([
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
      yieldVault.setActivated(deployer, true),
      yieldVault.setBountyInFixed(deployer, BountyFixed),
    ]);
    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);

    block = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      wallet_1.address,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenMintEvent(
      dx,
      wallet_1.address,
      "auto-fwp-wstx-alex"
    );

    // end of cycle 1
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 1050);

    block = chain.mineBlock([yieldVault.setBountyInFixed(deployer, ONE_8)]);
    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    block = chain.mineBlock([
      yieldVault.setBountyInFixed(wallet_2, BountyFixed),
      yieldVault.claimAndStake(wallet_2, 1),
    ]);
    block.receipts.forEach((e) => {
      e.result.expectErr();
    });

    block = chain.mineBlock([
      yieldVault.setBountyInFixed(deployer, BountyFixed),
      yieldVault.claimAndStake(wallet_2, 1),
    ]);
    block.receipts.forEach((e) => {
      e.result.expectOk();
    });

    block.receipts[1].events.expectFungibleTokenMintEvent(
      ONE_8,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      "alex"
    );
    block.receipts[1].events.expectFungibleTokenTransferEvent(
      BountyFixed,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      wallet_2.address,
      "alex"
    );
    block.receipts[1].events.expectFungibleTokenTransferEvent(
      ONE_8 - BountyFixed,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "alex"
    );
  },
});

Clarinet.test({
  name: "yield-vault-fwp-wstx-alex : ensure that reduce-position works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "yield-vault-fwp-wstx-alex");
    const reservePool = new ReservePool(chain);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const fwpToken = new FungibleToken(
      chain,
      deployer,
      "fwp-wstx-alex-50-50-v1-01"
    );
    const dx = ONE_8;
    const end_cycle = 120;

    let result: any = fwpToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();

    let block = chain.mineBlock([
      Tx.contractCall(
        "alex-vault",
        "add-approved-token",
        [types.principal(fwpTokenAddress)],
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
      reservePool.addToken(deployer, fwpTokenAddress),
      reservePool.setActivationBlock(
        deployer,
        fwpTokenAddress,
        ACTIVATION_BLOCK
      ),
      reservePool.setCoinbaseAmount(
        deployer,
        fwpTokenAddress,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8,
        ONE_8
      ),
      yieldVault.setActivated(deployer, true),
      yieldVault.setBountyInFixed(deployer, 0),
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

    // let temp = 0;
    // let temp2 = 0;
    for(let cycle = 1; cycle < end_cycle; cycle++){
      chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + (cycle + 1) * 525);
      // let call:any = chain.callReadOnlyFn("alex-reserve-pool", "get-staking-reward",
      //   [
      //     types.principal(fwpTokenAddress),
      //     types.uint(1),
      //     types.uint(cycle)          
      //   ], wallet_1.address);
      // temp += Number(call.result.replace(/\D/g, ""));    
      // call = chain.callReadOnlyFn("alex-reserve-pool", "get-staking-reward",
      //   [
      //     types.principal(alexTokenAddress),
      //     types.uint(1),
      //     types.uint(cycle)          
      //   ], wallet_1.address);   
      // temp2 += Number(call.result.replace(/\D/g, ""));     
      // console.log(cycle, temp, temp2, temp + temp2);      
      block = chain.mineBlock([yieldVault.claimAndStake(wallet_2, cycle)]);
      block.receipts.forEach(e => { e.result.expectOk() });
      // call = chain.callReadOnlyFn("alex-reserve-pool", "get-staker-at-cycle-or-default",
      //   [
      //     types.principal(alexTokenAddress),
      //     types.uint(end_cycle),
      //     types.uint(1)
      //   ], wallet_1.address);
      // console.log(call.result);
    }
    // end of cycle
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + (end_cycle + 1) * 525);

    block = chain.mineBlock([yieldVault.reducePosition(wallet_1, dx)]);
    // console.log(block.receipts[0].events);
    block.receipts.forEach(e => { e.result.expectOk() });

    const principal_coverage = end_cycle - Math.floor(end_cycle / 32); //principal farming misses every time principal needs to roll
    const alex_coverage = end_cycle - 2; // alex staking misses the first two cycles
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      ONE_8 * (principal_coverage + alex_coverage),
      deployer.address + ".yield-vault-fwp-wstx-alex",
      wallet_1.address,
      "alex"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".yield-vault-fwp-wstx-alex",
      wallet_1.address,
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenBurnEvent(
      dx,
      wallet_1.address,
      "auto-fwp-wstx-alex"
    )    
  },
});
