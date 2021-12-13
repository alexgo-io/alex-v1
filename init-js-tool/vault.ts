import {
  AnchorMode,
  broadcastTransaction,
  bufferCV,
  bufferCVFromString,
  callReadOnlyFunction,
  contractPrincipalCV,
  IntCV,
  makeContractCall,
  makeSTXTokenTransfer,
  PostConditionMode,
  someCV,
  uintCV,
} from '@stacks/transactions';
import { principalCV } from '@stacks/transactions/dist/clarity/types/principalCV';
import {
  ClarityType,
  ResponseOkCV,
} from '@stacks/transactions/dist/clarity';

import { getDeployerPK, getUserPK, network } from './wallet';
import { wait_until_confirmation } from './utils';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

export const flashloan = async (
  loan_contract: string,
  token: string,
  amount: number,
  expiry: number,
) => {
  console.log('[Vault] flash-loan...', loan_contract, token, amount, expiry);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-vault',
    functionName: 'flash-loan',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), loan_contract),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(amount),
      someCV(bufferCV(Buffer.from('0' + expiry.toString(16), 'hex'))),
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
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const mint_sft = async (
  token: string,
  token_id: number,
  amount: number,
  recipient: string,
) => {
  console.log('[Token] mint...', token, recipient, amount);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: token,
    functionName: 'mint-fixed',
    functionArgs: [uintCV(token_id), uintCV(amount), principalCV(recipient)],
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
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const mint_ft = async (
  token: string,
  amount: number,
  recipient: string,
) => {
  console.log('[Token] mint...', token, recipient, amount);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: token,
    functionName: 'mint-fixed',
    functionArgs: [uintCV(amount), principalCV(recipient)],
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
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const burn = async (
  token: string,
  recipient: string,
  amount: number,
) => {
  console.log('[Token] burn...', token, recipient, amount);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: token,
    functionName: 'burn-fixed',
    functionArgs: [uintCV(amount), principalCV(recipient)],
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
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const transfer = async (
  token: string,
  recipient: string,
  amount: number,
  deployer: boolean = false,
) => {
  console.log('[Token] transfer...', token, recipient, amount);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: token,
    functionName: 'transfer-fixed',
    functionArgs: [
      uintCV(amount),
      principalCV(
        deployer ? DEPLOYER_ACCOUNT_ADDRESS() : USER_ACCOUNT_ADDRESS(),
      ),
      principalCV(recipient),
      someCV(bufferCVFromString('')),
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
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const transferSTX = async (recipient: string, amount: number) => {
  console.log('transferSTX...', recipient, amount);

  const txOptions = {
    recipient: recipient,
    amount: amount,
    senderKey: await getDeployerPK(),
    network: network,
  } as any;
  // FIXME: typescript migrate;

  try {
    const transaction = await makeSTXTokenTransfer(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

export const balance = async (
  token: string,
  owner: string,
): Promise<ResponseOkCV<IntCV>> => {
  console.log('[Token] get-balance...', token, owner);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: token,
    functionName: 'get-balance-fixed',
    functionArgs: [principalCV(owner)],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    const value = (await callReadOnlyFunction(options))!;
    return value as ResponseOkCV<IntCV>;
  } catch (error) {
    console.log(error);
    return {
      type: ClarityType.ResponseOk,
      value: {
        type: ClarityType.Int,
        value: BigInt(0),
      },
    };
  }
};

export const getBalance = async (token: string) => {
  console.log('[VAULT] get-balance...', token);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-vault',
    functionName: 'get-balance-fixed',
    functionArgs: [contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token)],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    const result = await callReadOnlyFunction(options);
    console.log(result);
  } catch (error) {
    console.log(error);
  }
};
