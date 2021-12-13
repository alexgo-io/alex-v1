import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  contractPrincipalCV,
  makeContractCall,
  PostConditionMode,
  stringUtf8CV,
  uintCV,
} from '@stacks/transactions';
import { principalCV } from '@stacks/transactions/dist/clarity/types/principalCV';

import { DEPLOYER_ACCOUNT_ADDRESS } from './constants';
import { wait_until_confirmation } from './utils';
import { getDeployerPK, network } from './wallet';

//   (propose (uint (string-utf8 256) (string-utf8 256) uint uint) (response uint uint))
export const multisigPropose = async (
  contract_name: string,
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
    contract_name,
    start_block_height,
    title,
    url,
    new_fee_rate_x,
    new_fee_rate_y,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'propose',
    functionArgs: [
      uintCV(start_block_height),
      stringUtf8CV(title),
      stringUtf8CV(url),
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

//   (vote-for (<ft-trait> uint uint) (response uint uint))
export const multisigVoteFor = async (
  contract_name: string,
  token: string,
  proposal_id: number,
  amount: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[multisig] vote-for...',
    contract_name,
    token,
    proposal_id,
    amount,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'vote-for',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(proposal_id),
      uintCV(amount),
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

//   (vote-against (<ft-trait> uint uint) (response uint uint))
export const multisigVoteAgainst = async (
  contract_name: string,
  token: string,
  proposal_id: number,
  amount: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[multisig] vote-against...',
    contract_name,
    token,
    proposal_id,
    amount,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'vote-against',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(proposal_id),
      uintCV(amount),
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

//   (end-proposal (uint) (response bool uint))
export const multisigEndProposal = async (
  contract_name: string,
  proposal_id: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[multisig] end-proposal...', contract_name, proposal_id);
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'end-proposal',
    functionArgs: [uintCV(proposal_id)],
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

//   (return-votes-to-member (<ft-trait> uint principal) (response bool uint))
export const multisigReturnVotes = async (
  contract_name: string,
  token: string,
  proposal_id: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log(
    '[multisig] return-votes-to-member...',
    contract_name,
    token,
    proposal_id,
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'return-votes-to-member',
    functionArgs: [
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(proposal_id),
      principalCV(DEPLOYER_ACCOUNT_ADDRESS()),
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

export const multisigGetProposalById = async (
  contract_name: string,
  proposal_id: number,
) => {
  console.log(
    '--------------------------------------------------------------------------',
  );
  console.log('[multisig] get-proposal-by-id...]', contract_name, proposal_id);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: contract_name,
    functionName: 'get-proposal-by-id',
    functionArgs: [uintCV(proposal_id)],
    network: network,
    senderAddress: DEPLOYER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};
