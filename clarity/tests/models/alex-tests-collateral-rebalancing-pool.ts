import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.31.1/index.ts";
  
  class CRPTestAgent1 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    getPoolDetails(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-pool-details", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }    

    // getPoolValueInToken(token: string, collateral: string, expiry: number, spot: number) {
      getPoolValueInToken(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-pool-value-in-token", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }

    // getPoolValueInCollateral(token: string, collateral: string, expiry: number, spot: number) {
      getPoolValueInCollateral(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-pool-value-in-collateral", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }    
    
    // getWeightX(token: string, collateral: string, expiry: number, strike: number, bs_vol: number, spot: number) {
    getWeightX(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-weight-x", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
      ], this.deployer.address);
    }

    getSpot(token: string, collateral: string){
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-spot", [
        types.principal(token),
        types.principal(collateral)
      ], this.deployer.address);
    }    

    // getLtv(token: string, collateral: string, expiry: number, spot: number){
      getLtv(token: string, collateral: string, expiry: number){
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-ltv", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }

    getTokenGivenPosition(token: string, collateral: string, expiry: number, dx: number){
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-token-given-position", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
        types.uint(dx)
      ], this.deployer.address);
    }    
  
    createPool(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, keyToken: string, multiSig: string, ltv_0: number, conversion_ltv: number, bs_vol: number, moving_average: number, token_to_maturity: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "create-pool", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.principal(yieldToken),
          types.principal(keyToken),
          types.principal(multiSig),
          types.uint(ltv_0),
          types.uint(conversion_ltv),
          types.uint(bs_vol),
          types.uint(moving_average),
          types.uint(token_to_maturity),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, keyToken:string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "add-to-position", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),            
            types.principal(yieldToken),
            types.principal(keyToken),
            types.uint(dX)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      addToPositionAndSwitch(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, keyToken: string, dX: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "add-to-position-and-switch", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),            
            types.principal(yieldToken),
            types.principal(keyToken),
            types.uint(dX),
            types.some(types.uint(0))
          ], user.address),
        ]);
        return block.receipts[0].result;        
      }
  
      reducePositionYield(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "reduce-position-yield", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.principal(yieldToken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      reducePositionYieldMany(user: Account, token: string, collateral: string, yieldToken: string, percent: number, expiries: Array<number>) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "reduce-position-yield-many", [
            types.principal(token),
            types.principal(collateral),
            types.principal(yieldToken),
            types.uint(percent),
            types.list(expiries.map(types.uint)),
          ], user.address),
        ]);
        return block.receipts[0].result;
      }      

      reducePositionKey(user: Account, token: string, collateral: string, expiry: number, keyToken: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "reduce-position-key", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.principal(keyToken),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }

      reducePositionKeyMany(user: Account, token: string, collateral: string, keyToken: string, percent: number, expiries: Array<number>) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "reduce-position-key-many", [
            types.principal(token),
            types.principal(collateral),
            types.principal(keyToken),
            types.uint(percent),
            types.list(expiries.map(types.uint))
          ], user.address),
        ]);
        return block.receipts[0].result;
      }      
  
    swapXForY(user: Account, token: string, collateral: string, expiry: number, dX: number, dy_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "swap-x-for-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(dX),
          types.some(types.uint(dy_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, token: string, collateral: string, expiry: number, dY: number, min_dx: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool-v1", "swap-y-for-x", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.uint(dY),
            types.some(types.uint(min_dx))
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    getYgivenX(user: Account, token: string, collateral: string, expiry: number, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "get-y-given-x", [
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
          Tx.contractCall("collateral-rebalancing-pool-v1", "get-x-given-y", [
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
          Tx.contractCall("collateral-rebalancing-pool-v1", "get-balances", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry)
          ], user.address),
        ]);
        return block.receipts[0].result;
    }
  
    getFeetoAddress(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "get-fee-to-address", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    setFeeRateX(user: Account, token: string, collateral: string, expiry: number, feerate:number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-fee-rate-x", [
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
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-fee-rate-y", [
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
        Tx.contractCall("collateral-rebalancing-pool-v1", "get-fee-rate-x", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRateY(user: Account, token: string, collateral: string, expiry: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "get-fee-rate-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getPositionGivenBurnKey(token: string, collateral: string, expiry: number, shares: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-position-given-burn-key", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
        types.uint(shares)
      ], this.deployer.address);
    }

    burnKeyToken(user: Account, expiry: number, amount: number) {
      let block = this.chain.mineBlock([Tx.contractCall("key-wbtc-usda", "burn-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(user.address)        
      ], user.address),
      ]);
      return block.receipts[0].result;    
    }

    transfer(user: Account, token: string, expiry: number, amount: number, sender: string, recipient: string) {
      let block = this.chain.mineBlock([Tx.contractCall(token, "transfer-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(sender),
        types.principal(recipient),
      ], user.address),
      ]);
      return block.receipts[0].result;    
    }

    getBalance(token: string, expiry: number, owner: string) {
      return this.chain.callReadOnlyFn(token, "get-balance-fixed", [
        types.uint(expiry),
        types.principal(owner)
      ], this.deployer.address);
    }

    getXgivenPrice(token: string, collateral: string, expiry: number, price: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-x-given-price", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(price)
        ], this.deployer.address);
    }    

    getYgivenPrice(token: string, collateral: string, expiry: number, price: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-y-given-price", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry),
        types.uint(price)
      ], this.deployer.address);
    }    

    setFeeRebate(user: Account, token: string, collateral: string, expiry: number, rebate : number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-fee-rebate", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.uint(rebate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRebate(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-fee-rebate", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }

    setMaxInRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-max-in-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }        
  
    setMaxOutRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-max-out-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
    
    setApprovedContract(user: Account, owner: string, approved: boolean) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-contract", [
          types.principal(owner),
          types.bool(approved)
        ], user.address),        
      ]);
      return block.receipts[0].result;
    }
    
  }
  
  export { CRPTestAgent1 };