import {
  Account,
  Chain,
  Clarinet,
  Tx,
  types,
} from "https://deno.land/x/clarinet@v0.34.0/index.ts";

class SSPTestAgent1 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  getPoolDetails(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-pool-details", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }

  getOracleResilient(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-oracle-resilient", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }    

  getOracleInstant(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-oracle-instant", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }      

  setOracleEnabled(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-oracle-enabled", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }      

  setOracleAverage(user: Account, tokenX: string, tokenY: string, factor: number, average: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-oracle-average", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(average)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }    

  createPool(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, multisig: string, balanceX: number, balanceY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "create-pool", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.principal(multisig),
        types.uint(balanceX),
        types.uint(balanceY),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  addToPosition(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, dX: number, dY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "add-to-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.uint(dX),
        types.some(types.uint(dY)),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  reducePosition(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, percentage: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "reduce-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.uint(percentage),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapXForY(user: Account, tokenX: string, tokenY: string, factor: number, dx: number, dy_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "swap-x-for-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(dx),
        types.some(types.uint(dy_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapYForX(user: Account, tokenX: string, tokenY: string, factor: number, dy: number, dx_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "swap-y-for-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(dy),
        types.some(types.uint(dx_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  } 

  getXgivenPrice(tokenX: string, tokenY: string, factor: number, price: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-x-given-price", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(price)
    ], this.deployer.address);
  } 
  
  getYgivenPrice(tokenX: string, tokenY: string, factor: number, price: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-y-given-price", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(price)
    ], this.deployer.address);
  } 

  setFeetoAddress(user: Account, tokenX: string, tokenY: string, factor: number, address: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-fee-to-address", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(address) 
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeetoAddress(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "get-fee-to-address", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeX(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "get-fee-rate-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeY(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "get-fee-rate-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  setFeeRateX(user: Account, tokenX: string, tokenY: string, factor: number, feerate:number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-fee-rate-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(feerate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  setFeeRateY(user: Account, tokenX: string, tokenY: string, factor: number, feerate:number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-fee-rate-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(feerate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getYgivenX(tokenX: string, tokenY: string, factor: number, dx: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-y-given-x", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(dx)
    ], this.deployer.address);
  }
  
  getXgivenY(tokenX: string, tokenY: string, factor: number, dy: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-x-given-y", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(dy)
    ], this.deployer.address);
  }

  setFeeRebate(user: Account, tokenX: string, tokenY: string, factor: number, rebate : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-fee-rebate", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(rebate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeRebate(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("stable-swap-pool", "get-fee-rebate", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }

  setMaxInRatio(user: Account, ratio: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-max-in-ratio", [
        types.uint(ratio)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }        

  setMaxOutRatio(user: Account, ratio: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-max-out-ratio", [
        types.uint(ratio)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }   

  setStartBlock(user: Account, tokenX: string, tokenY: string, factor: number, start_block: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-start-block", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),          
        types.uint(start_block)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }        

  setEndBlock(user: Account, tokenX: string, tokenY: string, factor: number, end_block: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "set-end-block", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),          
        types.uint(end_block)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }  

  swapHelper(user: Account, tokenX: string, tokenY: string, factor: number, dx: number, dy_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "swap-helper", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(dx),
        types.some(types.uint(dy_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  }  

  swapHelperA(user: Account, tokenX: string, tokenY: string, tokenZ: string, factorX: number, factorY: number, dx: number, dz_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("stable-swap-pool", "swap-helper-a", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.principal(tokenZ),
        types.uint(factorX),
        types.uint(factorY),
        types.uint(dx),
        types.some(types.uint(dz_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  }    
}

class SSPTestAgent2 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  getPoolDetails(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-pool-details", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }

  getOracleResilient(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-oracle-resilient", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }    

  getOracleInstant(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-oracle-instant", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }      

  setOracleEnabled(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-oracle-enabled", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }      

  setOracleAverage(user: Account, tokenX: string, tokenY: string, factor: number, average: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-oracle-average", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(average)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }    

  createPool(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, multisig: string, balanceX: number, balanceY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "create-pool", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.principal(multisig),
        types.uint(balanceX),
        types.uint(balanceY),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  addToPosition(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, dX: number, dY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "add-to-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.uint(dX),
        types.some(types.uint(dY)),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  reducePosition(user: Account, tokenX: string, tokenY: string, factor: number, pooltoken: string, percentage: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "reduce-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(pooltoken),
        types.uint(percentage),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapXForY(user: Account, tokenX: string, tokenY: string, factor: number, dx: number, dy_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "swap-x-for-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(dx),
        types.some(types.uint(dy_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapYForX(user: Account, tokenX: string, tokenY: string, factor: number, dy: number, dx_min: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "swap-y-for-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(dy),
        types.some(types.uint(dx_min))
      ], user.address),
    ]);
    return block.receipts[0].result;
  } 

  getXgivenPrice(tokenX: string, tokenY: string, factor: number, price: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-x-given-price", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(price)
    ], this.deployer.address);
  } 
  
  getYgivenPrice(tokenX: string, tokenY: string, factor: number, price: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-y-given-price", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(price)
    ], this.deployer.address);
  } 

  setFeetoAddress(user: Account, tokenX: string, tokenY: string, factor: number, address: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-fee-to-address", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.principal(address) 
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeetoAddress(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "get-fee-to-address", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeX(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "get-fee-rate-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeY(user: Account, tokenX: string, tokenY: string, factor: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "get-fee-rate-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  

  setFeeRateX(user: Account, tokenX: string, tokenY: string, factor: number, feerate:number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-fee-rate-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(feerate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  setFeeRateY(user: Account, tokenX: string, tokenY: string, factor: number, feerate:number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-fee-rate-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(feerate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getYgivenX(tokenX: string, tokenY: string, factor: number, dx: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-y-given-x", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(dx)
    ], this.deployer.address);
  }
  
  getXgivenY(tokenX: string, tokenY: string, factor: number, dy: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-x-given-y", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
      types.uint(dy)
    ], this.deployer.address);
  }

  setFeeRebate(user: Account, tokenX: string, tokenY: string, factor: number, rebate : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-fee-rebate", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),
        types.uint(rebate)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  getFeeRebate(tokenX: string, tokenY: string, factor: number) {
    return this.chain.callReadOnlyFn("config-swap-pool", "get-fee-rebate", [
      types.principal(tokenX),
      types.principal(tokenY),
      types.uint(factor),
    ], this.deployer.address);
  }

  setMaxInRatio(user: Account, ratio: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-max-in-ratio", [
        types.uint(ratio)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }        

  setMaxOutRatio(user: Account, ratio: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-max-out-ratio", [
        types.uint(ratio)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }   

  setStartBlock(user: Account, tokenX: string, tokenY: string, factor: number, start_block: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-start-block", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),          
        types.uint(start_block)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }        

  setEndBlock(user: Account, tokenX: string, tokenY: string, factor: number, end_block: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("config-swap-pool", "set-end-block", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(factor),          
        types.uint(end_block)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }     
  

}

export { SSPTestAgent1, SSPTestAgent2 };