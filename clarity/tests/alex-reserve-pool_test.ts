import { assertEquals, describe, Tx, TxReceipt, types } from "./token-alex-src/deps.ts";
import { CoreClient } from "./token-alex-src/core-client.ts";
import { it } from "./token-alex-src/testutil.ts";

const ONE_8 = 1e8;
const APOWER_MULTIPLIER = 3;
const token = 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token';
const apower = 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-apower';

describe("STAKING :", () => {

  //////////////////////////////////////////////////
  // REGISTRATION
  //////////////////////////////////////////////////

  describe("REGISTRATION", () => {
    describe("get-activation-block()", () => {
      it("sould return the default block height", (chain, accounts, clients) => {
        const result = clients.core.getActivationBlockOrHeight(token).result
        result.expectUint(100000000);
      });

      it("succeeds and returns activation height", (chain, accounts, clients) => {
        // arrange
        const user = accounts.get("wallet_4")!;
        const deployer = accounts.get("deployer")!;
        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(user, token),
        ]);

        const activationBlockHeight =
           block.height + CoreClient.ACTIVATION_DELAY - 1;
        const result = clients.core.getActivationBlockOrHeight(token).result; 
        
        // assert
        result.expectUint(activationBlockHeight);
      });
    });

    describe("get-activation-delay()", () => {
      it("succeeds and returns activation delay", (chain, accounts, clients) => {
        // act
        const result = clients.core.getActivationDelay().result;
        // assert
        result.expectUint(CoreClient.ACTIVATION_DELAY);
      });
    });
    describe("get-activation-threshold()", () => {
      it("succeeds and returns activation threshold", (chain, accounts, clients) => {
        // act
        const result = clients.core.getActivationThreshold().result;
        // assert
        result.expectUint(CoreClient.ACTIVATION_THRESHOLD);
      });
    });

    describe("get-registered-users-nonce()", () => {
      it("succeeds and returns u0 if no users are registered", (chain, accounts, clients) => {
        // act
        const result = clients.core.getRegisteredUsersNonce(token).result;
        // assert
        result.expectNone();
      });
      it("succeeds and returns u1 if one user is registered", (chain, accounts, clients) => {
        // arrange
        const user = accounts.get("wallet_5")!;
        const deployer = accounts.get("deployer")!;
        const receipt = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(user, token)]
        ); 
        receipt.receipts[0].result.expectOk().expectBool(true);
        receipt.receipts[1].result.expectOk().expectBool(true);
        receipt.receipts[2].result.expectOk().expectBool(true);

        // act
        const result = clients.core.getRegisteredUsersNonce(token).result;
        // assert
        result.expectSome().expectUint(1);
      });
    });

    describe("register-user()", () => {
      it("successfully register new user and emits print event with memo when supplied", (chain, accounts, clients) => {
        // arrange
        const user = accounts.get("wallet_5")!;
        const deployer = accounts.get("deployer")!;
        const memo = "hello world";

        // act
        const receipts = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),          
          clients.core.registerUser(user, token, memo)
        ]).receipts;

        // assert
        receipts[0].result.expectOk().expectBool(true);
        receipts[1].result.expectOk().expectBool(true);
        receipts[2].result.expectOk().expectBool(true);
        receipts[3].result.expectOk().expectBool(true);
        clients.core.getUserId(token, user).result.expectSome().expectUint(1);

        assertEquals(receipts[3].events.length, 1);

        const expectedEvent = {
          type: "contract_event",
          contract_event: {
            contract_identifier: clients.core.getContractAddress(),
            topic: "print",
            value: types.some(types.utf8(memo)),
          },
        };

        assertEquals(receipts[3].events[0], expectedEvent);
      });

      it("successfully register new user and do not emit any events when memo is not supplied", (chain, accounts, clients) => {
        // arrange
        const user = accounts.get("wallet_4")!;
        const deployer = accounts.get("deployer")!;

        // act
        const receipt = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(user, token)])
          .receipts;

        // assert
        receipt[2].result.expectOk().expectBool(true);
        clients.core.getUserId(token, user).result.expectSome().expectUint(1);

        assertEquals(receipt[2].events.length, 0);
      });

      it("throws ERR_USER_ALREADY_REGISTERED while trying to register user 2nd time", (chain, accounts, clients) => {
        // arrange
        const user = accounts.get("wallet_4")!;
        const deployer = accounts.get("deployer")!;
        const registerUserTx = clients.core.registerUser(user, token);
        

        chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          registerUserTx]);
        
        // act
        const receipt = chain.mineBlock([registerUserTx]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_USER_ALREADY_REGISTERED);
      });
    });
  });

  //////////////////////////////////////////////////
  // STAKING ACTIONS
  //////////////////////////////////////////////////

  describe("STAKING ACTIONS", () => {
    describe("stake-tokens()", () => {
      it("throws ERR_STAKING_NOT_AVAILABLE when staking is not available", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const amountTokens = 200 * ONE_8;
        const lockPeriod = 2;
        chain.mineBlock([
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.token.mint(amountTokens, staker, deployer)]);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_STAKING_NOT_AVAILABLE);
      });

      it("throws ERR_CANNOT_STAKE while trying to stack with lock period = 0", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;
        const amountTokens = 200 * ONE_8;
        const lockPeriod = 0;
        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_CANNOT_STAKE);
      });

      it("throws ERR_CANNOT_STAKE while trying to stack with lock period > 32", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;        
        const amountTokens = 200 * ONE_8;
        const lockPeriod = 33;
        const block = chain.mineBlock([

          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_CANNOT_STAKE);
      });

      it("throws ERR_CANNOT_STAKE while trying to stack with amount tokens = 0", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;        
        const amountTokens = 0;
        const lockPeriod = 5;
        const block = chain.mineBlock([

          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_CANNOT_STAKE);
      });

      it("throws ERR_TRANSFER_FAILED while trying to stack with amount tokens > user balance", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;        
        const amountTokens = 20 * ONE_8;
        const lockPeriod = 5;
        const block = chain.mineBlock([

          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens + ONE_8, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_TRANSFER_FAILED);
      });

      it("succeeds and cause one ft_transfer_event to core contract", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const amountTokens = 20 * ONE_8;
        const lockPeriod = 5;
        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);

        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const receipt = chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]).receipts[0];

        // assert
        receipt.result.expectOk().expectBool(true);
        assertEquals(receipt.events.length, 1);
        receipt.events.expectFungibleTokenTransferEvent(
          amountTokens,
          staker.address,
          clients.core.getVaultAddress(),
          "alex"
        );
      });

      it("succeeds when called more than once", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const amountTokens = 20 * ONE_8;
        const lockPeriod = 5;

        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens * 3, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        const mineTokensTx = clients.core.stakeTokens(
          amountTokens,
          lockPeriod,
          staker,
          token
        );
        const receipts = chain.mineBlock([
          mineTokensTx,
          mineTokensTx,
          mineTokensTx,
        ]).receipts;

        // assert
        receipts.forEach((receipt: TxReceipt) => {
          receipt.result.expectOk().expectBool(true);
          assertEquals(receipt.events.length, 1);

          receipt.events.expectFungibleTokenTransferEvent(
            amountTokens,
            staker.address,
            clients.core.getVaultAddress(),
            "alex"
          );
        });
      });

      it("remembers when tokens should be returned when locking period = 1", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const amountTokens = 20 * ONE_8;
        const lockPeriod = 1;
        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]);

        // assert
        const rewardCycle = 1;
        const userId = 1;
        const result = clients.core.getStakerAtCycleOrDefault(
          rewardCycle,
          userId,
          token
        ).result;

        assertEquals(result.expectTuple(), {
          'amount-staked': types.uint(amountTokens),
          'to-return': types.uint(amountTokens),
        });
      });

      it("remembers when tokens should be returned when locking period > 1", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const amountTokens = 20 * ONE_8;
        const lockPeriod = 8;
        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        chain.mineBlock([
          clients.core.stakeTokens(amountTokens, lockPeriod, staker, token),
        ]);

        // assert
        const userId = 1;

        for (let rewardCycle = 1; rewardCycle <= lockPeriod; rewardCycle++) {
          const result = clients.core.getStakerAtCycleOrDefault(
            rewardCycle,
            userId,
            token
          ).result;

          assertEquals(result.expectTuple(), {
            'amount-staked': types.uint(amountTokens),
            'to-return': types.uint(rewardCycle === lockPeriod ? amountTokens : 0),
          });
        }
      });

      it("remembers when tokens should be returned when staking multiple times with different locking periods", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;            
        const userId = 1;
        class StakingRecord {
          constructor(
            readonly stackInCycle: number,
            readonly lockPeriod: number,
            readonly amountTokens: number
          ) {}
        }

        const StakingRecords: StakingRecord[] = [
          new StakingRecord(1, 4, 20 * ONE_8),
          new StakingRecord(3, 8, 432 * ONE_8),
          new StakingRecord(7, 3, 10 * ONE_8),
          new StakingRecord(8, 2, 15 * ONE_8),
          new StakingRecord(9, 5, 123 * ONE_8),
        ];

        const totalAmountTokens = StakingRecords.reduce(
          (sum, record) => sum + record.amountTokens,
          0
        );
        const maxCycle = Math.max.apply(
          Math,
          StakingRecords.map((record) => {
            return record.stackInCycle + 1 + record.lockPeriod;
          })
        );

        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(totalAmountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        // act
        StakingRecords.forEach((record) => {
          // move chain tip to the beginning of specific cycle
          chain.mineEmptyBlockUntil(
            activationBlockHeight +
              record.stackInCycle * CoreClient.REWARD_CYCLE_LENGTH
          );

          chain.mineBlock([
            clients.core.stakeTokens(
              record.amountTokens,
              record.lockPeriod,
              staker,
              token
            ),
          ]);
        });

        // assert
        for (let rewardCycle = 0; rewardCycle <= maxCycle; rewardCycle++) {
          let expected = {
            'amount-staked': 0,
            'to-return': 0,
          };

          StakingRecords.forEach((record) => {
            let firstCycle = record.stackInCycle + 1;
            let lastCycle = record.stackInCycle + record.lockPeriod;

            if (rewardCycle >= firstCycle && rewardCycle <= lastCycle) {
              expected['amount-staked'] += record.amountTokens;
            }

            if (rewardCycle == lastCycle) {
              expected['to-return'] += record.amountTokens;
            }
          });

          const result = clients.core.getStakerAtCycleOrDefault(
            rewardCycle,
            userId,
            token
          ).result;

          console.table({
            cycle: rewardCycle,
            expected: expected,
            actual: result.expectTuple(),
          });
          
          assertEquals(result.expectTuple(), {
            'amount-staked': types.uint(expected['amount-staked']),
            'to-return': types.uint(expected['to-return']),
          });
        }
      });
    });
  });

  //////////////////////////////////////////////////
  // STAKING REWARD CLAIMS
  //////////////////////////////////////////////////

  describe("STAKING REWARD CLAIMS", () => {
    describe("claim-staking-reward()", () => {
      it("throws ERR_STAKING_NOT_AVAILABLE when staking is not yet available", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_1")!;
        const deployer = accounts.get("deployer")!;   
        const targetCycle = 1;

        // act
        const receipt = chain.mineBlock([
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts[2];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_STAKING_NOT_AVAILABLE);
      });

      it("throws ERR_USER_ID_NOT_FOUND when called by unknown user", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_1")!;
        const otherUser = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;
        const targetCycle = 1;
        const setupBlock = chain.mineBlock([

          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(otherUser, token),
        ]);
        chain.mineEmptyBlockUntil(
          setupBlock.height + CoreClient.ACTIVATION_DELAY - 1
        );

        // act
        const receipt = chain.mineBlock([
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_USER_ID_NOT_FOUND);
      });

      it("throws ERR_REWARD_CYCLE_NOT_COMPLETED when reward cycle is not completed", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_1")!;
        const deployer = accounts.get("deployer")!;
        const targetCycle = 1;
        const setupBlock = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
        ]);
        chain.mineEmptyBlockUntil(
          setupBlock.height + CoreClient.ACTIVATION_DELAY - 1
        );

        // act
        const receipt = chain.mineBlock([
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts[0];

        // assert
        receipt.result
          .expectErr()
          .expectUint(CoreClient.ErrCode.ERR_REWARD_CYCLE_NOT_COMPLETED);
      });

      it("returns nothing when staker didn't stack at all", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_1")!;
        const deployer = accounts.get("deployer")!;
        const targetCycle = 1;
        const setupBlock = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
        ]);
        chain.mineEmptyBlockUntil(
          setupBlock.height +
            CoreClient.ACTIVATION_DELAY +
            CoreClient.REWARD_CYCLE_LENGTH * 2 -
            1
        );

        // act
        const receipt = chain.mineBlock([
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts[0];

        // assert
        let output:any = receipt.result.expectOk().expectTuple();
        output['entitled-token'].expectUint(0);
        output['to-return'].expectUint(0);
      });

      it("returns nothing while trying to claim reward 2nd time", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_1")!;
        const deployer = accounts.get("deployer")!;        
        const targetCycle = 1;
        const amount = 200 * ONE_8;
        const setupBlock = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amount, staker, deployer),
        ]);

        chain.mineEmptyBlockUntil(
          setupBlock.height + CoreClient.ACTIVATION_DELAY + 1
        );
        let result = chain.mineBlock([clients.core.stakeTokens(amount, 1, staker, token)]).receipts;

        chain.mineEmptyBlock(CoreClient.REWARD_CYCLE_LENGTH * 2);

        // act
        const receipt = chain.mineBlock([
          clients.core.setCoinbaseAmount(deployer, token, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
          clients.core.claimStakingReward(targetCycle, staker, token),
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts[2];

        // assert
        let output:any = receipt.result.expectOk().expectTuple();
        output['entitled-token'].expectUint(0);
        output['to-return'].expectUint(0);
      });

      it("succeeds and cause ft_transfer events", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;        
        const targetCycle = 1;
        const amountTokens = 200 * ONE_8;
        const setupBlock = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(amountTokens, staker, deployer),
        ]);
        chain.mineEmptyBlockUntil(
          setupBlock.height + CoreClient.ACTIVATION_DELAY + 1
        );
        let res = chain.mineBlock([clients.core.stakeTokens(amountTokens, 1, staker, token)]);
        chain.mineEmptyBlock(CoreClient.REWARD_CYCLE_LENGTH * 2);

        // act
        const receipts = chain.mineBlock([
          clients.core.setCoinbaseAmount(deployer, token, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
          clients.core.claimStakingReward(targetCycle, staker, token),
        ]).receipts;

        // assert
        let result:any = receipts[1].result.expectOk().expectTuple();
        result['entitled-token'].expectUint(ONE_8);
        result['to-return'].expectUint(amountTokens);

        assertEquals(receipts[1].events.length, (APOWER_MULTIPLIER > 0) ? 3 : 2);

        receipts[1].events.expectFungibleTokenTransferEvent(
          amountTokens,
          clients.core.getVaultAddress(),
          staker.address,
          "alex"
        );
        
        clients.apower.getBalance(staker).result.expectOk().expectUint(ONE_8 * APOWER_MULTIPLIER);

      });

      it("succeeds and release tokens only for last cycle in locked period", (chain, accounts, clients) => {
        // arrange
        const staker = accounts.get("wallet_2")!;
        const deployer = accounts.get("deployer")!;        
        const userId = 1;
        class StakingRecord {
          constructor(
            readonly stackInCycle: number,
            readonly lockPeriod: number,
            readonly amountTokens: number
          ) {}
        }

        const StakingRecords: StakingRecord[] = [
          new StakingRecord(1, 4, 20 * ONE_8),
          new StakingRecord(3, 8, 432 * ONE_8),
          new StakingRecord(7, 3, 10 * ONE_8),
          new StakingRecord(8, 2, 15 * ONE_8),
          new StakingRecord(9, 5, 123 * ONE_8),
        ];

        const totalAmountTokens = StakingRecords.reduce(
          (sum, record) => sum + record.amountTokens,
          0
        );
        const maxCycle = Math.max.apply(
          Math,
          StakingRecords.map((record) => {
            return record.stackInCycle + 1 + record.lockPeriod;
          })
        );

        const block = chain.mineBlock([
          clients.core.setActivationThreshold(deployer, 1),
          clients.core.addToken(deployer, token),
          clients.core.setApowerMultiplierInFixed(deployer, token, APOWER_MULTIPLIER * ONE_8),
          clients.core.registerUser(staker, token),
          clients.token.mint(totalAmountTokens, staker, deployer),
        ]);
        const activationBlockHeight =
          block.height + CoreClient.ACTIVATION_DELAY - 1;
        chain.mineEmptyBlockUntil(activationBlockHeight);

        StakingRecords.forEach((record) => {
          // move chain tip to the beginning of specific cycle
          chain.mineEmptyBlockUntil(
            activationBlockHeight +
              record.stackInCycle * CoreClient.REWARD_CYCLE_LENGTH
          );          

          chain.mineBlock([
            clients.core.stakeTokens(
              record.amountTokens,
              record.lockPeriod,
              staker,
              token
            ),
          ]);
        });

        chain.mineEmptyBlockUntil(
          CoreClient.REWARD_CYCLE_LENGTH * (maxCycle + 1)
        );

        chain.mineBlock([
          clients.core.setCoinbaseAmount(deployer, token, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8)]);

        // act + assert
        for (let rewardCycle = 0; rewardCycle < maxCycle; rewardCycle++) {
          let toReturn = 0;
          let coinbaseAmount = parseFloat(clients.core.getCoinbaseAmount(rewardCycle, token).result.substr(1));
          let stakingReward = parseFloat(clients.core.getStakingReward(1, rewardCycle, token).result.substr(1)); 
          let entitledToken = coinbaseAmount * stakingReward / ONE_8;          

          StakingRecords.forEach((record) => {
            let lastCycle = record.stackInCycle + record.lockPeriod;

            if (rewardCycle == lastCycle) {
              toReturn += record.amountTokens;
            }
          });

          let apower = Number(clients.apower.getBalance(staker).result.expectOk().substring(1));

          const receipt = chain.mineBlock([
            clients.core.claimStakingReward(rewardCycle, staker, token),
          ]).receipts[0];
         
          if (toReturn === 0 && entitledToken === 0) {
            let output:any = receipt.result.expectOk().expectTuple();
            output['entitled-token'].expectUint(0);
            output['to-return'].expectUint(0);
            clients.apower.getBalance(staker).result.expectOk().expectUint(0);
          } else if (toReturn === 0) {        
            // only mints entitled tokens
            let result:any = receipt.result.expectOk().expectTuple();
            result['entitled-token'].expectUint(ONE_8);
            result['to-return'].expectUint(0);
            assertEquals(receipt.events.length, (APOWER_MULTIPLIER > 0) ? 2 : 1);
            assertEquals(Number(clients.apower.getBalance(staker).result.expectOk().substring(1)) - apower, ONE_8 * APOWER_MULTIPLIER);
          } else {
            let result:any = receipt.result.expectOk().expectTuple();
            result['entitled-token'].expectUint(ONE_8);
            assertEquals(receipt.events.length, (APOWER_MULTIPLIER > 0) ? 3 : 2);

            receipt.events.expectFungibleTokenTransferEvent(
              toReturn,
              clients.core.getVaultAddress(),
              staker.address,
              "alex"
            );
            assertEquals(Number(clients.apower.getBalance(staker).result.expectOk().substring(1)) - apower, ONE_8 * APOWER_MULTIPLIER);
          }
        }
      });
    });
  });
});