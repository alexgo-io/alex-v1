import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.13.0/index.ts";
  
  class VaultAgent {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    // get balance
      getBalance(user: Account, tokenX: string) {
        let block = this.chain.mineBlock([
          Tx.contractCall("fixed-weight-pool", "get-balance", [
            types.principal(tokenX),
          ], user.address),
        ]);
        return block.receipts[0].result;
      }



      getTokenBalance(token: string) {
        return this.chain.callReadOnlyFn("alex-vault", "get-token-balance", [
        ], this.deployer.address);
      }
      getBalances(token: string) {
        return this.chain.callReadOnlyFn("alex-vault", "get-balances", [
        ], this.deployer.address);
      }

      addTokenBalance(user: Account, token: string, sender: string) {
        let block = this.chain.mineBlock([
          Tx.contractCall("alex-vault", "add-token-balance", [
            types.principal(token),
            types.principal(sender)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      transferToVault(user: Account, amount:number, sender:string, token: string) {
        let block = this.chain.mineBlock([
          Tx.contractCall("alex-vault", "transfer-to-vault", [
            types.uint(amount),
            types.principal(sender),
            types.principal(token),
            types.ascii("none"),
            
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
  }
  
  export { VaultAgent };