import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  
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

    getOracleResilient(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-oracle-resilient", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }    

    getOracleInstant(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-oracle-instant", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }      

    setOracleEnabled(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-oracle-enabled", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }      

    setOracleAverage(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, average: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-oracle-average", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(average)
        ], user.address),
      ]);
      return block.receipts[0].result;
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
          types.some(types.uint(dY)),
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
  
    swapXForY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dx: number, dy_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "swap-x-for-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dx),
          types.some(types.uint(dy_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dy: number, dx_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "swap-y-for-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dy),
          types.some(types.uint(dx_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    } 

    getXgivenPrice(tokenX: string, tokenY: string, weightX: number, weightY: number, price: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-x-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(price)
      ], this.deployer.address);
    } 
    
    getYgivenPrice(tokenX: string, tokenY: string, weightX: number, weightY: number, price: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-y-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(price)
      ], this.deployer.address);
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

    getFeeX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "get-fee-rate-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "get-fee-rate-y", [
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

    getYgivenX(tokenX: string, tokenY: string, weightX: number, weightY: number, dx: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-y-given-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(dx)
      ], this.deployer.address);
    }
    
    getXgivenY(tokenX: string, tokenY: string, weightX: number, weightY: number, dy: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-x-given-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(dy)
      ], this.deployer.address);
    }

    setFeeRebate(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, rebate : number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool", "set-fee-rebate", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(rebate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRebate(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool", "get-fee-rebate", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }

    setMaxInRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation", "set-max-in-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }        

    setMaxOutRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation", "set-max-out-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }            
  
  }

  class FWPTestAgent2 {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }
  
    getPoolDetails(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-pool-details", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }

    getOracleResilient(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-oracle-resilient", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }    

    getOracleInstant(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-oracle-instant", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }      

    setOracleEnabled(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-oracle-enabled", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }      

    setOracleAverage(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, average: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-oracle-average", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(average)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }    
  
    createPool(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, multisig: string, balanceX: number, balanceY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "create-pool", [
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
        Tx.contractCall("fixed-weight-pool-alex", "add-to-position", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.principal(pooltoken),
          types.uint(dX),
          types.some(types.uint(dY)),
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    reducePosition(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, percentage: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "reduce-position", [
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
  
    swapXForY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dx: number, dy_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "swap-x-for-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dx),
          types.some(types.uint(dy_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    }
  
    swapYForX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, dy: number, dx_min: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "swap-y-for-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(dy),
          types.some(types.uint(dx_min))
        ], user.address),
      ]);
      return block.receipts[0].result;
    } 

    getXgivenPrice(tokenX: string, tokenY: string, weightX: number, weightY: number, price: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-x-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(price)
      ], this.deployer.address);
    } 
    
    getYgivenPrice(tokenX: string, tokenY: string, weightX: number, weightY: number, price: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-y-given-price", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(price)
      ], this.deployer.address);
    } 
  
    setFeetoAddress(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, address: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-fee-to-address", [
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
        Tx.contractCall("fixed-weight-pool-alex", "get-fee-to-address", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "get-fee-rate-x", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "get-fee-rate-y", [
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
        Tx.contractCall("fixed-weight-pool-alex", "set-fee-rate-x", [
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
        Tx.contractCall("fixed-weight-pool-alex", "set-fee-rate-y", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(feerate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getYgivenX(tokenX: string, tokenY: string, weightX: number, weightY: number, dx: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-y-given-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(dx)
      ], this.deployer.address);
    }
    
    getXgivenY(tokenX: string, tokenY: string, weightX: number, weightY: number, dy: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-x-given-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.uint(dy)
      ], this.deployer.address);
    }

    setFeeRebate(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, rebate : number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-fee-rebate", [
          types.principal(tokenX),
          types.principal(tokenY),
          types.uint(weightX),
          types.uint(weightY),
          types.uint(rebate)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }

    getFeeRebate(tokenX: string, tokenY: string, weightX: number, weightY: number) {
      return this.chain.callReadOnlyFn("fixed-weight-pool-alex", "get-fee-rebate", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
      ], this.deployer.address);
    }

    setMaxInRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation", "set-max-in-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }        

    setMaxOutRatio(user: Account, ratio: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("weighted-equation", "set-max-out-ratio", [
          types.uint(ratio)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }    
    
    setStartBlock(user: Account, start_block: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-start-block", [
          types.uint(start_block)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }        

    setEndBlock(user: Account, end_block: number) {
      let block = this.chain.mineBlock([
        Tx.contractCall("fixed-weight-pool-alex", "set-end-block", [
          types.uint(end_block)
        ], user.address),
      ]);
      return block.receipts[0].result;
    }         
  
  }
  
  export { FWPTestAgent1, FWPTestAgent2 };