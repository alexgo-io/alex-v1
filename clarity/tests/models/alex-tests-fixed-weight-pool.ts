import {
  Account,
  Chain,
  Clarinet,
  Tx,
  types,
} from "https://deno.land/x/clarinet@v0.13.0/index.ts";

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

  createPool(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, vault: string, balanceX: number, balanceY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fixed-weight-pool", "create-pool", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.principal(pooltoken),
        types.principal(vault),
        types.uint(balanceX * 1000000),
        types.uint(balanceY * 1000000),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  addToPosition(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, vault: string, dX: number, dY: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fixed-weight-pool", "add-to-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.principal(pooltoken),
        types.principal(vault),
        types.uint(dX * 1000000),
        types.uint(dY * 1000000),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  reducePosition(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, vault: string, percentage: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fixed-weight-pool", "reduce-position", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.principal(pooltoken),
        types.principal(vault),
        types.uint(percentage),
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapXForY(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, vault: string, dx: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fixed-weight-pool", "swap-x-for-y", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.principal(pooltoken),
        types.principal(vault),
        types.uint(dx * 1000000) // 200
        //types.uint(dyMin * 1000000), // 38 (should get ~40)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

  swapYForX(user: Account, tokenX: string, tokenY: string, weightX: number, weightY: number, pooltoken: string, vault: string, dy: number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fixed-weight-pool", "swap-y-for-x", [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(weightX),
        types.uint(weightY),
        types.principal(pooltoken),
        types.principal(vault),
        types.uint(dy * 1000000) // 200
        //types.uint(dyMin * 1000000), // 38 (should get ~40)
      ], user.address),
    ]);
    return block.receipts[0].result;
  }

}

export { FWPTestAgent1 };