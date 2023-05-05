
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.34.0/index.ts';
import { assertEquals, assert, assertAlmostEquals } from 'https://deno.land/std@0.166.0/testing/asserts.ts';
import { SSPTestAgent3 } from './models/alex-tests-amm-swap-pool.ts';
import { USDAToken, WBTCToken, WXUSDToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const usdcAddress = ".token-wbtc"
const usdaAddress = ".token-wusda"
const wxusdAddress = ".token-wxusd"
const daoAddress = ".executor-dao"

const defaultFactor = 0.0001e8;
const balanceX = 70000e8;
const balanceY = 30000e8;
const thresholdX = balanceX * 0.05;
const thresholdY = balanceY * 0.05;
const mintAmount = Math.max(balanceX, balanceY) * 5;
const maxRatio = 0.9e8;

const testAmount = 1e8;

function stringToUint(a: any) { return Number(a.replace(/\D/g, "")); }

async function setup(chain: Chain, accounts: Map<string, Account>, _factor?: number) {
  const deployer = accounts.get("deployer")!;
  const wallet_1 = accounts.get("wallet_1")!;
  const SSPTest = new SSPTestAgent3(chain, deployer);
  const usdaToken = new USDAToken(chain, deployer);
  const usdcToken = new WBTCToken(chain, deployer);
  const wxusdToken = new WXUSDToken(chain, deployer);

  const factor = _factor ? _factor : defaultFactor;

  // Deployer minting initial tokens
  let result = usdaToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = usdaToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();
  result = usdcToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = usdcToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();
  result = wxusdToken.mintFixed(deployer, deployer.address, mintAmount);
  result.expectOk();
  result = wxusdToken.mintFixed(deployer, wallet_1.address, mintAmount);
  result.expectOk();

  let block = chain.mineBlock([
    Tx.contractCall("alex-vault-v1-1", "set-approved-token", [
      types.principal(deployer.address + wxusdAddress),
      types.bool(true)
    ], deployer.address),
    Tx.contractCall("alex-vault-v1-1", "set-approved-token", [
      types.principal(deployer.address + usdaAddress),
      types.bool(true)
    ], deployer.address),
    Tx.contractCall("alex-vault-v1-1", "set-approved-token", [
      types.principal(deployer.address + usdcAddress),
      types.bool(true)
    ], deployer.address),    
  ]);
  block.receipts.forEach(e => { e.result.expectOk() });  

  // Deployer creating a pool, initial tokens injected to the pool
  result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, deployer.address + daoAddress, balanceX, balanceY);
  result.expectOk().expectBool(true);
  result = SSPTest.createPool(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, deployer.address + daoAddress, balanceX, balanceY);
  result.expectOk().expectBool(true);

  result = SSPTest.setMaxInRatio(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, maxRatio);
  result.expectOk().expectBool(true);
  result = SSPTest.setMaxOutRatio(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, maxRatio);
  result.expectOk().expectBool(true);
  result = SSPTest.setMaxInRatio(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, maxRatio);
  result.expectOk().expectBool(true);
  result = SSPTest.setMaxOutRatio(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, maxRatio);
  result.expectOk().expectBool(true);  
  result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, 0);
  result.expectOk().expectBool(true);
  result = SSPTest.setStartBlock(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, 0);
  result.expectOk().expectBool(true);

  block = chain.mineBlock([
    Tx.contractCall("alex-vault-v1-1", "set-approved-contract", [
      types.principal(deployer.address + '.amm-swap-pool-v1-1'),
      types.bool(true)
    ], deployer.address),
    Tx.contractCall("amm-swap-pool-v1-1", "set-threshold-x", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(thresholdX)
    ], deployer.address),
    Tx.contractCall("amm-swap-pool-v1-1", "set-threshold-y", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(thresholdY)
    ], deployer.address),
    Tx.contractCall("amm-swap-pool-v1-1", "set-threshold-x", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdcAddress),
      types.uint(factor),
      types.uint(thresholdX)
    ], deployer.address),
    Tx.contractCall("amm-swap-pool-v1-1", "set-threshold-y", [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdcAddress),
      types.uint(factor),
      types.uint(thresholdY)
    ], deployer.address),
  ]);
  block.receipts.forEach(e => { e.result.expectOk() });

  return {
    deployer,
    wallet_1,
    SSPTest,
    usdaToken,
    usdcToken,
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
    usdcToken,
    wxusdToken,
    factor
  } = await setup(chain, accounts, _factor);

  // attempt to trade too much (> 90%) will be rejected
  let result = SSPTest.swapHelperA(deployer, deployer.address + usdcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, balanceX * maxRatio / 1e8, 0);
  result.expectErr().expectUint(4001);


  // single swap
  let call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-y-given-x",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(testAmount)
    ], wallet_1.address);
  let usdaAmount = stringToUint(call.result.expectOk());  

  result = SSPTest.swapHelper(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, testAmount, 0);
  console.log('swap xusd => usda');
  console.log('swap =>', 'expected:', usdaAmount, 'actual:', stringToUint(result.expectOk()))
  assert(stringToUint(result.expectOk()) <= usdaAmount, "result is greater than expected");

  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-x-given-y",
  [
    types.principal(deployer.address + wxusdAddress),
    types.principal(deployer.address + usdaAddress),
    types.uint(factor),
    types.uint(testAmount)
  ], wallet_1.address);
  let xusdAmount = stringToUint(call.result.expectOk());    

  result = SSPTest.swapHelper(deployer, deployer.address + usdaAddress, deployer.address + wxusdAddress, factor, testAmount, 0);
  console.log('swap usda => xusd');
  console.log('swap =>', 'expected:', xusdAmount, 'actual:', stringToUint(result.expectOk()))
  assert(stringToUint(result.expectOk()) <= xusdAmount, "result is greater than expected");  

  // multi hop
  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-x-given-y",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdcAddress),
      types.uint(factor),
      types.uint(testAmount)
    ], wallet_1.address);
  xusdAmount = stringToUint(call.result.expectOk());  
  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-y-given-x",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(xusdAmount)
    ], wallet_1.address);
  usdaAmount = stringToUint(call.result.expectOk());  

  // swap some usdc into usda
  result = SSPTest.swapHelperA(deployer, deployer.address + usdcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, testAmount, 0);  
  console.log('swap =>', 'usdc:', testAmount / xusdAmount, 'usda:', usdaAmount / xusdAmount);
  console.log('swap =>', 'expected:', usdaAmount, 'actual:', stringToUint(result.expectOk()))
  assert(stringToUint(result.expectOk()) <= usdaAmount, "result is greater than expected");

  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-x-given-y",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
      types.uint(testAmount)
    ], wallet_1.address);
  xusdAmount = stringToUint(call.result.expectOk());
  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-y-given-x",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdcAddress),
      types.uint(factor),
      types.uint(xusdAmount)
    ], wallet_1.address);
  let usdcAmount = stringToUint(call.result.expectOk());

  // swap some usda into usdc
  result = SSPTest.swapHelperA(deployer, deployer.address + usdaAddress, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, factor, testAmount, 0);
  console.log('swap =>', 'usdc:', usdcAmount / xusdAmount, 'usda:', testAmount / xusdAmount);
  console.log('swap =>', 'expected:', usdcAmount, 'actual:', stringToUint(result.expectOk()))
  assert(stringToUint(result.expectOk()) <= usdcAmount, "result is greater than expected");

  // attempt to swap zero throws an error
  result = SSPTest.swapHelperA(deployer, deployer.address + usdcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, 0, 0);
  result.expectErr().expectUint(2003);
  result = SSPTest.swapHelperA(deployer, deployer.address + usdcAddress, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, factor, 0, 0);
  result.expectErr().expectUint(2003);

  // let's do some arb
  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
    ], wallet_1.address);
  let usdaPrice = stringToUint(call.result.expectOk());  
  const PT = Math.floor(usdaPrice * (1 + 0.1 * factor / 1e8));
  call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, PT);
  result = SSPTest.swapYForX(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, stringToUint(call.result.expectOk()), 0)
  result.expectOk().expectTuple();

  // now pool price implies PT
  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor),
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());  
  console.log('arb =>', 'expected:', PT, 'actual:', usdaPrice)

  // let's do some more arb
  const newPT = Math.floor(usdaPrice * (1 - 0.1 * factor / 1e8));
  // but calling get-y-given-price throws an error
  call = await SSPTest.getYgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
  call.result.expectErr().expectUint(2002);
  // we need to call get-x-given-price
  call = await SSPTest.getXgivenPrice(deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, newPT);
  result = SSPTest.swapXForY(deployer, deployer.address + wxusdAddress, deployer.address + usdaAddress, factor, stringToUint(call.result.expectOk()), 0)
  result.expectOk().expectTuple();

  call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-price",
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdaAddress),
      types.uint(factor)
    ], wallet_1.address);
  usdaPrice = stringToUint(call.result.expectOk());  
  console.log('arb =>', 'expected:', newPT, 'actual:', usdaPrice)
}

Clarinet.test({
  name: "amm-swap-pool-v1-1 : pool creation, adding values and reducing values",
  async fn(chain: Chain, accounts: Map<string, Account>) {

    const {
      deployer,
      wallet_1,
      SSPTest,
      usdaToken,
      usdcToken,
      wxusdToken,
      factor
    } = await setup(chain, accounts);

    let call: any = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-token-given-position",
      [
        types.principal(deployer.address + wxusdAddress),
        types.principal(deployer.address + usdcAddress),
        types.uint(factor),
        types.uint(balanceX),
        types.none()
      ], wallet_1.address);
    const initial_supply = call.result.expectOk().expectTuple().token.replace(/\D/g, "");

    // Check pool details and print
    call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + usdcAddress, factor);
    let position: any = call.result.expectOk().expectTuple();

    position['total-supply'].expectUint(initial_supply);
    position['balance-x'].expectUint(balanceX);
    position['balance-y'].expectUint(balanceY);
    // Add extra liquidity (1/4 of initial liquidity)
    let result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, balanceX / 4, balanceY / 4);
    position = result.expectOk().expectTuple();
    position['supply'].expectUint(Math.floor(initial_supply / 4));
    position['dy'].expectUint(balanceY / 4);
    position['dx'].expectUint(balanceX / 4);

    // Check pool details and print
    call = await SSPTest.getPoolDetails(deployer.address + wxusdAddress, deployer.address + usdcAddress, factor);
    position = call.result.expectOk().expectTuple();
    position['total-supply'].expectUint(Math.floor(5 / 4 * initial_supply));
    position['balance-y'].expectUint(5 / 4 * balanceY);
    position['balance-x'].expectUint(5 / 4 * balanceX);

    // Reduce all liquidlity
    result = SSPTest.reducePosition(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, 1e8);
    position = result.expectOk().expectTuple();
    position['dy'].expectUint(5 / 4 * balanceY);
    position['dx'].expectUint(5 / 4 * balanceX);

    // Add back some liquidity
    result = SSPTest.addToPosition(deployer, deployer.address + wxusdAddress, deployer.address + usdcAddress, factor, balanceX, balanceY);
    position = result.expectOk().expectTuple();
    position['supply'].expectUint(initial_supply);
    position['dy'].expectUint(balanceY);
    position['dx'].expectUint(balanceX);

  },
});

Clarinet.test({
  name: "amm-swap-pool-v1-1 : check start-block and end-block",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const {
      deployer,
      wallet_1,
      SSPTest,
      usdaToken,
      usdcToken,
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
  name: "amm-swap-pool-v1-1 : factor = 1e8, aka uniswap",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    await swapTest(chain, accounts, 1e8);
  },
});

Clarinet.test({
  name: "amm-swap-pool-v1-1 : factor = 0.0001e8, aka Curve",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    await swapTest(chain, accounts, 0.0001e8);
  },
});

Clarinet.test({
  name: "amm-swap-pool-v1-1 : factor = 0.5e8, aka somewhere in between",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    await swapTest(chain, accounts, 0.5e8);
  },
});

Clarinet.test({
  name: "sanity check",
  async fn(chain: Chain, accounts: Map<string, Account>) {

    const {
      deployer,
      wallet_1,
      SSPTest,
      usdaToken,
      usdcToken,
      wxusdToken,
      factor
    } = await setup(chain, accounts);    

    const pool_setting = 
    [
      types.principal(deployer.address + wxusdAddress),
      types.principal(deployer.address + usdcAddress),
      types.uint(factor)
    ];

    let call: any = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-price",
    [
      ...pool_setting
    ], wallet_1.address);    
    let value: any = call.result.expectOk().replace(/\D/g, "");
    console.log(value);

    call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-y-given-x",
    [
      ...pool_setting,
      types.uint(1e8)
    ], wallet_1.address);    
    value = call.result.expectOk().replace(/\D/g, "");
    console.log(value);

    call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-x-given-y",
    [
      ...pool_setting,
      types.uint(value)
    ], wallet_1.address);    
    value = call.result.expectOk().replace(/\D/g, "");
    console.log(value); 

    call = chain.callReadOnlyFn("amm-swap-pool-v1-1", "get-y-in-given-x-out",
    [
      ...pool_setting,
      types.uint(value)
    ], wallet_1.address);    
    value = call.result.expectOk().replace(/\D/g, "");
    console.log(value);     
  }
})