require('dotenv').config();
const {initCoinPrice, setOpenOracle} = require('./oracles').default
async function run(){
    const {usdc, btc} = await initCoinPrice()
    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error
    await setOpenOracle('WBTC','CoinGecko', btc);
    // await setOpenOracle('USDA','CoinGecko', usdc);
}
run();