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
const { wait_until_confirmation } = require('./utils');


const flExecuteMarginUsdaWbtc16973 = async(amount) => {
    console.log('[FL] execute-margin-usda-wbtc-16973...', amount);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'flash-loan-user-margin-usda-wbtc-16973',
        functionName: 'execute-margin-usda-wbtc-16973',
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

exports.flExecuteMarginUsdaWbtc16973 = flExecuteMarginUsdaWbtc16973;