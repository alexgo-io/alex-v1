import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.31.1/index.ts";
  
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
  
    createPool(user: Account, projectName: string, tokenX: string, tokenY: string, weightX1: number, weightX2: number, expiry :number, pooltoken: string, multisig: string, price_x_min: number, price_x_max: number, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "create-pool", [
          types.utf8(projectName),
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX1),
          types.uint(weightX2),
          types.uint(expiry),
          types.principal(pooltoken),
          types.principal(multisig),
          types.uint(price_x_min),
          types.uint(price_x_max),
          types.uint(dX),
          types.uint(dY),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setPriceRange(user: Account, tokenX: string, tokenY: string, expiry :number, min_price: number, max_price: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "set-price-range", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(min_price),
          types.uint(max_price)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getPriceRange(tokenX: string, tokenY: string, expiry: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-price-range", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry)
      ], this.deployer.address);
    }     

    getWeightX(tokenX: string, tokenY: string, expiry: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-weight-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry)
      ], this.deployer.address);
    }      

    setPoolMultisig(user: Account, tokenX: string, tokenY: string, expiry :number, new_multisig: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "set-pool-multisig", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.principal(new_multisig)
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
  
    swapYForX(user: Account, tokenX: string, tokenY: string, expiry: number, dy: number, min_dx: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("liquidity-bootstrapping-pool", "swap-y-for-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(expiry),
          types.uint(dy),
          types.some(types.uint(min_dx))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getXgivenY(tokenX: string, tokenY: string, expiry: number, dy: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-x-given-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry),
        types.uint(dy)
      ], this.deployer.address);
    } 
    
    getYgivenX(tokenX: string, tokenY: string, expiry: number, dx: number) {
      return this.chain.callReadOnlyFn("liquidity-bootstrapping-pool", "get-y-given-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(expiry),
        types.uint(dx)
      ], this.deployer.address);
    }

    setMaxInRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation-v1-01", "set-max-in-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }        

    setMaxOutRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation-v1-01", "set-max-out-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }       
  
  }
  
  export { LBPTestAgent };