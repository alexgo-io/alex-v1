import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  

  class FLTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    flashLoan(user: Account, loanuser:string, token:string, amount: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("alex-vault", "flash-loan", [
          types.principal(loanuser),
          types.principal(token),
          types.uint(amount),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    // executeMarginUsdaWbtc59760(user: Account, amount:number) {
    //   let block = this.chain.mineBlock([
    //     Tx.contractCall("flash-loan-user-margin-usda-wbtc-59760", "execute-margin-usda-wbtc-59760", [
    //       types.uint(amount)
    //     ], user.address),
    //   ]);
    //   return block.receipts[0].result;
    // }

    getBalance(token: string, owner: string) {
      return this.chain.callReadOnlyFn(token, "get-balance", [
        types.principal(owner)
      ], this.deployer.address);
    }    

  }
  export { FLTestAgent1 };
  