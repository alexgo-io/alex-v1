require('dotenv').config();
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const {flExecuteMarginUsdaWbtc23670} = require('./flashloan')
const {flashloan, getBalance} = require('./vault')
const { 
    fwpCreate,
    fwpAddToPosition,
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
    const expiry = 23670 * ONE_8
    const ltv_0 = 0.7 * ONE_8
    const conversion_ltv = 0.95 * ONE_8
    const bs_vol = 0.8 * ONE_8
    const moving_average = 0.95 * ONE_8

    const weightX = 0.5 * ONE_8
    const weightY = 0.5 * ONE_8    

    console.log("------ Update Price Oracle ------")
    const {usdc, btc} = await initCoinPrice()
    await setOpenOracle('WBTC','coingecko', btc);
    await setOpenOracle('USDA','coingecko', usdc);
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;

    let usda_balance = BigInt(10000000e+8);
    let wbtc_balance = BigInt(20000e+8)   

    // console.log("------ Pool Creation ------");
    
    // let left_side = wbtc_balance / BigInt(100); //1% balance to fwp
    // let right_side = Math.round(Number(wbtcPrice) * Number(left_side) / ONE_8);
    // await fwpCreate('token-wbtc', 'token-usda', weightX, weightY, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', left_side, right_side);        
    
    // let left_side = wbtc_balance / BigInt(10); // 10% balance to ytp
    // let right_side = left_side;
    // await ytpCreate('yield-wbtc-23670', 'token-wbtc', 'ytp-yield-wbtc-23670-wbtc', 'multisig-ytp-yield-wbtc-23670-wbtc', left_side, right_side);
    
    let left_side = wbtc_balance / BigInt(10); // 10% balance to ytp
    let right_side = left_side;
    await ytpCreate('yield-wbtc-59760', 'token-wbtc', 'ytp-yield-wbtc-59760-wbtc', 'multisig-ytp-yield-wbtc-59760-wbtc', left_side, right_side);

    // let usda_collateral = Number(usda_balance / BigInt(100)); //10% usda balance to mint yield-wbtc
    // await crpCreate('token-wbtc', 'token-usda', 'yield-wbtc-23670', 'key-wbtc-23670-usda', 'multisig-crp-wbtc-23670-usda', ltv_0, conversion_ltv, bs_vol, moving_average, usda_collateral);    
    // await ytpSwapYforX('yield-wbtc-23670', 'token-wbtc', 1e+8);

    let usda_collateral = Number(usda_balance / BigInt(100)); //10% usda balance to mint yield-wbtc
    await crpCreate('token-wbtc', 'token-usda', 'yield-wbtc-59760', 'key-wbtc-59760-usda', 'multisig-crp-wbtc-59760-usda', ltv_0, conversion_ltv, bs_vol, moving_average, usda_collateral);    
    // await ytpSwapYforX('yield-wbtc-23670', 'token-wbtc', 1e+8);    

    // console.log("------ FWP Arbitrage ------")
    // let printed = parseFloat(wbtcPrice / usdaPrice);

    // let result = await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    // let balance_x = result.value.data['balance-x'].value;
    // let balance_y = result.value.data['balance-y'].value;

    // let implied = balance_y * BigInt(weightX) / balance_x / BigInt(weightY);
    // console.log("printed: ", printed, "implied:", implied);
    // if (printed < implied) {
    //     let dx = await fwpGetXGivenPrice('token-wbtc', 'token-usda', weightX, weightY, printed * ONE_8);
    //     console.log("dx = ", dx);
    //     if(dx.type === 7){
    //         await fwpSwapXforY('token-wbtc', 'token-usda', weightX, weightY, dx.value.value);
    //     }
    // } else {
    //     let dy = await fwpGetYGivenPrice('token-wbtc', 'token-usda', weightX, weightY, printed * ONE_8);
    //     console.log("dy = ", dy);
    //     if(dy.type === 7){
    //         await fwpSwapYforX('token-wbtc', 'token-usda', weightX, weightY, dy.value.value);
    //     }
    // }  
    // result = await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    // balance_x = result.value.data['balance-x'].value;
    // balance_y = result.value.data['balance-y'].value;      
    // console.log('post arb implied: ', balance_y / balance_x);

    // console.log("------ CRP Arbitrage ------")
    // printed = parseFloat(wbtcPrice / usdaPrice);

    // result = await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
    // balance_x = result.value.data['balance-x'].value;
    // balance_y = result.value.data['balance-y'].value;
    // weight_x = result.value.data['weight-x'].value;
    // weight_y = result.value.data['weight-y'].value;

    // implied = balance_x * weight_y / balance_y / weight_x;
    // console.log("printed: ", printed, "implied:", implied);
    // if (printed < implied) {
    //     let dx = await crpGetXgivenPrice('token-wbtc', 'token-usda', expiry, printed * ONE_8);
    //     console.log("dx = ", dx);
    //     if(dx.type === 7){
    //         await crpSwapXforY('token-wbtc', 'token-usda', expiry, dx.value.value);
    //     }
    // } else {
    //     let dy = await crpGetYgivenPrice('token-wbtc', 'token-usda', expiry, printed * ONE_8);
    //     console.log("dy = ", dy);
    //     if(dy.type === 7){
    //         await crpSwapYforX('token-wbtc', 'token-usda', expiry, dy.value.value);
    //     }
    // } 
    // result = await crpGetPoolDetails('token-wbtc', 'token-usda', expiry);
    // balance_x = result.value.data['balance-x'].value;
    // balance_y = result.value.data['balance-y'].value;
    // weight_x = result.value.data['weight-x'].value;
    // weight_y = result.value.data['weight-y'].value;    
    // console.log('post arb implied: ', balance_x * weight_y / balance_y / weight_x);    

    // console.log("------ Testing Spot Trading ------");
    // let from_amount = ONE_8;
    // let to_amount = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount)).value.value);
    // let exchange_rate = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, ONE_8)));
    // await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount);

    // from_amount = Number(wbtcPrice);
    // console.log(from_amount);
    // to_amount = (await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount));
    // if (to_amount.type === 7){
    //     await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, to_amount.value.value);
    // } else {
    //     console.log(to_amount);
    // }

    // console.log("------ Testing Margin Trading (Long USD vs BTC) ------");
    // let amount = 10000*ONE_8; //gross exposure of $10,000
    // let ltv = parseInt((await crpGetLtv('token-wbtc', 'token-usda', expiry)).value.value);
    // ltv /= parseInt((await ytpGetPrice("yield-wbtc-23670")).value.value);
    // let margin = Math.round(amount * (1 - ltv));
    // let leverage = 1 / (1 - ltv);
    // let trade_price = parseInt((await fwpGetXgivenY('token-wbtc', 'token-usda', weightX, weightY, amount)).value.value) / ONE_8;

    // console.log("ltv: ", ltv, "; amount: ", amount, "; margin: ", margin);
    // console.log("leverage: ", leverage, "; trade_price: ", trade_price)
    // await flExecuteMarginUsdaWbtc23670(amount);
    // await getBalance('token-usda');
    
    // await flashloan('flash-loan-user-margin-usda-wbtc-23670', 'token-usda', (amount - margin));

}
run();
