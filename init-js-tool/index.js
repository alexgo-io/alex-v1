require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const {flExecuteMarginUsdaWbtc16973} = require('./flashloan')
const {flashloan, getBalance} = require('./vault')
const { 
    fwpCreate,
    fwpGetXGivenPrice,
    fwpGetYGivenPrice,
    fwpGetXgivenY,
    fwpGetYgivenX,
    fwpSwapXforY,
    fwpSwapYforX,    
    fwpGetPoolDetails,
} = require('./pools-fwp')
const {
    crpCreate,
    crpAddToPostionAndSwitch,
    crpGetLtv,
    crpGetXgivenY,
    crpGetYgivenX,    
    crpGetXgivenPrice,
    crpGetYgivenPrice,      
    crpGetPoolDetails,
    crpGetPoolValueInToken,
    crpGetWeightY,
    crpSwapXforY,
    crpSwapYforX
} = require('./pools-crp')
const {
    ytpCreate,
    ytpGetPrice,
    ytpGetYield,
    ytpSwapXforY,
    ytpSwapYforX,
    ytpGetXgivenY,
    ytpGetYgivenX,
    ytpGetPoolDetails,    
 } = require('./pools-ytp')

async function run(){

    const ONE_8 = 100000000
    const expiry = 16973 * ONE_8
    const ltv_0 = 0.8 * ONE_8
    const conversion_ltv = 0.95 * ONE_8
    const bs_vol = 0.8 * ONE_8
    const moving_average = 0.95 * ONE_8

    const weightX = 0.5 * ONE_8
    const weightY = 0.5 * ONE_8

    const wbtcQ = 10*ONE_8
    // const wbtcPrice = 48126    

    //Need to call it one by one, or you'll receive 'ConflictingNonceInMempool' Error

    const {usdc, btc} = await initCoinPrice()
    await setOpenOracle('WBTC','nothing', btc);
    await setOpenOracle('USDA','nothing', usdc);

    // await fwpCreate('token-wbtc', 'token-usda', 5e+7, 5e+7, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', wbtcQ, wbtcPrice * wbtcQ);        
    // await ytpCreate('yield-wbtc-16973', 'token-wbtc', 'ytp-yield-wbtc-16973-wbtc', 'multisig-ytp-yield-wbtc-16973-wbtc', wbtcQ / 5, wbtcQ / 5);
    // await crpCreate('token-wbtc', 'token-usda', 'yield-wbtc-16973', 'key-wbtc-16973-usda', 'multisig-crp-wbtc-16973-usda', ltv_0, conversion_ltv, bs_vol, moving_average, 100000 * ONE_8);


    let wbtcPrice = (await getOpenOracle('nothing', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('nothing', 'USDA')).value.value;
    let printed = parseFloat(wbtcPrice / usdaPrice);

    // await crpGetLtv('token-wbtc', 'token-usda', 16973e+8);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', 16973e+8);
    let result = await crpGetPoolDetails('token-wbtc', 'token-usda', 16973e+8);
    let balance_x = result.value.data['balance-x'].value;
    let balance_y = result.value.data['balance-y'].value;
    let weight_x = result.value.data['weight-x'].value;
    let weight_y = result.value.data['weight-y'].value;

    let implied = balance_y * weight_x / balance_x / weight_y;
    if (printed < implied) {
        let dx = await crpGetXgivenPrice('token-wbtc', 'token-usda', expiry, Math.round(ONE_8 / printed));
        console.log("dx = ", dx);
        await crpSwapXforY('token-wbtc', 'token-usda', expiry, dx.value.value);
    } else {
        let dy = await crpGetYgivenPrice('token-wbtc', 'token-usda', expiry, Math.round(ONE_8 / printed));
        console.log("dy = ", dy);
        await crpSwapYforX('token-wbtc', 'token-usda', expiry, dy.value.value);
    }

    // await fwpGetXGivenPrice('token-wbtc', 'token-usda', weightX, weightY, 4846200000000)
    // await fwpGetYGivenPrice('token-wbtc', 'token-usda', weightX, weightY, 4846200000000)
    // await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    // await fwpGetYgivenX('token-wbtc', 'token-usda', weightX, weightY, 1e+8);
    // await fwpSwapXforY('token-wbtc', 'token-usda', weightX, weightY, 1e+8);


    // await fwpGetXgivenY('token-wbtc', 'token-usda', weightX, weightY, 10000e+8);

    // await ytpGetPrice('yield-wbtc-16973')
    // await ytpGetYield('yield-wbtc-16973')
    // await ytpGetPoolDetails('yield-wbtc-16973');
    // await ytpGetXgivenY('yield-wbtc-16973', 1e+8);
    // await ytpGetYgivenX('yield-wbtc-16973', 1e+8);

    // await crpGetLtv('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolValueInToken('token-wbtc', 'token-usda', expiry);
    // await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
    // await crpGetWeightY('token-wbtc', 'token-usda',  expiry, 4846200000000, 80e+7);
    // await crpGetXgivenY('token-wbtc', 'token-usda', expiry, 1e+8);
    // await crpGetYgivenX('token-wbtc', 'token-usda', expiry, 10000e+8);    
    // await crpGetYgivenPrice('token-wbtc', 'token-usda', expiry, Math.round((1/50000)*ONE_8));

    let amount = ONE_8;
    let ltv = parseInt((await crpGetLtv('token-wbtc', 'token-usda', expiry)).value.value);
    ltv /= parseInt((await ytpGetPrice("yield-wbtc-16973")).value.value);
    let margin = Math.round(amount * (1 - ltv));
    let leverage = 1 / (1 - ltv);
    let trade_price = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', weightX, weightY, amount)).value.value);

    console.log("ltv: ", ltv, "; amount: ", amount, "; margin: ", margin);
    console.log("leverage: ", leverage, "; trade_price: ", trade_price)
    await flExecuteMarginUsdaWbtc16973(amount);
    await getBalance('token-usda');
    
    await flashloan('flash-loan-user-margin-usda-wbtc-16973', 'token-usda', (amount - margin));

}
run();

// 55487943475558
// 9999999901620218
// 99999901620217

