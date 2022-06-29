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
import { FWPTestAgent3 } from './models/alex-tests-fixed-weight-pool.ts';
import { assertNotEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

const ONE_8 = 100000000;

const alexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const fwpTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-usda";
const ACTIVATION_BLOCK = 20;

Clarinet.test({
  name: "auto-fwp-alex-usda : ensure that x works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const yieldVault = new YieldVault(chain, "auto-fwp-alex-usda-100");
    const reservePool = new ReservePool(chain);
    const FWPTest = new FWPTestAgent3(chain, deployer);
    const alexToken = new FungibleToken(
      chain,
      deployer,
      "age000-governance-token"
    );
    const usdaToken = new FungibleToken(
      chain,
      deployer,
      "token-usda"
    );
    const dikoToken = new FungibleToken(
      chain,
      deployer,
      "token-diko"
    );    
    const dx = ONE_8;
    const end_cycle = 10;

    let result: any = usdaToken.mintFixed(deployer, wallet_1.address, dx);
    result.expectOk();
    result = alexToken.mintFixed(deployer, deployer.address, 1000e8);
    result.expectOk();
    result = usdaToken.mintFixed(deployer, deployer.address, 1000e8);
    result.expectOk();
    result = dikoToken.mintFixed(deployer, deployer.address + ".dual-farm-diko-helper", 1000e8);
    result.expectOk();

    result = FWPTest.createPool(
      deployer, 
      deployer.address + ".age000-governance-token", 
      deployer.address + ".token-wusda",
      deployer.address + ".fwp-alex-usda", 
      deployer.address + ".multisig-fwp-alex-usda", 
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
      // reservePool.addToken(deployer, fwpTokenAddress),
      Tx.contractCall(
        "dual-farming-pool",
        "add-token",
        [
          types.principal(fwpTokenAddress),
          types.principal(deployer.address + ".dual-farm-diko-helper"),
          types.principal(deployer.address + ".token-wdiko")
        ], 
        deployer.address
      ),
      Tx.contractCall(
        "dual-farming-pool",
        "set-multiplier-in-fixed",
        [
          types.principal(fwpTokenAddress),
          types.uint(ONE_8)
        ],
        deployer.address
      ),
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
        Tx.contractCall("auto-fwp-alex-usda-100x", "set-available-alex", 
          [
            types.principal(wallet_1.address), 
            types.uint(dx)
          ], deployer.address
        ),
        Tx.contractCall("auto-fwp-alex-usda-100x", "add-to-position",
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
        Tx.contractCall("auto-fwp-alex-usda-100x", "reduce-position", [], wallet_1.address)
      ]
    );
    const final_position:any = block.receipts[0].result.expectOk().expectTuple();
    assertNotEquals(final_position['alex'], 0);
    assertNotEquals(final_position['usda'], 0);
    console.log(block.receipts[0].events);

    block.receipts[0].events.expectFungibleTokenBurnEvent(
      dx,
      deployer.address + ".auto-fwp-alex-usda-100x",
      "alex"
    );
  },
});
