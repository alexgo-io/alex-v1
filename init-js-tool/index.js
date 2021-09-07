const CoinGecko = require('coingecko-api');
const CoinGeckoClient = new CoinGecko();
require('dotenv').config();
const {
  makeContractCall,
  AnchorMode,
  stringAsciiCV,
  uintCV,
  broadcastTransaction
} = require('@stacks/transactions');
const { StacksRegtest } = require('@stacks/network');
const { generateWallet } = require('@stacks/wallet-sdk');
const network = new StacksRegtest();
//Use CoinGeckoClient to fetch current prices of btc & usdc
const initCoinPrice = async () => {
  const btc = await CoinGeckoClient.coins.fetch('bitcoin', {
    vs_currency: 'usd',
    from: new Date(Date.now() - 60 * 1000).getTime(),
    to: Date.now(),
  });
  const usdc = await CoinGeckoClient.coins.fetch('usd-coin', {
    vs_currency: 'usd',
    from: new Date(Date.now() - 60 * 1000).getTime(),
    to: Date.now(),
  });
  const usdcPrice = usdc.data.market_data.current_price.usd * 1e8;
  const btcPrice = btc.data.market_data.current_price.usd * 1e8;
  return { usdc: usdcPrice, btc: btcPrice };
};
//Call open-oracle to set price
const setOpenOracle = async (symbol, src, price) => {
  console.log('Updating coin market price...', symbol, src, price);
  
  const wallet = await generateWallet({
      secretKey:process.env.ACCOUNT_SECRET,
      password:process.env.ACCOUNT_PWD
  })
  const privateKey = wallet.accounts[0].stxPrivateKey
  
  const txOptions = {
    contractAddress: process.env.ACCOUNT_ADDRESS,
    contractName: 'open-oracle',
    functionName: 'update-price',
    functionArgs: [
      stringAsciiCV(symbol),
      stringAsciiCV(src),
      uintCV(price),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    const txId = broadcastResponse.txid;
    console.log(broadcastResponse);    
  } catch (error) {
      console.log(error);
  }
};
async function run(){
    const {usdc, btc} = await initCoinPrice()
    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error
    await setOpenOracle('WBTC','CoinGecko', btc);
    // await setOpenOracle('USDA','CoinGecko', usdc);
}
run();