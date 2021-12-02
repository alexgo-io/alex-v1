const { generateWallet } = require('@stacks/wallet-sdk');
const { makeSTXTokenTransfer, broadcastTransaction } =require('@stacks/transactions');
const { wait_until_confirmation } = require('./utils');

const {
    StacksRegtest,
    StacksMocknet,
    StacksMainnet
  } = require('@stacks/network');

const getDeployerPK = async ()=>{
    const wallet = await generateWallet({
        secretKey:process.env.DEPLOYER_ACCOUNT_SECRET,
        password:process.env.ACCOUNT_PWD
    })
    const privateKey = wallet.accounts[0].stxPrivateKey
    return privateKey
}

const getUserPK = async ()=>{
    const wallet = await generateWallet({
        secretKey:process.env.USER_ACCOUNT_SECRET,
        password:process.env.ACCOUNT_PWD
    })
    const privateKey = wallet.accounts[0].stxPrivateKey
    return privateKey
}

// const network = new StacksRegtest({
const network = new StacksMocknet({
// const network = new StacksMainnet({    
    url:'https://regtest-3.alexgo.io'
})

const BigNum = require("bn.js");

const genesis_transfer = async() => {
    console.log('genesis-transfer...');

    const txOptions = {
      recipient: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      amount: new BigNum(1000000000000000),
      senderKey:
        "cb3df38053d132895220b9ce471f6b676db5b9bf0b4adefb55f2118ece2478df01",
      network: network,
    };
    
    try {
        const transaction = await makeSTXTokenTransfer(txOptions);
        const broadcastResponse = await broadcastTransaction(transaction, network);
        console.log(broadcastResponse);
        await wait_until_confirmation(broadcastResponse.txid)
    } catch (error) {
        console.log(error);
    }
}

exports.getDeployerPK = getDeployerPK;
exports.getUserPK = getUserPK;
exports.network = network;
exports.genesis_transfer = genesis_transfer;