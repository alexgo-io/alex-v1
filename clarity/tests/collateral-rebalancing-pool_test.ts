
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

import { 
    CRPTestAgent1,
  } from './models/alex-tests-collateral-rebalancing-pool.ts';
  
  import { 
    OracleManager,
  } from './models/alex-tests-oracle-mock.ts';
  
  

// Deployer Address Constants 
 const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
 const usdaTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda"
 const ayusdaAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda"
 const gAlexUsdaPoolAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda"
 
 const expiry = 52560   //  1 year  : Currently For Testing, Yield Token Expiry is hard coded to 52560

/**
 * Collateral Rebalancing Pool Test Cases
 * 
 * 1. Borrower adds Liquidity to the pool : puts collateral and mint ayusda
 *      collateral : usda
 *      ayToken : ayUSDA
 * 
 * 2. Arbitrageurs using collateral rebalancing pool for trading
 * 
 * 3. Set platform fee and collect
 * 
 */

Clarinet.test({
    name: "CRP : Creating Pool and Borrower use case",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        
        let deployer = accounts.get("deployer")!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"ALEX","nothing",500000000);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",500000000);
        oracleresult.expectOk()

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectOk().expectBool(true);

        // Initial Balance After Creation of Pool : TODO : NEED TO CHANGE EXPIRY AFTER CHANGING HARD CODED PART
        result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectList()[0].expectUint(5000000);
        result.expectOk().expectList()[1].expectUint(10000000);   
        
        // Borrower adds liquidity to the pool and mint ayusda
        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 50000000000, 100000000000);
        result.expectOk().expectBool(true);

        // Liquidity Added to the pool
        result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectList()[0].expectUint(50005000000);
        result.expectOk().expectList()[1].expectUint(100010000000); 

        // Reduce Liquidity
        // Previously Error Occured since the total supply was smaller than the balance of tx-sender. 
        result = CRPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 1000000);
        let position:any =result.expectOk().expectTuple();
            position['dx'].expectUint(6597636697);
            position['dy'].expectUint(9843294060);

        // // Liquidity Added to the pool
        // result = CRPTest.getBalances(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        // result.expectOk().expectList()[0].expectUint(9990001);
        // result.expectOk().expectList()[1].expectUint(19985083); 



    },
});

Clarinet.test({
    name: "CRP : Arbitragers using CRP for commiting Swaps",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"ALEX","nothing",500000000);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",500000000);
        oracleresult.expectOk()

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectOk().expectBool(true);
        
        // Get weight for testing swap - internal test
        let call = chain.callReadOnlyFn("collateral-rebalancing-pool", "get-weight-x", 
            [types.principal(gAlexTokenAddress),
            types.principal(usdaTokenAddress),
            types.uint(expiry)
            ], wallet_1.address);
        call.result.expectOk().expectUint(40129062)
        
        // Check whether internal weighted equation is working well - internal test
        result = CRPTest.getYgivenX(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 1000000);
        result.expectOk().expectUint(1149866)
        
        // Arbitrager swapping usda for ayusda 
        result = CRPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 1000000);
        result.expectOk().expectList()[0].expectUint(1000000); 
        result.expectOk().expectList()[1].expectUint(1149871); 

    },
});

Clarinet.test({
    name: "CRP : Setting a Fee to principal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);
        
        let oracleresult = Oracle.updatePrice(deployer,"ALEX","nothing",500000000);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",500000000);
        oracleresult.expectOk()

        // Deployer creates the pool
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectOk().expectBool(true);

        // Fees will be transferred to wallet_1
        result = CRPTest.setFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, wallet_1.address);
        result.expectOk().expectBool(true);
        
       // Check whether it is correctly settled
        result = CRPTest.getFeetoAddress(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
        result.expectOk().expectPrincipal(wallet_1.address);

        // Set X fee rate to 5%
        result = CRPTest.setFeeRateX(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 5000000); // 0.05 
        result.expectOk().expectBool(true);

        // Set Y fee rate to 5%
        result = CRPTest.setFeeRateY(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 5000000); // 0.05
        result.expectOk().expectBool(true);  
        
        // Swapping actions
        result = CRPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 300000);
        result.expectOk().expectList()[0].expectUint(300000); 
        result.expectOk().expectList()[1].expectUint(364260);         

       // Check whether it is correctly collected
    //    result = CRPTest.collectFees(deployer, gAlexTokenAddress, usdaTokenAddress, expiry);
    //    result.expectOk()


        // // Collect Fees - TO BE IMPLEMENTED AFTER FEE COLLECTOR IMPLEMENTATION
        
    },
});

Clarinet.test({
    name: "CRP : General Error Testing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get("deployer")!;
        let wallet_1 =accounts.get('wallet_1')!;
        let wallet_2 =accounts.get('wallet_2')!;
        let CRPTest = new CRPTestAgent1(chain, deployer);
        let Oracle = new OracleManager(chain, deployer);

        // Price not in Otacle Error
        let result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectErr().expectUint(7000);

        let oracleresult = Oracle.updatePrice(deployer,"ALEX","nothing",500000000);
        oracleresult.expectOk()

        oracleresult = Oracle.updatePrice(deployer,"USDA","nothing",500000000);
        oracleresult.expectOk()

        // Deployer creates the pool
        result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectOk().expectBool(true);

        // Existing Pool
        result = CRPTest.createPool(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress,  5000000, 10000000);
        result.expectErr().expectUint(2000);

        // Invalid Pool Access
        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, gAlexUsdaPoolAddress, ayusdaAddress, 5000000, 10000000);
        result.expectErr().expectUint(2001);

        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 5000000, 10000000);
        result.expectOk().expectBool(true);

        result = CRPTest.addToPosition(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 0, 0);
        result.expectErr().expectUint(2003);

        result = CRPTest.addToPosition(wallet_2, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 5000000, 10000000);
        result.expectErr().expectUint(3001);

        // Transfer Error 
        result = CRPTest.reducePosition(deployer, gAlexTokenAddress, usdaTokenAddress, ayusdaAddress, 0);
        result.expectErr().expectUint(3001);

        // dY = 0 
        // result = FWPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, testWeightX, testWeightY,  0);
        // result.expectErr();

        result = CRPTest.swapXForY(deployer, gAlexTokenAddress, usdaTokenAddress, expiry, 200000000000);
        result.expectErr().expectUint(1001);

        
    },
});