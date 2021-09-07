import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.13.0/index.ts";
  
  class YTPTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
    
    getT(expiry: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-t", [
        types.uint(expiry)
      ], this.deployer.address);
    }

    getYield(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-yield", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

    getPrice(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-price", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

      getPoolDetails(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-pool-details", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

    createPool(user: Account, aytoken: string, token: string, pooltoken: string, multiSig: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "create-pool", [
          types.principal(aytoken),
          types.principal(token),
          types.principal(pooltoken),
          types.principal(multiSig),
          types.uint(dX),
          types.uint(dY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, aytoken: string, token: string, pooltoken: string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "add-to-position", [
            types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(dX),
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
      reducePosition(user: Account, aytoken: string, token: string, pooltoken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "reduce-position", [
            types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    swapXForY(user: Account, aytoken: string, token: string, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "swap-x-for-y", [
          types.principal(aytoken),
          types.principal(token),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, aytoken: string, token: string, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "swap-y-for-x", [
            types.principal(aytoken),
            types.principal(token),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    getYgivenX(user: Account, aytoken: string, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-y-given-x", [
          types.principal(aytoken),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
    
    getXgivenY(user: Account, aytoken: string, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "get-x-given-y", [
            types.principal(aytoken),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-to-address", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    collectFees(user: Account, aytoken: string, token: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "collect-fees", [
            types.principal(aytoken),
            types.principal(token),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRateToken(user: Account, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-fee-rate-token", [
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateayToken(user: Account, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-fee-rate-aytoken", [
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateToken(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-rate-token", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateayToken(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-rate-aytoken", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

  
  }
  
  export { YTPTestAgent1 };