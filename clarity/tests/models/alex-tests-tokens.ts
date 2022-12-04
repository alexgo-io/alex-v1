import {
  Account,
  Chain,
  Clarinet,
  Tx,
  types,
} from "https://deno.land/x/clarinet@v0.34.0/index.ts";


class ALEXToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("age000-governance-token", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("age000-governance-token", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("age000-governance-token", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("age000-governance-token", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn("age000-governance-token", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { ALEXToken };

class USDAToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-usda", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("token-usda", "get-balance-fixed", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-usda", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-usda", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-usda", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  
  totalSupply() {
    return this.chain.callReadOnlyFn("token-usda", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { USDAToken };

class FWP_WSTX_ALEX_5050 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  getBalanceFixed(account: string) {
    return this.chain.callReadOnlyFn("fwp-wstx-alex-50-50-v1-01", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("fwp-wstx-alex-50-50-v1-01", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferFixed(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("fwp-wstx-alex-50-50-v1-01", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupplyFixed() {
    return this.chain.callReadOnlyFn("fwp-wstx-alex-50-50-v1-01", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { FWP_WSTX_ALEX_5050 };


class WBTCToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-xbtc", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("token-xbtc", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-xbtc", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-xbtc", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-xbtc", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn("token-xbtc", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { WBTCToken };

class WBANToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-banana", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("token-banana", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-banana", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-banana", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-banana", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn("token-banana", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { WBANToken };

class WSTXToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-wstx", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("token-wstx", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-wstx", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-wstx", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-wstx", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("token-wstx", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { WSTXToken };

class FWP_WSTX_USDA_5050 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("fwp-wstx-usda-50-50-v1-01", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("fwp-wstx-usda-50-50-v1-01", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { FWP_WSTX_USDA_5050 };

class FWP_ALEX_USDA {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("fwp-alex-usda", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("fwp-alex-usda", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { FWP_ALEX_USDA };
class FWP_WBTC_USDA_5050 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("fwp-wbtc-usda-50-50", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("fwp-wbtc-usda-50-50", "get-total-supply-fixed", [], this.deployer.address);
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
    return this.chain.callReadOnlyFn("ytp-yield-wbtc", "get-balance-fixed", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("ytp-yield-wbtc", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { YTP_YIELD_WBTC };

class YTP_YIELD_USDA {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("ytp-yield-usda", "get-balance-fixed", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("ytp-yield-usda", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { YTP_YIELD_USDA };

class KEY_USDA_WBTC {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("key-usda-wbtc", "get-balance-fixed", [
      types.uint(expiry),
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("key-usda-wbtc", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { KEY_USDA_WBTC };

class KEY_WBTC_USDA {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("key-wbtc-usda", "get-balance-fixed", [
      types.uint(expiry),
      types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("key-wbtc-usda", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
}
export { KEY_WBTC_USDA };

class YIELD_WBTC {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("yield-wbtc", "get-balance-fixed", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("yield-wbtc", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
  
  mintFixed(sender: Account, expiry: number, amount: number, recipient: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall("yield-wbtc", "mint-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(recipient)
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
}
export { YIELD_WBTC };

class ManyRecord {
  constructor(
    readonly to: Account,
    readonly amount: number
  ) {}
}
class ALEXLottery {

  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }
  
  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("lottery-ido-alex", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("lottery-ido-alex", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("lottery-ido-alex", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("lottery-ido-alex", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("lottery-ido-alex", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }
  
  totalSupply() {
    return this.chain.callReadOnlyFn("lottery-ido-alex", "get-total-supply-fixed", [], this.deployer.address);
  }

  mintMany(sender: Account, recipients: Array<ManyRecord>) {
    let block = this.chain.mineBlock([
        Tx.contractCall("lottery-ido-alex", "mint-many", [
          types.list(recipients.map((record) => { 
            return types.tuple({ to: types.principal(record.to.address), amount: types.uint(record.amount) });
          }))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }    
}
export { ALEXLottery, ManyRecord };
class YIELD_USDA {
  chain: Chain;
  deployer: Account;
  
  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn("yield-usda", "get-balance-fixed", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn("yield-usda", "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
  
  mintFixed(sender: Account, expiry: number, amount: number, recipient: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall("yield-usda", "mint-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(recipient)
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
}

export { YIELD_USDA };

class FungibleToken {
  chain: Chain;
  deployer: Account;
  token: string;

  constructor(chain: Chain, deployer: Account, token: string) {
    this.chain = chain;
    this.deployer = deployer;
    this.token = token;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn(this.token, "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn(this.token, "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall(this.token, "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall(this.token, "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn(this.token, "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { FungibleToken };

class SemiFungibleToken {
  chain: Chain;
  deployer: Account;
  token: string;

  constructor(chain: Chain, deployer: Account, token: string) {
    this.chain = chain;
    this.deployer = deployer;
    this.token = token;
  }

  balanceOf(expiry: number, wallet: string) {
    return this.chain.callReadOnlyFn(this.token, "get-balance-fixed", [
      types.uint(expiry), types.principal(wallet),
    ], this.deployer.address);
  }

  getTokenBalanceOwned(wallet: string) {
    return this.chain.callReadOnlyFn(this.token, "get-token-balance-owned-in-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }  
  
  totalSupply(expiry: number) {
    return this.chain.callReadOnlyFn(this.token, "get-total-supply-fixed", [
      types.uint(expiry)
    ], this.deployer.address);
  }
  
  mintFixed(sender: Account, expiry: number, amount: number, recipient: string) {
    let block = this.chain.mineBlock([
      Tx.contractCall(this.token, "mint-fixed", [
        types.uint(expiry),
        types.uint(amount),
        types.principal(recipient)
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

}
export { SemiFungibleToken };

class WXUSDToken {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
  }

  balanceOf(wallet: string) {
    return this.chain.callReadOnlyFn("token-wxusd", "get-balance-fixed", [
      types.principal(wallet),
    ], this.deployer.address);
  }

  getBalance(account: string) {
    return this.chain.callReadOnlyFn("token-wxusd", "get-balance", [
      types.principal(account),
    ], this.deployer.address);
  }

  // Always need to called by deployer
  mint(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-xusd", "mint", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }

  mintFixed(sender: Account, recipient: string, amount : number) {
    let block = this.chain.mineBlock([
      Tx.contractCall("token-xusd", "mint-fixed", [
        types.uint(amount),
        types.principal(recipient)        
      ], sender.address),
    ]);
    return block.receipts[0].result;
  }
  
  transferToken(sender: Account, amount: number, receiver: string, memo:ArrayBuffer) {
    let block = this.chain.mineBlock([
        Tx.contractCall("token-wxusd", "transfer-fixed", [
          types.uint(amount),
          types.principal(sender.address),
          types.principal(receiver),
          types.some(types.buff(memo))
        ], sender.address),
      ]);
      return block.receipts[0].result;
  }

  totalSupply() {
    return this.chain.callReadOnlyFn("token-xusd", "get-total-supply-fixed", [], this.deployer.address);
  }
}
export { WXUSDToken };
