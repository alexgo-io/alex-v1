
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    OracleManager,
  } from './models/alex-tests-oracle-mock.ts';
  

Clarinet.test({
    name: "open-oracle test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let OracleOwner = deployer;
        let wallet_1 = accounts.get("wallet_1")!;

        let oracleManager = new OracleManager(chain, deployer);

        let result = oracleManager.updatePrice(OracleOwner,"STX","coinbase", 30000000000);
        result.expectOk()

        let call = chain.callReadOnlyFn("open-oracle", "get-price", [types.ascii("coinbase"),types.ascii("STX")], deployer.address);
        call.result.expectOk().expectUint(30000000000)


    },
});