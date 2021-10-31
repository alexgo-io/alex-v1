import {
  Account,
  Chain,
  Clarinet,
  Tx,
  types,
} from "https://deno.land/x/clarinet@v0.13.0/index.ts";



class MS_FWP_WBTC_USDA_5050 {
  chain: Chain;
  deployer: Account;

  constructor(chain: Chain, deployer: Account) {
    this.chain = chain;
    this.deployer = deployer;
    //this.wallet_1 = wallet_1;
  }

  propose(startBlockHeight: number, proposeTitle: string, proposeURL: string, feeRateX: number, feeRateY: number) {
      let block = this.chain.mineBlock([
          Tx.contractCall("multisig-fwp-wbtc-usda-50-50", "propose", [
            types.uint(startBlockHeight),
            types.utf8(proposeTitle),
            types.utf8(proposeURL),
            types.uint(feeRateX),
            types.uint(feeRateY),
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
export { MS_FWP_WBTC_USDA_5050 };



class MS_YTP_WBT_59760 {
chain: Chain;
deployer: Account;

constructor(chain: Chain, deployer: Account) {
  this.chain = chain;
  this.deployer = deployer;
}

propose(startBlockHeight: number, proposeTitle: string, proposeURL: string, feeRateX: number, feeRateY: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-ytp-yield-wbtc-59760-wbtc", "propose", [
          types.uint(startBlockHeight),
          types.utf8(proposeTitle),
          types.utf8(proposeURL),
          types.uint(feeRateX),
          types.uint(feeRateY),
        ], this.deployer.address),
      ]);
      return block.receipts[0].result;
  }

voteFor(contractCaller: Account, token: string, proposalID: number, amount: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-ytp-yield-wbtc-59760-wbtc", "vote-for", [
          types.principal(token),
          types.uint(proposalID),
          types.uint(amount)
        ], contractCaller.address),
      ]);
      return block.receipts[0].result;
  }

voteAgainst(contractCaller: Account, token: string, proposalID: number, amount: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-ytp-yield-wbtc-59760-wbtc", "vote-against", [
          types.principal(token),
          types.uint(proposalID),
          types.uint(amount)
        ], contractCaller.address),
      ]);
      return block.receipts[0].result;
  }

endProposal(proposalID: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-ytp-yield-wbtc-59760-wbtc", "end-proposal", [
          types.uint(proposalID),
        ], this.deployer.address),
      ]);
      return block.receipts[0].result;
  }
}
export { MS_YTP_WBT_59760 };


class MS_CRP_WBTC_USDA_59760 {
chain: Chain;
deployer: Account;

constructor(chain: Chain, deployer: Account) {
  this.chain = chain;
  this.deployer = deployer;
}

propose(contractCaller: Account, startBlockHeight: number, proposeTitle: string, proposeURL: string, feeRateX: number, feeRateY: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-crp-wbtc-59760-usda", "propose", [
          types.uint(startBlockHeight),
          types.utf8(proposeTitle),
          types.utf8(proposeURL),
          types.uint(feeRateX),
          types.uint(feeRateY),
        ], contractCaller.address),
      ]);
      return block.receipts[0].result;
  }

voteFor(contractCaller: Account, token: string, proposalID: number, amount: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-crp-wbtc-59760-usda", "vote-for", [
          types.principal(token),
          types.uint(proposalID),
          types.uint(amount)
        ], contractCaller.address),
      ]);
      return block.receipts[0].result;
  }

voteAgainst(contractCaller: Account, token: string, proposalID: number, amount: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-crp-wbtc-59760-usda", "vote-against", [
          types.principal(token),
          types.uint(proposalID),
          types.uint(amount)
        ], contractCaller.address),
      ]);
      return block.receipts[0].result;
  }

endProposal(proposalID: number) {
    let block = this.chain.mineBlock([
        Tx.contractCall("multisig-crp-wbtc-59760-usda", "end-proposal", [
          types.uint(proposalID),
        ], this.deployer.address),
      ]);
      return block.receipts[0].result;
  }
}
export { MS_CRP_WBTC_USDA_59760 };