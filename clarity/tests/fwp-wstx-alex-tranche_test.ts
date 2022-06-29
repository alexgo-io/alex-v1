import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.31.1/index.ts";
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
  name: "fwp-wstx-alex-tranched-64 : ensure that privileged setters can only be called by contract owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    var notContractOwner = accounts.get("wallet_1")!;
    var wallet_2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "fwp-wstx-alex-tranched-64",
        "set-contract-owner",
        [types.principal(wallet_2.address)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "fwp-wstx-alex-tranched-64",
        "set-start-block",
        [types.uint(0)],
        notContractOwner.address
      ),
      Tx.contractCall(
        "fwp-wstx-alex-tranched-64",
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
  name: "fwp-wstx-alex-tranched-64 : ensure base line works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const wallet_3 = accounts.get("wallet_3")!;
    const wallet_4 = accounts.get("wallet_4")!;
    const wallet_5 = accounts.get("wallet_5")!;
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
    const end_cycle = 32;

    const participants = 
      [
        wallet_1.address,
        wallet_2.address,
        wallet_3.address,
        wallet_4.address,
        wallet_5.address
      ];

    let result = alexToken.mintFixed(deployer, deployer.address, 10_000e8);
    result.expectOk();

    let positions_to_add: any = [];
    let cofarm_to_add: any = [];
    let cofarm_to_reduce: any = [];
    participants.forEach(e => { 
      result = stxToken.transferToken(deployer, 1000e8, e, new ArrayBuffer(1)); 
      result.expectOk();
      result = alexToken.mintFixed(deployer, e, 1000e8);
      result.expectOk();    
      positions_to_add.push(
        Tx.contractCall(
          "fixed-weight-pool-v1-01",
          "add-to-position",
          [
            types.principal(deployer.address + ".token-wstx"),
            types.principal(deployer.address + ".age000-governance-token"),
            types.uint(0.5e8),
            types.uint(0.5e8),
            types.principal(fwpTokenAddress),
            types.uint(1000e8),
            types.some(types.uint(1000e8))
          ],
          e
        )
      );
      cofarm_to_add.push(Tx.contractCall("fwp-wstx-alex-tranched-64", "add-to-position", [types.uint(dx)], e));
      cofarm_to_reduce.push(Tx.contractCall("fwp-wstx-alex-tranched-64", "reduce-position", [], e));
    })

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
      ...positions_to_add   
    ]);
    block.receipts.forEach((e) => { e.result.expectOk() });

    // pass the first cycle
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525);

    // start from cycle 1, so first claim eligible at cycle 3 for cycle 2
    block = chain.mineBlock(
      [
        Tx.contractCall("auto-alex", "set-start-block", [types.uint(0)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "set-start-block", [types.uint(0)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "set-end-cycle", [types.uint(end_cycle)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "set-bounty-in-fixed", [types.uint(0e8)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "set-available-alex", [types.uint(2000e8)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "set-open-to-all", [types.bool(true)], deployer.address),
        ...cofarm_to_add
      ]);
    block.receipts.forEach((e) => { e.result.expectOk() });

    // pass the second cycle
    chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525 * 2);
    block = chain.mineBlock(
      [
        Tx.contractCall("fwp-wstx-alex-tranched-64", "claim-and-stake", [types.uint(1)], deployer.address),
        Tx.contractCall("fwp-wstx-alex-tranched-64", "distribute", 
          [
            types.uint(1),
            types.uint(0),
            types.list([types.principal(deployer.address), types.principal(wallet_1.address)])
          ],
          deployer.address)       
      ]
    )
    block.receipts[0].result.expectErr().expectUint(2045); // rewards is zero
    block.receipts[1].result.expectErr().expectUint(1410); // nothing to distribute

    // first claim eligible at cycle 3 for cycle 2
    for( let cycle = 3; cycle <= (end_cycle + 1); cycle++ ){
      chain.mineEmptyBlockUntil(ACTIVATION_BLOCK + 525 * cycle);

      if (cycle < end_cycle) {        
        const address = participants[cycle % participants.length];
        block = chain.mineBlock(
          [
            Tx.contractCall("fwp-wstx-alex-tranched-64", "add-to-position", [types.uint(dx)], address)
          ]
        )
        block.receipts[0].result.expectOk();
      }

      block = chain.mineBlock(
        [
          Tx.contractCall("fwp-wstx-alex-tranched-64", "claim-and-stake", [types.uint(cycle - 1)], deployer.address),
          Tx.contractCall("fwp-wstx-alex-tranched-64", "distribute", 
            [
              types.uint(cycle - 1),
              types.uint(0),
              types.list(participants.map(e => { types.principal(e) }))
            ],
            deployer.address),
          Tx.contractCall("fwp-wstx-alex-tranched-64", "distribute", 
            [
              types.uint(cycle - 1),
              types.uint(1),
              types.list([types.principal(wallet_1.address)])
            ],
            deployer.address)          
        ]
      )
      block.receipts.forEach((e) => { e.result.expectOk() });         
    }

    block = chain.mineBlock([
      Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", 
        [
          types.principal(deployer.address + ".age000-governance-token"),
          types.principal(deployer.address + ".token-wstx"),
          types.uint(0.5e8),
          types.uint(0.5e8),
          types.uint(6 * 299e8),
          types.none()
        ], deployer.address),                   
        Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", 
        [
          types.principal(deployer.address + ".age000-governance-token"),
          types.principal(deployer.address + ".token-wstx"),
          types.uint(0.5e8),
          types.uint(0.5e8),
          types.uint(6 * 299e8),
          types.none()
        ], deployer.address),                   
        Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", 
        [
          types.principal(deployer.address + ".age000-governance-token"),
          types.principal(deployer.address + ".token-wstx"),
          types.uint(0.5e8),
          types.uint(0.5e8),
          types.uint(6 * 299e8),
          types.none()
        ], deployer.address),       
        Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", 
        [
          types.principal(deployer.address + ".age000-governance-token"),
          types.principal(deployer.address + ".token-wstx"),
          types.uint(0.5e8),
          types.uint(0.5e8),
          types.uint(6 * 299e8),
          types.none()
        ], deployer.address),  
        Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", 
        [
          types.principal(deployer.address + ".age000-governance-token"),
          types.principal(deployer.address + ".token-wstx"),
          types.uint(0.5e8),
          types.uint(0.5e8),
          types.uint(6 * 299e8),
          types.none()
        ], deployer.address),                                              
    ]);
    block.receipts.forEach((e) => { e.result.expectOk() });

    block = chain.mineBlock(cofarm_to_reduce);
    block.receipts.forEach((e) => { e.result.expectOk() });
    console.log(block.receipts[0].events);
    console.log(block.receipts[block.receipts.length - 1].events);

  },
});

