import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
  } from "https://deno.land/x/clarinet@v0.31.1/index.ts";
  
  import { CRPTestAgent1 } from "./models/alex-tests-collateral-rebalancing-pool.ts";
  import { FWPTestAgent3 } from "./models/alex-tests-fixed-weight-pool.ts";
  import { YTPTestAgent1 } from "./models/alex-tests-yield-token-pool.ts";
  import { WBTCToken, USDAToken, ALEXToken } from './models/alex-tests-tokens.ts';

  
  // Deployer Address Constants
  const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc";
  const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wusda";
  const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
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
  const fwpalexusdaAddress =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-usda";
  const multisigfwpalexusda =
    "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-usda";
  
  const fwpalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-wbtc-50-50"
  const multisigalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-wbtc-50-50"
    
  const ONE_8 = 100000000;
  const expiry = 59760;
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
    name: "collateral-rebalacing-pool : Reduce yield before key tokens (CR-02)",
  
    async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet_1 = accounts.get("wallet_1")!;
      let CRPTest = new CRPTestAgent1(chain, deployer);
      let FWPTest = new FWPTestAgent3(chain, deployer);
      let YTPTest = new YTPTestAgent1(chain, deployer);
     
      let usdaToken = new USDAToken(chain, deployer);
      let wbtcToken = new WBTCToken(chain, deployer);
      let alexToken = new ALEXToken(chain, deployer);

      // Deployer minting initial tokens
      let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
      result.expectOk();
      result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
      result.expectOk();
      result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
      result.expectOk();
      result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
      result.expectOk();
      result = alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
      result.expectOk();
      result = alexToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
      result.expectOk(); 

      result = FWPTest.setMaxInRatio(deployer, 0.3e8);
      result.expectOk().expectBool(true);
      result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
      result.expectOk().expectBool(true);         

      result = FWPTest.createPool(deployer, alexAddress, wbtcAddress, fwpalexwbtcAddress, multisigalexwbtcAddress, Math.round(wbtcPrice * wbtcQ / ONE_8), 0.8 * wbtcQ);
      result.expectOk().expectBool(true);
      
      result = FWPTest.createPool(
        deployer,
        alexAddress,
        usdaAddress,
        fwpalexusdaAddress,
        multisigfwpalexusda,
        Math.round(wbtcPrice * wbtcQ / ONE_8), 
        0.8 * Math.round(wbtcPrice * wbtcQ / ONE_8)
      );
      result.expectOk().expectBool(true);     
      
      result = FWPTest.setStartBlock(deployer, alexAddress, usdaAddress, 0);   
      result.expectOk().expectBool(true);    
      result = FWPTest.setStartBlock(deployer, alexAddress, wbtcAddress, 0);   
      result.expectOk().expectBool(true);         
  
      let call = await FWPTest.getPoolDetails(
        alexAddress,
        usdaAddress
      );

      let position: any = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(5000000 * ONE_8);
      position["balance-y"].expectUint(4000000 * ONE_8);
  
      result = FWPTest.setOracleEnabled(
        deployer,
        alexAddress,
        usdaAddress,
      );
      result.expectOk().expectBool(true);
      result = FWPTest.setOracleAverage(
        deployer,
        alexAddress,
        usdaAddress,
        0.95e8,
      );
      result.expectOk().expectBool(true);

      result = FWPTest.setOracleEnabled(deployer, alexAddress, wbtcAddress);
      result.expectOk().expectBool(true);   
      result = FWPTest.setOracleAverage(deployer, alexAddress, wbtcAddress, 0.95e8);
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
      result.expectOk().expectTuple();

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
      result.expectOk().expectTuple();

      // call = await CRPTest.getSpot(wbtcAddress, usdaAddress);
      // call.result.expectOk();
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(99172619);
        
      call = await CRPTest.getLtv(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(80667426);
  
      // Check pool details and print
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(80000000);
      position["key-supply"].expectUint(80000000);
      position["weight-x"].expectUint(68641532);
      position["weight-y"].expectUint(ONE_8 - 68641532);
      position["balance-x"].expectUint(3432076600000);
      position["balance-y"].expectUint(31114541);
      position["strike"].expectUint((ONE_8 * 0.75 + ltv_0 * 0.25) * ONE_8 / wbtcPrice);
      position["ltv-0"].expectUint(ltv_0);
      position["bs-vol"].expectUint(bs_vol);
      position["conversion-ltv"].expectUint(conversion_ltv);
      position["moving-average"].expectUint(moving_average);
  
      // simulate to expiry + 1
      chain.mineEmptyBlockUntil(expiry + 1);
  
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(99172619);
  
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
      position["dy"].expectUint(80000000);
  
      // Pool has value left for key-token only
      call = await CRPTest.getPoolValueInToken(wbtcAddress, usdaAddress, expiry);
      call.result.expectOk().expectUint(17881795);
  
      // key-token remains, with some balances
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(80000000);
      position["balance-x"].expectUint(737562082899);
      position["balance-y"].expectUint(3469832);  
  
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
      position["dx"].expectUint(737562082899);
      position["dy"].expectUint(3469832);
  
      call = await CRPTest.getPoolDetails(wbtcAddress, usdaAddress, expiry);
      position = call.result.expectOk().expectTuple();
      position["balance-x"].expectUint(0);
      position["balance-y"].expectUint(0);
      position["yield-supply"].expectUint(0);
      position["key-supply"].expectUint(0);
    },
  });