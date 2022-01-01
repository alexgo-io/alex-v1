

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const ONE_8 = 100000000

const ticketAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lottery-ido-alex"

export class ManyRecord {
  constructor(
    readonly to: Account,
    readonly amount: number
  ) {}
}

class LotteryTicket {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    sendMany(sender: Account, recipients: Array<ManyRecord>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(ticketAddress, "send-many", [
            types.list(recipients.map((record) => { 
              return types.tuple({ to: types.principal(record.to.address), amount: types.uint(record.amount) });
            }))
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }    

    mintMany(sender: Account, recipients: Array<ManyRecord>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(ticketAddress, "mint-many", [
            types.list(recipients.map((record) => { 
              return types.tuple({ to: types.principal(record.to.address), amount: types.uint(record.amount) });
            }))
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
          Tx.contractCall(ticketAddress, "add-approved-contract", [
            types.principal(contract)
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }         

}

/**
 * lottery ticket test cases
 * 
 */

Clarinet.test({
    name: "Lottery ticket: send and mint some tokens",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_6 = accounts.get("wallet_6")!;
        let wallet_7 = accounts.get("wallet_7")!;
        let wallet_8 = accounts.get("wallet_8")!;
        let LotteryTest = new LotteryTicket(chain, deployer);

        // testing mint-many
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
        let result:any = await LotteryTest.mintMany(wallet_8, manyRecords);
        result.expectErr().expectUint(1000);

        result = await LotteryTest.mintMany(deployer, manyRecords);
        result.expectOk().expectBool(true);
        result = await LotteryTest.getBalance('lottery-ido-alex', wallet_6.address);
        result.result.expectOk().expectUint(100 * ONE_8);
        result = await LotteryTest.getBalance('lottery-ido-alex', wallet_8.address);
        result.result.expectOk().expectUint(200 * ONE_8);      
        
        // testing send-many
        recipients = [ accounts.get("wallet_7")!, accounts.get("wallet_8")! ];
        amounts = [50 * ONE_8, 50 * ONE_8];

        manyRecords = [];

        recipients.forEach((recipient, recipientIdx) => {
          let record = new ManyRecord(
            recipient,
            amounts[recipientIdx]
          );
          manyRecords.push(record);
        });
        
        // non contract-owner calling mint-alex-many throws an error.
        result = await LotteryTest.mintMany(wallet_6, manyRecords);
        result.expectErr().expectUint(1000);

        result = await LotteryTest.addApprovedContract(deployer, wallet_6.address);
        result.expectOk().expectBool(true);
        result = await LotteryTest.sendMany(wallet_6, manyRecords);
        result.expectOk().expectBool(true);
        result = await LotteryTest.getBalance('lottery-ido-alex', wallet_6.address);
        result.result.expectOk().expectUint(0);
        result = await LotteryTest.getBalance('lottery-ido-alex', wallet_7.address);
        result.result.expectOk().expectUint(50 * ONE_8);
        result = await LotteryTest.getBalance('lottery-ido-alex', wallet_8.address);
        result.result.expectOk().expectUint(250 * ONE_8);          
    },    
});
