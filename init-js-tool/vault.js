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


const flashloan = async(loan_contract, token, amount) => {
    console.log('[Vault] flash-loan...', loan_contract, token, amount);
    const privateKey = await getPK();
    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'alex-vault',
        functionName: 'flash-loan',
        functionArgs: [
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, loan_contract),
            contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
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

const getBalance = async(token) => {
    console.log('[VAULT] get-balance...', token);

    const options = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'alex-vault',
        functionName: 'get-balance',
        functionArgs: [
        contractPrincipalCV(process.env.ACCOUNT_ADDRESS, token),
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
}

exports.flashloan = flashloan;
exports.getBalance = getBalance;