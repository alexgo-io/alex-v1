import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.31.1/index.ts";
import { YieldVault } from "./models/alex-tests-auto.ts";
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { assertNotEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

const ONE_8 = 100000000;

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const fwpTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01";
const ACTIVATION_BLOCK = 20;
const BountyFixed = 0.1e8;

Clarinet.test({
  name: "auto-fwp-wstx-alex : ensure that privileged setters can only be called by contract owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    var notContractOwner = accounts.get("wallet_1")!;
    var wallet_2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "auto-fwp-wstx-alex",
        "set-contract-owner",
        [types.principal(wallet_2.address)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "auto-fwp-wstx-alex",
        "set-start-block",
        [types.uint(0)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "auto-fwp-wstx-alex",
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
  name: "auto-fwp-wstx-alex : ensure that contract is activated when adding to position",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
  name: "auto-fwp-wstx-alex : ensure that stacking is available when adding to position",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
      yieldVault.setStartBlock(deployer, 0),
    ]);
    setupBlock.receipts.forEach((e) => {
      e.result.expectOk();
    });

    const addBlock = chain.mineBlock([yieldVault.addToPosition(wallet_1, dx)]);
    addBlock.receipts[0].result.expectErr().expectUint(10015); //ERR-STACKING-NOT-AVAILABLE
  },
});

Clarinet.test({
  name: "auto-fwp-wstx-alex : ensure that add-to-position works on a valid pool",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
      yieldVault.setStartBlock(deployer, 0),
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
      deployer.address + ".auto-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex",
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
      "auto-fwp-wstx-alex",
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
      deployer.address + ".auto-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex",
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
  name: "auto-fwp-wstx-alex : ensure that claim-and-stake cannot claim future cycles",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
      yieldVault.setStartBlock(deployer, 0),
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
      deployer.address + ".auto-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex",
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
  name: "auto-fwp-wstx-alex : ensure that claim-and-stake works with a valid cycle",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
      yieldVault.setStartBlock(deployer, 0),
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
      deployer.address + ".auto-fwp-wstx-alex",
      "fwp-wstx-alex-50-50-v1-01"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex",
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
      deployer.address + ".auto-fwp-wstx-alex",
      "alex"
    );
    block.receipts[1].events.expectFungibleTokenTransferEvent(
      BountyFixed,
      deployer.address + ".auto-fwp-wstx-alex",
      wallet_2.address,
      "alex"
    );
    block.receipts[1].events.expectFungibleTokenTransferEvent(
      ONE_8 - BountyFixed,
      deployer.address + ".auto-fwp-wstx-alex",
      deployer.address + ".alex-vault",
      "alex"
    );
  },
});

Clarinet.test({
  name: "auto-fwp-wstx-alex : ensure that reduce-position works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex");
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
    const end_cycle = 10;

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
      yieldVault.setStartBlock(deployer, 0),
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

    block = chain.mineBlock([yieldVault.reducePosition(wallet_1, ONE_8)]);
    // console.log(block.receipts[0].events);
    block.receipts.forEach(e => { e.result.expectOk() });

    const principal_coverage = end_cycle - Math.floor(end_cycle / 32); //principal farming misses every time principal needs to roll
    const alex_coverage = end_cycle - 2; // alex staking misses the first two cycles
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      ONE_8 * (principal_coverage + alex_coverage),
      deployer.address + ".auto-fwp-wstx-alex",
      wallet_1.address,
      "alex"
    );
    block.receipts[0].events.expectFungibleTokenTransferEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex",
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


Clarinet.test({
  name: "auto-fwp-wstx-alex : ensure that x works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-wstx-alex-120");
    const reservePool = new ReservePool(chain);
    const FWPTest = new FWPTestAgent1(chain, deployer);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const stxToken = new FungibleToken(
      chain,
      deployer,
      "token-wstx"
    );
    const dx = ONE_8;
    const end_cycle = 10;

    let result: any = stxToken.transferToken(deployer, dx, wallet_1.address, new ArrayBuffer(1));
    result.expectOk();
    
    result = alexToken.mintFixed(deployer, deployer.address, 1000e8);
    result.expectOk();

    result = FWPTest.createPool(
      deployer, 
      deployer.address + ".token-wstx", 
      deployer.address + ".age000-governance-token",
      0.5e8,
      0.5e8,
      deployer.address + ".fwp-wstx-alex-50-50-v1-01", 
      deployer.address + ".multisig-fwp-wstx-alex-50-50-v1-01", 
      1000e8,
      1000e8
    );
    result.expectOk().expectBool(true);

    result = FWPTest.setMaxInRatio(deployer, 0.3e8);
    result.expectOk().expectBool(true);
    result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
    result.expectOk().expectBool(true);       

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
      yieldVault.setStartBlock(deployer, 0),
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

    block = chain.mineBlock(
      [
        Tx.contractCall("auto-fwp-wstx-alex-120x", "set-available-alex", 
          [
            types.principal(wallet_1.address), 
            types.uint(dx)
          ], deployer.address
        ),
        Tx.contractCall("auto-fwp-wstx-alex-120x", "add-to-position",
          [
            types.uint(dx)
          ], wallet_1.address
        )
      ]);
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

    block = chain.mineBlock(
      [
        Tx.contractCall("auto-fwp-wstx-alex-120x", "reduce-position", [], wallet_1.address)
      ]
    );
    const final_position:any = block.receipts[0].result.expectOk().expectTuple();
    assertNotEquals(final_position['alex'], 0);
    assertNotEquals(final_position['stx'], 0);

    block.receipts[0].events.expectFungibleTokenBurnEvent(
      dx,
      deployer.address + ".auto-fwp-wstx-alex-120x",
      "alex"
    );
  },
});
