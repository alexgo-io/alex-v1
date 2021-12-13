import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  ClarityType,
  contractPrincipalCV,
  makeContractCall,
  PostConditionMode,
  someCV,
  uintCV,
} from '@stacks/transactions';

import { getDeployerPK, getUserPK, network } from './wallet';
import { wait_until_confirmation } from './utils';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

export const ytpCreate = async (
  expiry: number,
  yiedToken: string,
  token: string,
  poolToken: string,
  multiSig: string,
  dx: number,
  dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[YTP] create-pool...',
    expiry,
    yiedToken,
    token,
    poolToken,
    multiSig,
    dx,
    dy,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'create-pool',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), multiSig),
      uintCV(dx),
      uintCV(dy),
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

export const ytpAddToPosition = async (
  expiry: number,
  yiedToken: string,
  token: string,
  poolToken: string,
  dx: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] add-to-position...', yiedToken, token, poolToken, dx);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'add-to-position',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
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

export const ytpReducePosition = async (
  expiry: number,
  yiedToken: string,
  token: string,
  poolToken: string,
  percent: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] reduce-position...', yiedToken, token, poolToken, percent);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'reduce-position',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
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

export const ytpGetPrice = async (expiry: number, yieldToken: string) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-price...', yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-price',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const ytpGetYield = async (expiry: number, yieldToken: string) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-yield...', yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-yield',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const ytpSwapXforY = async (
  expiry: number,
  yiedToken: string,
  token: string,
  dx: number,
  min_dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] swap-x-for-y...', yiedToken, token, dx);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'swap-x-for-y',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
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

export const ytpSwapYforX = async (
  expiry: number,
  yiedToken: string,
  token: string,
  dy: number,
  min_dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] swap-y-for-x...', yiedToken, token, dy);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'swap-y-for-x',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
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

export const ytpGetXgivenY = async (
  expiry: number,
  yieldToken: string,
  dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-x-given-y...', yieldToken, dy);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-x-given-y',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const ytpGetYgivenX = async (
  expiry: number,
  yieldToken: string,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-y-given-x...', yieldToken, dx);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-y-given-x',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const ytpGetXgivenYield = async (
  expiry: number,
  yieldToken: string,
  yied: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-x-given-yield...', yieldToken, yied);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-x-given-yield',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(yied),
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

export const ytpGetYgivenYield = async (
  expiry: number,
  yieldToken: string,
  yied: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-y-given-yield...', yieldToken, yied);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-y-given-yield',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(yied),
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

export const ytpGetPositionGivenBurn = async (
  expiry: number,
  yieldToken: string,
  shares: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-position-given-burn...', yieldToken, shares);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-position-given-burn',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const ytpGetPoolDetails = async (expiry: number, yieldToken: string) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[YTP] get-pool-details...', yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'yield-token-pool',
    functionName: 'get-pool-details',
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
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

export const printResult = (result: {
  type: ClarityType;
  value: any;
}) => {
  if (result.type === ClarityType.ResponseOk) {
    if (result.value.type == ClarityType.UInt) {
      console.log(result.value);
    } else if (result.value.type == ClarityType.Tuple) {
      console.log('|');
      for (const key in result.value.data) {
        console.log('---', key, ':', result.value.data[key]);
      }
    }
  }
};
