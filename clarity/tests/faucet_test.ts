

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_8 = 100000000

class Faucet {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    setUsdaAmount(sender: Account, amount: number) {
      let block = this.chain.mineBlock([
          Tx.contractCall("faucet", "set-usda-amount", [
            types.uint(amount),
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }

    setWbtcAmount(sender: Account, amount: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("faucet", "set-wbtc-amount", [
              types.uint(amount),
            ], sender.address),
          ]);
          return block.receipts[0].result;
      }
      
    setStxAmount(sender: Account, amount: number) {
      let block = this.chain.mineBlock([
          Tx.contractCall("faucet", "set-stx-amount", [
            types.uint(amount),
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }  
    
    getUsdaAmount() {
        return this.chain.callReadOnlyFn("faucet", "get-usda-amount", [
        ], this.deployer.address);
    }

    getWbtcAmount() {
        return this.chain.callReadOnlyFn("faucet", "get-wbtc-amount", [
        ], this.deployer.address);
    }
    
    getStxAmount() {
        return this.chain.callReadOnlyFn("faucet", "get-stx-amount", [
        ], this.deployer.address);
    }    
    
    getSomeTokens(sender: Account, recipient: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall("faucet", "get-some-tokens", [
              types.principal(recipient),
            ], sender.address),
          ]);
          return block.receipts[0].result;
    }
    
    getBalance(token: string, owner: string) {
        return this.chain.callReadOnlyFn(token, "get-balance", [
          types.principal(owner)
        ], this.deployer.address);
    }    

}

/**
 * faucet test cases
 * 
 */

Clarinet.test({
    name: "Faucet: set amounts and send some tokens",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let wallet_7 = accounts.get("wallet_7")!;
        let FaucetTest = new Faucet(chain, deployer);
        
        let result:any = await FaucetTest.setStxAmount(wallet_1, 10);
        result.expectErr().expectUint(1000);

        result = await FaucetTest.setUsdaAmount(wallet_1, 10);
        result.expectErr().expectUint(1000);

        result = await FaucetTest.setWbtcAmount(wallet_1, 10);
        result.expectErr().expectUint(1000)      
        
        await FaucetTest.setStxAmount(deployer, 100 * ONE_8);
        result = await FaucetTest.getStxAmount(); 
        result.result.expectOk().expectUint(100 * ONE_8);

        await FaucetTest.setUsdaAmount(deployer, 100 * ONE_8);
        result = await FaucetTest.getUsdaAmount(); 
        result.result.expectOk().expectUint(100 * ONE_8);

        await FaucetTest.setWbtcAmount(deployer, 100 * ONE_8);
        result = await FaucetTest.getWbtcAmount(); 
        result.result.expectOk().expectUint(100 * ONE_8); 

        result = await FaucetTest.getBalance('token-usda', wallet_7.address);
        result.result.expectOk().expectUint(0);

        result = await FaucetTest.getBalance('token-wbtc', wallet_7.address);
        result.result.expectOk().expectUint(0);     

        result = await FaucetTest.getSomeTokens(deployer, wallet_7.address);
        result.expectOk();

        result = await FaucetTest.getBalance('token-usda', wallet_7.address);
        result.result.expectOk().expectUint(100 * ONE_8);

        result = await FaucetTest.getBalance('token-wbtc', wallet_7.address);
        result.result.expectOk().expectUint(100 * ONE_8);             
    },    
});
