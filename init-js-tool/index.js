require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const { 
    fwpCreate,
    crpCreate,
    crpAddToPostionAndSwitch,
    crpGetLtv,
    crpGetPoolDetails,
    crpGetPoolValueInToken,
    ytpCreate,
    ytpSwapXforY,
    ytpSwapYforX
 } = require('./pools')
async function run(){
    // const {usdc, btc} = await initCoinPrice()
    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error
    // await setOpenOracle('WBTC','nothing', btc);
    // await setOpenOracle('USDA','nothing', usdc);
    // await fwpCreate('token-wbtc', 'token-usda', 5e+7, 5e+7, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', 1e+8, 50000e+8);    
    await getOpenOracle('nothing', 'WBTC');
    await getOpenOracle('nothing', 'USDA');

    await crpGetLtv('token-wbtc', 'token-usda', 59760e+8);
    await crpGetPoolValueInToken('token-wbtc', 'token-usda', 59760e+8);
    await crpGetPoolDetails('token-wbtc', 'token-usda', 59760e+8);

}
run();