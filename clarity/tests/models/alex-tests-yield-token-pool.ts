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
      return this.chain.callReadOnlyFn("yield-token-pool-usda-wbtc", "get-t", [
        types.uint(expiry)
      ], this.deployer.address);
    }

    getYield(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool-usda-wbtc", "get-yield", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

    getPrice(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool-usda-wbtc", "get-price", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

      getPoolDetails(aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool-usda-wbtc", "get-pool-details", [
          types.principal(aytoken)
        ], this.deployer.address);
      }

    createPool(user: Account, aytoken: string, token: string, pooltoken: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "create-pool", [
          types.principal(aytoken),
          types.principal(token),
          types.principal(pooltoken),
          types.uint(dX),
          types.uint(dY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, aytoken: string, token: string, pooltoken: string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool-usda-wbtc", "add-to-position", [
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
          Tx.contractCall("yield-token-pool-usda-wbtc", "reduce-position", [
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
        Tx.contractCall("yield-token-pool-usda-wbtc", "swap-x-for-y", [
          types.principal(aytoken),
          types.principal(token),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, aytoken: string, token: string, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool-usda-wbtc", "swap-y-for-x", [
            types.principal(aytoken),
            types.principal(token),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    getYgivenX(user: Account, aytoken: string, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "get-y-given-x", [
          types.principal(aytoken),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
    
    getXgivenY(user: Account, aytoken: string, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool-usda-wbtc", "get-x-given-y", [
            types.principal(aytoken),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
    }


    setFeetoAddress(user: Account, aytoken: string, address: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "set-fee-to-address", [
          types.principal(aytoken),
          types.principal(address) 
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "get-fee-to-address", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    collectFees(user: Account, aytoken: string, token: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "collect-fees", [
            types.principal(aytoken),
            types.principal(token),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRateToken(user: Account, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "set-fee-rate-token", [
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateayToken(user: Account, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "set-fee-rate-aytoken", [
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateToken(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "get-fee-rate-token", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateayToken(user: Account, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool-usda-wbtc", "get-fee-rate-aytoken", [
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

  
  }
  
  export { YTPTestAgent1 };