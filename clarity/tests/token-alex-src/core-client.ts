import { Account, ReadOnlyFn, Tx, types } from "./deps.ts";
import { Client } from "./client.ts";

enum ErrCode {
  ERR_TRANSFER_FAILED = 3000,
  ERR_UNAUTHORIZED = 1000,
  ERR_USER_ALREADY_REGISTERED = 10001,
  ERR_USER_NOT_FOUND = 10002,
  ERR_USER_ID_NOT_FOUND = 10003,
  ERR_ACTIVATION_THRESHOLD_REACHED = 10004,
  ERR_CONTRACT_NOT_ACTIVATED = 10005,
  ERR_CLAIMED_BEFORE_MATURITY = 10010,
  ERR_NO_MINERS_AT_BLOCK = 10011,
  ERR_REWARD_ALREADY_CLAIMED = 10012,
  ERR_MINER_DID_NOT_WIN = 10013,
  ERR_NO_VRF_SEED_FOUND = 10014,
  ERR_STAKING_NOT_AVAILABLE = 10015,
  ERR_CANNOT_STAKE = 10016,
  ERR_REWARD_CYCLE_NOT_COMPLETED = 10017,
  ERR_NOTHING_TO_REDEEM = 10018,
}

export class CoreClient extends Client {
  static readonly ErrCode = ErrCode;
  static readonly ACTIVATION_BLOCKS = 10000000;
  static readonly ACTIVATION_DELAY = 150;
  static readonly ACTIVATION_THRESHOLD = 20;
  static readonly TOKEN_HALVING_CYCLE = 100;
  static readonly REWARD_CYCLE_LENGTH = 525;
  static readonly TOKEN_REWARD_MATURITY = 100;
  static readonly BONUS_PERIOD_LENGTH = 10000;

  //////////////////////////////////////////////////
  // REGISTRATION
  //////////////////////////////////////////////////


  getActivationBlockOrHeight(token: string): ReadOnlyFn {
    return this.callReadOnlyFn("get-activation-block-or-default", [types.principal(token)]);
  }

  getActivationBlock(): ReadOnlyFn {
    return this.callReadOnlyFn("get-activation-block");
  }

  getActivationDelay(): ReadOnlyFn {
    return this.callReadOnlyFn("get-activation-delay");
  }

  getActivationStatus(): ReadOnlyFn {
    return this.callReadOnlyFn("get-activation-status");
  }

  getActivationThreshold(): ReadOnlyFn {
    return this.callReadOnlyFn("get-activation-threshold");
  }

  registerUser(sender: Account, token: string, memo: string | undefined = undefined): Tx {
    return Tx.contractCall(
      this.contractName,
      "register-user",
      [
        types.principal(token),
        typeof memo == "undefined"
          ? types.none()
          : types.some(types.utf8(memo)),
      ],
      sender.address
    );
  }

  getRegisteredUsersNonce(token: string): ReadOnlyFn {
    return this.callReadOnlyFn("get-registered-users-nonce", [types.principal(token)]);
  }

  getUserId(token: string, user: Account): ReadOnlyFn {
    return this.callReadOnlyFn("get-user-id", [
      types.principal(token),
      types.principal(user.address)]);
  }

  getUser(userId: number): ReadOnlyFn {
    return this.callReadOnlyFn("get-user", [types.uint(userId)]);
  }

  setActivationThreshold(sender: Account, threshold: number): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-activation-threshold",
      [
        types.uint(threshold)
      ],
      sender.address
    );
  }

  addToken(sender: Account, token: string): Tx {
    return Tx.contractCall(
      this.contractName,
      "add-token",
      [
        types.principal(token)
      ],
      sender.address
    );
  }

  setApowerMultiplierInFixed(sender: Account, token: string, apower: number): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-apower-multiplier-in-fixed",
      [
        types.principal(token),
        types.uint(apower)
      ],
      sender.address
    );
  }  

  addToBalance(sender: Account, amount: number, token: string): Tx {
    return Tx.contractCall(
      this.contractName,
      "add-to-balance",
      [
        types.principal(token),
        types.uint(amount)
      ],
      sender.address
    );
  }

  //////////////////////////////////////////////////
  // STAKING CONFIGURATION
  //////////////////////////////////////////////////

  getStakerAtCycleOrDefault(rewardCycle: number, userId: number, token: string): ReadOnlyFn {
    return this.callReadOnlyFn("get-staker-at-cycle-or-default", [
      types.principal(token),
      types.uint(rewardCycle),
      types.uint(userId),
    ]);
  }

  getStakingReward(rewardCycle: number, userId: number, token: string): ReadOnlyFn {
    return this.callReadOnlyFn("get-staking-reward", [
      types.principal(token),
      types.uint(rewardCycle),
      types.uint(userId),
    ]);
  }  

  //////////////////////////////////////////////////
  // STAKING ACTIONS
  //////////////////////////////////////////////////

  stakeTokens(amountTokens: number, lockPeriod: number, staker: Account, token: string): Tx {
    return Tx.contractCall(
      this.contractName,
      "stake-tokens",
      [types.principal(token), types.uint(amountTokens), types.uint(lockPeriod)],
      staker.address
    );
  }

  //////////////////////////////////////////////////
  // STAKING REWARD CLAIMS
  //////////////////////////////////////////////////

  claimStakingReward(targetCycle: number, sender: Account, token: string): Tx {
    return Tx.contractCall(
      this.contractName,
      "claim-staking-reward",
      [types.principal(token), types.uint(targetCycle)],
      sender.address
    );
  }

  getCoinbaseAmount(rewardCycle: number, token: string): ReadOnlyFn {
    return this.callReadOnlyFn("get-coinbase-amount-or-default", [
      types.principal(token),
      types.uint(rewardCycle)
    ]);
  }  

  setCoinbaseAmount(user: Account, token: string, coinbaseOne: number, coinbaseTwo: number,
    coinbaseThree: number, coinbaseFour: number, coinbaseFive: number): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-coinbase-amount",
      [
        types.principal(token), types.uint(coinbaseOne), types.uint(coinbaseTwo), 
        types.uint(coinbaseThree) ,types.uint(coinbaseFour), types.uint(coinbaseFive)
      ],
      user.address
    );
  }  
}