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
    
    getWeightX(token: string, collateral: string, expiry: number) {
      return this.chain.callReadOnlyFn("collateral-rebalancing-pool", "get-weight-x", [
        types.principal(token),
        types.principal(collateral),
        types.uint(expiry)
      ], this.deployer.address);
    }
  
    createPool(user: Account, token: string, collateral: string, yieldToken: string, vault: string, dX: number, dY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "create-pool", [
          types.principal(token),
          types.principal(collateral),
          types.principal(yieldToken),
          types.principal(vault),
          types.uint(dX),
          types.uint(dY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    addToPosition(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, vault: string, dX: number, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "add-to-position", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.principal(yieldToken),
            types.principal(vault),
            types.uint(dX),
            types.uint(dY)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
      reducePosition(user: Account, token: string, collateral: string, expiry: number, yieldToken: string, vault: string, percent: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "reduce-position", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.principal(yieldToken),
            types.principal(vault),
            types.uint(percent)
          ], user.address),
        ]);
        return block.receipts[0].result;
      }
  
    swapXForY(user: Account, token: string, collateral: string, expiry: number, vault: string, dX: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "swap-x-for-y", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.principal(vault),
          types.uint(dX)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, token: string, collateral: string, expiry: number, vault: string, dY: number) {
        let block = this.chain.mineBlock([
          Tx.contractCall("collateral-rebalancing-pool", "swap-y-for-x", [
            types.principal(token),
            types.principal(collateral),
            types.uint(expiry),
            types.principal(vault),
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


    setFeetoAddress(user: Account, token: string, collateral: string, expiry: number, address: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("collateral-rebalancing-pool", "set-fee-to-address", [
          types.principal(token),
          types.principal(collateral),
          types.uint(expiry),
          types.principal(address) 
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
  
  }
  
  export { CRPTestAgent1 };