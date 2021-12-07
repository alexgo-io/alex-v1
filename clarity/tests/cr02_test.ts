import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
  
  import { CRPTestAgent1 } from "./models/alex-tests-collateral-rebalancing-pool.ts";
  import { FWPTestAgent1 } from "./models/alex-tests-fixed-weight-pool.ts";
  import { YTPTestAgent1 } from "./models/alex-tests-yield-token-pool.ts";
  
  // Deployer Address Constants
  const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc";
  const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda";
  const fwpwbtcusdaAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wbtc-usda-50-50";
  const multisigfwpAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wbtc-usda-50-50";
  const yieldwbtc59760Address =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc-59760";
  const keywbtc59760Address =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-59760-usda";
  const ytpyieldwbtc59760Address =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc-59760-wbtc";
  const multisigncrpwbtc59760Address =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-59760-usda";
  const multisigytpyieldwbtc59760 =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc-59760-wbtc";
  
  const ONE_8 = 100000000;
  const expiry = 59760 * ONE_8;
  const ltv_0 = 0.8 * ONE_8;
  const conversion_ltv = 0.95 * ONE_8;
  const bs_vol = 0.8 * ONE_8;
  const moving_average = 0 * ONE_8; // for testing only
  
  const wbtcPrice = 50000 * ONE_8;
  
  const weightX = 0.5 * ONE_8;
  const weightY = 0.5 * ONE_8;
  
  const wbtcQ = 100 * ONE_8;
  
  /**
   * Collateral Rebalancing Pool Test Cases
   */
  
  Clarinet.test({
    name: "CRP : Reduce yield before key tokens (CR-02)",
  
    async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet_1 = accounts.get("wallet_1")!;
      let CRPTest = new CRPTestAgent1(chain, deployer);
      let FWPTest = new FWPTestAgent1(chain, deployer);
      let YTPTest = new YTPTestAgent1(chain, deployer);
  
      // // take away what was minted for testing to another address
      let block = chain.mineBlock([
        Tx.contractCall("yield-wbtc-59760", "transfer", [
          types.uint(2000000000000),
          types.principal(deployer.address),
          types.principal(wallet_1.address),
          types.some(types.buff(new ArrayBuffer(10))),
        ], deployer.address),
      ]);
      block.receipts[0].result.expectOk();
  
      let result = FWPTest.createPool(
        deployer,
        wbtcAddress,
        usdaAddress,
        weightX,
        weightY,
        fwpwbtcusdaAddress,
        multisigfwpAddress,
        wbtcQ,
        Math.round(wbtcPrice * wbtcQ / ONE_8),
      );
      result.expectOk().expectBool(true);
  
      let call = await FWPTest.getPoolDetails(
        wbtcAddress,
        usdaAddress,
        weightX,
        weightY,
      );
      let position: any = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(wbtcQ);
      position["balance-y"].expectUint(Math.round(wbtcQ * wbtcPrice / ONE_8));
  
      result = FWPTest.setOracleEnabled(
        deployer,
        wbtcAddress,
        usdaAddress,
        weightX,
        weightY,
      );
      result.expectOk().expectBool(true);
      result = FWPTest.setOracleAverage(
        deployer,
        wbtcAddress,
        usdaAddress,
        weightX,
        weightY,
        0.95e8,
      );
      result.expectOk().expectBool(true);
  
      result = YTPTest.createPool(
        deployer,
        yieldwbtc59760Address,
        wbtcAddress,
        ytpyieldwbtc59760Address,
        multisigytpyieldwbtc59760,
        wbtcQ / 10,
        wbtcQ / 10,
      );
      result.expectOk().expectBool(true);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(500000000000000);
  
      //Deployer creating a pool, initial tokens injected to the pool
      result = CRPTest.createPool(
        deployer,
        wbtcAddress,
        usdaAddress,
        yieldwbtc59760Address,
        keywbtc59760Address,
        multisigncrpwbtc59760Address,
        ltv_0,
        conversion_ltv,
        bs_vol,
        moving_average,
        11520 * ONE_8,
        50000 * ONE_8,
      );
      result.expectOk().expectBool(true);
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(100089191);
  
      // ltv-0 is 80%, but injecting liquidity pushes up LTV
      call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(80735351);
  
      // Check pool details and print
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(80807360);
      position["key-supply"].expectUint(80807360);
      position["weight-x"].expectUint(66534062);
      position["weight-y"].expectUint(ONE_8 - 66534062);
      position["balance-x"].expectUint(3326703100000);
      position["balance-y"].expectUint(33577500);
      position["strike"].expectUint(50000 * ONE_8);
      position["ltv-0"].expectUint(ltv_0);
      position["bs-vol"].expectUint(bs_vol);
      position["conversion-ltv"].expectUint(conversion_ltv);
      position["moving-average"].expectUint(moving_average);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(495000000000000);
  
      // // simulate to expiry + 1
      chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(100089191);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(1989000000000);
  
      // deployer burns all the yield tokens
      result = CRPTest.reducePositionYield(
        deployer,
        wbtcAddress,
        usdaAddress,
        yieldwbtc59760Address,
        ONE_8,
      );
      position = result.expectOk().expectTuple();
      position["dx"].expectUint(0);
      position["dy"].expectUint(80807360);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(1989080807360);
  
      // Pool has value left for key-token only
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(19299897);
  
      // key-token remains, with some balances
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(80807360);
      position["balance-x"].expectUint(0);
      position["balance-y"].expectUint(19299897);  
  
      // remove all key tokens for nothing
      result = CRPTest.reducePositionKey(
        deployer,
        wbtcAddress,
        usdaAddress,
        keywbtc59760Address,
        ONE_8,
      );
      position = result.expectOk().expectTuple();
      position["dx"].expectUint(0);
      position["dy"].expectUint(19299897);
  
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(0);
      position["balance-y"].expectUint(0);
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(0);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(1989080807360 + 19299897);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(495000000000000);
    },
  });