
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.10.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';



/**
 * Collateral Rebalancing Pool Test Cases
 * 
 * 1. Borrower puts collateral to the pool and mint the ayToken
 * 
 * 2. Add Liquidity to the pool
 * 
 * 3. Set platform fee and collect
 */


Clarinet.test({
    name: "collateral-rebalancing-pool Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {


    },
});
