

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';
import { ALEXToken } from './models/alex-tests-tokens.ts';


class Exchange {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    exchange(sender: Account, mainnet: string) {
      let block = this.chain.mineBlock([
        Tx.contractCall("exchange", "exchange", [
          types.principal(mainnet),
        ], sender.address),
      ]);
      return block.receipts[0].result;    
    }
}

/**
 * faucet test cases
 * 
 */

Clarinet.test({
    name: "Exchange: exchange",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let ExchangeTest = new Exchange(chain, deployer);
        let alexToken = new ALEXToken(chain, deployer);

        let result:any = await alexToken.mintFixed(deployer, deployer.address, 100e8);
        result.expectOk();

        result = await alexToken.getBalance(deployer.address);
        result.result.expectOk().expectUint(100e8);
        
        result = ExchangeTest.exchange(deployer, 'SPZP1114C4EA044RE54M6G5ZC2NYK9SAK9SJN0M');
        result.expectOk().expectUint(1);

        result = await alexToken.getBalance(deployer.address);
        result.result.expectOk().expectUint(0);
    },    
});
