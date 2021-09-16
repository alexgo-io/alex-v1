require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const { 
    fwpCreate,
    fwpGetXGivenPrice,
    fwpGetPoolDetails,
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

    const ONE_8 = 100000000
    const expiry = 79760 * ONE_8
    const ltv_0 = 0.8 * ONE_8
    const conversion_ltv = 0.95 * ONE_8
    const bs_vol = 0.8 * ONE_8
    const moving_average = 0.95 * ONE_8

    const weightX = 0.5 * ONE_8
    const weightY = 0.5 * ONE_8

    const wbtcQ = 100*ONE_8
    const wbtcPrice = 50000    

    // const {usdc, btc} = await initCoinPrice()
    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error
    // await setOpenOracle('WBTC','nothing', btc);
    // await setOpenOracle('USDA','nothing', usdc);
    await getOpenOracle('nothing', 'WBTC');
    await getOpenOracle('nothing', 'USDA');

    // await crpGetLtv('token-wbtc', 'token-usda', 59760e+8);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', 59760e+8);
    // await crpGetPoolDetails('token-wbtc', 'token-usda', 59760e+8);

    // await fwpCreate('token-wbtc', 'token-usda', 5e+7, 5e+7, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', wbtcQ, wbtcPrice * wbtcQ);        
    // await ytpCreate('yield-wbtc-79760', 'token-wbtc', 'ytp-yield-wbtc-79760-wbtc', 'multisig-ytp-yield-wbtc-79760-wbtc', wbtcQ / 10, wbtcQ / 10);
    // await crpCreate('token-wbtc', 'token-usda', 'yield-wbtc-79760', 'key-wbtc-79760-usda', 'multisig-crp-wbtc-79760-usda', ltv_0, conversion_ltv, bs_vol, moving_average, 50000 * ONE_8);

    await fwpGetXGivenPrice('token-wbtc', 'token-usda', weightX, weightY, 4846200000000)
    //await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);

    // await crpGetLtv('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
}
run();