import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  contractPrincipalCV,
  makeContractCall,
  PostConditionMode,
  uintCV,
} from '@stacks/transactions';
import { principalCV } from '@stacks/transactions/dist/clarity/types/principalCV';

import { getDeployerPK, getUserPK, network } from './wallet';
import { wait_until_confirmation } from './utils';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

export const launchCreate = async (
  token: string,
  ticket: string,
  fee_to_address: string,
  amount_per_ticket: number,
  wstx_per_ticket_in_fixed: number,
  registration_start: number,
  registration_end: number,
  claim_end: number,
  activation_threshold: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[Launch] create-pool...',
    token,
    ticket,
    fee_to_address,
    amount_per_ticket,
    wstx_per_ticket_in_fixed,
    registration_start,
    registration_end,
    claim_end,
    activation_threshold,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-launchpad',
    functionName: 'create-pool',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), ticket),
      principalCV(fee_to_address),
      uintCV(amount_per_ticket),
      uintCV(wstx_per_ticket_in_fixed),
      uintCV(registration_start),
      uintCV(registration_end),
      uintCV(claim_end),
      uintCV(activation_threshold),
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

export const launchAddToPosition = async (token: string, tickets: number) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[Launch] add-to-position...', token, tickets);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-launchpad',
    functionName: 'add-to-position',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(tickets),
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

export const launchRegister = async (
  token: string,
  ticket: string,
  ticket_amount: number,
  deployer = true,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[Launch] register...', token, ticket, ticket_amount);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-launchpad',
    functionName: 'register',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), ticket),
      uintCV(ticket_amount),
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
export const launchGetSubscriberAtToken = async (
  token: string,
  user_id: string,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[Launch] get-subscriber-at-token-or-default...', token, user_id);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-launchpad',
    functionName: 'get-subscriber-at-token-or-default',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(user_id),
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

export const launchGetTokenDetails = async (token: string) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[Launch] get-token-details...', token);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'alex-launchpad',
    functionName: 'get-token-details',
    functionArgs: [contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token)],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};
