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
        "21d43d2ae0da1d9d04cfcaac7d397a33733881081f0b2cd038062cf0ccbb752601",
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