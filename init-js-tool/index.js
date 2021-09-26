require('dotenv').config();
const { ClarityType } = require('@stacks/transactions');
const {initCoinPrice, setOpenOracle, getOpenOracle} = require('./oracles').default
const {
    flExecuteMarginUsdaWbtc23670,
    flExecuteMarginUsdaWbtc59760,
    flExecuteMarginUsdaWbtc23040,
    flExecuteMarginUsdaWbtc34560,
    flExecuteMarginUsdaWbtc74880,
    flExecuteMarginWbtcUsda23040,
    flExecuteMarginWbtcUsda34560,
    flExecuteMarginWbtcUsda74880,
} = require('./flashloan')
const {flashloan, getBalance, mint, burn, balance} = require('./vault')
const {setUsdaAmount, setWbtcAmount, setStxAmount, getSomeTokens} = require('./faucet')
const { 
    fwpCreate,
    fwpAddToPosition,
    fwpReducePosition,
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
    crpAddToPostion,
    crpReducePostionYield,
    crpReducePostionKey,
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
    ytpAddToPosition,
    ytpReducePosition  
 } = require('./pools-ytp')

const _deploy = {
    // 59760: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-59760', 
    //     key_token: 'key-wbtc-59760-usda',
    //     pool_token: 'ytp-yield-wbtc-59760-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-59760-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-59760-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8
    // },
    // 23670: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-23670', 
    //     key_token: 'key-wbtc-23670-usda',
    //     pool_token: 'ytp-yield-wbtc-23670-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-23670-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-23670-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8
    // },           
    // 1: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-23040', 
    //     key_token: 'key-wbtc-23040-usda',
    //     pool_token: 'ytp-yield-wbtc-23040-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-23040-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-23040-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8
    // },
    // 2: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-34560', 
    //     key_token: 'key-wbtc-34560-usda',
    //     pool_token: 'ytp-yield-wbtc-34560-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-34560-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-34560-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8
    // },   
    // 3: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-74880', 
    //     key_token: 'key-wbtc-74880-usda',
    //     pool_token: 'ytp-yield-wbtc-74880-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-74880-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-74880-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8
    // },
    4: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-74880', 
        key_token: 'key-usda-74880-wbtc',
        pool_token: 'ytp-yield-usda-74880-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-74880-usda',
        multisig_crp: 'multisig-crp-usda-74880-wbtc',
        liquidity_ytp: 1000000e+8,
        collateral_crp: 250e+8
    },      
    5: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-34560', 
        key_token: 'key-usda-34560-wbtc',
        pool_token: 'ytp-yield-usda-34560-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-34560-usda',
        multisig_crp: 'multisig-crp-usda-34560-wbtc',
        liquidity_ytp: 1000000e+8,
        collateral_crp: 250e+8
    },     
    6: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-23040', 
        key_token: 'key-usda-23040-wbtc',
        pool_token: 'ytp-yield-usda-23040-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-23040-usda',
        multisig_crp: 'multisig-crp-usda-23040-wbtc',
        liquidity_ytp: 1000000e+8,
        collateral_crp: 250e+8
    }                              
}

const ONE_8 = 100000000

const printResult = (result)=>{
    if(result.type === ClarityType.ResponseOk){
        if(result.value.type == ClarityType.UInt){
            console.log(result.value);
        }else if(result.value.type == ClarityType.Tuple){
            console.log('|');
            for (const key in result.value.data) {
                console.log('---',key,':',result.value.data[key]);
            }
        }
    }
  }

async function update_price_oracle(){
    console.log("------ Update Price Oracle ------")
    const {usdc, btc} = await initCoinPrice()
    await setOpenOracle('WBTC','coingecko', btc);
    await setOpenOracle('USDA','coingecko', usdc);    
}

async function mint_to_deployer(){
    await mint('token-usda', process.env.ACCOUNT_ADDRESS, 100000000000000000n);
    usda_balance = await balance('token-usda', process.env.ACCOUNT_ADDRESS);
    console.log('usda balance: ', usda_balance);    
    await mint('token-wbtc', process.env.ACCOUNT_ADDRESS, 2439024390244);
    wbtc_balance = await balance('token-wbtc', process.env.ACCOUNT_ADDRESS);
    console.log('wbtc balance: ', wbtc_balance);    
}

async function see_deployer_balance(){
    usda_balance = await balance('token-usda', process.env.ACCOUNT_ADDRESS);
    console.log('usda balance: ', usda_balance);
    wbtc_balance = await balance('token-wbtc', process.env.ACCOUNT_ADDRESS);
    console.log('wbtc balance: ', wbtc_balance); 
}

async function create_fwp(add_only){
    console.log("------ FWP Creation / Add Liquidity ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  

    usda_balance = await balance('token-usda', process.env.ACCOUNT_ADDRESS);
    console.log('usda balance: ', usda_balance);   
    wbtc_balance = await balance('token-wbtc', process.env.ACCOUNT_ADDRESS);
    console.log('wbtc balance: ', wbtc_balance);        

    left_side = wbtc_balance.value.value / BigInt(10); //10% balance to fwp
    right_side = Math.round(Number(wbtcPrice) * Number(left_side) / ONE_8);
    if (add_only){
        await fwpAddToPosition('token-wbtc', 'token-usda', weightX, weightY, 'fwp-wbtc-usda-50-50', left_side, right_side);
    } else {
        await fwpCreate('token-wbtc', 'token-usda', weightX, weightY, 'fwp-wbtc-usda-50-50', 'multisig-fwp-wbtc-usda-50-50', left_side, right_side);         
    }
}

async function create_ytp(add_only){
    console.log("------ YTP Creation / Add Liquidity ------");    

    for(const key in _deploy){
        if (add_only) {
            await ytpAddToPosition(_deploy[key]['yield_token'], _deploy[key]['token'], _deploy[key]['pool_token'], _deploy[key]['liquidity_ytp']);
        } else {
            await ytpCreate(_deploy[key]['yield_token'], _deploy[key]['token'], _deploy[key]['pool_token'], _deploy[key]['multisig_ytp'], _deploy[key]['liquidity_ytp'], _deploy[key]['liquidity_ytp']);
        }        
    }
}

async function create_crp(add_only){
    console.log("------ CRP Creation / Add Liquidity ------");     

    const ltv_0 = 0.6 * ONE_8
    const conversion_ltv = 0.95 * ONE_8
    const bs_vol = 0.8 * ONE_8
    const moving_average = 0.95 * ONE_8    
    
    for(const key in _deploy){
        if (add_only){
            await crpAddToPostionAndSwitch(_deploy[key]['token'], _deploy[key]['collateral'], _deploy[key]['yield_token'], _deploy[key]['key_token'], _deploy[key]['collateral_crp']);    
        } else {
            await crpCreate(_deploy[key]['token'], _deploy[key]['collateral'], _deploy[key]['yield_token'], _deploy[key]['key_token'], _deploy[key]['multisig_crp'], ltv_0, conversion_ltv, bs_vol, moving_average, _deploy[key]['collateral_crp']);            
        }
    }
}

async function set_faucet_amounts(){
    await setUsdaAmount(1000000e+8);
    await setWbtcAmount(24e+8);
    await setStxAmount(100e+8);
}

async function arbitrage_fwp(){
    console.log("------ FWP Arbitrage ------")

    const weightX = 0.5 * ONE_8
    const weightY = 0.5 * ONE_8   

    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;  

    let printed = parseFloat(wbtcPrice / usdaPrice);

    let result = await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    let balance_x = result.value.data['balance-x'].value;
    let balance_y = result.value.data['balance-y'].value;

    let implied = balance_y * BigInt(weightX) / balance_x / BigInt(weightY);
    console.log("printed: ", printed, "implied:", implied);
    if (printed < implied) {
        let dx = await fwpGetXGivenPrice('token-wbtc', 'token-usda', weightX, weightY, printed * ONE_8);
        console.log("dx = ", dx);
        if(dx.type === 7){
            await fwpSwapXforY('token-wbtc', 'token-usda', weightX, weightY, dx.value.value);
        }
    } else {
        let dy = await fwpGetYGivenPrice('token-wbtc', 'token-usda', weightX, weightY, printed * ONE_8);
        console.log("dy = ", dy);
        if(dy.type === 7){
            await fwpSwapYforX('token-wbtc', 'token-usda', weightX, weightY, dy.value.value);
        }
    }  
    result = await fwpGetPoolDetails('token-wbtc', 'token-usda', weightX, weightY);
    balance_x = result.value.data['balance-x'].value;
    balance_y = result.value.data['balance-y'].value;      
    console.log('post arb implied: ', balance_y / balance_x);    
}

async function arbitrage_crp(){
    console.log("------ CRP Arbitrage ------")
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;      

    _list = {
        1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23040e+8 },
        2: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23670e+8 },    
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        4: { token: 'token-wbtc', collateral: 'token-usda', expiry: 59760e+8 },               
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },   
        7: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },                             
        8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },           
    }

    for (const key in _list) {
        console.log(_list[key]);
        printed = parseFloat(wbtcPrice / usdaPrice);
        if (_list[key]['token'] === 'token-usda') {
            printed = parseFloat(usdaPrice / wbtcPrice);
        }

        result = await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']);
        balance_x = result.value.data['balance-x'].value;
        balance_y = result.value.data['balance-y'].value;
        weight_x = result.value.data['weight-x'].value;
        weight_y = result.value.data['weight-y'].value;

        implied = balance_x * weight_y / balance_y / weight_x;
        console.log("printed: ", printed, "implied:", implied);
        if (printed < implied) {
            let dx = await crpGetXgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], printed * ONE_8);
            console.log("dx = ", dx);
            if(dx.type === 7){
                await crpSwapXforY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx.value.value);
            }
        } else {
            let dy = await crpGetYgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], printed * ONE_8);
            console.log("dy = ", dy);
            if(dy.type === 7){
                await crpSwapYforX(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dy.value.value);
            }
        } 
        result = await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']);
        balance_x = result.value.data['balance-x'].value;
        balance_y = result.value.data['balance-y'].value;
        weight_x = result.value.data['weight-x'].value;
        weight_y = result.value.data['weight-y'].value;    
        console.log('post arb implied: ', balance_x * weight_y / balance_y / weight_x);    
    }    
}

async function test_spot_trading(){
    console.log("------ Testing Spot Trading ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;   

    let from_amount = ONE_8;
    let to_amount = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount)).value.value);
    let exchange_rate = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, ONE_8)));
    await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount);

    from_amount = Number(wbtcPrice);
    to_amount = (await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount));
    exchange_rate = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, ONE_8)));
    if (to_amount.type === 7){
        await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount);
    } else {
        console.log(to_amount);
    }
}

async function test_margin_trading(){
    console.log("------ Testing Margin Trading (Long BTC vs USD) ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;   

    let expiry_0 = 23040e+8
    let amount = 1*ONE_8; //gross exposure of 1 BTC
    let trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD    
    let trade_amount = amount; // in BTC
    let ltv = Number((await crpGetLtv('token-usda', 'token-wbtc', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-usda-23040")).value.value);
    let margin = Math.round(amount * (1 - ltv)); // in BTC
    let leverage = 1 / (1 - ltv);

    console.log("ltv: ", ltv, "; amount (BTC): ", amount, "; margin (BTC): ", margin);
    console.log("leverage: ", leverage, "; trade_price (USD): ", trade_price)
    await flExecuteMarginWbtcUsda23040(amount);
    await flashloan('flash-loan-user-margin-wbtc-usda-23040', 'token-wbtc', (amount - margin));

    console.log("------ Testing Margin Trading (Short BTC vs USD) ------");
    expiry_0 = 23040e+8    
    amount = 1*ONE_8; //gross exposure of 1 BTC
    trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD
    trade_amount = amount; // in BTC
    ltv = Number((await crpGetLtv('token-wbtc', 'token-usda', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-wbtc-23040")).value.value);
    margin = Math.round(amount * (1 - ltv) * Number(wbtcPrice) / ONE_8); // in USD
    leverage = 1 / (1 - ltv);

    console.log("ltv: ", ltv, "; amount (BTC): ", amount, "; margin (USD): ", margin);
    console.log("leverage: ", leverage, "; trade_price (USD): ", trade_price)
    await flExecuteMarginUsdaWbtc23040(trade_price);    
    await flashloan('flash-loan-user-margin-usda-wbtc-23040', 'token-usda', (trade_price - margin));    
}

async function get_pool_details_crp(){
    _list = {
        1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23040e+8 },
        2: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23670e+8 },    
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        4: { token: 'token-wbtc', collateral: 'token-usda', expiry: 59760e+8 },               
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },   
        7: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },                             
        8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },           
    }
    
    for (const key in _list){
        printResult(await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']));
    }
}

async function get_pool_details_ytp(){
    _list = {
        1: { yield_token: 'yield-wbtc-23040' },
        2: { yield_token: 'yield-wbtc-34560' },
        3: { yield_token: 'yield-wbtc-74880' },
        4: { yield_token: 'yield-usda-23040' },
        5: { yield_token: 'yield-usda-34560' },
        6: { yield_token: 'yield-usda-74880' }
    }
    for (const key in _list){
        printResult(await ytpGetPoolDetails(_list[key]['yield_token']))
    }
}
async function reduce_position_ytp(percent){
    _list = {
        1: { yield_token: 'yield-wbtc-23040' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-23040-wbtc' },
        2: { yield_token: 'yield-wbtc-34560' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-34560-wbtc' },
        3: { yield_token: 'yield-wbtc-74880' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-74880-wbtc' },
        4: { yield_token: 'yield-usda-23040' , token: 'token-usda' , pool_token: 'ytp-yield-usda-23040-usda' },
        5: { yield_token: 'yield-usda-34560' , token: 'token-usda' , pool_token: 'ytp-yield-usda-23040-usda' },
        6: { yield_token: 'yield-usda-74880' , token: 'token-usda' , pool_token: 'ytp-yield-usda-23040-usda' }
    }
    for(const key in _list){
        await ytpReducePosition(_list[key]['yield_token'], _list[key]['token'], _list[key]['pool_token'], percent);
    }
}

async function run(){
    // await see_deployer_balance();
    // await update_price_oracle();
    // await set_faucet_amounts();
    // await mint_to_deployer();
    // await create_fwp(add_only=true);
    // await create_ytp(add_only=true);
    // await create_crp(add_only=true);
    // await arbitrage_fwp();
    // await arbitrage_crp();
    // await test_spot_trading();
    // await test_margin_trading();
    // await get_pool_details_crp();
    // await get_pool_details_ytp();
    await reduce_position_ytp(0.9999e+8);
}
run();

