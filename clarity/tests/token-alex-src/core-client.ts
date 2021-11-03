import { Account, ReadOnlyFn, Tx, types } from "./deps.ts";
import { Client } from "./client.ts";

enum ErrCode {
  ERR_FT_INSUFFICIENT_BALANCE = 1,
  ERR_UNAUTHORIZED = 1000,
  ERR_USER_ALREADY_REGISTERED = 10001,
  ERR_USER_NOT_FOUND = 10002,
  ERR_USER_ID_NOT_FOUND = 10003,
  ERR_ACTIVATION_THRESHOLD_REACHED = 10004,
  ERR_CONTRACT_NOT_ACTIVATED = 10005,
  ERR_USER_ALREADY_MINED = 10006,
  ERR_INSUFFICIENT_COMMITMENT = 10007,
  ERR_INSUFFICIENT_BALANCE = 10008,
  ERR_USER_DID_NOT_MINE_IN_BLOCK = 10009,
  ERR_CLAIMED_BEFORE_MATURITY = 10010,
  ERR_NO_MINERS_AT_BLOCK = 10011,
  ERR_REWARD_ALREADY_CLAIMED = 10012,
  ERR_MINER_DID_NOT_WIN = 10013,
  ERR_NO_VRF_SEED_FOUND = 10014,
  ERR_STACKING_NOT_AVAILABLE = 10015,
  ERR_CANNOT_STACK = 10016,
  ERR_REWARD_CYCLE_NOT_COMPLETED = 10017,
  ERR_NOTHING_TO_REDEEM = 10018,
}

export class CoreClient extends Client {
  static readonly ErrCode = ErrCode;
  static readonly ACTIVATION_DELAY = 150;
  static readonly ACTIVATION_THRESHOLD = 20;
  static readonly TOKEN_HALVING_BLOCKS = 210000;
  static readonly REWARD_CYCLE_LENGTH = 2100;
  static readonly SPLIT_CITY_PCT = 0.3;
  static readonly TOKEN_REWARD_MATURITY = 100;
  static readonly BONUS_PERIOD_LENGTH = 10000;

  //////////////////////////////////////////////////
  // CITY WALLET MANAGEMENT
  //////////////////////////////////////////////////

  setCityWallet(newCityWallet: Account, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-city-wallet",
      [types.principal(newCityWallet.address)],
      sender.address
    );
  }

  getCityWallet(): ReadOnlyFn {
    return this.callReadOnlyFn("get-city-wallet");
  }

  //////////////////////////////////////////////////
  // REGISTRATION
  //////////////////////////////////////////////////

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

  registerUser(sender: Account, memo: string | undefined = undefined): Tx {
    return Tx.contractCall(
      this.contractName,
      "register-user",
      [
        typeof memo == "undefined"
          ? types.none()
          : types.some(types.utf8(memo)),
      ],
      sender.address
    );
  }

  getRegisteredUsersNonce(): ReadOnlyFn {
    return this.callReadOnlyFn("get-registered-users-nonce");
  }

  getUserId(user: Account): ReadOnlyFn {
    return this.callReadOnlyFn("get-user-id", [types.principal(user.address)]);
  }

  getUser(userId: number): ReadOnlyFn {
    return this.callReadOnlyFn("get-user", [types.uint(userId)]);
  }

  //////////////////////////////////////////////////
  // MINING CONFIGURATION
  //////////////////////////////////////////////////

  getBlockWinnerId(stacksHeight: number): ReadOnlyFn {
    return this.callReadOnlyFn("get-block-winner-id", [
      types.uint(stacksHeight),
    ]);
  }

  //////////////////////////////////////////////////
  // MINING ACTIONS
  //////////////////////////////////////////////////

  mineTokens(
    amountUstx: number,
    miner: Account,
    memo: ArrayBuffer | undefined = undefined
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "mine-tokens",
      [
        types.uint(amountUstx),
        typeof memo == "undefined"
          ? types.none()
          : types.some(types.buff(memo)),
      ],
      miner.address
    );
  }

  mineMany(amounts: number[], miner: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "mine-many",
      [types.list(amounts.map((amount) => types.uint(amount)))],
      miner.address
    );
  }

  hasMinedAtBlock(stacksHeight: number, userId: number): ReadOnlyFn {
    return this.callReadOnlyFn("has-mined-at-block", [
      types.uint(stacksHeight),
      types.uint(userId),
    ]);
  }

  //////////////////////////////////////////////////
  // MINING REWARD CLAIM ACTIONS
  //////////////////////////////////////////////////

  claimMiningReward(minerBlockHeight: number, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "claim-mining-reward",
      [types.uint(minerBlockHeight)],
      sender.address
    );
  }

  isBlockWinner(user: Account, minerBlockHeight: number): ReadOnlyFn {
    return this.callReadOnlyFn("is-block-winner", [
      types.principal(user.address),
      types.uint(minerBlockHeight),
    ]);
  }

  canClaimMiningReward(user: Account, minerBlockHeight: number): ReadOnlyFn {
    return this.callReadOnlyFn("can-claim-mining-reward", [
      types.principal(user.address),
      types.uint(minerBlockHeight),
    ]);
  }

  //////////////////////////////////////////////////
  // STACKING CONFIGURATION
  //////////////////////////////////////////////////

  getStackerAtCycleOrDefault(rewardCycle: number, userId: number): ReadOnlyFn {
    return this.callReadOnlyFn("get-stacker-at-cycle-or-default", [
      types.uint(rewardCycle),
      types.uint(userId),
    ]);
  }

  //////////////////////////////////////////////////
  // STACKING ACTIONS
  //////////////////////////////////////////////////

  stackTokens(amountTokens: number, lockPeriod: number, stacker: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "stack-tokens",
      [types.uint(amountTokens), types.uint(lockPeriod)],
      stacker.address
    );
  }

  //////////////////////////////////////////////////
  // STACKING REWARD CLAIMS
  //////////////////////////////////////////////////

  claimStackingReward(targetCycle: number, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "claim-stacking-reward",
      [types.uint(targetCycle)],
      sender.address
    );
  }

  //////////////////////////////////////////////////
  // TOKEN CONFIGURATION
  //////////////////////////////////////////////////

  //////////////////////////////////////////////////
  // UTILITIES
  //////////////////////////////////////////////////

  //////////////////////////////////////////////////
  // TESTING ONLY
  //////////////////////////////////////////////////

  unsafeSetCityWallet(newCityWallet: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-unsafe-set-city-wallet",
      [types.principal(newCityWallet.address)],
      this.deployer.address
    );
  }

  unsafeSetActivationThreshold(newThreshold: number): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-set-activation-threshold",
      [types.uint(newThreshold)],
      this.deployer.address
    );
  }

  testInitializeCore(coreContract: string): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-initialize-core",
      [types.principal(coreContract)],
      this.deployer.address
    );
  }

  testMint(amount: number, recipient: Account, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-mint",
      [types.uint(amount), types.principal(recipient.address)],
      sender.address
    );
  }

  testBurn(amount: number, recipient: Account, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-burn",
      [types.uint(amount), types.principal(recipient.address)],
      sender.address
    );
  }
}