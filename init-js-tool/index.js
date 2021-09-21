require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const { 
    fwpCreate,
    fwpGetXGivenPrice,
    fwpGetYGivenPrice,
    fwpGetXgivenY,
    fwpGetYgivenX,
    fwpGetPoolDetails,
    crpCreate,
    crpAddToPostionAndSwitch,
    crpGetLtv,
    crpGetXgivenY,
    crpGetYgivenX,    
    crpGetPoolDetails,
    crpGetPoolValueInToken,
    crpGetWeightY,
    ytpCreate,
    ytpSwapXforY,
    ytpSwapYforX,
    ytpGetXgivenY,
    ytpGetYgivenX,
    ytpGetPoolDetails,    
 } = require('./pools')
async function run(){

    const ONE_8 = 100000000
    const expiry = 59760 * ONE_8
    const ltv_0 = 0.8 * ONE_8
    const conversion_ltv = 0.95 * ONE_8
    const bs_vol = 0.8 * ONE_8
    const moving_average = 0.95 * ONE_8

    const weightX = 0.5 * ONE_8
    const weightY = 0.5 * ONE_8

    const wbtcQ = 10*ONE_8
    const wbtcPrice = 48126    

    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error

    // const {usdc, btc} = await initCoinPrice()
    // await setOpenOracle('WBTC','nothing', btc);
    // await setOpenOracle('USDA','nothing', usdc);
    // await getOpenOracle('nothing', 'WBTC');
    // await getOpenOracle('nothing', 'USDA');

    // await crpGetLtv('token-wbtc', 'token-usda', 59760e+8);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', 59760e+8);
    // await crpGetPoolDetails('token-wbtc', 'token-usda', 59760e+8);

    // await fwpCreate('token-wbtc', 'token-usda', 5e+7, 5e+7, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', wbtcQ, wbtcPrice * wbtcQ);        
    // await ytpCreate('yield-wbtc-59760', 'token-wbtc', 'ytp-yield-wbtc-59760-wbtc', 'multisig-ytp-yield-wbtc-59760-wbtc', wbtcQ / 5, wbtcQ / 5);
    // await crpCreate('token-wbtc', 'token-usda', 'yield-wbtc-59760', 'key-wbtc-59760-usda', 'multisig-crp-wbtc-59760-usda', ltv_0, conversion_ltv, bs_vol, moving_average, 100000 * ONE_8);

    // await fwpGetXGivenPrice('token-wbtc', 'token-usda', weightX, weightY, 4846200000000)
    // await fwpGetYGivenPrice('token-wbtc', 'token-usda', weightX, weightY, 4846200000000)
    // await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    // await fwpGetYgivenX('token-wbtc', 'token-usda', weightX, weightY, 1e+8);
    // await fwpGetXgivenY('token-wbtc', 'token-usda', weightX, weightY, 10000e+8);

    await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
    await crpGetXgivenY('token-wbtc', 'token-usda', expiry, 1e+8);
    await crpGetYgivenX('token-wbtc', 'token-usda', expiry, 10000e+8);

    // await ytpGetPoolDetails('yield-wbtc-59760');
    // await ytpGetXgivenY('yield-wbtc-59760', 1e+8);
    // await ytpGetYgivenX('yield-wbtc-59760', 1e+8);

    // await crpGetLtv('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
    await crpGetWeightY('token-wbtc', 'token-usda',  expiry, 4846200000000, 80e+7);
}
run();
