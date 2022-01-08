

import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const stakeContract = "age000-governance-token"
const reserveContract = "alex-reserve-pool";
const helperContract = "staking-helper";
const reward_cycle_length = 525;

const ONE_8 = 100000000;
const stakedAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE." + stakeContract;
const fwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool";

class StakingHelper {
    chain: Chain;
    deployer: Account;
  
    constructor(chain: Chain, deployer: Account) {
      this.chain = chain;
      this.deployer = deployer;
    }

    claimStakingReward(sender: Account, stakedToken: string, reward_cycle: number) {
      let block = this.chain.mineBlock([
          Tx.contractCall(helperContract, "claim-staking-reward-by-tx-sender", [
            types.principal(stakedToken),
            types.uint(reward_cycle),
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

    setActivationThreshold(sender: Account, threshold: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-activation-threshold", [
          types.uint(threshold)
        ], sender.address),
      ]);
      return block.receipts[0].result;        
    }

    setActivationDelay(sender: Account, delay: number){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "set-activation-delay", [
          types.uint(delay)
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

    registerUser(sender: Account, token: string){
      let block = this.chain.mineBlock([
        Tx.contractCall(reserveContract, "register-user", [
          types.principal(token),
          types.none()
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
}

/**
 * test cases
 * 
 */

Clarinet.test({
    name: "staking-helper tests",

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

        let result:any = await StakingTest.setActivationThreshold(deployer, 1);
        result.expectOk().expectBool(true);
        result = await StakingTest.setActivationDelay(deployer, 1);
        result.expectOk().expectBool(true);
        result = await StakingTest.setRewardCycleLength(deployer, reward_cycle_length);
        result.expectOk().expectBool(true);
        result = await StakingTest.addToken(deployer, stakedAddress);
        result.expectOk().expectBool(true);  
        result = await StakingTest.setCoinbaseAmount(deployer, stakedAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8);
        result.expectOk().expectBool(true);      
        result = await StakingTest.registerUser(deployer, stakedAddress);
        result.expectOk().expectBool(true);

        result = await StakingTest.stakeTokens(wallet_6, stakedAddress, 100e8, 3);
        result.expectOk().expectBool(true);

        // you can stake only from next cycle
        let call:any = await StakingTest.getStaked(wallet_6, stakedAddress, [0,1,3]);
        result = call.result.expectList();
        let result0:any = result[0].expectTuple();
        result0['amount-staked'].expectUint(0);
        result0['to-return'].expectUint(0);

        result0 = result[1].expectTuple();
        result0['amount-staked'].expectUint(100e8);
        result0['to-return'].expectUint(0);

        result0 = result[2].expectTuple();
        result0['amount-staked'].expectUint(100e8);
        result0['to-return'].expectUint(100e8);          

        call = await StakingTest.getStakingStatsCoinbaseAsList(stakedAddress, [0,1,3]);
        result = call.result.expectList();
        result0 = result[0].expectTuple();
        result0['staking-stats'].expectUint(0);
        result0['coinbase-amount'].expectUint(ONE_8);      

        call = await StakingTest.getFirstStacksBlocksInRewardCycle(stakedAddress, 1);
        result = call.result.expectUint(8 + reward_cycle_length);
        
        chain.mineEmptyBlockUntil(8 + reward_cycle_length * 2 + 1);

        call = await StakingTest.getRewardCycle(stakedAddress);
        call.result.expectSome().expectUint(2); 
        
        result = await StakingTest.claimStakingReward(wallet_6, stakedAddress, 1);
        let claimed:any = result.expectOk().expectTuple();
        claimed['entitled-token'].expectUint(ONE_8);
        claimed['to-return'].expectUint(0);       
        
        result = await StakingTest.claimStakingReward(wallet_6, stakedAddress, 1);
        claimed = result.expectOk().expectTuple();
        claimed['entitled-token'].expectUint(0);
        claimed['to-return'].expectUint(0);    
        
        chain.mineEmptyBlockUntil(8 + reward_cycle_length * 4 + 1);
        
        call = await StakingTest.getRewardCycle(stakedAddress);
        call.result.expectSome().expectUint(4);    
        
        result = await StakingTest.claimStakingReward(wallet_6, stakedAddress, 3);
        claimed = result.expectOk().expectTuple();
        claimed['entitled-token'].expectUint(ONE_8);
        claimed['to-return'].expectUint(100e8);          

        result = await StakingTest.claimStakingReward(wallet_6, stakedAddress, 3);
        claimed = result.expectOk().expectTuple();
        claimed['entitled-token'].expectUint(0);
        claimed['to-return'].expectUint(0);            
    },    
});
