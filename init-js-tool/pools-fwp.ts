import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  ClarityType,
  contractPrincipalCV,
  makeContractCall,
  PostConditionMode,
  someCV,
  stringAsciiCV,
  uintCV,
} from '@stacks/transactions';

import { getDeployerPK, getUserPK, network } from './wallet';
import { wait_until_confirmation } from './utils';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

const contractName = 'fixed-weight-pool';

export const fwpCreate = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  poolToken: string,
  multiSig: string,
  dx: number,
  dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] create-pool...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    poolToken,
    multiSig,
    dx,
    dy,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'create-pool',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpSetOracleEnbled = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] set-oracle-enabled...', tokenX, tokenY, weightX, weightY);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'set-oracle-enabled',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpSetOracleAverage = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  average: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] set-oracle-average...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    average,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'set-oracle-average',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(average),
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

export const fwpAddToPosition = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  poolToken: string,
  dx: number,
  dy: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] add-to-position...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    poolToken,
    dx,
    dy,
  );
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'add-to-position',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
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

export const fwpReducePosition = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  poolToken: string,
  percent: number,
  deployer = false,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] reduce-position...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    poolToken,
    percent,
  );
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'reduce-position',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

const printResult = (result: any) => {
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

export const fwpGetXGivenPrice = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  price: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] get-x-given-price...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    price,
  );

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-x-given-price',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpGetYgivenX = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] get-y-given-x...', tokenX, tokenY, weightX, weightY, dx);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-y-given-x',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpSwapXforY = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  dx: number,
  min_dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] swap-x-for-y...', tokenX, tokenY, weightX, weightY, dx);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'swap-x-for-y',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpSwapYforX = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  dy: number,
  min_dx: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] swap-y-for-x...', tokenX, tokenY, weightX, weightY, dy);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'swap-y-for-x',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpGetXgivenY = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  dy: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] get-x-given-y...', tokenX, tokenY, weightX, weightY, dy);
  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-x-given-y',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpGetYGivenPrice = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  price: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] get-y-given-price...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    price,
  );

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-y-given-price',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const fwpGetPositionGivenBurn = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
  token: string,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[FWP] get-position-given-burn...',
    tokenX,
    tokenY,
    weightX,
    weightY,
    token,
  );

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-position-given-burn',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(token),
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

export const fwpGetPoolDetails = async (
  tokenX: string,
  tokenY: string,
  weightX: number,
  weightY: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[FWP] get-pool-details...]', tokenX, tokenY, weightX, weightY);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contractName,
    functionName: 'get-pool-details',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenX),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), tokenY),
      uintCV(weightX),
      uintCV(weightY),
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

export const multisigProposeWBTCUSDA = async (
  start_block_height: number,
  title: string,
  url: string,
  new_fee_rate_x: number,
  new_fee_rate_y: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[multisig] propose...',
    start_block_height,
    title,
    url,
    new_fee_rate_x,
    new_fee_rate_y,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'multisig-fwp-wbtc-usda-50-50',
    functionName: 'propose',
    functionArgs: [
      uintCV(start_block_height),
      stringAsciiCV(title),
      stringAsciiCV(url),
      uintCV(new_fee_rate_x),
      uintCV(new_fee_rate_y),
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
