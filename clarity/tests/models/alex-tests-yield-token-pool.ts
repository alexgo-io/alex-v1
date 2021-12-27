import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  
  class YTPTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
    
    getT(expiry: number, listed: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-t", [
        types.uint(expiry),
        types.uint(listed)
      ], this.deployer.address);
    }

    getYield(expiry: number, aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-yield", [
          types.uint(expiry),
          types.principal(aytoken)
        ], this.deployer.address);
      }

    getPrice(expiry: number, aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-price", [
          types.uint(expiry),
          types.principal(aytoken)
        ], this.deployer.address);
      }

      getPoolDetails(expiry: number, aytoken: string) {
        return this.chain.callReadOnlyFn("yield-token-pool", "get-pool-details", [
          types.uint(expiry),
          types.principal(aytoken)
        ], this.deployer.address);
      }

    createPool(user: Account, expiry: number, aytoken: string, token: string, pooltoken: string, multiSig: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "create-pool", [
          types.uint(expiry),
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
  
    addToPosition(user: Account, expiry: number, aytoken: string, token: string, pooltoken: string, dX: number, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "add-to-position", [
            types.uint(expiry),
            types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(dX),
            types.some(types.uint(dY))
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      buyAndAddToPosition(user: Account, expiry: number, aytoken: string, token: string, pooltoken: string, dX: number, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "buy-and-add-to-position", [
            types.uint(expiry),
          types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(dX),
            types.some(types.uint(dY))
          ], user.address),
        ]);
        return block.receipts[0].result;
      }    
      
      rollPosition(user: Account, expiry: number, aytoken: string, token: string, pooltoken: string, percent: number, expiry_to_roll: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "roll-position", [
            types.uint(expiry),
          types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(percent),
            types.uint(expiry_to_roll)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }         
  
      reducePosition(user: Account, expiry: number, aytoken: string, token: string, pooltoken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "reduce-position", [
            types.uint(expiry),
            types.principal(aytoken),
            types.principal(token),
            types.principal(pooltoken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    swapXForY(user: Account, expiry: number, aytoken: string, token: string, dX: number, dy_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "swap-x-for-y", [
          types.uint(expiry),
          types.principal(aytoken),
          types.principal(token),
          types.uint(dX),
          types.some(types.uint(dy_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, expiry: number, aytoken: string, token: string, dY: number, dx_min: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("yield-token-pool", "swap-y-for-x", [
            types.uint(expiry),
          types.principal(aytoken),
            types.principal(token),
            types.uint(dY),
            types.some(types.uint(dx_min))
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

    getYgivenX(expiry: number, aytoken: string, dx: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-y-given-x", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(dx)
      ], this.deployer.address);      
    }
    
    getXgivenY(expiry: number, aytoken: string, dy: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-x-given-y", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(dy)
      ], this.deployer.address);      
    }      
  
    getYgivenPrice(expiry: number, aytoken: string, price: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-y-given-price", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(price)
      ], this.deployer.address);      
    }
    
    getXgivenPrice(expiry: number, aytoken: string, price: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-x-given-price", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(price)
      ], this.deployer.address);      
    }

    getYgivenYield(expiry: number, aytoken: string, yied: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-y-given-yield", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(yied)
      ], this.deployer.address);      
    }
    
    getXgivenYield(expiry: number, aytoken: string, yied: number) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-x-given-yield", [
       types.uint(expiry),
        types.principal(aytoken),
        types.uint(yied)
      ], this.deployer.address);      
    }    
  
    getFeetoAddress(user: Account, expiry: number, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-to-address", [
          types.uint(expiry),
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    collectFees(user: Account, expiry: number, aytoken: string, token: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "collect-fees", [
            types.uint(expiry),
          types.principal(aytoken),
            types.principal(token),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRateToken(user: Account, expiry: number, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-fee-rate-token", [
          types.uint(expiry),
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateayToken(user: Account, expiry: number, aytoken: string, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-fee-rate-aytoken", [
          types.uint(expiry),
          types.principal(aytoken),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateToken(user: Account, expiry: number, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-rate-token", [
          types.uint(expiry),
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateayToken(user: Account, expiry: number, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "get-fee-rate-aytoken", [
          types.uint(expiry),
          types.principal(aytoken)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRebate(user: Account, expiry: number, aytoken: string, rebate : number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-fee-rebate", [
          types.uint(expiry),
          types.principal(aytoken),
          types.uint(rebate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRebate(expiry: number, aytoken: string) {
      return this.chain.callReadOnlyFn("yield-token-pool", "get-fee-rebate", [
       types.uint(expiry),
        types.principal(aytoken),
      ], this.deployer.address);
    }

    setOracleEnabled(user: Account, expiry: number, aytoken: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-oracle-enabled", [
          types.uint(expiry),
          types.principal(aytoken),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }      

    setOracleAverage(user: Account, expiry: number, aytoken: string, average: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("yield-token-pool", "set-oracle-average", [
          types.uint(expiry),
          types.principal(aytoken),
          types.uint(average),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }    


  
  }
  
  export { YTPTestAgent1 };