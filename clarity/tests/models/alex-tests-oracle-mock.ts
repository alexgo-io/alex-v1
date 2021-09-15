import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.10.0/index.ts";
  

  class OracleManager {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    updatePrice(user: Account, symbol:string, oraclesrc:string, price: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("open-oracle", "update-price", [
          types.ascii(symbol),
          types.ascii(oraclesrc),
          types.uint(price),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getPrice(oraclesrc:string, token: string) {
      return this.chain.callReadOnlyFn("open-oracle", "get-price", [
        types.ascii(oraclesrc),
        types.ascii(token)
      ], this.deployer.address);
    }

  }
  export { OracleManager };
  