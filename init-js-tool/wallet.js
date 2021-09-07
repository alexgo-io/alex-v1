const { generateWallet } = require('@stacks/wallet-sdk');

const getWallet = async () => {
    const wallet = await generateWallet({
        secretKey:process.env.ACCOUNT_SECRET,
        password:process.env.ACCOUNT_PWD
    })
    return wallet
}
exports.default = {
    getWallet
}