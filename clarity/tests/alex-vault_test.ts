
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"
const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"



Clarinet.test({
    name: "VAULT : get Balance ",
    async fn(chain: Chain, accounts: Map<string, Account>) {
 
        let user = accounts.get("deployer")!;

        let block = chain.mineBlock([
            
            Tx.contractCall("alex-vault", "get-balance", [
                types.principal(usdaTokenAddress)
              ], user.address),

              Tx.contractCall("alex-vault", "get-balance", [
                types.principal(gAlexTokenAddress)
              ], user.address),

              Tx.contractCall("alex-vault", "update-token-balance", [
                types.principal(usdaTokenAddress)
              ], user.address),

              Tx.contractCall("alex-vault", "update-token-balance", [
                types.principal(gAlexTokenAddress)
              ], user.address),

              Tx.contractCall("alex-vault", "get-balances", [
              ], user.address),
            
            

        ]);
        block.receipts[0].result.expectOk().expectUint(1000000000000);
        block.receipts[1].result.expectOk().expectUint(1000000000000);
        block.receipts[2].result.expectOk();
        block.receipts[3].result.expectOk();
        block.receipts[4].result.expectOk().expectList();
        
    },
});