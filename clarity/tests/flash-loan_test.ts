import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { FWPTestAgent1 } from './models/alex-tests-fixed-weight-pool.ts';

const gAlexTokenAddress =
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex';
const usdaTokenAddress = 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-usda';
const ayusdaAddress = 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-ayusda';
const gAlexUsdaPoolAddress =
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.pool-token-alex-usda';
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
          types.principal(usdaTokenAddress),
          types.uint(testWeightX),
          types.uint(testWeightY),
          types.principal(gAlexUsdaPoolAddress),
          types.principal(alexVaultAddress),
          types.uint(balanceX * 1000000),
          types.uint(balanceY * 1000000),
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'transfer-to-vault',
        [
          types.uint(100000000),
          types.principal(wallet_1.address),
          types.principal(usdaTokenAddress),
          types.none()
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'transfer-to-vault',
        [
          types.uint(100000000),
          types.principal(wallet_1.address),
          types.principal(usdaTokenAddress),
          types.none()
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'flash-loan-1',
        [
          types.principal(testFlashLoanUser),
          types.principal(gAlexTokenAddress),
          types.uint(10000),
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'flash-loan-2',
        [
          types.principal(testFlashLoanUser),
          types.principal(gAlexTokenAddress),
          types.principal(usdaTokenAddress),
          types.uint(10000),
          types.uint(20000),
        ],
        deployer.address
      ),
      Tx.contractCall(
        'alex-vault',
        'flash-loan-3',
        [
          types.principal(testFlashLoanUser),
          types.principal(gAlexTokenAddress),
          types.principal(usdaTokenAddress),
          types.principal(ayusdaAddress),
          types.uint(10000),
          types.uint(20000),
          types.uint(30000),
        ],
        deployer.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectOk();
    block.receipts[3].result.expectOk();
    block.receipts[4].result.expectErr(); // will trigger error cause the token has been swapped 
    block.receipts[5].result.expectErr(); // will trigger error cause there are not balance in ayusdaAddress
  },
});
