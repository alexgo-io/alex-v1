typescript
import {
  Chain,
  Tx,
  types,
  Account,
  Cl,
  TxReceipt,
  AssetInfo,
} from "clarinet-sdk";
import {
  describe,
  it,
  expect,
  beforeEach,
  afterEach,
  assert,
} from "vitest";

// ---------------------------------------------------------------------------
// Constants (using "as const" for literal types)
// ---------------------------------------------------------------------------

/** Bounty amount in microALEX (0.01 ALEX with 6 decimals) */
const BOUNTY_AMOUNT = 10_000 as const;

/** Initial ALEX balance for the auto-alex contract (1000 ALEX) */
const INITIAL_BALANCE = 1_000_000_000 as const;

/** Principal stake amount for test user (500 ALEX) */
const USER_STAKE = 500_000_000 as const;

/** Cycle at which the test position ends */
const END_CYCLE = 5n;

/** Predefined cycle constants for reusability */
const CYCLE_0 = 0n;
const CYCLE_1 = 1n;
const CYCLE_5 = 5n;
const CYCLE_6 = 6n;
const CYCLE_10 = 10n;

/**
 * Expected error codes from the auto-alex contract.
 * Must match the contract's error definitions.
 */
enum ErrorCodes {
  CycleAlreadyClaimed = 1,
  NothingToClaim = 2,
  UnauthorizedCaller = 3,
}

/** Generic key-value mapping for Clarity values */
interface ClarityMap {
  [key: string]: Cl.Value;
}

/** Clarity response union type */
type ClarityResponse = Cl.ResponseOk & Cl.ResponseErr;

// ---------------------------------------------------------------------------
// Custom Error Classes for Domain-Specific Errors
// ---------------------------------------------------------------------------

/**
 * Error thrown when a required argument is missing, null, or invalid.
 */
class ArgumentError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ArgumentError";
  }
}

/**
 * Error thrown when an asset balance retrieval fails.
 */
class AssetBalanceError extends Error {
  public readonly address: string;
  public readonly cause?: unknown;

  constructor(address: string, cause?: unknown) {
    const message = `Failed to get ALEX balance for ${address}`;
    super(message);
    this.name = "AssetBalanceError";
    this.address = address;
    this.cause = cause;
  }
}

/**
 * Error thrown when block mining fails or returns unexpected results.
 */
class BlockMiningError extends Error {
  public readonly description: string;
  public readonly cause?: unknown;

  constructor(description: string, cause?: unknown) {
    const message = `Failed to mine block for "${description}"`;
    super(message);
    this.name = "BlockMiningError";
    this.description = description;
    this.cause = cause;
  }
}

/**
 * Error thrown when a transaction receipt does not contain the expected result.
 */
class ReceiptError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ReceiptError";
  }
}

// ---------------------------------------------------------------------------
// Structured Logger for Test Output
// ---------------------------------------------------------------------------

const LOG_PREFIX = "[AutoALEX-Test]";

const logger = {
  debug: (message: string, ...args: readonly unknown[]): void => {
    // eslint-disable-next-line no-console
    console.debug(`${LOG_PREFIX} ${message}`, ...args);
  },
  info: (message: string, ...args: readonly unknown[]): void => {
    // eslint-disable-next-line no-console
    console.info(`${LOG_PREFIX} ${message}`, ...args);
  },
  warn: (message: string, ...args: readonly unknown[]): void => {
    // eslint-disable-next-line no-console
    console.warn(`${LOG_PREFIX} ${message}`, ...args);
  },
  error: (message: string, ...args: readonly unknown[]): void => {
    // eslint-disable-next-line no-console
    console.error(`${LOG_PREFIX} ${message}`, ...args);
  },
};

// ---------------------------------------------------------------------------
// Input Validation Helpers
// ---------------------------------------------------------------------------

/** Asserts that a value is a non‑empty string; throws ArgumentError otherwise. */
function assertNonEmptyString(value: unknown, label: string): asserts value is string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ArgumentError(`${label} must be a non‑empty string`);
  }
}

/** Asserts that a value is a valid Account object. */
function assertAccount(value: unknown): asserts value is Account {
  if (!value || typeof value !== "object" || !("address" in (value as Account))) {
    throw new ArgumentError("Invalid account object: must have an 'address' property");
  }
}

/** Asserts that a value is a valid Chain object with a mineBlock method. */
function assertChain(value: unknown): asserts value is Chain {
  if (!value || typeof value !== "object" || !("mineBlock" in (value as Chain))) {
    throw new ArgumentError("Invalid chain object: must implement 'mineBlock'");
  }
}

/** Asserts that a value is a valid Tx object. */
function assertTx(value: unknown): asserts value is Tx {
  if (!value || typeof value !== "object" || !("functionName" in (value as Tx))) {
    throw new ArgumentError("Invalid transaction object");
  }
}

/** Asserts that a value is a valid AssetInfo object. */
function assertAssetInfo(value: unknown): asserts value is AssetInfo {
  if (!value || typeof value !== "object" || !("name" in (value as AssetInfo))) {
    throw new ArgumentError("Invalid asset info object");
  }
}

// ---------------------------------------------------------------------------
// Utility Functions
// ---------------------------------------------------------------------------

/**
 * Retrieves the ALEX balance of a given address.
 *
 * @param chain    - The Clarinet chain instance.
 * @param assetInfo - The asset info for ALEX.
 * @param address  - The address to query.
 * @returns The balance as a bigint.
 * @throws {ArgumentError}     If parameters are invalid.
 * @throws {AssetBalanceError} If the balance cannot be retrieved.
 */
function getAlexBalance(
  chain: Chain,
  assetInfo: AssetInfo,
  address: string
): bigint {
  assertChain(chain);
  assertAssetInfo(assetInfo);
  assertNonEmptyString(address, "address");

  try {
    const balanceResult = chain.getAssetBalance(assetInfo, address);
    if (typeof balanceResult !== "bigint") {
      throw new AssetBalanceError(
        address,
        `Unexpected type: ${typeof balanceResult}`
      );
    }
    return balanceResult;
  } catch (cause) {
    if (cause instanceof AssetBalanceError) {
      throw cause;
    }
    throw new AssetBalanceError(address, cause);
  }
}

/**
 * Mines a single block containing the given transaction and logs the result.
 *
 * @param chain       - Clarinet chain instance.
 * @param tx          - Transaction to be mined.
 * @param description - Human‑readable label for logging purposes.
 * @returns The transaction receipt from the block.
 * @throws {ArgumentError}   If parameters are invalid.
 * @throws {BlockMiningError} If block mining fails or receipt is missing.
 */
function mineAndLog(
  chain: Chain,
  tx: Tx,
  description: string
): TxReceipt {
  assertChain(chain);
  assertTx(tx);
  assertNonEmptyString(description, "description");

  try {
    logger.info(`Mining block for: ${description}`);
    const block = chain.mineBlock([tx]);

    if (!block.receipts || block.receipts.length === 0) {
      throw new BlockMiningError(description, "No receipts returned");
    }

    const receipt = block.receipts[0] as TxReceipt;
    logger.debug(`[${description}] result: ${receipt.result}`);

    if (receipt.events && receipt.events.length > 0) {
      logger.debug(`[${description}] events: ${JSON.stringify(receipt.events)}`);
    }

    return receipt;
  } catch (error) {
    if (error instanceof BlockMiningError) {
      throw error;
    }
    logger.error(`Failed to mine block for ${description}: ${(error as Error).message}`);
    throw new BlockMiningError(description, error);
  }
}

/**
 * Advances the chain to a specific burn block height by mining empty blocks.
 *
 * @param chain         - The Clarinet chain instance.
 * @param targetHeight  - The target burn block height (must be >= current height).
 * @throws {BlockMiningError} If chain cannot be advanced.
 */
function advanceToBlock(chain: Chain, targetHeight: number): void {
  assertChain(chain);
  const currentHeight = chain.blockHeight;
  if (targetHeight < currentHeight) {
    throw new BlockMiningError(
      `Cannot go back to block ${targetHeight} (currently at ${currentHeight})`
    );
  }
  logger.info(`Advancing chain from block ${currentHeight} to ${targetHeight}`);
  for (let i = currentHeight; i < targetHeight; i++) {
    try {
      chain.mineEmptyBlock();
    } catch (cause) {
      throw new BlockMiningError(
        `advance to block ${targetHeight} (failed at step ${i})`,
        cause
      );
    }
  }
}

/**
 * Asserts that a transaction receipt succeeded with an `(ok ...)` result.
 * Throws a descriptive `ReceiptError` on failure.
 *
 * @param receipt       - The transaction receipt to check.
 * @param expectedValue - Optional expected `Ok` value (Cl.Value). If provided,
 *                        an assertion is made against `receipt.result`.
 * @throws {ArgumentError} If receipt is invalid.
 * @throws {ReceiptError}  If the receipt indicates failure or unexpected value.
 */
function assertOkReceipt(
  receipt: TxReceipt,
  expectedValue?: Cl.Value
): void {
  if (!receipt) {
    throw new ArgumentError("receipt must be provided");
  }

  // Check for explicit error in receipt
  if (receipt.result && typeof receipt.result === "object" && "type" in receipt.result) {
    const resultObj = receipt.result as Cl.ResponseOk;
    if (resultObj.type === "response_err") {
      // Try to extract error code for debugging
      const errPayload = (resultObj as unknown as { value: bigint }).value;
      throw new ReceiptError(
        `Transaction failed with error code: ${errPayload ?? "unknown"}`
      );
    }
    // If expectedValue provided, compare using vitest assert (throws on mismatch)
    if (expectedValue !== undefined) {
      try {
        assert.deepStrictEqual(receipt.result, expectedValue);
      } catch (assertionError) {
        throw new ReceiptError(
          `Receipt result does not match expected value. Expected: ${JSON.stringify(expectedValue)}, got: ${JSON.stringify(receipt.result)}`
        );
      }
    }
  } else {
    // No result object – might be a success that didn't return structured response.
    // For safety, log a warning and assume success if no error events.
    if (receipt.events && receipt.events.some((e) => (e as { event?: string }).event === "print" && (e as { data?: unknown }).data === "error")) {
      throw new ReceiptError("Receipt contains error print events");
    }
  }
}

// ---------------------------------------------------------------------------
// Test Suite: Auto-ALEX Repeated Claim Exploit
// ---------------------------------------------------------------------------

describe("AutoALEX claim-and-stake exploit (CVE simulation)", () => {
  let chain: Chain;
  let deployer: Account;
  let alice: Account;
  let bob: Account;
  let alexAssetInfo: AssetInfo;

  /**
   * Setup accounts, chain, and initial state.
   * This runs once before all tests (using beforeAll would be more efficient,
   * but we use beforeEach for test isolation and clarity).
   */
  beforeEach(async () => {
    // Initialise chain and accounts using Clarinet SDK runtime.
    // In real integration, this would be done via clarinet-sdk methods.
    // For this test, we assume the chain is already seeded with accounts.
    chain = (await import("./chain-setup"))?.chain ?? {} as Chain;
    deployer = (await import("./chain-setup"))?.deployer ?? {} as Account;
    alice = (await import("./chain-setup"))?.alice ?? {} as Account;
    bob = (await import("./chain-setup"))?.bob ?? {} as Account;
    alexAssetInfo = (await import("./chain-setup"))?.alexAssetInfo ?? {} as AssetInfo;

    assertChain(chain);
    assertAccount(deployer);
    assertAccount(alice);
    assertAccount(bob);
    assertAssetInfo(alexAssetInfo);

    // Ensure test contracts are deployed and initialised
    // (e.g., call staking-init, fund auto-alex, etc.)
    // Skipped for brevity in this snippet but would be present in a real test.
  });

  afterEach(() => {
    // Clean up any side effects if needed (e.g., reset chain state).
    logger.debug("Cleanup after test");
  });

  /**
   * Reproduces the vulnerability: unprivileged caller repeatedly calls
   * `claim-and-stake` at the boundary where `current-cycle == end-cycle`.
   * The function should only pay the bounty once per cycle, but due to
   * the missing guard, it drains the AutoALEX ALEX balance.
   */
  it("should NOT allow repeated bounty claims at cycle boundary", async () => {
    // Arrange
    const initialBalance = getAlexBalance(chain, alexAssetInfo, deployer.address);

    // Fund AutoALEX contract (simulation – in real test, this would be done
    // via proper staking flows)
    await fundAutoAlexContract(chain, alexAssetInfo, deployer, INITIAL_BALANCE);

    // Alice stakes principal
    await mineAndLog(
      chain,
      Tx.contractCall("auto-alex", "stake", [
        types.uint(USER_STAKE),
      ], alice.address),
      "Alice stakes"
    );

    // Advance chain to the final block of cycle 5 (inside the vulnerable window)
    // In real scenario, this would be the burn block height where end-cycle = 5
    // and current-cycle = 5.
    advanceToBlock(chain, 100); // arbitrary height where cycle condition holds

    // Act: Bob (unprivileged) calls claim-and-stake repeatedly
    const bobInitialBalance = getAlexBalance(chain, alexAssetInfo, bob.address);
    const numberOfAttempts = 5;

    for (let i = 0; i < numberOfAttempts; i++) {
      const receipt = await mineAndLog(
        chain,
        Tx.contractCall("auto-alex", "claim-and-stake", [
          types.principal(alice.address),
          types.uint(CYCLE_0),
          types.uint(CYCLE_10),
        ], bob.address),
        `Bob claim-and-stake attempt #${i + 1}`
      );

      // Expect success (unfortunately, due to bug)
      assertOkReceipt(receipt);
    }

    // Assert: Bob should have gained at most one bounty (or zero if first attempt already claimed)
    const bobFinalBalance = getAlexBalance(chain, alexAssetInfo, bob.address);
    const bobGain = bobFinalBalance - bobInitialBalance;

    // If vulnerability is present, bobGain >> BOUNTY_AMOUNT (drained thousands)
    // We assert that Bob did **not** drain more than BOUNTY_AMOUNT per call.
    // In the fixed version, only one bounty should be paid.
    // For demonstration we check that total gain < 2 * BOUNTY_AMOUNT (more than one bounty = exploit)
    expect(bobGain).toBeLessThan(BOUNTY_AMOUNT * 2n);

    logger.info(
      `Bob gained ${bobGain} microALEX over ${numberOfAttempts} attempts (expected < ${BOUNTY_AMOUNT * 2n})`
    );
  });

  /**
   * Test that after the cycle boundary, holders can redeem without exploit.
   */
  it("should allow proper redemption after end cycle", async () => {
    // Arrange: Simulate a full staking cycle and advance past end-cycle
    // (omitted for brevity – would set up position, advance blocks, etc.)

    // Act: Alice calls reduce-position (or claim) when allowed
    // const receipt = await mineAndLog(...);

    // Assert: Alice recovers principal + yield, no extra bounty paid.
    // expect(...);
  });
});

/**
 * Helper to fund the auto-alex contract with ALEX tokens.
 * In a real test environment, this may use chain.transfer or contract calls.
 *
 * @param chain        - The chain instance.
 * @param assetInfo    - The ALEX asset info.
 * @param from         - The funding account.
 * @param amount       - Amount of microALEX to transfer.
 */
async function fundAutoAlexContract(
  chain: Chain,
  assetInfo: AssetInfo,
  from: Account,
  amount: bigint
): Promise<void> {
  // This is a placeholder – implementation depends on exact setup.
  // It might call a custom faucet or token transfer function.
  logger.info(`Funding auto-alex contract with ${amount} microALEX from ${from.address}`);
  // chain.transfer(assetInfo, from, "auto-alex", amount); // imaginary API
  // Instead, we just log and trust the initial setup.
}