

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

const ONE_8 = 100000000

const tokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-apower"
export class ManyRecord {
  constructor(
    readonly recipient: Account,
    readonly amount: number
  ) {}
}
class Token {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    sendFixedMany(sender: Account, recipients: Array<ManyRecord>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "send-fixed-many", [
            types.list(recipients.map((record) => { 
              return types.tuple({ recipient: types.principal(record.recipient.address), amount: types.uint(record.amount) });
            }))
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }    

    mintFixedMany(sender: Account, recipients: Array<ManyRecord>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "mint-fixed-many", [
            types.list(recipients.map((record) => { 
              return types.tuple({ recipient: types.principal(record.recipient.address), amount: types.uint(record.amount) });
            }))
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }

    mintFixed(sender: Account, amount: number, recipient: string) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "mint-fixed", [
            types.uint(amount),
            types.principal(recipient)
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }   
    
    burnFixed(sender: Account, amount: number, recipient: string) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "burn-fixed", [
            types.uint(amount),
            types.principal(recipient)
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }      
    
    transferFixed(sender: Account, amount: number, recipient: string, memo:ArrayBuffer) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "transfer-fixed", [
            types.uint(amount),
            types.principal(sender.address),            
            types.principal(recipient),
            types.some(types.buff(memo))            
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }       
    
    getBalance(token: string, owner: string) {
      return this.chain.callReadOnlyFn(token, "get-balance", [
        types.principal(owner)
      ], this.deployer.address);
    }    

    addApprovedContract(sender: Account, contract: string) {
      let block = this.chain.mineBlock([
          Tx.contractCall(tokenAddress, "add-approved-contract", [
            types.principal(contract)
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }         

}

Clarinet.test({
    name: "token-apower : send, mint and burn some tokens",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_6 = accounts.get("wallet_6")!;
        let wallet_7 = accounts.get("wallet_7")!;
        let wallet_8 = accounts.get("wallet_8")!;
        let TokenTest = new Token(chain, deployer);

        // testing mint-fixed-many
        let recipients: Array<Account> = [ accounts.get("wallet_6")!, accounts.get("wallet_8")! ];
        let amounts: Array<number> = [100 * ONE_8, 200 * ONE_8];

        let manyRecords: ManyRecord[] = [];

        recipients.forEach((recipient, recipientIdx) => {
          let record = new ManyRecord(
            recipient,
            amounts[recipientIdx]
          );
          manyRecords.push(record);
        });
        
        // non contract-owner calling mint-alex-many throws an error.
        let result:any = await TokenTest.mintFixedMany(wallet_8, manyRecords);
        result.expectErr().expectUint(1000);
        
        // once added to approved, you can.
        result = await TokenTest.addApprovedContract(deployer, wallet_8.address);
        result.expectOk();
        result = await TokenTest.mintFixed(wallet_8, 100 * ONE_8, wallet_7.address);
        result.expectOk();

        result = await TokenTest.mintFixedMany(deployer, manyRecords);
        result.expectOk().expectList();
        result = await TokenTest.getBalance('token-apower', wallet_6.address);
        result.result.expectOk().expectUint(100 * ONE_8);
        result = await TokenTest.getBalance('token-apower', wallet_8.address);
        result.result.expectOk().expectUint(200 * ONE_8);      
        
        // wallet_6 does have 100, but it will fail.
        result = await TokenTest.transferFixed(wallet_6, 50 * ONE_8, wallet_7.address, new ArrayBuffer(4));
        result.expectErr().expectUint(3000);        
        result = await TokenTest.getBalance('token-apower', wallet_6.address);
        result.result.expectOk().expectUint(100 * ONE_8);
        result = await TokenTest.getBalance('token-apower', wallet_7.address);
        result.result.expectOk().expectUint(100 * ONE_8);

        // trying to burn by non approved will throw error.
        result = await TokenTest.burnFixed(wallet_6, 100 * ONE_8, wallet_6.address);
        result.expectErr().expectUint(1000);

        // approved burning tokens is ok.
        result = await TokenTest.burnFixed(wallet_8, 100 * ONE_8, wallet_6.address);
        result.expectOk();
        result = await TokenTest.getBalance('token-apower', wallet_6.address);
        result.result.expectOk().expectUint(0);
    },    
});

Clarinet.test({
  name: "autoalex-apower-helper : mint and burn apower",

  async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet_6 = accounts.get("wallet_6")!;
      let wallet_7 = accounts.get("wallet_7")!;
      let wallet_8 = accounts.get("wallet_8")!;
      let TokenTest = new Token(chain, deployer);

      // testing mint-fixed-many
      let recipients: Array<Account> = [ accounts.get("wallet_6")!, accounts.get("wallet_8")! ];
      let ratios: Array<number> = [3_000 * ONE_8, 7_000 * ONE_8];

      let manyRecords: ManyRecord[] = [];

      recipients.forEach((recipient, recipientIdx) => {
        let record = new ManyRecord(
          recipient,
          ratios[recipientIdx]
        );
        manyRecords.push(record);
      });
      
      // non contract-owner calling mint-alex-many throws an error.
      let result:any = await TokenTest.mintFixed(deployer, 10_000e8, deployer.address + '.auto-alex');
      result.expectOk();
      result = await TokenTest.addApprovedContract(deployer, deployer.address + '.autoalex-apower-helper');
      result.expectOk();

      let block:any = chain.mineBlock(
        [
          Tx.contractCall(deployer.address + '.autoalex-apower-helper', 'set-approved-contract',
            [
              types.principal(wallet_7.address),
              types.bool(true)
            ],
            deployer.address
          ),
          Tx.contractCall(deployer.address + '.autoalex-apower-helper', 'mint-and-burn-apower', 
            [
              types.uint(1),
              types.uint(1),
              types.list(manyRecords.map((record) => { return types.tuple({ recipient: types.principal(record.recipient.address), amount: types.uint(record.amount) })}))
            ], 
            wallet_7.address
          )
        ]
      );      
      block.receipts[1].events.expectFungibleTokenMintEvent(
        3_000e8,
        wallet_6.address,
        "apower"
      );   
      block.receipts[1].events.expectFungibleTokenMintEvent(
        7_000e8,
        wallet_8.address,
        "apower"
      );  
      block.receipts[1].events.expectFungibleTokenBurnEvent(
        10_000e8,
        deployer.address + '.auto-alex',
        "apower"
      );              
  },    
});
