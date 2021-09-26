const {
    getPK, network
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
    console.log('[CRP] create-pool...', token, collateral, yieldToken, keyToken, multiSig, ltv_0, conversion_ltv, bs_vol, moving_average, dx);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, keyToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, multiSig),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }
  
  const crpAddToPostionAndSwitch = async (token, collateral, yieldToken, keyToken, dx) => {
    console.log('[CRP] add-to-position-and-switch...', token, collateral, yieldToken, keyToken, dx);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'add-to-position-and-switch',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, keyToken),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }

  const crpAddToPostion = async (token, collateral, yieldToken, keyToken, dx) => {
    console.log('[CRP] add-to-position..', token, collateral, yieldToken, keyToken, dx);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'add-to-position',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yieldToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, keyToken),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }  

  const crpReducePostionYield = async (token, collateral, yieldToken, percent) => {
    console.log('[CRP] reduce-position-yield..', token, collateral, yieldToken, percent);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'reduce-position-yield',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yieldToken),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }  

  const crpReducePostionKey = async (token, collateral, keyToken, percent) => {
    console.log('[CRP] reduce-position-key..', token, collateral, keyToken, percent);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'reduce-position-key',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, keyToken),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }  

  const crpSwapXforY = async (token, collateral, expiry, dx) => {
    console.log('[CRP] swap-x-for-y...', token, collateral, expiry, dx);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'swap-x-for-y',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }  

  const crpSwapYforX = async (token, collateral, expiry, dy) => {
    console.log('[CRP] swap-x-for-y...', token, collateral, expiry, dy);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'swap-y-for-x',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
  }   
  
  const crpGetLtv = async (token, collateral, expiry) => {
    console.log('[CRP] get-ltv...]', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-ltv',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
    } catch (error) {
      console.log(error);
    }
  };
  
  const crpGetXgivenY = async (token, collateral, expiry, dy) => {
    console.log('[CRP] get-x-given-y...', token, collateral, expiry, dy);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-x-given-y',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
        uintCV(dy)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
      
    } catch (error) {
      console.log(error);
    }
  };
  
  const crpGetYgivenX = async (token, collateral, expiry, dx) => {
    console.log('[CRP] get-y-given-x...', token, collateral, expiry, dx);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-y-given-x',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
        uintCV(dx)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
      
    } catch (error) {
      console.log(error);
    }
  };

  const crpGetYgivenPrice = async (token, collateral, expiry, price) => {
    console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-y-given-price',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
        uintCV(price)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
    } catch (error) {
      console.log(error);
    }
  };  

  const crpGetXgivenPrice = async (token, collateral, expiry, price) => {
    console.log('[CRP] get-y-given-price...', token, collateral, expiry, price);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-x-given-price',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry),
        uintCV(price)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
    } catch (error) {
      console.log(error);
    }
  };  
  
  const crpGetPoolValueInToken = async (token, collateral, expiry) => {
    console.log('[CRP] get-pool-value-in-token...]', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-pool-value-in-token',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
      
    } catch (error) {
      console.log(error);
    }
  };
  
  const crpGetPoolDetails = async (token, collateral, expiry) => {
    console.log('[CRP] get-pool-details...]', token, collateral, expiry);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'collateral-rebalancing-pool',
      functionName: 'get-pool-details',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
        uintCV(expiry)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
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
  
  const crpGetWeightY = async (token, collateral, expiry, strike, bs_vol) => {
      console.log('Getting CRP Weight-Y...', token, collateral, expiry, strike, bs_vol);
    
      const options = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'get-weight-y',
        functionArgs: [
          contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),     
          contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
          uintCV(expiry),
          uintCV(strike),
          uintCV(bs_vol)
        ],
        network: network,
        senderAddress: process.env.ACCOUNT_ADDRESS,
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
  