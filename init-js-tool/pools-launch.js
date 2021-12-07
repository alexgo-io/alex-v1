const {
  getDeployerPK, getUserPK, network
} = require('./wallet');
const {
  makeContractCall,
  callReadOnlyFunction,
  AnchorMode,
  PostConditionMode,
  uintCV,
  someCV,
  stringAsciiCV,
  contractPrincipalCV,
  broadcastTransaction,
  ClarityType
} = require('@stacks/transactions');
const {wait_until_confirmation} = require('./utils');
const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');

const launchCreate = async (token, ticket, fee_to_address, amount_per_ticket, wstx_per_ticket_in_fixed, registration_start, activation_delay, activation_threshold) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[Launch] create-pool...', token, ticket, fee_to_address, amount_per_ticket, wstx_per_ticket_in_fixed, registration_start, activation_delay, activation_threshold);
  const privateKey = await getDeployerPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'alex-launchpad',
      functionName: 'create-pool',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, ticket),
          principalCV(fee_to_address),
          uintCV(amount_per_ticket),
          uintCV(wstx_per_ticket_in_fixed),
          uintCV(registration_start),
          uintCV(activation_delay),
          uintCV(activation_threshold)
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
}

const launchAddToPosition = async (token, tickets) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[Launch] add-to-position...', token, tickets);
  const privateKey = await getDeployerPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'alex-launchpad',
      functionName: 'add-to-position',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
          uintCV(tickets)
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
}

const launchRegister = async (token, ticket, ticket_amount, deployer=true) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[Launch] register...', token, ticket, ticket_amount);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'alex-launchpad',
      functionName: 'register',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, ticket),
          uintCV(ticket_amount)
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
}

const launchGetSubscriberAtToken = async (token, user_id) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[Launch] get-subscriber-at-token-or-default...', token, user_id);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'alex-launchpad',
    functionName: 'get-subscriber-at-token-or-default',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
      uintCV(user_id)
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
    
  } catch (error) {
    console.log(error);
  }
};

const launchGetTokenDetails = async (token) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[Launch] get-token-details...', token);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'alex-launchpad',
    functionName: 'get-token-details',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token)
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
    
  } catch (error) {
    console.log(error);
  }
};

exports.launchCreate = launchCreate;
exports.launchAddToPosition = launchAddToPosition;
exports.launchRegister = launchRegister;
exports.launchGetSubscriberAtToken = launchGetSubscriberAtToken;
exports.launchGetTokenDetails = launchGetTokenDetails;
