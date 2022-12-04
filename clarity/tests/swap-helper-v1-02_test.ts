
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

import { FWPTestAgent1, FWPTestAgent3, FWPTestAgent4 } from './models/alex-tests-fixed-weight-pool.ts';
import { USDAToken, WBTCToken, ALEXToken } from './models/alex-tests-tokens.ts';

// Deployer Address Constants 
const wbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const usdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wusda"
const wstxAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wstx"
const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token"
const fwpalexusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-usda"
const fwpalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-wbtc-50-50"
const fwpwstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-alex-50-50-v1-01"
const fwpwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-usda-50-50-v1-01"
const fwpwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-wstx-wbtc-50-50-v1-01"
const multisigalexusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-usda"
const multisigalexwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-wbtc-50-50"
const multisigwstxalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-alex-50-50-v1-01"
const multisigwstxusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-usda-50-50-v1-01"
const multisigwstxwbtcAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-wstx-wbtc-50-50-v1-01"

const ONE_8 = 100000000

const weightX = 0.5 * ONE_8;
const weightY = 0.5 * ONE_8;

const price = 50000;

const quantity = 10 * ONE_8;

Clarinet.test({
    name: "swap-helper-v1-02 : ALEX only swap works",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTestSTX = new FWPTestAgent1(chain, deployer);
        let FWPTestALEX = new FWPTestAgent3(chain, deployer);
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
        result = alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();      
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTestALEX.createPool(deployer, alexAddress, usdaAddress, fwpalexusdaAddress, multisigalexusdaAddress, quantity * price, quantity * price);
        result.expectOk().expectBool(true);
        result = FWPTestALEX.createPool(deployer, alexAddress, wbtcAddress, fwpalexwbtcAddress, multisigalexwbtcAddress, quantity * price, quantity);
        result.expectOk().expectBool(true);

        result = FWPTestALEX.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTestALEX.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);      
        result = FWPTestALEX.setStartBlock(deployer, alexAddress, usdaAddress, 0);   
        result.expectOk().expectBool(true);  
        result = FWPTestALEX.setStartBlock(deployer, alexAddress, wbtcAddress, 0);   
        result.expectOk().expectBool(true);                    

        const block = chain.mineBlock(
            [
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(usdaAddress), types.principal(wbtcAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(wbtcAddress), types.principal(usdaAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address)
            ]
        );
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    },
});

Clarinet.test({
    name: "swap-helper-v1-02 : STX only swap works",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTestSTX = new FWPTestAgent1(chain, deployer);
        let FWPTestALEX = new FWPTestAgent3(chain, deployer);
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
        result = alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();      
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTestSTX.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, quantity * price, quantity * price);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.createPool(deployer, wstxAddress, wbtcAddress, weightX, weightY, fwpwstxwbtcAddress, multisigwstxwbtcAddress, quantity * price, quantity);
        result.expectOk().expectBool(true);

        result = FWPTestSTX.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);   
        result = FWPTestSTX.setOracleEnabled(deployer, wstxAddress, usdaAddress, 0.5e8, 0.5e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setOracleAverage(deployer, wstxAddress, usdaAddress, 0.5e8, 0.5e8, 0.95e8);
        result.expectOk().expectBool(true);   
        result = FWPTestSTX.setOracleEnabled(deployer, wstxAddress, wbtcAddress, 0.5e8, 0.5e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setOracleAverage(deployer, wstxAddress, wbtcAddress, 0.5e8, 0.5e8, 0.95e8);
        result.expectOk().expectBool(true);                               

        const block = chain.mineBlock(
            [
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(usdaAddress), types.principal(wbtcAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(wbtcAddress), types.principal(usdaAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
            ]
        );
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    },
});

Clarinet.test({
    name: "swap-helper-v1-02 : STX-anchored pool <=> ALEX-anchored pool works",

    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 = accounts.get("wallet_1")!;
        let FWPTestSTX = new FWPTestAgent1(chain, deployer);
        let FWPTestALEX = new FWPTestAgent3(chain, deployer);
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
        result = alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();      
        
        // Deployer creating a pool, initial tokens injected to the pool
        result = FWPTestSTX.createPool(deployer, wstxAddress, alexAddress, weightX, weightY, fwpwstxalexAddress, multisigwstxalexAddress, quantity * price, quantity * price);
        result.expectOk().expectBool(true);        
        result = FWPTestSTX.createPool(deployer, wstxAddress, usdaAddress, weightX, weightY, fwpwstxusdaAddress, multisigwstxusdaAddress, quantity * price, quantity * price);
        result.expectOk().expectBool(true);        
        result = FWPTestALEX.createPool(deployer, alexAddress, wbtcAddress, fwpalexwbtcAddress, multisigalexwbtcAddress, quantity * price, quantity);
        result.expectOk().expectBool(true);

        result = FWPTestSTX.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);   
        result = FWPTestSTX.setOracleEnabled(deployer, wstxAddress, usdaAddress, 0.5e8, 0.5e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setOracleAverage(deployer, wstxAddress, usdaAddress, 0.5e8, 0.5e8, 0.95e8);
        result.expectOk().expectBool(true);   
        result = FWPTestSTX.setOracleEnabled(deployer, wstxAddress, alexAddress, 0.5e8, 0.5e8);
        result.expectOk().expectBool(true);
        result = FWPTestSTX.setOracleAverage(deployer, wstxAddress, alexAddress, 0.5e8, 0.5e8, 0.95e8);
        result.expectOk().expectBool(true);                       
        result = FWPTestALEX.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = FWPTestALEX.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);         
        result = FWPTestALEX.setStartBlock(deployer, alexAddress, wbtcAddress, 0);   
        result.expectOk().expectBool(true);                   

        const block = chain.mineBlock(
            [
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(alexAddress), types.principal(usdaAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(usdaAddress), types.principal(alexAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),                                                
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(wstxAddress), types.principal(wbtcAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(wbtcAddress), types.principal(wstxAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),                
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(usdaAddress), types.principal(wbtcAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("swap-helper-v1-02", "swap-helper", [types.principal(wbtcAddress), types.principal(usdaAddress), types.uint(ONE_8), types.some(types.uint(0))], deployer.address),
                Tx.contractCall("fixed-weight-pool-v1-01", "swap-helper", [types.principal(wstxAddress), types.principal(alexAddress), types.uint(weightX), types.uint(weightY), types.uint(ONE_8), types.some(types.uint(0))], deployer.address)
            ]
        );
        block.receipts.map(e => { return e.result.expectOk() });
    },
});