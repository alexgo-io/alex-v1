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
    bufferCVFromString,
    stringAsciiCV,
    stringUtf8CV,
    contractPrincipalCV,
    broadcastTransaction,
    ClarityType
  } = require('@stacks/transactions');
  const {wait_until_confirmation} = require('./utils');
  const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');
  
  const reserveAddToken = async (token) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] add-token...', token);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'add-token',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token)
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

  const reserveSetActivationThreshold = async (activation_threshold) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] set-activation-threshold...', activation_threshold);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'set-activation-threshold',
        functionArgs: [
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

  const reserveSetActivationDelay = async (activation_delay) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] set-activation-delay...', activation_delay);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'set-activation-delay',
        functionArgs: [
            uintCV(activation_delay)
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

  const reserveRegisterUser = async (token) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] register-user...', token);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'register-user',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            someCV(stringUtf8CV(""))
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

  const reserveSetCoinbaseAmount = async (token, coinbase1, coinbase2, coinbase3, coinbase4, coinbase5) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] set-coinbase-amount...', token, coinbase1, coinbase2, coinbase3, coinbase4, coinbase5);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'set-coinbase-amount',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            uintCV(coinbase1),
            uintCV(coinbase2),
            uintCV(coinbase3),
            uintCV(coinbase4),
            uintCV(coinbase5)
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
  
  const reserveGetUserId = async (token, user) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] get-user-id...', token, user);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'alex-reserve-pool-v10',
      functionName: 'get-user-id',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
        principalCV(user)
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

  const reserveGetStakerAtCycleOrDefault = async (token, reward_cycle, user_id) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] get-staker-at-cycle-or-default...', token, reward_cycle, user_id);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'alex-reserve-pool-v10',
      functionName: 'get-staker-at-cycle-or-default',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
        uintCV(reward_cycle),
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

  const reserveSetRewardCycleLength = async (length) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[reserve] set-reward-cycle-length...', length);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'alex-reserve-pool-v10',
        functionName: 'set-reward-cycle-length',
        functionArgs: [
            uintCV(length)
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

  exports.reserveAddToken = reserveAddToken;
  exports.reserveSetActivationDelay = reserveSetActivationDelay;
  exports.reserveSetActivationThreshold = reserveSetActivationThreshold;
  exports.reserveRegisterUser = reserveRegisterUser;
  exports.reserveSetCoinbaseAmount = reserveSetCoinbaseAmount;
  exports.reserveGetUserId = reserveGetUserId;
  exports.reserveGetStakerAtCycleOrDefault = reserveGetStakerAtCycleOrDefault;
  exports.reserveSetRewardCycleLength = reserveSetRewardCycleLength;
  