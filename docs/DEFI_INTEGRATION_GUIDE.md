# ALEX DeFi Integration Guide

A comprehensive guide for integrating with ALEX, the leading DeFi protocol on Stacks.

## Table of Contents

1. [Overview](#overview)
2. [Swap Integration](#swap-integration)
3. [Liquidity Pool Integration](#liquidity-pool-integration)
4. [Orderbook Trading](#orderbook-trading)
5. [Yield Farming](#yield-farming)
6. [Price Feeds](#price-feeds)
7. [Best Practices](#best-practices)

## Overview

ALEX provides a complete DeFi ecosystem on Stacks:

- **AMM Swaps**: Automated market making for token swaps
- **Orderbook**: Limit order trading
- **Liquidity Pools**: Earn fees by providing liquidity
- **Yield Farming**: Stake LP tokens for ALEX rewards
- **Launchpad**: Token launches and IDOs

### Core Contracts

```typescript
const ALEX_CONTRACTS = {
  // AMM Core
  ammSwap: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.amm-swap-pool-v1-1',
  ammRegistry: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.amm-registry-v2-01',
  
  // Orderbook
  orderbook: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.alex-orderbook-v1',
  
  // Farming
  yieldFarm: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.alex-farming-v1',
  
  // Tokens
  alexToken: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-alex',
  autoAlex: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.auto-alex-v3'
};
```

## Swap Integration

### Get Swap Quote

```typescript
import { callReadOnlyFunction, cvToValue, uintCV } from '@stacks/transactions';
import { StacksMainnet } from '@stacks/network';

interface SwapQuote {
  amountOut: bigint;
  priceImpact: number;
  fee: bigint;
}

async function getSwapQuote(
  tokenIn: string,
  tokenOut: string,
  amountIn: bigint
): Promise<SwapQuote> {
  const network = new StacksMainnet();
  
  const result = await callReadOnlyFunction({
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'amm-swap-pool-v1-1',
    functionName: 'get-helper',
    functionArgs: [
      contractPrincipalCV(tokenIn.split('.')[0], tokenIn.split('.')[1]),
      contractPrincipalCV(tokenOut.split('.')[0], tokenOut.split('.')[1]),
      uintCV(amountIn)
    ],
    network,
    senderAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM'
  });

  const value = cvToValue(result);
  return {
    amountOut: BigInt(value.dx),
    priceImpact: calculatePriceImpact(amountIn, BigInt(value.dx)),
    fee: BigInt(value.fee)
  };
}

function calculatePriceImpact(amountIn: bigint, amountOut: bigint): number {
  // Simplified price impact calculation
  return Number((amountIn - amountOut) * 10000n / amountIn) / 100;
}
```

### Execute Swap

```typescript
import { openContractCall } from '@stacks/connect';
import {
  contractPrincipalCV,
  uintCV,
  someCV,
  noneCV,
  PostConditionMode,
  makeContractFungiblePostCondition,
  FungibleConditionCode
} from '@stacks/transactions';

interface SwapParams {
  tokenIn: string;
  tokenOut: string;
  amountIn: bigint;
  minAmountOut: bigint;
  senderAddress: string;
}

async function executeSwap(params: SwapParams) {
  const [tokenInAddr, tokenInName] = params.tokenIn.split('.');
  const [tokenOutAddr, tokenOutName] = params.tokenOut.split('.');

  // Create post-conditions to protect user
  const postConditions = [
    makeContractFungiblePostCondition(
      params.senderAddress,
      FungibleConditionCode.Equal,
      params.amountIn,
      `${params.tokenIn}::${tokenInName}`
    ),
    makeContractFungiblePostCondition(
      'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.amm-swap-pool-v1-1',
      FungibleConditionCode.GreaterEqual,
      params.minAmountOut,
      `${params.tokenOut}::${tokenOutName}`
    )
  ];

  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'amm-swap-pool-v1-1',
    functionName: 'swap-helper',
    functionArgs: [
      contractPrincipalCV(tokenInAddr, tokenInName),
      contractPrincipalCV(tokenOutAddr, tokenOutName),
      uintCV(params.amountIn),
      someCV(uintCV(params.minAmountOut))
    ],
    postConditionMode: PostConditionMode.Deny,
    postConditions,
    onFinish: (data) => {
      console.log('Swap TX:', data.txId);
    }
  });
}
```

### Multi-Hop Swaps

```typescript
interface SwapRoute {
  path: string[];
  expectedOutput: bigint;
}

async function findBestRoute(
  tokenIn: string,
  tokenOut: string,
  amountIn: bigint
): Promise<SwapRoute> {
  // Common intermediate tokens for routing
  const intermediates = [
    'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-wstx',
    'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-alex',
    'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.token-usda'
  ];

  let bestRoute: SwapRoute = {
    path: [tokenIn, tokenOut],
    expectedOutput: 0n
  };

  // Check direct swap
  try {
    const directQuote = await getSwapQuote(tokenIn, tokenOut, amountIn);
    bestRoute.expectedOutput = directQuote.amountOut;
  } catch {
    // Direct path not available
  }

  // Check 2-hop routes through intermediates
  for (const intermediate of intermediates) {
    if (intermediate === tokenIn || intermediate === tokenOut) continue;

    try {
      const quote1 = await getSwapQuote(tokenIn, intermediate, amountIn);
      const quote2 = await getSwapQuote(intermediate, tokenOut, quote1.amountOut);

      if (quote2.amountOut > bestRoute.expectedOutput) {
        bestRoute = {
          path: [tokenIn, intermediate, tokenOut],
          expectedOutput: quote2.amountOut
        };
      }
    } catch {
      // Route not available
    }
  }

  return bestRoute;
}
```

## Liquidity Pool Integration

### Add Liquidity

```typescript
interface AddLiquidityParams {
  tokenA: string;
  tokenB: string;
  amountA: bigint;
  amountB: bigint;
  minLPTokens: bigint;
}

async function addLiquidity(params: AddLiquidityParams) {
  const [tokenAAddr, tokenAName] = params.tokenA.split('.');
  const [tokenBAddr, tokenBName] = params.tokenB.split('.');

  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'amm-swap-pool-v1-1',
    functionName: 'add-to-position',
    functionArgs: [
      contractPrincipalCV(tokenAAddr, tokenAName),
      contractPrincipalCV(tokenBAddr, tokenBName),
      uintCV(params.amountA),
      someCV(uintCV(params.amountB))
    ],
    postConditionMode: PostConditionMode.Deny,
    onFinish: (data) => {
      console.log('Add Liquidity TX:', data.txId);
    }
  });
}
```

### Remove Liquidity

```typescript
interface RemoveLiquidityParams {
  tokenA: string;
  tokenB: string;
  lpTokenAmount: bigint;
  minAmountA: bigint;
  minAmountB: bigint;
}

async function removeLiquidity(params: RemoveLiquidityParams) {
  const [tokenAAddr, tokenAName] = params.tokenA.split('.');
  const [tokenBAddr, tokenBName] = params.tokenB.split('.');

  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'amm-swap-pool-v1-1',
    functionName: 'reduce-position',
    functionArgs: [
      contractPrincipalCV(tokenAAddr, tokenAName),
      contractPrincipalCV(tokenBAddr, tokenBName),
      uintCV(params.lpTokenAmount)
    ],
    postConditionMode: PostConditionMode.Deny,
    onFinish: (data) => {
      console.log('Remove Liquidity TX:', data.txId);
    }
  });
}
```

### Get Pool Information

```typescript
interface PoolInfo {
  tokenA: string;
  tokenB: string;
  reserveA: bigint;
  reserveB: bigint;
  totalSupply: bigint;
  fee: number;
}

async function getPoolInfo(tokenA: string, tokenB: string): Promise<PoolInfo> {
  const network = new StacksMainnet();
  const [tokenAAddr, tokenAName] = tokenA.split('.');
  const [tokenBAddr, tokenBName] = tokenB.split('.');

  const result = await callReadOnlyFunction({
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'amm-swap-pool-v1-1',
    functionName: 'get-pool-details',
    functionArgs: [
      contractPrincipalCV(tokenAAddr, tokenAName),
      contractPrincipalCV(tokenBAddr, tokenBName)
    ],
    network,
    senderAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM'
  });

  const value = cvToValue(result);
  return {
    tokenA,
    tokenB,
    reserveA: BigInt(value['balance-x']),
    reserveB: BigInt(value['balance-y']),
    totalSupply: BigInt(value['total-supply']),
    fee: Number(value['fee-rate-x']) / 10000
  };
}
```

## Orderbook Trading

### Place Limit Order

```typescript
interface LimitOrder {
  tokenGive: string;
  tokenGet: string;
  amountGive: bigint;
  price: bigint; // Price in basis points
  expiry: number; // Block height
}

async function placeLimitOrder(order: LimitOrder) {
  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'alex-orderbook-v1',
    functionName: 'create-order',
    functionArgs: [
      contractPrincipalCV(...order.tokenGive.split('.')),
      contractPrincipalCV(...order.tokenGet.split('.')),
      uintCV(order.amountGive),
      uintCV(order.price),
      uintCV(order.expiry)
    ],
    onFinish: (data) => {
      console.log('Order placed:', data.txId);
    }
  });
}
```

### Cancel Order

```typescript
async function cancelOrder(orderId: number) {
  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'alex-orderbook-v1',
    functionName: 'cancel-order',
    functionArgs: [uintCV(orderId)],
    onFinish: (data) => {
      console.log('Order cancelled:', data.txId);
    }
  });
}
```

## Yield Farming

### Stake LP Tokens

```typescript
interface StakeParams {
  poolId: number;
  amount: bigint;
  lockPeriod: number; // In cycles
}

async function stakeLPTokens(params: StakeParams) {
  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'alex-farming-v1',
    functionName: 'stake',
    functionArgs: [
      uintCV(params.poolId),
      uintCV(params.amount),
      uintCV(params.lockPeriod)
    ],
    onFinish: (data) => {
      console.log('Staked:', data.txId);
    }
  });
}
```

### Claim Rewards

```typescript
async function claimRewards(poolId: number) {
  openContractCall({
    network: 'mainnet',
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'alex-farming-v1',
    functionName: 'claim-rewards',
    functionArgs: [uintCV(poolId)],
    onFinish: (data) => {
      console.log('Rewards claimed:', data.txId);
    }
  });
}
```

### Get Pending Rewards

```typescript
async function getPendingRewards(
  userAddress: string,
  poolId: number
): Promise<bigint> {
  const network = new StacksMainnet();

  const result = await callReadOnlyFunction({
    contractAddress: 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
    contractName: 'alex-farming-v1',
    functionName: 'get-pending-rewards',
    functionArgs: [
      standardPrincipalCV(userAddress),
      uintCV(poolId)
    ],
    network,
    senderAddress: userAddress
  });

  return BigInt(cvToValue(result));
}
```

## Price Feeds

### Get Token Price

```typescript
interface TokenPrice {
  priceUSD: number;
  priceSTX: number;
  change24h: number;
}

async function getTokenPrice(token: string): Promise<TokenPrice> {
  // Use ALEX API for price data
  const response = await fetch(
    `https://api.alexgo.io/v1/price?token=${encodeURIComponent(token)}`
  );
  const data = await response.json();

  return {
    priceUSD: data.price_usd,
    priceSTX: data.price_stx,
    change24h: data.change_24h
  };
}

// Calculate USD value of holdings
async function getPortfolioValue(
  holdings: Map<string, bigint>
): Promise<number> {
  let totalValue = 0;

  for (const [token, amount] of holdings) {
    const price = await getTokenPrice(token);
    const decimals = await getTokenDecimals(token);
    const value = Number(amount) / Math.pow(10, decimals) * price.priceUSD;
    totalValue += value;
  }

  return totalValue;
}
```

## Best Practices

### 1. Always Use Post-Conditions

```typescript
// Protect users from unexpected token transfers
function createSwapPostConditions(
  userAddress: string,
  tokenIn: string,
  amountIn: bigint,
  tokenOut: string,
  minAmountOut: bigint
) {
  return [
    makeStandardFungiblePostCondition(
      userAddress,
      FungibleConditionCode.Equal,
      amountIn,
      tokenIn
    ),
    makeContractFungiblePostCondition(
      'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM',
      'amm-swap-pool-v1-1',
      FungibleConditionCode.GreaterEqual,
      minAmountOut,
      tokenOut
    )
  ];
}
```

### 2. Handle Slippage

```typescript
function calculateMinOutput(
  expectedOutput: bigint,
  slippageBps: number = 100 // 1%
): bigint {
  return expectedOutput * BigInt(10000 - slippageBps) / 10000n;
}

// Usage
const quote = await getSwapQuote(tokenIn, tokenOut, amountIn);
const minOutput = calculateMinOutput(quote.amountOut, 50); // 0.5% slippage
```

### 3. Check Pool Liquidity

```typescript
async function hasEnoughLiquidity(
  tokenA: string,
  tokenB: string,
  amountIn: bigint
): Promise<boolean> {
  const pool = await getPoolInfo(tokenA, tokenB);
  
  // Ensure swap doesn't exceed 10% of pool reserves
  const maxSwap = pool.reserveA / 10n;
  return amountIn <= maxSwap;
}
```

### 4. Monitor Transaction Status

```typescript
async function waitForSwapConfirmation(txId: string): Promise<{
  success: boolean;
  amountReceived?: bigint;
}> {
  const apiUrl = 'https://api.mainnet.hiro.so/extended/v1';
  
  // Wait for confirmation
  let tx;
  for (let i = 0; i < 60; i++) {
    const response = await fetch(`${apiUrl}/tx/${txId}`);
    tx = await response.json();
    
    if (tx.tx_status !== 'pending') break;
    await new Promise(r => setTimeout(r, 10000));
  }

  if (tx.tx_status === 'success') {
    // Parse events to get actual amount received
    const transferEvent = tx.events?.find(
      (e: any) => e.event_type === 'fungible_token_transfer'
    );
    
    return {
      success: true,
      amountReceived: transferEvent ? BigInt(transferEvent.amount) : undefined
    };
  }

  return { success: false };
}
```

## Additional Resources

- [ALEX Documentation](https://docs.alexgo.io/)
- [ALEX API Reference](https://api.alexgo.io/docs)
- [Stacks.js SDK](https://stacks.js.org/)

---

*This guide is maintained by the community. Contributions welcome!*
