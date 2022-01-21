

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


const ONE_8 = 1e8;

const oldContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool";
const newContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool-v1-01";
const wstxContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx";
const alexContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const helperContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.migration-helper-v1-01";
const oldMultisigContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-alex-50-50"
const newMultisigContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-alex-50-50-v1-01"
const oldPoolContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50"
const newPoolContract = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01"

class MigrationHelper {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    createPool(sender: Account, contract: string, token_x: string, token_y: string, weight_x: number, weight_y: number, pool_token: string, multisig: string, dx: number, dy: number) {
      let block = this.chain.mineBlock([
          Tx.contractCall(contract, "create-pool", [
            types.principal(token_x),
            types.principal(token_y),
            types.uint(weight_x),
            types.uint(weight_y),
            types.principal(pool_token),
            types.principal(multisig),
            types.uint(dx),
            types.uint(dy)
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }

    migrate(sender: Account) {
      let block = this.chain.mineBlock([
          Tx.contractCall(helperContract, "migrate-fwp-wstx-alex-50-50", [], sender.address),
        ]);
        return block.receipts[0].result;
    }    
}

/**
 * test cases
 * 
 */

Clarinet.test({
    name: "migration-helper tests",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let MigrationTest = new MigrationHelper(chain, deployer);

        chain.mineBlock([
          Tx.contractCall(alexContract, "mint-fixed", [
            types.uint(100000e8),
            types.principal(deployer.address)
          ], deployer.address),
        ]);

        let result:any = await MigrationTest.createPool(deployer, oldContract, wstxContract, alexContract, 0.5e8, 0.5e8, oldPoolContract, oldMultisigContract, ONE_8, ONE_8);
        result.expectOk().expectBool(true);
        result = await MigrationTest.createPool(deployer, newContract, wstxContract, alexContract, 0.5e8, 0.5e8, newPoolContract, newMultisigContract, ONE_8, ONE_8);
        result.expectOk().expectBool(true);

        let call = chain.callReadOnlyFn(oldPoolContract, "get-balance", [ types.principal(deployer.address)], deployer.address);
        call.result.expectOk().expectUint(99999990);
        call = chain.callReadOnlyFn(newPoolContract, "get-balance", [ types.principal(deployer.address)], deployer.address);
        call.result.expectOk().expectUint(99999990);        

        result = await MigrationTest.migrate(deployer);
        result.expectOk().expectTuple();
        
        call = chain.callReadOnlyFn(oldPoolContract, "get-balance", [ types.principal(deployer.address)], deployer.address);
        call.result.expectOk().expectUint(0);
        call = chain.callReadOnlyFn(newPoolContract, "get-balance", [ types.principal(deployer.address)], deployer.address);
        call.result.expectOk().expectUint(199999980);
    },    
});
