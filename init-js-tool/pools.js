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
const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');

const fwpCreate = async (tokenX, tokenY, weightX, weightY, poolToken, multiSig, dx, dy) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'fixed-weight-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenX),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenY),
            uintCV(weightX),
            uintCV(weightY),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, poolToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, multiSig),
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
    } catch (error) {
        console.log(error);
    }
}
const crpCreate = async (token, collateral, yiedToken, keyToken, multiSig, ltv_0, conversion_ltv, bs_vol, moving_average, dx) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
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
    } catch (error) {
        console.log(error);
    }
}
const ytpCreate = async (yiedToken, token, poolToken, multiSig, dx, dy) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, poolToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, multiSig),            
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
    } catch (error) {
        console.log(error);
    }
}

const crpAddToPostionAndSwitch = async (token, collateral, yiedToken, keyToken, multiSig, ltv_0, conversion_ltv, bs_vol, moving_average, dx) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'add-to-position-and-switch',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, collateral),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
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
    } catch (error) {
        console.log(error);
    }
}

const ytpSwapXforY = async (yiedToken, token, dx) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'swap-x-for-y',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),          
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
    } catch (error) {
        console.log(error);
    }
}

const ytpSwapYforX = async (yiedToken, token, dy) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'swap-y-for-x',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),          
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
    } catch (error) {
        console.log(error);
    }
}

const crpGetLtv = async (token, collateral, expiry) => {
    console.log('Getting LTV...', token, collateral, expiry);
  
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
      const result = await callReadOnlyFunction(options);
      console.log(result);
    } catch (error) {
      console.log(error);
    }
};

const crpGetPoolValueInToken = async (token, collateral, expiry) => {
    console.log('Getting CRP Pool Value in Token...', token, collateral, expiry);
  
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
      const result = await callReadOnlyFunction(options);
      console.log(result);
    } catch (error) {
      console.log(error);
    }
};

const crpGetPoolDetails = async (token, collateral, expiry) => {
    console.log('Getting CRP Pool Details...', token, collateral, expiry);
  
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
      const result = await callReadOnlyFunction(options);
      printResult(result);
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

const fwpGetXGivenPrice = async (tokenX, tokenY, weightX, weightY, price) => {
    console.log('[FWP] For given price, what is X...', tokenX, tokenY, weightX, weightY, price);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'get-x-given-price',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenX),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenY),
        uintCV(weightX),
        uintCV(weightY),
        uintCV(price)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      const result = await callReadOnlyFunction(options);
      console.log(result);
    } catch (error) {
      console.log(error);
    }
};

const fwpGetPoolDetails = async (tokenX, tokenY, weightX, weightY) => {
    console.log('Getting FWP Pool Details...', tokenX, tokenY, weightX, weightY);
  
    const options = {
      contractAddress: process.env.ACCOUNT_ADDRESS,
      contractName: 'fixed-weight-pool',
      functionName: 'get-pool-details',
      functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenX),     
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, tokenY),
        uintCV(weightX),
        uintCV(weightY)
      ],
      network: network,
      senderAddress: process.env.ACCOUNT_ADDRESS,
    };
    try {
      const result = await callReadOnlyFunction(options);
      printResult(result);
    } catch (error) {
      console.log(error);
    }
};

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
      const result = await callReadOnlyFunction(options);
      console.log(result);
    } catch (error) {
      console.log(error);
    }
};

exports.fwpCreate = fwpCreate;
exports.crpCreate = crpCreate;
exports.ytpCreate = ytpCreate;
exports.crpAddToPostionAndSwitch = crpAddToPostionAndSwitch;
exports.ytpSwapXforY = ytpSwapXforY;
exports.ytpSwapYforX = ytpSwapYforX;
exports.crpGetLtv = crpGetLtv;
exports.crpGetPoolDetails = crpGetPoolDetails;
exports.crpGetPoolValueInToken = crpGetPoolValueInToken;
exports.crpGetWeightY = crpGetWeightY;
exports.fwpGetXGivenPrice = fwpGetXGivenPrice;
exports.fwpGetPoolDetails = fwpGetPoolDetails;
