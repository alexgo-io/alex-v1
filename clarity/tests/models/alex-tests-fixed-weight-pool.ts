import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.13.0/index.ts";
  
  class FWPTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    getPoolDetails(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-pool-details", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }
  
    createPool(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, multisig: string, balanceX: number, balanceY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "create-pool", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.principal(pooltoken),
          types.principal(multisig),
          types.uint(balanceX),
          types.uint(balanceY),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "add-to-position", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.principal(pooltoken),
          types.uint(dX),
          types.uint(dY),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    reducePosition(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, percentage: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "reduce-position", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.principal(pooltoken),
          types.uint(percentage),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapXForY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dx: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "swap-x-for-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dx) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dy: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "swap-y-for-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dy) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    getYgivenX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "get-y-given-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dX) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeetoAddress(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, address: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-fee-to-address", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.principal(address) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "get-fee-to-address", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    collectFees(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "collect-fees", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    
  
    setFeeRateX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-fee-rate-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-fee-rate-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
  }
  
  export { FWPTestAgent1 };