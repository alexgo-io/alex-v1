import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';
import { assertNotEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_8 = 100000000;

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const fwpTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01";
const ACTIVATION_BLOCK = 20;
const BountyFixed = 0.1e8;

Clarinet.test({
  name: "fwp-wstx-alex-tranched-120 : ensure that privileged setters can only be called by contract owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    var notContractOwner = accounts.get("wallet_1")!;
    var wallet_2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "fwp-wstx-alex-tranched-120",
        "set-contract-owner",
        [types.principal(wallet_2.address)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "fwp-wstx-alex-tranched-120",
        "set-start-block",
        [types.uint(0)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "fwp-wstx-alex-tranched-120",
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
  name: "fwp-wstx-alex-tranched-120 : ensure base line works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
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
    const end_cycle = 120;

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
    ]);
    block.receipts.forEach((e) => { e.result.expectOk() });

    // pass the first cycle
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

    // start from cycle 1, so first claim eligible at cycle 3 for cycle 2
    block = chain.mineBlock(
      [
        Tx.contractCall("auto-alex", "set-start-block", [types.uint(0)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "set-start-block", [types.uint(0)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "set-end-cycle", [types.uint(end_cycle)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "set-bounty-in-fixed", [types.uint(0e8)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "set-distributed", [types.uint(0), types.bool(true)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "set-available-alex", [types.uint(2000e8)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-120", "add-to-position", [types.uint(dx)], deployer.address)
      ]);
    block.receipts.forEach((e) => { e.result.expectOk() });

    // first claim eligible at cycle 3 for cycle 2
    for( let cycle = 3; cycle <= (end_cycle + 1); cycle++ ){
      chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525 * cycle);

      if (cycle < end_cycle) {
        block = chain.mineBlock(
          [
            Tx.contractCall("fwp-wstx-alex-tranched-120", "add-to-position", [types.uint(dx)], deployer.address)
          ]
        )
        block.receipts[0].result.expectErr().expectUint(1410);
      }

      block = chain.mineBlock(
        [
          Tx.contractCall("fwp-wstx-alex-tranched-120", "claim-and-stake", [types.uint(cycle - 1)], deployer.address),
          Tx.contractCall("fwp-wstx-alex-tranched-120", "distribute", 
            [
              types.uint(cycle - 1),
              types.uint(0),
              types.list([types.principal(deployer.address)]),
              types.bool(false)
            ],
            deployer.address),
            Tx.contractCall("fwp-wstx-alex-tranched-120", "distribute", 
            [
              types.uint(cycle - 1),
              types.uint(1),
              types.list([types.principal(deployer.address)]),
              types.bool(true)
            ],
            deployer.address)          
        ]
      )
      block.receipts.forEach((e) => { e.result.expectOk() });     
      
      if (cycle < end_cycle) {
        block = chain.mineBlock(
          [
            Tx.contractCall("fwp-wstx-alex-tranched-120", "add-to-position", [types.uint(dx)], deployer.address)
          ]
        )
        block.receipts[0].result.expectOk();
      }      
    }

    block = chain.mineBlock(
      [
        Tx.contractCall("fwp-wstx-alex-tranched-120", "reduce-position", [], deployer.address)
      ]
    )
    block.receipts.forEach((e) => { e.result.expectOk() });
    console.log(block.receipts[0].events);

  },
});

