
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.34.0/index.ts';
import { assertEquals, assert } from 'https://deno.land/std@0.166.0/testing/asserts.ts';
import { SSPTestAgent2 } from './models/alex-tests-stable-swap-pool.ts';
import { USDAToken, WBTCToken, WXUSDToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = ".token-wbtc"
const usdaAddress = ".token-wusda"
const wxusdAddress = ".token-wxusd"
const daoAddress = ".executor-dao"

const default_factor = 0.999e8;
const threshold = 500e8;
const balance = 50000e8;
const mintAmount = balance * 5;

const testAmount = 1e8;

function stringToUint(a: any) { return Number(a.replace(/\D/g, "")); }

async function setup(chain: Chain, accounts: Map<string, Account>, _factor?: number) {
  const deployer = accounts.get("deployer")!;
  const wallet_1 = accounts.get("wallet_1")!;
  const SSPTest = new SSPTestAgent2(chain, deployer);
  const usdaToken = new USDAToken(chain, deployer);
  const wbtcToken = new WBTCToken(chain, deployer);
  const wxusdToken = new WXUSDToken(chain, deployer);

  const factor = _factor ? _factor : default_factor;

  // Deployer minting initial tokens
  let result = usdaToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = usdaToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();
  result = wbtcToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = wbtcToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();
  result = wxusdToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = wxusdToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();

  // Deployer creating a pool, initial tokens injected to the pool
  result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, deployer.address + daoAddress, balance, balance);
  result.expectOk().expectBool(true);
  result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, deployer.address + daoAddress, balance, balance);
  result.expectOk().expectBool(true);

  result = SSPTest.setMaxInRatio(deployer, 0.3e8);
  result.expectOk().expectBool(true);
  result = SSPTest.setMaxOutRatio(deployer, 0.3e8);
  result.expectOk().expectBool(true);
  result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 0);
  result.expectOk().expectBool(true);
  result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, 0);
  result.expectOk().expectBool(true);

  let block = chain.mineBlock([
    Tx.contractCall("alex-vault", "add-approved-contract", [
      types.principal(deployer.address + '.config-swap-pool')
    ], deployer.address),
    Tx.contractCall("alex-reserve-pool", "add-approved-contract", [
      types.principal(deployer.address + '.config-swap-pool')
    ], deployer.address),
    Tx.contractCall("config-swap-pool", "set-threshold-x", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(threshold)
    ], deployer.address),
    Tx.contractCall("config-swap-pool", "set-threshold-y", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(threshold)
    ], deployer.address),
    Tx.contractCall("config-swap-pool", "set-threshold-x", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + wbtcAddress),
      types.uint(factor),
      types.uint(threshold)
    ], deployer.address),
    Tx.contractCall("config-swap-pool", "set-threshold-y", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + wbtcAddress),
      types.uint(factor),
      types.uint(threshold)
    ], deployer.address),
  ]);
  block.receipts.forEach(e => { e.result.expectOk() });

  return {
    deployer,
    wallet_1,
    SSPTest,
    usdaToken,
    wbtcToken,
    wxusdToken,
    factor
  }
}

async function swapTest(chain: Chain, accounts: Map<string, Account>, _factor?: number) {

  const {
    deployer,
    wallet_1,
    SSPTest,
    usdaToken,
    wbtcToken,
    wxusdToken,
    factor
  } = await setup(chain, accounts, _factor);

  // attempt to trade too much (> 90%) will be rejected
  let result = SSPTest.swapHelperA(deployer, deployer.address + wbtcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, balance * 0.9, 0);
  let position = result.expectErr().expectUint(4001);

  let call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  let usdaPrice = stringToUint(call.result.expectOk());
  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + wbtcAddress),
      types.uint(factor)
    ], wallet_1.address);
  let wbtcPrice = stringToUint(call.result.expectOk());

  // swap some wbtc into usda
  result = SSPTest.swapHelperA(deployer, deployer.address + wbtcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, testAmount, 0);  
  assert(stringToUint(result.expectOk()) <= testAmount * wbtcPrice / usdaPrice);

  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());
  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + wbtcAddress),
      types.uint(factor)
    ], wallet_1.address);
  wbtcPrice = stringToUint(call.result.expectOk());

  // swap some usda into wbtc
  result = SSPTest.swapHelperA(deployer, deployer.address + usdaAddress, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, factor, testAmount, 0);
  assert(stringToUint(result.expectOk()) <= testAmount * usdaPrice / wbtcPrice);

  // attempt to swap zero throws an error
  result = SSPTest.swapHelperA(deployer, deployer.address + wbtcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, 0, 0);
  result.expectErr().expectUint(2003);
  result = SSPTest.swapHelperA(deployer, deployer.address + wbtcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, 0, 0);
  result.expectErr().expectUint(2003);

  // let's do some arb
  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());  
  const PT = Math.floor(usdaPrice * (1 + 0.1 * factor / 1e8));
  call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, PT);
  result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, stringToUint(call.result.expectOk()), 0)
  position = result.expectOk().expectTuple();

  // now pool price implies PT
  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());  
  assertEquals(usdaPrice, PT);

  // let's do some arb
  const newPT = Math.floor(PT * (1 - 0.1 * factor / 1e8));
  // but calling get-y-given-price throws an error
  call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
  call.result.expectErr().expectUint(2002);
  // we need to call get-x-given-price
  call = await SSPTest.getXgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
  result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, stringToUint(call.result.expectOk()), 0)
  position = result.expectOk().expectTuple();

  call = chain.callReadOnlyFn("config-swap-pool", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());  
  assertEquals(usdaPrice, newPT);
}

Clarinet.test({
  name: "config-swap-pool : pool creation, adding values and reducing values",

  async fn(chain: Chain, accounts: Map<string, Account>) {

    const {
      deployer,
      wallet_1,
      SSPTest,
      usdaToken,
      wbtcToken,
      wxusdToken,
      factor
    } = await setup(chain, accounts);

    let call: any = chain.callReadOnlyFn("config-swap-pool", "get-token-given-position",
      [
        types.principal(deployer.address + wxusdAddress),
        types.principal(deployer.address + wbtcAddress),
        types.uint(factor),
        types.uint(balance),
        types.none()
      ], wallet_1.address);
    const initial_supply = call.result.expectOk().expectTuple().token.replace(/\D/g, "");

    // Check pool details and print
    call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor);
    let position: any = call.result.expectOk().expectTuple();

    position['total-supply'].expectUint(initial_supply);
    position['balance-x'].expectUint(balance);
    position['balance-y'].expectUint(balance);
    // Add extra liquidity (1/4 of initial liquidity)
    let result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, balance / 4, balance / 4);
    position = result.expectOk().expectTuple();
    position['supply'].expectUint(Math.floor(initial_supply / 4));
    position['dy'].expectUint(balance / 4);
    position['dx'].expectUint(balance / 4);

    // Check pool details and print
    call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor);
    position = call.result.expectOk().expectTuple();
    position['total-supply'].expectUint(Math.floor(5 / 4 * initial_supply));
    position['balance-y'].expectUint(5 / 4 * balance);
    position['balance-x'].expectUint(5 / 4 * balance);

    // Reduce all liquidlity
    result = SSPTest.reducePosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, 1e8);
    position = result.expectOk().expectTuple();
    position['dy'].expectUint(5 / 4 * balance);
    position['dx'].expectUint(5 / 4 * balance);

    // Add back some liquidity
    result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + wbtcAddress, factor, balance, balance);
    position = result.expectOk().expectTuple();
    position['supply'].expectUint(initial_supply);
    position['dy'].expectUint(balance);
    position['dx'].expectUint(balance);

  },
});

Clarinet.test({
  name: "config-swap-pool : check start-block and end-block",

  async fn(chain: Chain, accounts: Map<string, Account>) {
    const {
      deployer,
      wallet_1,
      SSPTest,
      usdaToken,
      wbtcToken,
      wxusdToken,
      factor
    } = await setup(chain, accounts);

    const startBlock = 100;
    let result = SSPTest.setStartBlock(wallet_1, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, startBlock);
    result.expectErr().expectUint(1000);
    result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, startBlock);
    result.expectOk().expectBool(true);

    result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectErr().expectUint(1000);
    result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectErr().expectUint(1000);

    chain.mineEmptyBlockUntil(startBlock);

    result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectOk().expectTuple();
    result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectOk().expectTuple();

    const endBlock = 200;
    result = SSPTest.setEndBlock(wallet_1, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, endBlock);
    result.expectErr().expectUint(1000);
    result = SSPTest.setEndBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, endBlock);
    result.expectOk().expectBool(true);

    chain.mineEmptyBlockUntil(endBlock + 1);

    result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectErr().expectUint(1000);
    result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 1e8, 0);
    result.expectErr().expectUint(1000);

  },
});       


Clarinet.test({
  name: "config-swap-pool : testing get-x-given-price and get-y-given-price",

  async fn(chain: Chain, accounts: Map<string, Account>) {
    await swapTest(chain, accounts, 0.0001e8);
  },
});