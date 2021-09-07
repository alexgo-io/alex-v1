const {
    getWallet
} = require('./wallet').default;

const createFWP = async () => {
    const wallet = await getWallet();
    const privateKey = wallet.accounts[0].stxPrivateKey

    const txOptions = {
        contractAddress: process.env.ACCOUNT_ADDRESS,
        contractName: 'fixed-weight-pool',
        functionName: 'create-pool',
        functionArgs: [
            
        ],
        senderKey: privateKey,
        validateWithAbi: true,
        network,
        anchorMode: AnchorMode.Any,
    };
    try {
        const transaction = await makeContractCall(txOptions);
        const broadcastResponse = await broadcastTransaction(transaction, network);
        console.log(broadcastResponse);
    } catch (error) {
        console.log(error);
    }
}