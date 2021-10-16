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
const { wait_until_confirmation } = require('./utils');

const flExecuteMarginUsdaWbtc23040 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-23040...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-23040',
        functionName: 'execute-margin-usda-wbtc-23040',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginWbtcUsda23040 = async(amount) => {
    console.log('[FL] execute-margin-wbtc-usda-23040...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-wbtc-usda-23040',
        functionName: 'execute-margin-wbtc-usda-23040',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginUsdaWbtc23670 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-23670...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-23670',
        functionName: 'execute-margin-usda-wbtc-23670',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginUsdaWbtc34560 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-34560...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-34560',
        functionName: 'execute-margin-usda-wbtc-34560',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginWbtcUsda34560 = async(amount) => {
    console.log('[FL] execute-margin-wbtc-usda-34560...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-wbtc-usda-34560',
        functionName: 'execute-margin-wbtc-usda-34560',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginUsdaWbtc74880 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-74880...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-74880',
        functionName: 'execute-margin-usda-wbtc-74880',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginWbtcUsda74880 = async(amount) => {
    console.log('[FL] execute-margin-wbtc-usda-74880...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-wbtc-usda-74880',
        functionName: 'execute-margin-wbtc-usda-74880',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

const flExecuteMarginUsdaWbtc59760 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-59760...', amount);
    const privateKey = await getUserPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-59760',
        functionName: 'execute-margin-usda-wbtc-59760',
        functionArgs: [
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
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

exports.flExecuteMarginUsdaWbtc59760 = flExecuteMarginUsdaWbtc59760;
exports.flExecuteMarginUsdaWbtc23670 = flExecuteMarginUsdaWbtc23670;
exports.flExecuteMarginUsdaWbtc23040 = flExecuteMarginUsdaWbtc23040;
exports.flExecuteMarginUsdaWbtc34560 = flExecuteMarginUsdaWbtc34560;
exports.flExecuteMarginUsdaWbtc74880 = flExecuteMarginUsdaWbtc74880;
exports.flExecuteMarginWbtcUsda23040 = flExecuteMarginWbtcUsda23040;
exports.flExecuteMarginWbtcUsda34560 = flExecuteMarginWbtcUsda34560;
exports.flExecuteMarginWbtcUsda74880 = flExecuteMarginWbtcUsda74880;