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

  
  }
  
  export { VaultAgent };