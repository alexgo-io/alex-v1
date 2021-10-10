const {
  getDeployerPK, getUserPK, network
} = require('./wallet');
const {
  makeContractCall,
  callReadOnlyFunction,
  AnchorMode,
  PostConditionMode,
  uintCV,
  contractPrincipalCV,
  broadcastTransaction,
  ClarityType
} = require('@stacks/transactions');
const {wait_until_confirmation} = require('./utils');
const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');

const fwpCreate = async (tokenX, tokenY, weightX, weightY, poolToken, multiSig, dx, dy) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] create-pool...', tokenX, tokenY, weightX, weightY, poolToken, multiSig, dx, dy);
  const privateKey = await getDeployerPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'create-pool',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
          uintCV(weightX),
          uintCV(weightY),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, poolToken),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, multiSig),
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
}

const fwpAddToPosition = async (tokenX, tokenY, weightX, weightY, poolToken, dx, dy) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] add-to-position...', tokenX, tokenY, weightX, weightY, poolToken, dx, dy);
  const privateKey = await getUserPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'add-to-position',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
          uintCV(weightX),
          uintCV(weightY),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, poolToken),
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
}

const fwpReducePosition = async (tokenX, tokenY, weightX, weightY, poolToken, percent) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] reduce-position...', tokenX, tokenY, weightX, weightY, poolToken, percent);
  const privateKey = await getUserPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'reduce-position',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
          uintCV(weightX),
          uintCV(weightY),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, poolToken),
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
}

const printResult = (result)=>{
  if(result.type === ClarityType.ResponseOk){
      if(result.value.type == ClarityType.UInt){
          console.log(result.value);
      }else if(result.value.type == ClarityType.Tuple){
          console.log('|');
          for (const key in result.value.data) {
              console.log('---',key,':',result.value.data[key]);
          }
      }
  }
}

const fwpGetXGivenPrice = async (tokenX, tokenY, weightX, weightY, price) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] get-x-given-price...', tokenX, tokenY, weightX, weightY, price);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'fixed-weight-pool',
    functionName: 'get-x-given-price',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),     
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(price)
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

const fwpGetYgivenX = async (tokenX, tokenY, weightX, weightY, dx) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] get-y-given-x...', tokenX, tokenY, weightX, weightY, dx);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'fixed-weight-pool',
    functionName: 'get-y-given-x',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),     
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(dx)
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

const fwpSwapXforY = async (tokenX, tokenY, weightX, weightY, dx) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] swap-x-for-y...', tokenX, tokenY, weightX, weightY, dx);
  const privateKey = await getUserPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'swap-x-for-y',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
          uintCV(weightX),
          uintCV(weightY),          
          uintCV(dx)
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

const fwpSwapYforX = async (tokenX, tokenY, weightX, weightY, dy) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] swap-y-for-x...', tokenX, tokenY, weightX, weightY, dy);
  const privateKey = await getUserPK();
  const txOptions = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'swap-y-for-x',
      functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
          uintCV(weightX),
          uintCV(weightY),          
          uintCV(dy)
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

const fwpGetXgivenY = async (tokenX, tokenY, weightX, weightY, dy) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] get-x-given-y...', tokenX, tokenY, weightX, weightY, dy);
  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'fixed-weight-pool',
    functionName: 'get-x-given-y',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),     
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(dy)
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

const fwpGetYGivenPrice = async (tokenX, tokenY, weightX, weightY, price) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] get-y-given-price...', tokenX, tokenY, weightX, weightY, price);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'fixed-weight-pool',
    functionName: 'get-y-given-price',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),     
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
      uintCV(weightX),
      uintCV(weightY),
      uintCV(price)
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

const fwpGetPoolDetails = async (tokenX, tokenY, weightX, weightY) => {
  console.log('--------------------------------------------------------------------------');
  console.log('[FWP] get-pool-details...]', tokenX, tokenY, weightX, weightY);

  const options = {
    contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    contractName: 'fixed-weight-pool',
    functionName: 'get-pool-details',
    functionArgs: [
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenX),     
      contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, tokenY),
      uintCV(weightX),
      uintCV(weightY)
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

exports.fwpCreate = fwpCreate;
exports.fwpAddToPosition = fwpAddToPosition;
exports.fwpReducePosition = fwpReducePosition;
exports.fwpGetXGivenPrice = fwpGetXGivenPrice;
exports.fwpGetYGivenPrice = fwpGetYGivenPrice;
exports.fwpGetPoolDetails = fwpGetPoolDetails;
exports.fwpGetYgivenX = fwpGetYgivenX;
exports.fwpGetXgivenY = fwpGetXgivenY;
exports.fwpSwapXforY = fwpSwapXforY;
exports.fwpSwapYforX = fwpSwapYforX;
