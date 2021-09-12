import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.13.0/index.ts";
  
  

class MultiSigFWP {
    chain: Chain;
    deployer: Account;
    wallet_1: Account;
  
    constructor(chain: Chain, deployer: Account, wallet_1: Account) {
      this.chain = chain;
      this.deployer = deployer;
      this.wallet_1 = wallet_1;
    }

    propose(startBlockHeight: number, proposeTitle: string, proposeURL: string, feeRateX: number, feeRateY: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("multisig-fwp-wbtc-usda-50-50", "propose", [
              types.uint(startBlockHeight),
              types.utf8(proposeTitle),
              types.utf8(proposeURL),
              types.uint(feeRateX),
              types.uint(feeRateY)
            ], this.deployer.address),
          ]);
          return block.receipts[0].result;
      }
    
    voteFor(contractCaller: Account, token: string, proposalID: number, amount: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("multisig-fwp-wbtc-usda-50-50", "vote-for", [
              types.principal(token),
              types.uint(proposalID),
              types.uint(amount)
            ], contractCaller.address),
          ]);
          return block.receipts[0].result;
      }
    
    voteAgainst(contractCaller: Account, token: string, proposalID: number, amount: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("multisig-fwp-wbtc-usda-50-50", "vote-against", [
              types.principal(token),
              types.uint(proposalID),
              types.uint(amount)
            ], contractCaller.address),
          ]);
          return block.receipts[0].result;
      }

    endProposal(proposalID: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("multisig-fwp-wbtc-usda-50-50", "end-proposal", [
              types.uint(proposalID),
            ], this.deployer.address),
          ]);
          return block.receipts[0].result;
      }
}
export { MultiSigFWP };
