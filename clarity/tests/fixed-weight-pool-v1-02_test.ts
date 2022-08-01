
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

import { FWPTestAgent5 } from './models/alex-tests-fixed-weight-pool.ts';
import { MS_FWP_WSTX_USDA_5050 } from './models/alex-tests-multisigs.ts';
import { 
    USDAToken,
    WBTCToken,
    WSTXToken,
    FWP_WSTX_USDA_5050,
  } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wusda"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50-v1-01"
const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50-v1-01"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50-v1-01"
const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50-v1-01"
const fwpAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fixed-weight-pool-v1-01"
const wrongPooltokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.lbp-alex-usda-90-10"
const alexReservePoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-reserve-pool"

const ONE_8 = 100000000

const weightX = 0.5 * ONE_8;
const weightY = 0.5 * ONE_8;

const wbtcPrice = 50000;

const wbtcQ = 10 * ONE_8;

Clarinet.test({
    name: "fixed-weight-pool-v1-02 : pool creation, adding values and reducing values",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTest = new FWPTestAgent5(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        // result = wstxToken.mintFixed(wallet_1, wallet_1.address, 200000 * ONE_8);
        // result.expectOk();      
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);
        result = FWPTest.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, wbtcQ*wbtcPrice, wbtcQ);
        result.expectOk().expectBool(true);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);    
        result = FWPTest.setStartBlock(deployer, wstxAddress, usdaAddress, weightX, weightY, 0);   
        result.expectOk().expectBool(true);     
        result = FWPTest.setStartBlock(deployer, wstxAddress, wbtcAddress, weightX, weightY, 0);   
        result.expectOk().expectBool(true);                

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(wstxAddress, wbtcAddress,weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(223606760109);
        position['balance-x'].expectUint(wbtcQ*wbtcPrice);
        position['balance-y'].expectUint(wbtcQ);

        // Add extra liquidity (1/4 of initial liquidity)
        result = FWPTest.addToPosition(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, wbtcQ*wbtcPrice / 4, wbtcQ / 4);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(Math.round(223606760109 / 4));
        position['dy'].expectUint(wbtcQ / 4);
        position['dx'].expectUint(wbtcQ*wbtcPrice / 4);

        // Check pool details and print
        call = await FWPTest.getPoolDetails(wstxAddress, wbtcAddress, weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['total-supply'].expectUint(Math.round(5/4 * 223606760109));
        position['balance-y'].expectUint(5/4 * wbtcQ);
        position['balance-x'].expectUint(5/4 * wbtcQ*wbtcPrice);        

        // Reduce all liquidlity
        result = FWPTest.reducePosition(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(1250000000);
        position['dx'].expectUint(62500000000000);

        // Add back some liquidity
        result = FWPTest.addToPosition(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, wbtcQ*wbtcPrice, wbtcQ);
        position = result.expectOk().expectTuple();
        position['supply'].expectUint(223606760109);
        position['dy'].expectUint(wbtcQ);
        position['dx'].expectUint(wbtcQ*wbtcPrice);        

        // attempt to trade too much (> 90%) will be rejected
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 91*ONE_8, 0);
        position = result.expectErr().expectUint(4002);

        // swap some wbtc into usda
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(ONE_8);
        position['dy'].expectUint(4166658500000);    
        
        // swap some usda into wbtc
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, wbtcPrice*ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(116128760);
        position['dy'].expectUint(wbtcPrice*ONE_8);        

        // attempt to swap zero throws an error
        result = FWPTest.swapYForX(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0, 0);
        result.expectErr().expectUint(2003);    
        result = FWPTest.swapXForY(deployer, wbtcAddress, usdaAddress, weightX, weightY, 0, 0);
        result.expectErr().expectUint(2003);               
    },
});

Clarinet.test({
    name: "fixed-weight-pool-v1-02 : trait check",

    async fn(chain: Chain, accounts: Map<string, Account>){
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTest = new FWPTestAgent5(chain, deployer);
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = usdaToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, wallet_1.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();
        // result = wstxToken.mintFixed(wallet_1, wallet_1.address, 200000 * ONE_8);
        // result.expectOk();
        
        // non-deployer attempting to create a pool will throw an error
        result = FWPTest.createPool(wallet_1, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectErr().expectUint(1000);

        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        // Add extra liquidity (1/4 of initial liquidity)
        result = FWPTest.addToPosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, wbtcQ*wbtcPrice / 4, wbtcQ*wbtcPrice / 4);
        let position:any = result.expectOk().expectTuple();
        
        // supplying a wrong pool token will throw an error
        result = FWPTest.addToPosition(wallet_1, wstxAddress, usdaAddress, weightX, weightY, wrongPooltokenAddress, wbtcQ / 4, wbtcQ*wbtcPrice / 4);
        result.expectErr().expectUint(2026);

        // supplying a wrong pool token will throw and error
        result = FWPTest.reducePosition(deployer, wstxAddress, usdaAddress, weightX, weightY, wrongPooltokenAddress, ONE_8);
        result.expectErr().expectUint(2026);

        // Reduce all liquidlity
        result = FWPTest.reducePosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, ONE_8);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(62500000000000);
        position['dy'].expectUint(62500000000000);        
    }
})

Clarinet.test({
    name: "fixed-weight-pool-v1-02 : error testing",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let FWPTest = new FWPTestAgent5(chain, deployer);
        let MultiSigTest = new MS_FWP_WSTX_USDA_5050(chain, deployer);
        let fwpPoolToken = new FWP_WSTX_USDA_5050(chain, deployer);
        const feeRateX = 5000000; // 5%
        const feeRateY = 5000000;
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();        

        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);
        
        // Duplicated pool creation
        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectErr().expectUint(2000);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);     
        result = FWPTest.setStartBlock(deployer, wstxAddress, usdaAddress, weightX, weightY, 0);   
        result.expectOk().expectBool(true);                
        
        // Tx-sender does not have enough balance
        result = FWPTest.addToPosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, wbtcQ*wbtcPrice * 1000, wbtcQ*wbtcPrice * 1000);
        result.expectErr().expectUint(3000);

        // Tx-sender tries to add zero balance
        result = FWPTest.addToPosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress,0, 0);
        result.expectErr().expectUint(2003);

        // Add liquidity
        result = FWPTest.addToPosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, wbtcQ*wbtcPrice / 4, wbtcQ*wbtcPrice / 4);
        let position:any = result.expectOk().expectTuple();

        // Reducing Liquidity more than 100%
        result = FWPTest.reducePosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, ONE_8+1);
        result.expectErr().expectUint(5000);

        // Reducing Liquidity of zero, Error caught on the code which tries to transfer zero balance from vault
        result = FWPTest.reducePosition(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, 0);
        result.expectErr().expectUint(3);

        let ROresult = FWPTest.getPoolDetails(wstxAddress, usdaAddress, weightX, weightY);
        position = ROresult.result.expectOk().expectTuple();
        position['balance-x'].expectUint(62500000000000);
        position['balance-y'].expectUint(62500000000000);           

        // Swapping 
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, wbtcPrice*ONE_8, 0);
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(wbtcPrice*ONE_8);
        position['dy'].expectUint(4629624375000);   

        // Attempts to trade more than limit
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8*ONE_8, 0);
        result.expectErr().expectUint(4001); 

        // Zero swapping
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, 0, 0);
        result.expectErr().expectUint(2003); 
    },
});

Clarinet.test({
    name: "fixed-weight-pool-v1-02 : testing get-x-given-price and get-y-given-price",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let FWPTest = new FWPTestAgent5(chain, deployer);     
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);
        // let wstxToken = new WSTXToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();
        // result = wstxToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        // result.expectOk();                 

        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);      
        result = FWPTest.setStartBlock(deployer, wstxAddress, usdaAddress, weightX, weightY, 0);   
        result.expectOk().expectBool(true);                  

        // Check pool details and print
        let call = await FWPTest.getPoolDetails(wstxAddress, usdaAddress, weightX, weightY);
        let position:any = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(wbtcQ*wbtcPrice);
        position['balance-y'].expectUint(wbtcQ*wbtcPrice);      
        
        // let's do some arb
        call = await FWPTest.getYgivenPrice(wstxAddress, usdaAddress, weightX, weightY, Math.round(ONE_8*1.1));
        call.result.expectOk().expectUint(2440438000000);         
        result = FWPTest.swapYForX(deployer, wstxAddress, usdaAddress, weightX, weightY, 2326871500000, 0)
        position = result.expectOk().expectTuple();
        position['dy'].expectUint(2326871500000);
        position['dx'].expectUint(2223395500000);

        // now pool price implies 1.1
        call = await FWPTest.getPoolDetails(wstxAddress, usdaAddress, weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(50000000000000 - 2223395500000);
        position['balance-y'].expectUint(50000000000000 + 2326871500000);       
        
        // let's do some arb
        // but calling get-y-given-price throws an error
        call = await FWPTest.getYgivenPrice(wstxAddress, usdaAddress, weightX, weightY, Math.round(ONE_8 * 1.1 * 0.95));
        call.result.expectErr().expectUint(2002);
        // we need to call get-x-given-price
        call = await FWPTest.getXgivenPrice(wstxAddress, usdaAddress, weightX, weightY, Math.round(ONE_8 * 1.1 * 0.95));
        call.result.expectOk().expectUint(1134992960654);                 
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, 1240808997564, 0)
        position = result.expectOk().expectTuple();
        position['dx'].expectUint(1240808997564);         
        position['dy'].expectUint(1324578878058);      

        // now pool price implies 1.1*0.95 ~= 1.045
        call = await FWPTest.getPoolDetails(wstxAddress, usdaAddress, weightX, weightY);
        position = call.result.expectOk().expectTuple();
        position['balance-x'].expectUint(50000000000000 - 2223395500000 + 1240808997564);
        position['balance-y'].expectUint(50000000000000 + 2326871500000 - 1324578878058);         
        
        call = await FWPTest.getYgivenX(wstxAddress, usdaAddress, weightX, weightY, 50000*ONE_8);
        call.result.expectOk().expectUint(4720906851139);

        call = await FWPTest.getYgivenX(wstxAddress, usdaAddress, weightX, weightY, 0);
        call.result.expectOk().expectUint(0);

        call = await FWPTest.getYgivenX(wstxAddress, wstxAddress, weightX, weightY, 0);
        call.result.expectErr().expectUint(2001);

        call = await FWPTest.getXgivenY(wstxAddress, usdaAddress, weightX, weightY, 50000*ONE_8);
        call.result.expectOk().expectUint(4376370751192);

        call = await FWPTest.getXgivenY(wstxAddress, usdaAddress, weightX, weightY, 0);
        call.result.expectOk().expectUint(0);

        call = await FWPTest.getXgivenY(wstxAddress, wstxAddress, weightX, weightY, 0);
        call.result.expectErr().expectUint(2001);
    },
});          
        

Clarinet.test({
    name: "fixed-weight-pool-v1-02 : check start-block and end-block",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTest = new FWPTestAgent5(chain, deployer);     
        let usdaToken = new USDAToken(chain, deployer);
        let wbtcToken = new WBTCToken(chain, deployer);

        // Deployer minting initial tokens        
        let result = usdaToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = wbtcToken.mintFixed(deployer, deployer.address, 100000 * ONE_8);
        result.expectOk();               

        result = FWPTest.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, wbtcQ*wbtcPrice, wbtcQ*wbtcPrice);
        result.expectOk().expectBool(true);

        result = FWPTest.setStartBlock(wallet_1, wstxAddress, usdaAddress, weightX, weightY, 100);
        result.expectErr().expectUint(1000);        
        result = FWPTest.setStartBlock(deployer, wstxAddress, usdaAddress, weightX, weightY, 100);
        result.expectOk().expectBool(true);
        
        result = FWPTest.swapYForX(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectErr().expectUint(1000);
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectErr().expectUint(1000);        

        chain.mineEmptyBlockUntil(100);

        result = FWPTest.swapYForX(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectOk().expectTuple();
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectOk().expectTuple();        

        result = FWPTest.setEndBlock(wallet_1, wstxAddress, usdaAddress, weightX, weightY, 200);
        result.expectErr().expectUint(1000);        
        result = FWPTest.setEndBlock(deployer, wstxAddress, usdaAddress, weightX, weightY, 200);
        result.expectOk().expectBool(true);

        chain.mineEmptyBlockUntil(201);

        result = FWPTest.swapYForX(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectErr().expectUint(1000);
        result = FWPTest.swapXForY(deployer, wstxAddress, usdaAddress, weightX, weightY, ONE_8, 0);
        result.expectErr().expectUint(1000);        
        
        
    },       
});       
