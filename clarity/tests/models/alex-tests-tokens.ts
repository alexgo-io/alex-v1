import {
  Account,
  Chain,
  Clarinet,
  Tx,
  types,
} from "https://deno.land/x/clarinet@v0.13.0/index.ts";


class USDAToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-usda", "get-balance", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  transferToken(amount: number, sender: string, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-usda", "transfer", [
          types.uint(amount),
          types.principal(sender),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], this.deployer.address),
      ]);
      return block.receipts[0].result;
  }

  
  totalSupply() {
    return this.chain.callReadOnlyFn("token-usda", "get-total-supply", [], this.deployer.address);
  }
}
export { USDAToken };


class WBTCToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-wbtc", "get-balance", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  transferToken(amount: number, sender: string, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-wbtc", "transfer", [
          types.uint(amount),
          types.principal(sender),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], this.deployer.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn("token-wbtc", "get-total-supply", [], this.deployer.address);
  }
}
export { WBTCToken };



class POOLTOKEN_FWP_WBTC_USDA_5050 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("fwp-wbtc-usda-50-50", "get-balance", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("fwp-wbtc-usda-50-50", "get-total-supply", [], this.deployer.address);
  }
}
export { POOLTOKEN_FWP_WBTC_USDA_5050 };

class POOLTOKEN_YTP_WBTC_WBTC_59760 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("ytp-yield-wbtc-59760-wbtc", "get-balance", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("ytp-yield-wbtc-59760-wbtc", "get-total-supply", [], this.deployer.address);
  }
}
export { POOLTOKEN_YTP_WBTC_WBTC_59760 };

