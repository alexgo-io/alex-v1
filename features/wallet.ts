import { broadcastTransaction, makeSTXTokenTransfer } from '@stacks/transactions';
import BigNum from 'bn.js';
import { StacksMocknet } from '@stacks/network/dist';
import { generateWallet } from '@stacks/wallet-sdk/dist';

import {
  DEPLOYER_ACCOUNT_ADDRESS,
  DEPLOYER_ACCOUNT_PASSWORD,
  DEPLOYER_ACCOUNT_SECRET,
  STACKS_API_URL,
  USER_ACCOUNT_PASSWORD,
  USER_ACCOUNT_SECRET,
} from './constants';
import { wait_until_confirmation } from './utils';

export const getDeployerPK = async () => {
  const wallet = await generateWallet({
    secretKey: DEPLOYER_ACCOUNT_SECRET(),
    password: DEPLOYER_ACCOUNT_PASSWORD(),
  });
  const privateKey = wallet.accounts[0].stxPrivateKey;
  return privateKey;
};

export const getUserPK = async () => {
  const wallet = await generateWallet({
    secretKey: USER_ACCOUNT_SECRET(),
    password: USER_ACCOUNT_PASSWORD(),
  });
  const privateKey = wallet.accounts[0].stxPrivateKey;
  return privateKey;
};

// const network = new StacksRegtest({
export const network = new StacksMocknet({
  // const network = new StacksMainnet({
  url: STACKS_API_URL(),
});

export const genesis_transfer = async () => {
  console.log('genesis-transfer...');

  const txOptions = {
    recipient: DEPLOYER_ACCOUNT_ADDRESS(),
    amount: new BigNum(1000000000000000),
    senderKey:
      '21d43d2ae0da1d9d04cfcaac7d397a33733881081f0b2cd038062cf0ccbb752601',
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
