
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    CRPTestAgent1,
  } from './models/alex-tests-collateral-rebalancing-pool.ts';
  

/**
 * Collateral Rebalancing Pool Test Cases
 * 
 * 1. Borrower adds Liquidity to the pool : puts collateral and mint ayusda
 *      collateral : usda
 *      ayToken : ayUSDA
 * 2. Set platform fee and collect
 */

 const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
 const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"
 const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
 const alexVaultAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault"
 const Wallet1VaultAddress = "ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK.alex-vault"
 const expiry = 52560   //  1 year  : Currently For Testing, Yield Token Expiry is hard coded to 52560
 
Clarinet.test({
    name: "CRP : Creating Pool and Borrower use case",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Initial Balance After Creation of Pool : TODO : NEED TO CHANGE EXPIRY AFTER CHANGING HARD CODED PART
        result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectList()[0].expectUint(5000000);
        result.expectOk().expectList()[1].expectUint(10000000);   
        
        // Borrower adds liquidity to the pool and mint ayusda
        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, ayusdaAddress,alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Liquidity Added to the pool
        result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectList()[0].expectUint(10000000);
        result.expectOk().expectList()[1].expectUint(20000000); 

        // Reduce Liquidity
        result = CRPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, ayusdaAddress,alexVaultAddress, 100000);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(9999);
            position['dy'].expectUint(22431);

        // Liquidity Added to the pool
        result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectList()[0].expectUint(9990001);
        result.expectOk().expectList()[1].expectUint(19977569); 

        // Check Minted ayusda


    },
});

Clarinet.test({
    name: "CRP : Arbitragers using CRP for commiting Swaps",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);
        
        // Get weight for testing swap - internal test
        let call = chain.callReadOnlyFn("collateral-rebalancing-pool", "get-weight-x", 
            [types.principal(gAlexTokenAddress),
            types.principal(usdaTokenAddress),
            types.uint(expiry)
            ], wallet_1.address);
        call.result.expectOk().expectUint(30832099)
        
        // Check whether internal weighted equation is working well - internal test
        result = CRPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 1000000);
        result.expectOk().expectUint(779640)
        
        // Arbitrager swapping usda for ayusda 
        result = CRPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, alexVaultAddress,1000000);
        result.expectOk().expectList()[0].expectUint(1000000); 
        result.expectOk().expectList()[1].expectUint(779640); 

    },
});

Clarinet.test({
    name: "CRP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, alexVaultAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = CRPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = CRPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectPrincipal(wallet_1.address);

        // // Collect Fees - TO BE IMPLEMENTED AFTER FEE COLLECTOR IMPLEMENTATION
        
    },
});