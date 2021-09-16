import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.13.0/index.ts";
  
  class CRPTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    getPoolDetails(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-pool-details", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }    

    getPoolValueInToken(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-pool-value-in-token", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }

    getPoolValueInCollateral(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-pool-value-in-collateral", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }    
    
    getWeightY(token: string, collateral: string, expiry: number, strike: number, bs_vol: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-weight-y", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
        types.uint(strike),
        types.uint(bs_vol)
      ], this.deployer.address);
    }

    getLtv(token: string, collateral: string, expiry: number){
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-ltv", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }
  
    createPool(user: Account, token: string, collateral: string, yieldToken: string, keyToken: string, multiSig: string, ltv_0: number, conversion_ltv: number, bs_vol: number, moving_average: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "create-pool", [
          types.principal(token),
          types.principal(collateral),
          types.principal(yieldToken),
          types.principal(keyToken),
          types.principal(multiSig),
          types.uint(ltv_0),
          types.uint(conversion_ltv),
          types.uint(bs_vol),
          types.uint(moving_average),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, token: string, collateral: string, yieldToken: string, keyToken:string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "add-to-position", [
            types.principal(token),
            types.principal(collateral),
            types.principal(yieldToken),
            types.principal(keyToken),
            types.uint(dX)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      addToPositionAndSwitch(user: Account, token: string, collateral: string, yieldToken: string, keyToken: string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "add-to-position-and-switch", [
            types.principal(token),
            types.principal(collateral),
            types.principal(yieldToken),
            types.principal(keyToken),
            types.uint(dX)
          ], user.address),
        ]);
        return block.receipts[0].result;        
      }
  
      reducePositionYield(user: Account, token: string, collateral: string, yieldToken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "reduce-position-yield", [
            types.principal(token),
            types.principal(collateral),
            types.principal(yieldToken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      reducePositionKey(user: Account, token: string, collateral: string, keyToken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "reduce-position-key", [
            types.principal(token),
            types.principal(collateral),
            types.principal(keyToken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    swapXForY(user: Account, token: string, collateral: string, expiry: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "swap-x-for-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, token: string, collateral: string, expiry: number, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "swap-y-for-x", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    getYgivenX(user: Account, token: string, collateral: string, expiry: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "get-y-given-x", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
    
    getXgivenY(user: Account, token: string, collateral: string, expiry: number, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "get-x-given-y", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
    }

    getBalances(user: Account, token: string, collateral: string, expiry: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "get-balances", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry)
          ], user.address),
        ]);
        return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "get-fee-to-address", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    collectFees(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "collect-fees", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRateX(user: Account, token: string, collateral: string, expiry: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "set-fee-rate-x", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    setFeeRateY(user: Account, token: string, collateral: string, expiry: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "set-fee-rate-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateX(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "get-fee-rate-x", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateY(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "get-fee-rate-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getPositionGivenBurnKey(token: string, collateral: string, expiry: number, shares: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-position-given-burn-key", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
        types.uint(shares)
      ], this.deployer.address);
    }

    burnKeyToken(user: Account, amount: number) {
      let block = this.chain.mineBlock([Tx.contractCall("key-wbtc-59760-usda", "burn", [
        types.principal(user.address),
        types.uint(amount)
      ], user.address),
      ]);
      return block.receipts[0].result;    
    }
  }
  
  export { CRPTestAgent1 };