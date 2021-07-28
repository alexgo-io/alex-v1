
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

        let block = chain.mineBlock([
            
            Tx.contractCall("alex-vault", "get-balance", [
                types.principal(usdaTokenAddress)
              ], user.address),
            
              // Must return empty list
              Tx.contractCall("alex-vault", "get-balances", [
              ], user.address),
            
            // Transfer usda to Vault
            // Since User is deployer, Vault address is User.vault 
            Tx.contractCall("alex-vault", "transfer-to-vault", [
                types.uint(100000000),
                types.principal(wallet_1.address),
                types.principal(usdaTokenAddress),
                types.none()
            ], user.address),

            // transfer galex to Vault
            Tx.contractCall("alex-vault", "transfer-to-vault", [
              types.uint(100000000),
              types.principal(wallet_1.address),
              types.principal(gAlexTokenAddress),
              types.none()
          ], user.address),
            
            // should return (ok [{balance: u1000100000000, token: "Alex Token"}, {balance: u1000100000000, token: "USDA"}])
            Tx.contractCall("alex-vault", "get-balances", [
              ], user.address),
              
              // u1000100000000
              Tx.contractCall("alex-vault", "get-balance", [
                types.principal(gAlexTokenAddress)
              ], user.address),

              // transfer galex from Vault
              Tx.contractCall("alex-vault", "transfer-from-vault", [
                types.uint(100000000),
                types.principal(wallet_1.address),
                types.principal(gAlexTokenAddress),
                types.none()
            ], user.address),

            // Transfer usda from vault
            Tx.contractCall("alex-vault", "transfer-from-vault", [
              types.uint(100000000),
              types.principal(wallet_1.address),
              types.principal(usdaTokenAddress),
              types.none()
          ], user.address),

          // Should Return (ok [{balance: u1000000000000, token: "Alex Token"}, {balance: u1000000000000, token: "USDA"}])
          Tx.contractCall("alex-vault", "get-balances", [
          ], user.address),

          // u1000000000000
          Tx.contractCall("alex-vault", "get-balance", [
            types.principal(gAlexTokenAddress)
          ], user.address),
            
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectOk();
        block.receipts[3].result.expectOk();
        let lists:any = block.receipts[4].result;//.result.expectOk();
        lists.expectOk().expectList() 
        block.receipts[5].result.expectOk().expectUint(1000100000000);
        block.receipts[9].result.expectOk().expectUint(1000000000000);

    },
});