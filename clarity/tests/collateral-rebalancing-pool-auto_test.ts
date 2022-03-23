import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.14.0/index.ts";
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
const ytpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.ytp-alex";
const multisigYtpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-ytp-alex";
const yieldAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-alex";
const keyAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.key-alex-autoalex";
const multisigCrpAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.multisig-crp-alex-autoalex";
const autoYieldAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-yield-alex";
const autoYtpAlexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-ytp-alex";
const autoKeyAlexAutoalexAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.auto-key-alex-autoalex";

const ACTIVATION_BLOCK = 20;
const BountyPercentage = 0.001;
const BountyCap = 10 * ONE_8;
const APOWER_MULTIPLIER = ONE_8;

const liquidity = 100 * ONE_8;

const ltv_0 = 0.5e8;
const conversion_ltv = 0.9e8;
const bs_vol = 1e8;
const moving_average = 0.95e8;
const token_to_maturity = 0e8;

Clarinet.test({
    name: "AUTO: test",
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
        result = FWPTest.setMaxInRatio(deployer, 0.3e8);
        result.expectOk();
        result = FWPTest.setMaxOutRatio(deployer, 0.3e8);
        result.expectOk();
        result = FWPTest.createPool(deployer, alexAddress, autoAlexAddress, fwpAlexAutoalexAddress, multisigFwpAlexAutoalexAddress, liquidity, liquidity);
        result.expectOk();
        result = FWPTest.setStartBlock(deployer, alexAddress, autoAlexAddress, 0);
        result.expectOk();
        result = FWPTest.setOracleEnabled(deployer, alexAddress, autoAlexAddress);
        result.expectOk();
        result = FWPTest.setOracleAverage(deployer, alexAddress, autoAlexAddress, 0.95e8);
        result.expectOk();

        let block = chain.mineBlock([
            reservePool.addToken(deployer, alexAddress),
            reservePool.setActivationBlock(deployer, alexAddress, ACTIVATION_BLOCK),
            reservePool.setCoinbaseAmount(deployer, alexAddress, ONE_8, ONE_8, ONE_8, ONE_8, ONE_8),
            reservePool.setApowerMultiplierInFixed(deployer, alexAddress, APOWER_MULTIPLIER),          
        ]);
        block.receipts.forEach(e => { e.result.expectOk() }); 

        chain.mineEmptyBlockUntil(ACTIVATION_BLOCK);   
        
        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool", "set-approved-pair",
                [types.principal(autoYtpAlexAddress), types.principal(ytpAlexAddress)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "set-pool-underlying",
                [types.principal(ytpAlexAddress), types.principal(alexAddress)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "set-approved-pair",
                [types.principal(autoKeyAlexAutoalexAddress), types.principal(keyAlexAutoalexAddress)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "set-pool-underlying",
                [types.principal(keyAlexAutoalexAddress), types.principal(alexAddress)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "set-approved-pair",
                [types.principal(autoYieldAlexAddress), types.principal(yieldAlexAddress)],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "set-pool-underlying",
                [types.principal(yieldAlexAddress), types.principal(alexAddress)],
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

        let call = chain.callReadOnlyFn("collateral-rebalancing-pool", "get-expiry", [types.principal(ytpAlexAddress)], deployer.address);
        const expiry = Number(call.result.expectOk().replace(/\D/g, ""));
        
        result = YTPTest.createPool(deployer, expiry, yieldAlexAddress, alexAddress, ytpAlexAddress, multisigYtpAlexAddress, liquidity, 0);
        result.expectOk();
        result = CRPTest.createPool(deployer, alexAddress, autoAlexAddress, expiry, yieldAlexAddress, keyAlexAutoalexAddress, multisigCrpAlexAutoalexAddress, ltv_0, conversion_ltv, bs_vol, moving_average, token_to_maturity, ONE_8);
        result.expectOk();
        
        call = chain.callReadOnlyFn(ytpAlexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(deployer.address)], deployer.address);
        const ytpAlexBalance = Number(call.result.expectOk().replace(/\D/g, ""));
        call = chain.callReadOnlyFn(keyAlexAutoalexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(deployer.address)], deployer.address);
        const keyAlexAutoalexBalance = Number(call.result.expectOk().replace(/\D/g, ""));        
        call = chain.callReadOnlyFn(yieldAlexAddress, "get-balance-fixed", [types.uint(expiry), types.principal(deployer.address)], deployer.address);
        const yieldAlexBalance = Number(call.result.expectOk().replace(/\D/g, ""));                

        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool", "mint-auto",
                [
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress),
                    types.uint(ytpAlexBalance)
                ],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "mint-auto",
                [
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress),
                    types.uint(keyAlexAutoalexBalance)
                ],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "mint-auto",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(autoYieldAlexAddress),
                    types.uint(yieldAlexBalance)
                ],
                deployer.address
            )                         
        ]);
        block.receipts.forEach(e => 
            { 
                e.result.expectOk();
                // console.log(e.events);
            }
        );      
        
        chain.mineEmptyBlockUntil(expiry + 1);
        
        // (define-public (roll-auto-pool (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (collateral-trait <ft-trait>) (pool-token-trait <sft-trait>) (auto-token-trait <ft-trait>))        
        // (define-public (roll-auto-key (token-trait <ft-trait>) (collateral-trait <ft-trait>) (yield-token-trait <sft-trait>) (key-token-trait <sft-trait>) (auto-token-trait <ft-trait>))
        // (define-public (roll-auto-yield (yield-token-trait <sft-trait>) (token-trait <ft-trait>) (collateral-trait <ft-trait>) (auto-token-trait <ft-trait>))
        block = chain.mineBlock([
            Tx.contractCall("collateral-rebalancing-pool", "roll-auto-pool",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.principal(ytpAlexAddress),
                    types.principal(autoYtpAlexAddress)
                ],
                deployer.address
            ),
            Tx.contractCall("collateral-rebalancing-pool", "roll-auto-key",
                [
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.principal(yieldAlexAddress),
                    types.principal(keyAlexAutoalexAddress),
                    types.principal(autoKeyAlexAutoalexAddress)
                ],
                deployer.address
            ),            
            Tx.contractCall("collateral-rebalancing-pool", "roll-auto-yield",
                [
                    types.principal(yieldAlexAddress),
                    types.principal(alexAddress),
                    types.principal(autoAlexAddress),
                    types.principal(autoYieldAlexAddress)
                ],
                deployer.address
            ),     
        ]);
        block.receipts.forEach(e => 
            { 
                e.result.expectOk();
                // console.log(e.events);
            }
        );

        // block = chain.mineBlock([
        //     Tx.contractCall("collateral-rebalancing-pool", "redeem-auto",
        //         [
        //             types.principal(ytpAlexAddress),
        //             types.principal(autoYtpAlexAddress),
        //             types.uint(ONE_8)
        //         ],
        //         deployer.address
        //     )
        // ]);
        // block.receipts.forEach(e => 
        //     { 
        //         e.result.expectOk();
        //         // console.log(e.events);
        //     }
        // );                      
    }
});

