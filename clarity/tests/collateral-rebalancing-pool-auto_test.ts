import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.31.1/index.ts";
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';
import { CRPTestAgent1 } from './models/alex-tests-collateral-rebalancing-pool.ts';
import { FWPTestAgent3 } from './models/alex-tests-fixed-weight-pool.ts';
import { YTPTestAgent1 } from './models/alex-tests-yield-token-pool.ts';
import { ReservePool } from "./models/alex-tests-reserve-pool.ts";
import { FungibleToken } from "./models/alex-tests-tokens.ts";

const ONE_8 = 100000000

const alexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token";
const autoAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-alex";
const fwpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.fwp-alex-autoalex";
const multisigFwpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-fwp-alex-autoalex";
const ytpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-alex-v1";
const multisigYtpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-alex";
const yieldAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-alex-v1";
const keyAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-alex-autoalex-v1";
const multisigCrpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-alex-autoalex-v1";
const autoYieldAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-yield-alex";
const autoYtpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-ytp-alex";
const autoKeyAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-key-alex-autoalex";
const wrongPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-wbtc";

const ACTIVATION_BLOCK = 20;
const FIXED_BOUNTY = 0.01e8;
const APOWER_MULTIPLIER = ONE_8;

const liquidity = 10 * ONE_8;

const ltv_0 = 0.5e8;
const conversion_ltv = 0.9e8;
const bs_vol = 1e8;
const moving_average = 0.95e8;
const token_to_maturity = 0e8;

Clarinet.test({
    name: "collateral-rebalancing-pool-v1 auto : test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const wallet_2 = accounts.get("wallet_2")!;
        const reservePool = new ReservePool(chain);
        const CRPTest = new CRPTestAgent1(chain, deployer);
        const FWPTest = new FWPTestAgent3(chain, deployer);
        const YTPTest = new YTPTestAgent1(chain, deployer);
        const alexToken = new FungibleToken(chain, deployer, "age000-governance-token");
        const autoAlexToken = new FungibleToken(chain, deployer, "auto-alex");

        const dx = ONE_8;

        let result = alexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = alexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = autoAlexToken.mintFixed(deployer, deployer.address, 100000000 * ONE_8);
        result.expectOk();
        result = autoAlexToken.mintFixed(deployer, wallet_1.address, 200000 * ONE_8);
        result.expectOk();
        result = autoAlexToken.mintFixed(deployer, wallet_2.address, 20000 * ONE_8);

        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk();
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk();
        result = YTPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk();
        result = YTPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk();
        result = CRPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);
        result = CRPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk().expectBool(true);            

        result = FWPTest.createPool(deployer, alexAddress, autoAlexAddress, fwpAlexAutoalexAddress, multisigFwpAlexAutoalexAddress, liquidity, liquidity);
        result.expectOk();
        result = FWPTest.setStartBlock(deployer, alexAddress, autoAlexAddress, 0);
        result.expectOk();
        result = FWPTest.setOracleEnabled(deployer, alexAddress, autoAlexAddress);
        result.expectOk();
        result = FWPTest.setOracleAverage(deployer, alexAddress, autoAlexAddress, 0.95e8);
        result.expectOk();

        // chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);        

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexAddress),
            reservePool.setActivationBlock(deployer, alexAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.setApowerMultiplierInFixed(deployer, alexAddress, APOWER_MULTIPLIER),          
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });    
        
        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-contract",
                [types.principal(wallet_1.address), types.bool(true)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-contract",
                [types.principal(deployer.address), types.bool(true)],
                deployer.address
            ),    
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-strike-multiplier",
                [types.uint(0.5e8)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-expiry-cycle-length",
                [types.uint(1234)],
                deployer.address
            ),           
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-pair",
                [
                    types.principal(autoYtpAlexAddress), 
                    types.principal(ytpAlexAddress),
                    types.uint(ACTIVATION_BLOCK),
                    types.uint(FIXED_BOUNTY)
                ],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-pair",
                [
                    types.principal(autoKeyAlexAutoalexAddress), 
                    types.principal(keyAlexAutoalexAddress),
                    types.uint(ACTIVATION_BLOCK),
                    types.uint(FIXED_BOUNTY)                    
                ],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-approved-pair",
                [
                    types.principal(autoYieldAlexAddress), 
                    types.principal(yieldAlexAddress),
                    types.uint(ACTIVATION_BLOCK),
                    types.uint(FIXED_BOUNTY)                    
                ],
                deployer.address
            ),                     
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(alexAddress)], deployer.address),
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(autoAlexAddress)], deployer.address),
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(autoYtpAlexAddress)], deployer.address),               
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(autoKeyAlexAutoalexAddress)], deployer.address),                 
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(autoYieldAlexAddress)], deployer.address),   
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(yieldAlexAddress)], deployer.address),
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(ytpAlexAddress)], deployer.address),
            Tx.contractCall("alex-vault", "add-approved-token", [types.principal(keyAlexAutoalexAddress)], deployer.address)                    
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });         

        let call = chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-expiry", [types.principal(ytpAlexAddress)], deployer.address);
        const expiry = Number(call.result.expectOk().replace(/\D/g, ""));

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(0)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(0)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(0)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(0)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(2003); });        

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(1)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1001); });

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(wrongPoolAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(wrongPoolAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(1)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(wrongPoolAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(wrongPoolAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1000); });

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(alexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(alexAddress),
                    types.uint(1)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(alexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(alexAddress),
                    types.uint(1)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1000); });

        
        result = YTPTest.createPool(deployer, expiry, yieldAlexAddress, alexAddress, ytpAlexAddress, multisigYtpAlexAddress, liquidity, 0);
        result.expectOk();
        result = CRPTest.createPool(deployer, alexAddress, autoAlexAddress, expiry, yieldAlexAddress, keyAlexAutoalexAddress, multisigCrpAlexAutoalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk();        

        result = YTPTest.addToPosition(wallet_1, expiry, yieldAlexAddress, alexAddress, ytpAlexAddress, ONE_8, Number.MAX_SAFE_INTEGER);
        result.expectOk();
        result = CRPTest.addToPosition(wallet_1, alexAddress, autoAlexAddress, expiry, yieldAlexAddress, keyAlexAutoalexAddress, ONE_8);
        result.expectOk();

        call = chain.callReadOnlyFn(ytpAlexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(wallet_1.address)], wallet_1.address);
        const ytpAlexBalance = Number(call.result.expectOk().replace(/\D/g, ""));
        call = chain.callReadOnlyFn(keyAlexAutoalexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(wallet_1.address)], wallet_1.address);
        const keyAlexAutoalexBalance = Number(call.result.expectOk().replace(/\D/g, ""));        
        call = chain.callReadOnlyFn(yieldAlexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(wallet_1.address)], wallet_1.address);
        const yieldAlexBalance = Number(call.result.expectOk().replace(/\D/g, ""));    
        // console.log(yieldAlexBalance);
        
        call = chain.callReadOnlyFn(ytpAlexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(deployer.address)], deployer.address);
        const ytpAlexBalanceD = Number(call.result.expectOk().replace(/\D/g, ""));     
        
        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ytpAlexBalance + 1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ytpAlexBalanceD + 1)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(keyAlexAutoalexBalance + 1)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(yieldAlexBalance + 1)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectErr(); });              

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ytpAlexBalance)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ytpAlexBalanceD)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(keyAlexAutoalexBalance)
                ],
                wallet_1.address
            ),
            Tx.contractCall("collateral-rebalancing-pool-v1", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(yieldAlexBalance)
                ],
                wallet_1.address
            )                         
        ]);
        block.receipts.forEach(e => { e.result.expectOk(); });      
        
        call = chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-expiry", [types.principal(ytpAlexAddress)], deployer.address);
        assertEquals(expiry, Number(call.result.expectOk().replace(/\D/g, "")));

        chain.mineEmptyBlockUntil(expiry + 1);    

        call = chain.callReadOnlyFn("collateral-rebalancing-pool-v1", "get-expiry", [types.principal(ytpAlexAddress)], deployer.address);
        const expiry_to_roll = Number(call.result.expectOk().replace(/\D/g, ""));
        
        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool-v1", "set-shortfall-coverage",
                [
                    types.uint(1.1e8)
                ], deployer.address
            ),        
            Tx.contractCall("collateral-rebalancing-pool-v1", "roll-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.principal(yieldAlexAddress),
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.principal(autoKeyAlexAutoalexAddress)
                ],
                wallet_1.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool-v1", "add-to-position-and-switch",
                [
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.uint(expiry_to_roll), 
                    types.principal(yieldAlexAddress), 
                    types.principal(keyAlexAutoalexAddress),
                    types.uint(ONE_8),
                    types.some(types.uint(0))
                ],
                wallet_2.address
            ),       
            Tx.contractCall("collateral-rebalancing-pool-v1", "roll-auto-yield",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.principal(autoYieldAlexAddress)
                ],
                wallet_1.address
            ),               
        ]);
        block.receipts.forEach(e => { e.result.expectOk(); });
        console.log(block.receipts[2].result);

        block = chain.mineBlock([            
            Tx.contractCall("collateral-rebalancing-pool-v1", "redeem-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ONE_8)
                ],
                deployer.address
            )
        ]);
        block.receipts.forEach(e => 
            { 
                e.result.expectOk();
                console.log(e.events);
            }
        );                      
    }
});
