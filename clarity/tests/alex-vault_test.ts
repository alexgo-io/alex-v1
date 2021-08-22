
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
  VaultAgent,
} from './models/alex-tests-vault.ts';


const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"



Clarinet.test({
    name: "VAULT : get Balance ",
    async fn(chain: Chain, accounts: Map<string, Account>) {
 
        let user = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;

        let block = chain.mineBlock([
            
          // must return zero 
            Tx.contractCall("alex-vault", "get-balance", [
                types.principal(usdaTokenAddress)
              ], user.address),
            
            
          // u1000000000000
          Tx.contractCall("alex-vault", "get-balance", [
            types.principal(gAlexTokenAddress)
          ], user.address),

          // Must Return zero
          Tx.contractCall("alex-vault", "get-balance", [
            types.principal(gAlexUsdaPoolAddress)
          ], user.address),
            
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectOk();


    },
});


