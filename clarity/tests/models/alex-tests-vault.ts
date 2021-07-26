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
    getBalance(token: string) {
        return this.chain.callReadOnlyFn("alex-vault", "get-balance", [
          types.principal(token)
        ], this.deployer.address);
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

      transferToVault(user: Account, amount:number, sender:string, recipient:string, token: string, memo:string) {
        let block = this.chain.mineBlock([
          Tx.contractCall("alex-vault", "transfer-to-vault", [
            types.number(amount),
            types.principal(sender),
            types.principal(recipient),
            types.principal(token),
            types.string(memo),
            
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
  }
  
  export { VaultAgent };