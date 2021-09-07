const CoinGecko = require('coingecko-api');
const CoinGeckoClient = new CoinGecko();
const {
  makeContractCall,
  AnchorMode,
  stringAsciiCV,
  uintCV,
  broadcastTransaction
} = require('@stacks/transactions');
const {
  StacksRegtest
} = require('@stacks/network');
const {
  getWallet
} = require('./wallet').default;
const network = new StacksRegtest();
//Use CoinGeckoClient to fetch current prices of btc & usdc
const initCoinPrice = async () => {
  console.log('Updating coin market price...');
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
  return {
    usdc: usdcPrice,
    btc: btcPrice
  };
};
//Call open-oracle to set price
const setOpenOracle = async (symbol, src, price) => {
  console.log('Setting oracle...', symbol, src, price);
  const wallet = await getWallet();
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
    console.log(broadcastResponse);
  } catch (error) {
    console.log(error);
  }
};

exports.default = {
  initCoinPrice,
  setOpenOracle
}