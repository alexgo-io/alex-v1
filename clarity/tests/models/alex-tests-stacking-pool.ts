import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  

  class StackingTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    flashLoan(user: Account, loanuser:string, token:string, amount: number, memo: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("alex-vault", "flash-loan", [
          types.principal(loanuser),
          types.principal(token),
          types.uint(amount),
          types.some(types.uint(memo))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getBalance(token: string, owner: string) {
      return this.chain.callReadOnlyFn(token, "get-balance-fixed", [
        types.principal(owner)
      ], this.deployer.address);
    }      

  }
  export { StackingTestAgent1 };
  