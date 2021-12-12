import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  contractPrincipalCV,
  makeContractCall,
  PostConditionMode,
  someCV,
  uintCV,
} from '@stacks/transactions';

import { getDeployerPK, getUserPK, network } from './wallet';
import { wait_until_confirmation } from './utils';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

export const crpCreate = async (
  token: string,
  collateral: string,
  expiry: number,
  yieldToken: string,
  keyToken: string,
  multiSig: string,
  ltv_0: number,
  conversion_ltv: number,
  bs_vol: number,
  moving_average: number,
  token_to_maturity: number,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] create-pool...',
    token,
    collateral,
    expiry,
    yieldToken,
    keyToken,
    multiSig,
    ltv_0,
    conversion_ltv,
    bs_vol,
    moving_average,
    token_to_maturity,
    dx,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'create-pool',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), keyToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), multiSig),
      uintCV(ltv_0),
      uintCV(conversion_ltv),
      uintCV(bs_vol),
      uintCV(moving_average),
      uintCV(token_to_maturity),
      uintCV(dx),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpAddToPostionAndSwitch = async (
  token: string,
  collateral: string,
  expiry: number,
  yieldToken: string,
  keyToken: string,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] add-to-position-and-switch...',
    token,
    collateral,
    expiry,
    yieldToken,
    keyToken,
    dx,
  );
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'add-to-position-and-switch',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), keyToken),
      uintCV(dx),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpAddToPostion = async (
  token: string,
  collateral: string,
  expiry: number,
  yieldToken: string,
  keyToken: string,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] add-to-position..',
    token,
    collateral,
    expiry,
    yieldToken,
    keyToken,
    dx,
  );
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'add-to-position',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), keyToken),
      uintCV(dx),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpReducePostionYield = async (
  token: string,
  collateral: string,
  expiry: number,
  yieldToken: string,
  percent: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] reduce-position-yield..',
    token,
    collateral,
    expiry,
    yieldToken,
    percent,
  );
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'reduce-position-yield',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(percent),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpReducePostionKey = async (
  token: string,
  collateral: string,
  expiry: number,
  keyToken: string,
  percent: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] reduce-position-key..',
    token,
    collateral,
    expiry,
    keyToken,
    percent,
  );

  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'reduce-position-key',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), keyToken),
      uintCV(percent),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpSwapXforY = async (
  token: string,
  collateral: string,
  expiry: number,
  dx: number,
  min_dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] swap-x-for-y...', token, collateral, expiry, dx);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'swap-x-for-y',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(dx),
      someCV(uintCV(min_dy)),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpSwapYforX = async (
  token: string,
  collateral: string,
  expiry: number,
  dy: number,
  min_dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] swap-y-for-x...', token, collateral, expiry, dy);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'swap-y-for-x',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(dy),
      someCV(uintCV(min_dx)),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetLtv = async (
  token: string,
  collateral: string,
  expiry: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-ltv...', token, collateral, expiry);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-ltv',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetXgivenY = async (
  token: string,
  collateral: string,
  expiry: number,
  dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-x-given-y...', token, collateral, expiry, dy);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-x-given-y',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(dy),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetYgivenX = async (
  token: string,
  collateral: string,
  expiry: number,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-y-given-x...', token, collateral, expiry, dx);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-y-given-x',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(dx),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetYgivenPrice = async (
  token: string,
  collateral: string,
  expiry: number,
  price: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-y-given-price',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(price),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetXgivenPrice = async (
  token: string,
  collateral: string,
  expiry: number,
  price: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-x-given-price',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(price),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetPositionGivenBurnKey = async (
  token: string,
  collateral: string,
  expiry: number,
  shares: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[CRP] get-position-given-burn-key...',
    token,
    collateral,
    expiry,
    shares,
  );

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-position-given-burn-key',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(shares),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetPoolValueInToken = async (
  token: string,
  collateral: string,
  expiry: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-pool-value-in-token...', token, collateral, expiry);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-pool-value-in-token',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetPoolDetails = async (
  token: string,
  collateral: string,
  expiry: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-pool-details...', token, collateral, expiry);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-pool-details',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetSpot = async (token: string, collateral: string) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[CRP] get-spot...', token, collateral);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-spot',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const crpGetWeightY = async (
  token: string,
  collateral: string,
  expiry: number,
  strike: number,
  bs_vol: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    'Getting CRP Weight-Y...',
    token,
    collateral,
    expiry,
    strike,
    bs_vol,
  );

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'collateral-rebalancing-pool',
    functionName: 'get-weight-y',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), collateral),
      uintCV(expiry),
      uintCV(strike),
      uintCV(bs_vol),
    ],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};
