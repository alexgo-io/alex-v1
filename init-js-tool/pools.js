const {
    getPK, network
  } = require('./wallet');
const {
    makeContractCall,
    AnchorMode,
    PostConditionMode,
    uintCV,
    contractPrincipalCV,
    broadcastTransaction
  } = require('@stacks/transactions');

const createFWP = async () => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'fixed-weight-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'token-wbtc'),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'token-usda'),
            uintCV(5*1e7),
            uintCV(5*1e7),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS,'pool-token-usda-59760-usda'),
            uintCV(5*1e11),
            uintCV(1e11),
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
const createCRP = async (yiedToken, keyToken) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'collateral-rebalancing-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'token-wbtc'),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'token-usda'),
            // contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'yield-usda-59760'),
            // contractPrincipalCV(process.env.ACCOUNT_ADDRESS, 'key-usda-wbtc-59760'),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, keyToken),
            uintCV(10*1e8),
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
const createYTP = async (yiedToken, token, poolToken) => {
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'yield-token-pool',
        functionName: 'create-pool',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, yiedToken),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, poolToken),
            uintCV(10*1e8),
            uintCV(10*1e8),
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
exports.createFWP = createFWP;
exports.createCRP = createCRP;
exports.createYTP = createYTP;
