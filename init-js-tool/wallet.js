const { generateWallet } = require('@stacks/wallet-sdk');
const {
    StacksRegtest
  } = require('@stacks/network');
const getPK = async ()=>{
    const wallet = await generateWallet({
        secretKey:process.env.ACCOUNT_SECRET,
        password:process.env.ACCOUNT_PWD
    })
    const privateKey = wallet.accounts[0].stxPrivateKey
    return privateKey
}
const network = new StacksRegtest();
exports.getPK = getPK
exports.network = network;