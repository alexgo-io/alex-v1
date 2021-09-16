require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const { createFWP, createCRP,createYTP } = require('./pools')
async function run(){
    const {usdc, btc} = await initCoinPrice()
    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error
    // await setOpenOracle('WBTC','CoinGecko', btc);
    // await setOpenOracle('USDA','CoinGecko', usdc);
    //await createFWP()
    //await createCRP('yield-usda-59760','key-usda-wbtc-59760');
    //await createYTP('yield-usda-59760','token-wbtc', 'pool-token-usda-59760-usda');
    //await getOpenOracle('nothing', 'WBTC');
    //await getOpenOracle('nothing', 'USDA');
}
run();