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
const {wait_until_confirmation } = require('./utils');
  const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');
  
  const crpCreate = async (token, collateral, yieldToken, keyToken, multiSig, ltv_0, conversion_ltv, bs_vol, moving_average, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] create-pool...', token, collateral, yieldToken, keyToken, multiSig, ltv_0, conversion_ltv, bs_vol, moving_average, dx);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, keyToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, multiSig),
            uintCV(ltv_0),
            uintCV(conversion_ltv),
            uintCV(bs_vol),
            uintCV(moving_average),
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
  }
  
  const crpAddToPostionAndSwitch = async (token, collateral, yieldToken, keyToken, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] add-to-position-and-switch...', token, collateral, yieldToken, keyToken, dx);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'add-to-position-and-switch',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, keyToken),
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
  }

  const crpAddToPostion = async (token, collateral, yieldToken, keyToken, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] add-to-position..', token, collateral, yieldToken, keyToken, dx);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'add-to-position',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, keyToken),
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
  }  

  const crpReducePostionYield = async (token, collateral, yieldToken, percent, deployer=false) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] reduce-position-yield..', token, collateral, yieldToken, percent);
    const privateKey = (deployer) ? await getDeployerPK() : await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'reduce-position-yield',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
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

  const crpReducePostionKey = async (token, collateral, keyToken, percent, deployer=false) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] reduce-position-key..', token, collateral, keyToken, percent);

    const privateKey = (deployer) ? await getDeployerPK() : await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'reduce-position-key',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, keyToken),
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

  const crpSwapXforY = async (token, collateral, expiry, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] swap-x-for-y...', token, collateral, expiry, dx);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'swap-x-for-y',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            uintCV(expiry),
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
  }  

  const crpSwapYforX = async (token, collateral, expiry, dy) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] swap-y-for-x...', token, collateral, expiry, dy);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'swap-y-for-x',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
            uintCV(expiry),
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
  
  const crpGetLtv = async (token, collateral, expiry) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-ltv...', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-ltv',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
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
  
  const crpGetXgivenY = async (token, collateral, expiry, dy) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-x-given-y...', token, collateral, expiry, dy);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-x-given-y',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
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
  
  const crpGetYgivenX = async (token, collateral, expiry, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-y-given-x...', token, collateral, expiry, dx);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-y-given-x',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
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

  const crpGetYgivenPrice = async (token, collateral, expiry, price) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-y-given-price',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
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

  const crpGetXgivenPrice = async (token, collateral, expiry, price) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-x-given-price',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
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
  
  const crpGetPoolValueInToken = async (token, collateral, expiry) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-pool-value-in-token...', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-pool-value-in-token',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
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
  
  const crpGetPoolDetails = async (token, collateral, expiry) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-pool-details...', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-pool-details',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
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

  const crpGetSpot = async (token, collateral, expiry) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[CRP] get-spot...', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-spot',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
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
  
  const crpGetWeightY = async (token, collateral, expiry, strike, bs_vol) => {
    console.log('--------------------------------------------------------------------------');
      console.log('Getting CRP Weight-Y...', token, collateral, expiry, strike, bs_vol);
    
      const options = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'get-weight-y',
        functionArgs: [
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),     
          contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, collateral),
          uintCV(expiry),
          uintCV(strike),
          uintCV(bs_vol)
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

  exports.crpCreate = crpCreate;
  exports.crpAddToPostion = crpAddToPostion;
  exports.crpAddToPostionAndSwitch = crpAddToPostionAndSwitch;
  exports.crpReducePostionKey = crpReducePostionKey;
  exports.crpReducePostionYield = crpReducePostionYield;
  exports.crpGetLtv = crpGetLtv;
  exports.crpGetYgivenX = crpGetYgivenX;
  exports.crpGetXgivenY = crpGetXgivenY;
  exports.crpGetPoolDetails = crpGetPoolDetails;
  exports.crpGetPoolValueInToken = crpGetPoolValueInToken;
  exports.crpGetWeightY = crpGetWeightY;
  exports.crpGetYgivenPrice = crpGetYgivenPrice;
  exports.crpGetXgivenPrice = crpGetXgivenPrice;
  exports.crpSwapXforY = crpSwapXforY;
  exports.crpSwapYforX = crpSwapYforX;
  exports.crpGetSpot = crpGetSpot;
  