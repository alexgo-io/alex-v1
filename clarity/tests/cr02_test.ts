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
  import { WBTCToken, USDAToken, WSTXToken } from './models/alex-tests-tokens.ts';

  
  // Deployer Address Constants
  const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc";
  const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda";
  const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx";
  const yieldwbtcAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc";
  const keywbtcAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-wbtc-usda";
  const ytpyieldwbtcAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-yield-wbtc";
  const multisigncrpwbtcAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-wbtc-usda";
  const multisigytpyieldwbtc =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-yield-wbtc";
  const fwpwstxusdaAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50";
  const multisigfwpwstxusda =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50";
  
  const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50"
  const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50"
    
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
     
      let usdaToken = new USDAToken(chain, deployer);
      let wbtcToken = new WBTCToken(chain, deployer);
      let wstxToken = new WSTXToken(chain, deployer);

      // Deployer minting initial tokens
      let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
      result.expectOk();
      result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
      result.expectOk();
      result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
      result.expectOk();
      result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
      result.expectOk();
  
      // take away what was minted for testing to another address
      let block = await chain.mineBlock([
        Tx.contractCall("yield-wbtc", "transfer", [
          types.uint(1),
          types.uint(2000000000000),
          types.principal(deployer.address),
          types.principal(wallet_1.address)
        ], deployer.address),
      ]);
      block.receipts[0].result.expectErr();

      result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
      result.expectOk().expectBool(true);
      
      result = FWPTest.createPool(
        deployer,
        wstxAddress,
        usdaAddress,
        weightX,
        weightY,
        fwpwstxusdaAddress,
        multisigfwpwstxusda,
        Math.round(wbtcPrice * wbtcQ / ONE_8), 
        0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8)
      );
      result.expectOk().expectBool(true);
  
      let call = await FWPTest.getPoolDetails(
        wstxAddress,
        usdaAddress,
        weightX,
        weightY,
      );

      let position: any = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(5000000 * ONE_8);
      position["balance-y"].expectUint(4000000 * ONE_8);
  
      result = FWPTest.setOracleEnabled(
        deployer,
        wstxAddress,
        usdaAddress,
        weightX,
        weightY,
      );
      result.expectOk().expectBool(true);
      result = FWPTest.setOracleAverage(
        deployer,
        wstxAddress,
        usdaAddress,
        weightX,
        weightY,
        0.95e8,
      );
      result.expectOk().expectBool(true);

      result = FWPTest.setOracleEnabled(deployer, wstxAddress, wbtcAddress, weightX, weightY);
      result.expectOk().expectBool(true);   
      result = FWPTest.setOracleAverage(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0.95e8);
      result.expectOk().expectBool(true);     

      result = YTPTest.createPool(
        deployer,
        expiry, 
        yieldwbtcAddress,
        wbtcAddress,
        ytpyieldwbtcAddress,
        multisigytpyieldwbtc,
        wbtcQ / 10 ,
        wbtcQ / 10,
      );
      result.expectOk().expectBool(true);

      call = await YTPTest.getPoolDetails(expiry, yieldwbtcAddress);
      position = call.result.expectOk().expectTuple();
      position['balance-token'].expectUint(wbtcQ / 10);
      position['balance-yield-token'].expectUint(0);
      position['balance-virtual'].expectUint(wbtcQ / 10);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9600000000000000);
  
      //Deployer creating a pool, initial tokens injected to the pool
      result = CRPTest.createPool(
        deployer,
        wbtcAddress,
        usdaAddress,
        expiry,
        yieldwbtcAddress,
        keywbtcAddress,
        multisigncrpwbtcAddress,
        ltv_0,
        conversion_ltv,
        bs_vol,
        moving_average,
        1 * ONE_8,
        50000 * ONE_8,
      );
      result.expectOk().expectBool(true);

      // call = await CRPTest.getSpot(wbtcAddress, usdaAddress);
      // call.result.expectOk();
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(99929107);
  
      // ltv-0 is 80%, but injecting liquidity pushes up LTV
      call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(80055793);
  
      // Check pool details and print
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(79999040);
      position["key-supply"].expectUint(79999040);
      position["weight-x"].expectUint(66533150);
      position["weight-y"].expectUint(ONE_8 - 66533150);
      position["balance-x"].expectUint(3326657500000);
      position["balance-y"].expectUint(33465520);
      position["strike"].expectUint(50000 * ONE_8);
      position["ltv-0"].expectUint(ltv_0);
      position["bs-vol"].expectUint(bs_vol);
      position["conversion-ltv"].expectUint(conversion_ltv);
      position["moving-average"].expectUint(moving_average);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9595000000000000);
  
      // simulate to expiry + 1
      chain.mineEmptyBlockUntil((expiry / ONE_8) + 1);
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(99929107);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9991000000000);
  
      // deployer burns all the yield tokens
      result = CRPTest.reducePositionYield(
        deployer,
        wbtcAddress,
        usdaAddress,
        expiry,
        yieldwbtcAddress,
        ONE_8,
      );
      position = result.expectOk().expectTuple();
      position["dx"].expectUint(0);
      position["dy"].expectUint(79999040);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9991079999040);
  
      // Pool has value left for key-token only
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(18896504);
  
      // key-token remains, with some balances
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(79999040);
      position["balance-x"].expectUint(0);
      position["balance-y"].expectUint(18896504);  
  
      // remove all key tokens for nothing
      result = CRPTest.reducePositionKey(
        deployer,
        wbtcAddress,
        usdaAddress,
        expiry, 
        keywbtcAddress,
        ONE_8,
      );
      position = result.expectOk().expectTuple();
      position["dx"].expectUint(0);
      position["dy"].expectUint(18896504);
  
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(0);
      position["balance-y"].expectUint(0);
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(0);
  
      call = chain.callReadOnlyFn(wbtcAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9991098895544);
  
      call = chain.callReadOnlyFn(usdaAddress, "get-balance", [
        types.principal(deployer.address),
      ], deployer.address);
      call.result.expectOk().expectUint(9595000000000000);
    },
  });