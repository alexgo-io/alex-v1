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
  
  
  const ytpCreate = async (yiedToken, token, poolToken, multiSig, dx, dy) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] create-pool...', yiedToken, token, poolToken, multiSig, dx, dy);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
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

  const ytpAddToPosition = async (yiedToken, token, poolToken, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] add-to-position...', yiedToken, token, poolToken, dx);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'add-to-position',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, poolToken),           
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
  
  const ytpReducePosition = async (yiedToken, token, poolToken, percent) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] reduce-position...', yiedToken, token, poolToken, percent);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'reduce-position',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, poolToken),           
            uintCV(percent)
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
  
  const ytpGetPrice = async(yieldToken) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-price...', yieldToken);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-price',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
      ],
      network: network,
      senderAddress: process.env.USER_ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
    } catch (error) {
      console.log(error);
    }
  }
  
  const ytpGetYield = async(yieldToken) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-yield...', yieldToken);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-yield',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
      ],
      network: network,
      senderAddress: process.env.USER_ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
      
    } catch (error) {
      console.log(error);
    }
  }
  
  const ytpSwapXforY = async (yiedToken, token, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] swap-x-for-y...', yiedToken, token, dx);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'swap-x-for-y',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),          
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
  
  const ytpSwapYforX = async (yiedToken, token, dy) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] swap-y-for-x...', yiedToken, token, dy);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'swap-y-for-x',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),          
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
  
  const ytpGetXgivenY = async (yieldToken, dy) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-x-given-y...', yieldToken, dy);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-x-given-y',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
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
  
  const ytpGetYgivenX = async (yieldToken, dx) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-y-given-x...', yieldToken, dx);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-y-given-x',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
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

  const ytpGetXgivenYield = async (yieldToken, yied) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-x-given-yield...', yieldToken, yied);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-x-given-yield',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
        uintCV(yied)
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
  
  const ytpGetYgivenYield = async (yieldToken, yied) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-y-given-yield...', yieldToken, yied);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-y-given-yield',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken),
        uintCV(yied)
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
  
  const ytpGetPoolDetails = async (yieldToken) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[YTP] get-pool-details...', yieldToken);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: 'yield-token-pool',
      functionName: 'get-pool-details',
      functionArgs: [
        contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, yieldToken)
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
  
  exports.ytpCreate = ytpCreate;
  exports.ytpGetPrice = ytpGetPrice;
  exports.ytpGetYield = ytpGetYield;
  exports.ytpSwapXforY = ytpSwapXforY;
  exports.ytpSwapYforX = ytpSwapYforX;
  exports.ytpGetYgivenX = ytpGetYgivenX;
  exports.ytpGetXgivenY = ytpGetXgivenY;
  exports.ytpGetPoolDetails = ytpGetPoolDetails;
  exports.ytpAddToPosition = ytpAddToPosition;
  exports.ytpReducePosition = ytpReducePosition;
  exports.ytpGetXgivenYield = ytpGetXgivenYield;
  exports.ytpGetYgivenYield = ytpGetYgivenYield;
