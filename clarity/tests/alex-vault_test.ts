
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
        let wallet_1 = accounts.get("wallet_1")!;
        let vault = accounts.get("wallet_2")!;

        let block = chain.mineBlock([
            
            Tx.contractCall("alex-vault", "get-balance", [
                types.principal(usdaTokenAddress)
              ], wallet_1.address),
            

              // Must return empty list
            //   Tx.contractCall("alex-vault", "get-balances", [
            //     types.principal(gAlexTokenAddress)
            //   ], user.address),
            
            // Tx.contractCall("alex-vault", "add-token-balance", [
            //     types.principal(ayusdaAddress),
            //     types.principal(user.address),
            //   ], user.address),

           //(transfer-to-vault (amount uint)  (sender principal) (recipient principal) (token-trait <ft-trait>) (memo (optional (buff 34))))
            Tx.contractCall("alex-vault", "transfer-to-vault", [
                types.uint(1000000),
                types.principal(user.address),
                types.principal(vault.address),
                types.principal(usdaTokenAddress),
                types.none()
            ], vault.address),
            
            // Tx.contractCall("alex-vault", "get-tokenlist", [
            //   ], user.address),

            // Tx.contractCall("alex-vault", "get-balance", [
            //     types.principal(usdaTokenAddress)
            //   ], wallet_1.address),

            //   // Added value of token should be returned
            //   Tx.contractCall("alex-vault", "get-balances", [
            //   ], wallet_1.address),
              
            
            

        ]);

        block.receipts[0].result.expectOk().expectUint(0);
        block.receipts[1].result.expectOk();
//        block.receipts[2].result.expectOk()
        //block.receipts[3].result.expectOk().expectUint(1000000);
        // block.receipts[3].result.expectOk();
        // block.receipts[2].result.expectOk().expectList();
        
    },
});