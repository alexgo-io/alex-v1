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
    // 1: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-23040', 
    //     key_token: 'key-wbtc-23040-usda',
    //     pool_token: 'ytp-yield-wbtc-23040-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-23040-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-23040-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },
    // 2: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-34560', 
    //     key_token: 'key-wbtc-34560-usda',
    //     pool_token: 'ytp-yield-wbtc-34560-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-34560-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-34560-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },   
    // 3: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-74880', 
    //     key_token: 'key-wbtc-74880-usda',
    //     pool_token: 'ytp-yield-wbtc-74880-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-74880-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-74880-usda',
    //     liquidity_ytp: 250e+8,
    //     collateral_crp: 1000000e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },
    // 4: {token: 'token-usda', 
    //     collateral: 'token-wbtc', 
    //     yield_token: 'yield-usda-74880', 
    //     key_token: 'key-usda-74880-wbtc',
    //     pool_token: 'ytp-yield-usda-74880-usda',
    //     multisig_ytp: 'multisig-ytp-yield-usda-74880-usda',
    //     multisig_crp: 'multisig-crp-usda-74880-wbtc',
    //     liquidity_ytp: 1000000e+8,
    //     collateral_crp: 1e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },      
    // 5: {token: 'token-usda', 
    //     collateral: 'token-wbtc', 
    //     yield_token: 'yield-usda-34560', 
    //     key_token: 'key-usda-34560-wbtc',
    //     pool_token: 'ytp-yield-usda-34560-usda',
    //     multisig_ytp: 'multisig-ytp-yield-usda-34560-usda',
    //     multisig_crp: 'multisig-crp-usda-34560-wbtc',
    //     liquidity_ytp: 1000000e+8,
    //     collateral_crp: 1e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },     
    6: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-23040', 
        key_token: 'key-usda-23040-wbtc',
        pool_token: 'ytp-yield-usda-23040-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-23040-usda',
        multisig_crp: 'multisig-crp-usda-23040-wbtc',
        liquidity_ytp: 1000000e+8,
        collateral_crp: 1e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },
    // 7: {token: 'token-usda', 
    //     collateral: 'yield-usda-74880', 
    //     yield_token: 'yield-usda-23040', 
    //     key_token: 'key-usda-23040-yield-usda-74880',
    //     pool_token: '',
    //     multisig_ytp: '',
    //     multisig_crp: 'multisig-crp-usda-23040-yield-usda-74880',
    //     liquidity_ytp: 1000000e+8,
    //     collateral_crp: 20000e+8,
    //     ltv_0: 0.9e+8,
    //     bs_vol: 0.1e+8
    // }    
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

async function mint_some_tokens(recipient){
    await mint('token-usda', recipient, 100000000000000000n);
    usda_balance = await balance('token-usda', recipient);
    console.log('usda balance: ', usda_balance);    
    await mint('token-wbtc', recipient, 2439024390244);
    wbtc_balance = await balance('token-wbtc', recipient);
    console.log('wbtc balance: ', wbtc_balance);    
}

async function see_balance(owner){
    usda_balance = await balance('token-usda', owner);
    console.log('usda balance: ', usda_balance);
    wbtc_balance = await balance('token-wbtc', owner);
    console.log('wbtc balance: ', wbtc_balance); 
}

async function create_fwp(add_only){
    console.log("------ FWP Creation / Add Liquidity ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  

    usda_balance = await balance('token-usda', process.env.ACCOUNT_ADDRESS);
    console.log('usda balance: ', usda_balance);   
    wbtc_balance = await balance('token-wbtc', process.env.ACCOUNT_ADDRESS);
    console.log('wbtc balance: ', wbtc_balance);   
    
    _pools = {
        1: {
            token_x: 'token-wbtc',
            token_y: 'token-usda',
            weight_x: 0.5e+8,
            weight_y: 0.5e+8,
            pool_token: 'fwp-wbtc-usda-50-50',
            multisig: 'multisig-fwp-wbtc-usda-50-50',
            left_side: Math.round(100000000e+8 * ONE_8 / Number(wbtcPrice)),
            right_side: 100000000e+8
        },
        // 2: {
        //     token_x: 'yield-usda-24030',
        //     token_y: 'yield-usda-74880',
        //     weight_x: 0.5e+8,
        //     weight_y: 0.5e+8,
        //     pool_token: 'fwp-yield-usda-24030-yield-usda-74880-50-50',
        //     multisig: 'multisig-fwp-yield-usda-24030-yield-usda-74880-50-50',
        //     left_side: 1000000e+8,
        //     right_side: 1000000e+8
        // }        
    }

    for (const key in _pools){
        if (add_only){
            await fwpAddToPosition(_pools[key]['token_x'], _pools[key]['token_y'], _pools[key]['weight_x'], _pools[key]['weight_y'], _pools[key]['pool_token'], _pools[key]['left_side'], _pools[key]['right_side']);
        } else {
            await fwpCreate(_pools[key]['token_x'], _pools[key]['token_y'], _pools[key]['weight_x'], _pools[key]['weight_y'], _pools[key]['pool_token'], _pools[key]['multisig'], _pools[key]['left_side'], _pools[key]['right_side']);         
        }
    }
}

async function create_ytp(add_only){
    console.log("------ YTP Creation / Add Liquidity ------");    

    for(const key in _deploy){
        if(_deploy[key]['pool_token'] != ''){
            if (add_only) {
                await ytpAddToPosition(_deploy[key]['yield_token'], _deploy[key]['token'], _deploy[key]['pool_token'], _deploy[key]['liquidity_ytp']);
            } else {
                await ytpCreate(_deploy[key]['yield_token'], _deploy[key]['token'], _deploy[key]['pool_token'], _deploy[key]['multisig_ytp'], _deploy[key]['liquidity_ytp'], _deploy[key]['liquidity_ytp']);
            }        
        }
    }
}

async function create_crp(add_only){
    console.log("------ CRP Creation / Add Liquidity ------");     

    const conversion_ltv = 0.95 * ONE_8
    const moving_average = 0.95 * ONE_8    
    
    for(const key in _deploy){
        if (add_only){
            await crpAddToPostionAndSwitch(_deploy[key]['token'], _deploy[key]['collateral'], _deploy[key]['yield_token'], _deploy[key]['key_token'], _deploy[key]['collateral_crp']);    
        } else {
            await crpCreate(_deploy[key]['token'], _deploy[key]['collateral'], _deploy[key]['yield_token'], _deploy[key]['key_token'], _deploy[key]['multisig_crp'], _deploy[key]['ltv_0'], conversion_ltv, _deploy[key]['bs_vol'], moving_average, _deploy[key]['collateral_crp']);            
        }
    }
}

async function set_faucet_amounts(){
    await setUsdaAmount(500000e+8);
    await setWbtcAmount(5e+8);
    await setStxAmount(250e+8);
}

async function get_some_token(recipient){
    console.log("------ Get Some Tokens ------")
    await see_balance(recipient);
    await getSomeTokens(recipient);
    await see_balance(recipient);
}

async function arbitrage_fwp(){
    console.log("------ FWP Arbitrage ------")

    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;  

    let printed = parseFloat(wbtcPrice / usdaPrice);

    let result = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
    let balance_x = result.value.data['balance-x'].value;
    let balance_y = result.value.data['balance-y'].value;

    let implied = Number(balance_y) / Number(balance_x);
    console.log("printed: ", printed, "implied:", implied);
    if (printed < implied) {
        let dx = await fwpGetXGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, printed * ONE_8);
        console.log("dx = ", dx);
        if(dx.type === 7){
            await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx.value.value);
        }
    } else {
        let dy = await fwpGetYGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, printed * ONE_8);
        console.log("dy = ", dy);
        if(dy.type === 7){
            await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy.value.value);
        }
    }  
    result = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
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
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },   
        7: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },                             
        8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },           
    }

    for (const key in _list) {
        console.log(_list[key]);
        printed = Number(usdaPrice) / Number(wbtcPrice);
        if (_list[key]['token'] === 'token-usda') {
            printed = Number(wbtcPrice) / Number(usdaPrice);
        }

        result = await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']);
        balance_x = result.value.data['balance-x'].value;
        balance_y = result.value.data['balance-y'].value;
        weight_x = result.value.data['weight-x'].value;
        weight_y = result.value.data['weight-y'].value;

        implied = Number(balance_y) * Number(weight_x) / Number(balance_x) / Number(weight_y);
        console.log("printed: ", printed, "implied:", implied);
        if (printed < implied) {
            let dx = await crpGetXgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], Math.round(printed * ONE_8));
            console.log("dx = ", dx);
            if(dx.type === 7){
                await crpSwapXforY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx.value.value);
            }
        } else {
            let dy = await crpGetYgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], Math.round(printed * ONE_8));
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
        implied = Number(balance_y) * Number(weight_x) / Number(balance_x) / Number(weight_y);
        console.log('post arb implied: ', implied);    
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
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },   
        7: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },                             
        8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },           
    }
    
    for (const key in _list){
        printResult(await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']));
    }
}

async function get_pool_details_fwp(){
    printResult(await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8));
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
        5: { yield_token: 'yield-usda-34560' , token: 'token-usda' , pool_token: 'ytp-yield-usda-34560-usda' },
        6: { yield_token: 'yield-usda-74880' , token: 'token-usda' , pool_token: 'ytp-yield-usda-74880-usda' }
    }
    for(const key in _list){
        await ytpReducePosition(_list[key]['yield_token'], _list[key]['token'], _list[key]['pool_token'], percent);
    }
}

_white_list = {
    Hadan: 'SP24XV1GFP70T7CK9SZJMX1BAEV0VQ8PH6D2ZP266',
    Chiente: 'ST3N9GSEWX710RE5PSD110APZGKSD1EFMBEC7PFWK',
    Marvin: 'SP1YMQJR0T1P52RT1VVPZZYZEQXQ5HBE6VWR36HFE',
    James: 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ',
    Jing: 'ST2Q086N22CPRA5RK306CT5T0QFG6GNMJQBY4HXZC',
    Chan: 'ST3BQ65DRM8DMTYDD5HWMN60EYC0JFS5NC262MM33', 
    Sidney: 'ST14YKBTNC0V2QXS3DSGFVCBJHQ7RM396511TJBTJ',
    Liming: 'ST27WEWFJ3R3A8P20SRZHYJT1RP7GQRSB999RBN31',
    Rachel: 'STY8YN3BJBF96FA3T916D5MFQQJ2GMKBNQW10NT5',
    Tiger: 'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4',
    Noise: 'ST290HKX9PWEQ7C3T3MFH3GZ4MXDP10F68K5GPSM2',
    Oscar: 'ST19VTXARP3J5NFH1T69DCVJZ01CYYTWP0ME2VTX0'
}

async function run(){
    // await see_balance(process.env.ACCOUNT_ADDRESS);
    // await update_price_oracle();
    // await set_faucet_amounts();
    // await mint_some_tokens(process.env.ACCOUNT_ADDRESS);
    // await create_fwp(add_only=true);
    // await create_ytp(add_only=true);
    // await create_crp(add_only=true);
    // await arbitrage_fwp();
    // await arbitrage_crp();
    // await test_spot_trading();
    await test_margin_trading();
    // await get_pool_details_fwp();
    // await get_pool_details_crp();
    // await get_pool_details_ytp();
    // await reduce_position_ytp(0.5e+8); // TODO: still doesn't work
    // for(const key in _white_list){
    //     await get_some_token(_white_list[key]);
    //     // await burn('token-wbtc', _white_list[key], 5);
    //     // await burn('token-usda', _white_list[key], 500000e+6);
    // }
    // await mint_some_tokens('STB2BWB0K5XZGS3FXVTG3TKS46CQVV66NAK3YVN8');
}
run();