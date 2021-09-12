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
    
    totalSupply() {
      return this.chain.callReadOnlyFn("token-wbtc", "get-total-supply", [], this.deployer.address);
    }
  }
  export { WBTCToken };



  class FWPWBTCUSDA5050Token {
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
  export { FWPWBTCUSDA5050Token };
