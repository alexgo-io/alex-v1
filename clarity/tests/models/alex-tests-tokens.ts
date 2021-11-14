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



class FWP_WBTC_USDA_5050 {
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
export { FWP_WBTC_USDA_5050 };

class YTP_YIELD_WBTC {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("ytp-yield-wbtc", "get-balance", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("ytp-yield-wbtc", "get-total-supply", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { YTP_YIELD_WBTC };

class KEY_USDA_WBTC {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("key-usda-wbtc", "get-balance", [
      types.uint(expiry),
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("key-usda-wbtc", "get-total-supply", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { KEY_USDA_WBTC };

class YIELD_WBTC {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }
  
  mintFixed(expiry: number, amount: number, recipient: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall("yield-wbtc", "mint-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(recipient)
      ], this.deployer.address),
    ]);
    return block.receipts[0].result;
  }
}
export { YIELD_WBTC };
