

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.34.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.166.0/testing/asserts.ts';

const stakeContract = "age000-governance-token"
const reserveContract = "alex-reserve-pool";
const helperContract = "staking-helper";
const dualFarmingContract = "dual-farming-pool-v1-01";
const reward_cycle_length = 525;

const ONE_8 = 100000000;
const stakedAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE." + stakeContract;
const dualAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.dual-farm-xusd-usda-helper";
const underlyingAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wdiko";

class StakingHelper {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    claimStakingReward(sender: Account, stakedToken: string, reward_cycles: Array<number>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(helperContract, "claim-staking-reward", [
            types.principal(stakedToken),
            types.list(reward_cycles.map(reward_cycle => { return types.uint(reward_cycle) })),
          ], sender.address),
        ]);
        return block.receipts[0].result;
    }

    getStaked(sender: Account, stakedToken: string, reward_cycles: Array<number>) {
        return this.chain.callReadOnlyFn(helperContract, "get-staked", [
          types.principal(stakedToken),
          types.list(reward_cycles.map(e=>{return types.uint(e)}))
        ], sender.address);
    }
    
    addToken(sender: Account, token: string){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "add-token", [
          types.principal(token)
        ], sender.address),
      ]);
      return block.receipts[0].result;      
    }

    setActivationBlock(sender: Account, token: string, blockheight: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-activation-block", [
          types.principal(token),
          types.uint(blockheight)
        ], sender.address),
      ]);
      return block.receipts[0].result;        
    }

    setRewardCycleLength(sender: Account, length: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-reward-cycle-length", [
          types.uint(length)
        ], sender.address),
      ]);
      return block.receipts[0].result;        
    }      
    
    stakeTokens(sender: Account, token: string, amount: number, lock_period: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "stake-tokens", [
          types.principal(token),
          types.uint(amount),
          types.uint(lock_period)
        ], sender.address),
      ]);
      return block.receipts[0].result;        
    }    

    getRewardCycle(token: string) {
      return this.chain.callReadOnlyFn(reserveContract, "get-reward-cycle", [
        types.principal(token),
        types.uint(this.chain.blockHeight)
      ], this.deployer.address);
    }      

    getFirstStacksBlocksInRewardCycle(token: string, reward_cycle: number) {
      return this.chain.callReadOnlyFn(reserveContract, "get-first-stacks-block-in-reward-cycle", [
        types.principal(token),
        types.uint(reward_cycle)
      ], this.deployer.address);
    } 

    setCoinbaseAmount(sender: Account, token: string, coinbase1: number, coinbase2: number, coinbase3: number, coinbase4: number, coinbase5: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-coinbase-amount", [
          types.principal(token),
          types.uint(coinbase1),
          types.uint(coinbase2),
          types.uint(coinbase3),
          types.uint(coinbase4),
          types.uint(coinbase5),
        ], sender.address),
      ]);
      return block.receipts[0].result;        
    }    
    
    getStakingStatsCoinbaseAsList(token: string, reward_cycles: Array<number>) {
      return this.chain.callReadOnlyFn(helperContract, "get-staking-stats-coinbase-as-list", [
        types.principal(token),
        types.list(reward_cycles.map(e=>{return types.uint(e)}))
      ], this.deployer.address);
    }

    claimStakingRewardDual(sender: Account, stakedToken: string, dualToken: string, reward_cycles: Array<number>) {
      let block = this.chain.mineBlock([
          Tx.contractCall(dualFarmingContract, "claim-staking-reward", [
            types.principal(stakedToken),
            types.principal(dualToken),
            types.list(reward_cycles.map(reward_cycle => { return types.uint(reward_cycle) })),
          ], sender.address),
        ]);
        return block.receipts[0];
    }
    
    addTokenDual(sender: Account, token: string, dualToken: string, underlyingToken: string, emission: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(dualFarmingContract, "add-token", [
          types.principal(token),
          types.principal(dualToken),
          types.principal(underlyingToken),
          types.uint(emission)
        ], sender.address),
      ]);
      return block.receipts[0].result;      
    }    
    
    setApowerMultiplierInFixed(sender: Account, token: string, multiplier: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-apower-multiplier-in-fixed", [
          types.principal(token),
          types.uint(multiplier),
        ], sender.address),
      ]);
      return block.receipts[0].result;      
    }  
}

/**
 * test cases
 * 
 */

Clarinet.test({
  name: "dual-farming-pool-v1-01/xusd-usda tests",

  async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet_6 = accounts.get("wallet_6")!;
      let StakingTest = new StakingHelper(chain, deployer);


      chain.mineBlock([
        Tx.contractCall(stakeContract, "mint-fixed", [
          types.uint(100000e8),
          types.principal(wallet_6.address)
        ], deployer.address),
      ]);

      chain.mineBlock([
        Tx.contractCall(deployer.address + ".token-diko", "mint-fixed", [
          types.uint(100000e8),
          types.principal(dualAddress)
        ], deployer.address),
      ]);      
      
      let result:any = await StakingTest.addTokenDual(wallet_6, stakedAddress, dualAddress, underlyingAddress, ONE_8);
      result.expectErr().expectUint(1000);      
      result = await StakingTest.addTokenDual(deployer, stakedAddress, dualAddress, underlyingAddress, ONE_8);
      result.expectOk().expectBool(true);
    

      result = await StakingTest.setRewardCycleLength(deployer, reward_cycle_length);
      result.expectOk().expectBool(true);      
      result = await StakingTest.setActivationBlock(deployer, stakedAddress, 1);
      result.expectOk().expectBool(true);          
      result = await StakingTest.setCoinbaseAmount(deployer, stakedAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8);
      result.expectOk().expectBool(true);
      result = await StakingTest.setApowerMultiplierInFixed(deployer, stakedAddress, 0.6e8);
      result.expectOk().expectBool(true);      

      result = await StakingTest.stakeTokens(wallet_6, stakedAddress, 100e8, 3);
      result.expectOk().expectBool(true);
      
      chain.mineEmptyBlockUntil(8 + reward_cycle_length * 4 + 1);  
      
      let block = await StakingTest.claimStakingRewardDual(wallet_6, stakedAddress, dualAddress, [1,2,3]);
      let claimed:any = block.result.expectOk().expectList();
      for(let i = 0; i < 3; i++){
        const output = claimed[i].expectOk().expectTuple();
        output['entitled-dual'].expectUint(ONE_8);
        output['entitled-token'].expectUint(ONE_8);
        output['to-return'].expectUint(i == 2 ? 100e8 : 0)
      }

      block.events.expectFungibleTokenTransferEvent(
        1e6,
        dualAddress,
        wallet_6.address,
        "diko"
      );
      block.events.expectFungibleTokenMintEvent(
        ONE_8,
        wallet_6.address,
        "alex"
      );                
  },    
});

