import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  
  class LBPTestAgent {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    getPoolDetails(tokenX: string, tokenY: string, expiry: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-pool-details", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry),
      ], this.deployer.address);
    }
  
    createPool(user: Account, tokenX: string, tokenY: string, weightX1: number, weightX2: number, expiry :number, pooltoken: string, multisig: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "create-pool", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX1),
          types.uint(weightX2),
          types.uint(expiry),
          types.principal(pooltoken),
          types.principal(multisig),
          types.uint(dX),
          types.uint(dY),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, tokenX: string, tokenY: string, expiry :number, pooltoken: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "add-to-position", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.principal(pooltoken),
          types.uint(dX),
          types.uint(dY),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    reducePosition(user: Account, tokenX: string, tokenY: string, expiry :number, pooltoken: string, percentage: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "reduce-position", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.principal(pooltoken),
          types.uint(percentage),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapXForY(user: Account, tokenX: string, tokenY: string, expiry: number, dx: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "swap-x-for-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(dx) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, tokenX: string, tokenY: string, expiry: number, dy: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "swap-y-for-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(dy) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getXgivenPrice(tokenX: string, tokenY: string, expiry: number, price: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-x-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry),
        types.uint(price)
      ], this.deployer.address);
    } 
    
    getYgivenPrice(tokenX: string, tokenY: string, expiry: number, price: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-y-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry),
        types.uint(price)
      ], this.deployer.address);
    } 
  
    setFeetoAddress(user: Account, tokenX: string, tokenY: string, expiry: number, address: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "set-fee-to-address", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.principal(address) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, tokenX: string, tokenY: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "get-fee-to-address", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeX(user: Account, tokenX: string, tokenY: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "get-fee-rate-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeY(user: Account, tokenX: string, tokenY: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "get-fee-rate-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

  
    collectFees(user: Account, tokenX: string, tokenY: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "collect-fees", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    
  
    setFeeRateX(user: Account, tokenX: string, tokenY: string, expiry: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "set-fee-rate-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateY(user: Account, tokenX: string, tokenY: string, expiry: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "set-fee-rate-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
  }
  
  export { LBPTestAgent };