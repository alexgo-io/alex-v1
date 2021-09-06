import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';

const gAlexTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex"
const wBTCTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-wbtc"
const ayUsdawBTCPoolTokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-usda-4380-wbtc"
const ayUsda4380TokenAddress = "ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.yield-usda-4380"

const alexVaultAddress = 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.alex-vault';
const testFlashLoanUser =
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.test-flash-loan-user';
/**
 * Flash Loan Testing in Vault implementation.
 *
 * 1. User using Flashloan for 2 tokens
 *
 * 2. User using Flashloan for 3 tokens (two different pools)
 */


const testWeightX = 50000000; //0.5
const testWeightY = 50000000; //0.5
const balanceX = 500000;
const balanceY = 100000;
Clarinet.test({
  name: 'VAULT : Flash Loan Test',
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get('deployer')!;
    let wallet_1 = accounts.get('wallet_1')!;
    let block = chain.mineBlock([
      Tx.contractCall(
        'fixed-weight-pool',
        'create-pool',
        [
          types.principal(gAlexTokenAddress),
          types.principal(wBTCTokenAddress),
          types.uint(testWeightX),
          types.uint(testWeightY),
          types.principal(ayUsdawBTCPoolTokenAddress),
          types.uint(balanceX * 1000000),
          types.uint(balanceY * 1000000),
        ],
        deployer.address
      ),
      Tx.contractCall(
        'token-alex',
        'transfer',
        [
          types.uint(100000000),
          types.principal(deployer.address),
          types.principal(alexVaultAddress),
          types.none()
        ],
        deployer.address
      ),
      Tx.contractCall(
        'token-usda',
        'transfer',
        [
          types.uint(100000000),
          types.principal(deployer.address),
          types.principal(alexVaultAddress),
          types.none()
        ],
        deployer.address
      ),
      Tx.contractCall(
        'yield-usda-4380',
        'mint',
        [
          types.principal(deployer.address),
          types.uint(100000000),
        ],
        deployer.address
      ),

      Tx.contractCall(
        'yield-usda-4380',
        'transfer',
        [
          types.uint(100000000),
          types.principal(deployer.address),
          types.principal(alexVaultAddress),
          types.none()
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'flash-loan',
        [
          types.principal(testFlashLoanUser),
          types.principal(gAlexTokenAddress),
          types.principal(wBTCTokenAddress),
          types.principal(ayUsda4380TokenAddress),
          types.uint(10000),
          types.uint(20000),
          types.uint(30000),
        ],
        deployer.address
      ),
    ]);
    block.receipts.forEach(r => {
      r.result.expectOk();
    });
  },
});


