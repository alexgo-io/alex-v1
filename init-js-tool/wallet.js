const { generateWallet } = require('@stacks/wallet-sdk');
const {
    StacksRegtest,
    StacksMocknet,
    StacksMainnet
  } = require('@stacks/network');
const getPK = async ()=>{
    const wallet = await generateWallet({
        secretKey:process.env.ACCOUNT_SECRET,
        password:process.env.ACCOUNT_PWD
    })
    const privateKey = wallet.accounts[0].stxPrivateKey
    return privateKey
}
const network = new StacksRegtest({
//const network = new StacksMocknet({
// const network = new StacksMainnet({    
    url:'https://regtest-2.alexgo.io'
})
exports.getPK = getPK
exports.network = network;