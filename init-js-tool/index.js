require('dotenv').config();
const { ClarityType, getNonce } = require('@stacks/transactions');
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
    crpGetSpot,
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
    ytpReducePosition,
    ytpGetXgivenYield,
    ytpGetYgivenYield
 } = require('./pools-ytp')

const _deploy = {  
    // test1: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-240', 
    //     key_token: 'key-wbtc-240-usda',
    //     pool_token: 'ytp-yield-wbtc-240-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-240-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-240-usda',
    //     liquidity_ytp: 2500000000000n / BigInt(2),
    //     collateral_crp: 50000e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },
    // test2: {token: 'token-usda', 
    //     collateral: 'token-wbtc', 
    //     yield_token: 'yield-usda-240', 
    //     key_token: 'key-usda-240-wbtc',
    //     pool_token: 'ytp-yield-usda-240-usda',
    //     multisig_ytp: 'multisig-ytp-yield-usda-240-usda',
    //     multisig_crp: 'multisig-crp-usda-240-wbtc',
    //     liquidity_ytp: 100000000000000000n / BigInt(2),
    //     collateral_crp: 1e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },              
    1: {token: 'token-wbtc', 
        collateral: 'token-usda', 
        yield_token: 'yield-wbtc-5760', 
        key_token: 'key-wbtc-5760-usda',
        pool_token: 'ytp-yield-wbtc-5760-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-5760-wbtc',
        multisig_crp: 'multisig-crp-wbtc-5760-usda',
        liquidity_ytp: 2500000000000n / BigInt(2),
        collateral_crp: 50000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },
    2: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-5760', 
        key_token: 'key-usda-5760-wbtc',
        pool_token: 'ytp-yield-usda-5760-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-5760-usda',
        multisig_crp: 'multisig-crp-usda-5760-wbtc',
        liquidity_ytp: 100000000000000000n / BigInt(2),
        collateral_crp: 1e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },              
    3: {token: 'token-wbtc', 
        collateral: 'token-usda', 
        yield_token: 'yield-wbtc-23040', 
        key_token: 'key-wbtc-23040-usda',
        pool_token: 'ytp-yield-wbtc-23040-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-23040-wbtc',
        multisig_crp: 'multisig-crp-wbtc-23040-usda',
        liquidity_ytp: 2500000000000n / BigInt(7),
        collateral_crp: 50000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },
    4: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-23040', 
        key_token: 'key-usda-23040-wbtc',
        pool_token: 'ytp-yield-usda-23040-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-23040-usda',
        multisig_crp: 'multisig-crp-usda-23040-wbtc',
        liquidity_ytp: 100000000000000000n / BigInt(7),
        collateral_crp: 1e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },     
    5: {token: 'token-wbtc', 
        collateral: 'token-usda', 
        yield_token: 'yield-wbtc-34560', 
        key_token: 'key-wbtc-34560-usda',
        pool_token: 'ytp-yield-wbtc-34560-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-34560-wbtc',
        multisig_crp: 'multisig-crp-wbtc-34560-usda',
        liquidity_ytp: 2500000000000n / BigInt(10),
        collateral_crp: 50000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },   
    6: {token: 'token-usda', 
        collateral: 'token-wbtc', 
        yield_token: 'yield-usda-34560', 
        key_token: 'key-usda-34560-wbtc',
        pool_token: 'ytp-yield-usda-34560-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-34560-usda',
        multisig_crp: 'multisig-crp-usda-34560-wbtc',
        liquidity_ytp: 100000000000000000n / BigInt(10),
        collateral_crp: 1e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8
    },    
    // 7: {token: 'token-wbtc', 
    //     collateral: 'token-usda', 
    //     yield_token: 'yield-wbtc-74880', 
    //     key_token: 'key-wbtc-74880-usda',
    //     pool_token: 'ytp-yield-wbtc-74880-wbtc',
    //     multisig_ytp: 'multisig-ytp-yield-wbtc-74880-wbtc',
    //     multisig_crp: 'multisig-crp-wbtc-74880-usda',
    //     liquidity_ytp: 2500000000000n / BigInt(100),
    //     collateral_crp: 50000e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },      
    // 8: {token: 'token-usda', 
    //     collateral: 'token-wbtc', 
    //     yield_token: 'yield-usda-74880', 
    //     key_token: 'key-usda-74880-wbtc',
    //     pool_token: 'ytp-yield-usda-74880-usda',
    //     multisig_ytp: 'multisig-ytp-yield-usda-74880-usda',
    //     multisig_crp: 'multisig-crp-usda-74880-wbtc',
    //     liquidity_ytp: 100000000000000000n / BigInt(100),
    //     collateral_crp: 1e+8,
    //     ltv_0: 0.7e+8,
    //     bs_vol: 0.8e+8
    // },        
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
    await mint_some_usda(recipient);
    await mint_some_wbtc(recipient);
}

async function mint_some_usda(recipient){
    await mint('token-usda', recipient, 200000000000000000n);
    usda_balance = await balance('token-usda', recipient);
    console.log('usda balance: ', usda_balance);
}

async function mint_some_wbtc(recipient){
    await mint('token-wbtc', recipient, 5000000000000);
    wbtc_balance = await balance('token-wbtc', recipient);
    console.log('wbtc balance: ', wbtc_balance);
}

async function see_balance(owner){
    usda_balance = await balance('token-usda', owner);
    console.log('usda balance: ', Number(usda_balance.value.value) / ONE_8);
    wbtc_balance = await balance('token-wbtc', owner);
    console.log('wbtc balance: ', Number(wbtc_balance.value.value) / ONE_8); 
}

async function create_fwp(add_only){
    console.log("------ FWP Creation / Add Liquidity ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  

    usda_balance = await balance('token-usda', process.env.DEPLOYER_ACCOUNT_ADDRESS);
    console.log('usda balance: ', usda_balance);   
    wbtc_balance = await balance('token-wbtc', process.env.DEPLOYER_ACCOUNT_ADDRESS);
    console.log('wbtc balance: ', wbtc_balance);   
    
    _pools = {
        1: {
            token_x: 'token-wbtc',
            token_y: 'token-usda',
            weight_x: 0.5e+8,
            weight_y: 0.5e+8,
            pool_token: 'fwp-wbtc-usda-50-50',
            multisig: 'multisig-fwp-wbtc-usda-50-50',
            left_side: Math.round(Number(100000000000000000) / 2 * ONE_8 / Number(wbtcPrice)),
            right_side: Number(100000000000000000) / 2
        },
        // 2: {
        //     token_x: 'yield-usda-23040',
        //     token_y: 'yield-usda-74880',
        //     weight_x: 0.5e+8,
        //     weight_y: 0.5e+8,
        //     pool_token: 'fwp-yield-usda-23040-yield-usda-74880-50-50',
        //     multisig: 'multisig-fwp-yield-usda-23040-yield-usda-74880-50-50',
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
            await crpAddToPostion(_deploy[key]['token'], _deploy[key]['collateral'], _deploy[key]['yield_token'], _deploy[key]['key_token'], _deploy[key]['collateral_crp']);    
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

async function arbitrage_fwp(dry_run=true){
    console.log("------ FWP Arbitrage ------")
    console.log(timestamp());

    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;  

    let printed = parseFloat(wbtcPrice / usdaPrice);

    let result = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
    let balance_x = result.value.data['balance-x'].value;
    let balance_y = result.value.data['balance-y'].value;

    let implied = Number(balance_y) / Number(balance_x);
    console.log("printed: ", printed, "implied:", implied);

    if (!dry_run) {
        if (printed < implied) {
            let dx = await fwpGetXGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, printed * ONE_8);

            if(dx.type === 7 && dx.value.value > 0n){
                let dy = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx.value.value);
                if(dy.type == 7) {
                    await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx.value.value);
                } else {
                    console.log('error: ', dy.value.value);
                    let dx_i = Number(dx.value.value) / 4;
                    for(let i = 0; i < 4; i++){
                        let dy_i = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx_i);
                        if( dy_i.type == 7 ){
                            await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx_i);
                        }
                    }
                }
            } else {
                console.log('error (or zero): ', dx.value.value);
            }
        } else {
            let dy = await fwpGetYGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, printed * ONE_8);

            if(dy.type === 7 && dy.value.value > 0n){
                let dx = await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy.value.value);
                if(dx.type == 7) {
                    await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy.value.value);
                } else {
                    console.log('error: ', dx.value.value);
                    let dy_i = Number(dy.value.value) / 4;
                    for(let i = 0; i < 4; i++){
                        let dx_i = await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy_i);
                        if( dx_i.type == 7 ){
                            await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy_i);
                        }
                    }
                }
            } else {
                console.log('error (or zero): ', dy.value.value);
            }
        }  
        result = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
        balance_x = result.value.data['balance-x'].value;
        balance_y = result.value.data['balance-y'].value;      
        console.log('post arb implied: ', balance_y / balance_x);    
    }
}

async function arbitrage_crp(dry_run=true){
    console.log("------ CRP Arbitrage ------")
    console.log(timestamp());    
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;      

    _list = {
        // test1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 240e+8 },
        // test2: { token: 'token-usda', collateral: 'token-wbtc', expiry: 240e+8 },            
        1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 5760e+8 },
        2: { token: 'token-usda', collateral: 'token-wbtc', expiry: 5760e+8 },        
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23040e+8 },
        4: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },          
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },          
        // 7: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        // 8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },                                       
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

        if (!dry_run){
            if (printed < implied) {
                let dx = await crpGetXgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], Math.round(printed * ONE_8));

                if(dx.type === 7 && dx.value.value > 0n){
                    let dy = await crpGetYgivenX(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx.value.value);
                    if(dy.type == 7){
                        await crpSwapXforY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx.value.value);
                    } else {
                        console.log('error: ', dy.value.value);
                        let dx_i = Math.round(Number(dx.value.value) / 4);
                        for(let i = 0; i < 4; i++) {
                            let dy_i = await crpGetYgivenX(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx_i);
                            if(dy_i.type == 7) {
                                await crpSwapXforY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dx_i);
                            } else {
                                console.log('error: ', dy_i.value.value);
                            }
                        }
                    }
                } else {
                    console.log('error (or zero): ', dx.value.value);
                }
            } else {
                let dy = await crpGetYgivenPrice(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], Math.round(printed * ONE_8));

                if(dy.type === 7 && dy.value.value > 0n){
                    let dx = await crpGetXgivenY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dy.value.value);
                    if(dx.type == 7){
                        await crpSwapYforX(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dy.value.value);
                    } else {
                        console.log('error: ', dx.value.value);
                        let dy_i = Math.round(Number(dy.value.value) / 4);
                        for(let i = 0; i < 4; i++) {
                            let dx_i = await crpGetXgivenY(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dy_i);
                            if(dx_i.type == 7) {
                                await crpSwapYforX(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'], dy_i);
                            } else {
                                console.log('error: ', dx_i.value.value);
                            }
                        }                    
                    }
                } else {
                    console.log('error (or zero): ', dy.value.value);
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
}

async function arbitrage_ytp(dry_run=true){
    console.log("------ YTP Arbitrage ------")
    console.log(timestamp());

    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;      

    _list = {
        // test1: { yield_token: 'yield-wbtc-240' , token: 'token-wbtc', target_apy: 0.10, collateral: 'token-usda', key_token: 'key-wbtc-240-usda', expiry: 240e+8 },
        // test2: { yield_token: 'yield-usda-240' , token: 'token-usda', target_apy: 0.10, collateral: 'token-wbtc', key_token: 'key-usda-240-wbtc', expiry: 240e+8 },        
        1: { yield_token: 'yield-wbtc-5760' , token: 'token-wbtc', target_apy: 0.10, collateral: 'token-usda', key_token: 'key-wbtc-5760-usda', expiry: 5760e+8 },
        2: { yield_token: 'yield-usda-5760' , token: 'token-usda', target_apy: 0.10, collateral: 'token-wbtc', key_token: 'key-usda-5760-wbtc', expiry: 5760e+8 },        
        3: { yield_token: 'yield-wbtc-23040' , token: 'token-wbtc', target_apy: 0.15, collateral: 'token-usda', key_token: 'key-wbtc-23040-usda', expiry: 23040e+8 },
        4: { yield_token: 'yield-usda-23040' , token: 'token-usda', target_apy: 0.15, collateral: 'token-wbtc', key_token: 'key-usda-23040-wbtc', expiry: 23040e+8 },        
        5: { yield_token: 'yield-wbtc-34560' , token: 'token-wbtc', target_apy: 0.20, collateral: 'token-usda', key_token: 'key-wbtc-34560-usda', expiry: 34560e+8 },
        6: { yield_token: 'yield-usda-34560' , token: 'token-usda', target_apy: 0.20, collateral: 'token-wbtc', key_token: 'key-usda-34560-wbtc', expiry: 34560e+8 },        
        // 7: { yield_token: 'yield-wbtc-74880' , token: 'token-wbtc', target_apy: 0.30, collateral: 'token-usda', key_token: 'key-wbtc-74880-usda', expiry: 74880e+8 },
        // 8: { yield_token: 'yield-usda-74880' , token: 'token-usda', target_apy: 0.30, collateral: 'token-wbtc', key_token: 'key-usda-74880-wbtc', expiry: 74880e+8 }                                  
    }

    for (const key in _list) {
        console.log(_list[key]);
        result = await ytpGetYield(_list[key]['yield_token']);
        implied_yield = Number(result.value.value) / ONE_8;

        let node_info = await (await fetch('https://regtest-2.alexgo.io/v2/info')).json();
        let time_to_maturity = (Math.round(_list[key]['expiry'] / ONE_8) - node_info['burn_block_height']) / 2102400;
        target_yield = _list[key]['target_apy'] * time_to_maturity;

        console.log("target: ", target_yield, "implied:", implied_yield);

        if (!dry_run){
            if (target_yield < implied_yield) {
                let dx = await ytpGetXgivenYield(_list[key]['yield_token'], Math.round(target_yield * ONE_8));

                if(dx.type === 7 && dx.value.value > 0n){
                    let dy = await ytpGetYgivenX(_list[key]['yield_token'], dx.value.value);                    
                    if(dy.type == 7){                
                        await ytpSwapXforY(_list[key]['yield_token'], _list[key]['token'], dx.value.value);
                    } else {
                        console.log('error: ', dy.value.value);
                        dx_i = Math.round(Number(dx.value.value) / 4);
                        for (let i = 0; i < 4; i++) {
                            let dy_i = await ytpGetYgivenX(_list[key]['yield_token'], dx_i);
                            if(dy_i.type == 7){
                                await ytpSwapXforY(_list[key]['yield_token'], _list[key]['token'], dx_i);
                            } else {
                                console.log('error: ', dy_i.value.value);
                            }
                        }
                    }
                } else {
                    console.log('error (or zero):', dx.value.value);
                }
            } else {
                let dy = await ytpGetYgivenYield(_list[key]['yield_token'], Math.round(target_yield * ONE_8));
                
                if(dy.type === 7 && dy.value.value > 0n){
                    let spot = Number((await crpGetSpot(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'])).value.value) / ONE_8;
                    let dy_collateral = Number(dy.value.value) * spot;
                    let ltv = Number((await crpGetLtv(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'])).value.value);
                    ltv /= Number((await ytpGetPrice(_list[key]['yield_token'])).value.value);
                    let dy_ltv = Math.round(dy_collateral / ltv);
                    let dx = await ytpGetXgivenY(_list[key]['yield_token'], Math.round(Number(dy.value.value) / ltv));                    
                    let dx_fwp;
                    if(_list[key]['collateral'] == 'token-usda') {
                        dx_fwp = await fwpGetXgivenY(_list[key]['token'], _list[key]['collateral'], 0.5e+8, 0.5e+8, dy_ltv);
                    } else {
                        dx_fwp = await fwpGetYgivenX(_list[key]['collateral'], _list[key]['token'], 0.5e+8, 0.5e+8, dy_ltv);
                    }
                    if (dx.type == 7 && dx_fwp.type == 7){
                        await crpAddToPostionAndSwitch(_list[key]['token'], _list[key]['collateral'], _list[key]['yield_token'], _list[key]['key_token'], dy_ltv);
                    } else {         
                        console.log('error (ytp): ', dx.value.value, 'error (fwp): ', dx_fwp.value.value);          
                        dy_ltv = Math.round(dy_ltv / 4);
                        dy_i = Math.round(Number(dy.value.value) / 4 );
                        for (let i = 0; i < 4; i++){
                            let dx_i = await ytpGetXgivenY(_list[key]['yield_token'], dy_i);
                            if (dx_i.type == 7){
                                await crpAddToPostionAndSwitch(_list[key]['token'], _list[key]['collateral'], _list[key]['yield_token'], _list[key]['key_token'], dy_ltv); 
                            } else {
                                console.log('error: ', dx_i.value.value);
                            }
                        }
                    }
                } else {
                    console.log('error (or zero): ', dy.value.value);
                }
            }    

            result = await ytpGetYield(_list[key]['yield_token']);
            implied_yield = Number(result.value.value) / ONE_8;
            console.log('post arb implied: ', implied_yield);    
        }
    }    
}

async function test_spot_trading(){
    console.log("------ Testing Spot Trading ------");
    console.log(timestamp());    
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
    console.log(timestamp());    
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;  
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;   

    let expiry_0 = 5760e+8
    let amount = 1*ONE_8; //gross exposure of 1 BTC
    let trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD    
    let trade_amount = amount; // in BTC
    let ltv = Number((await crpGetLtv('token-usda', 'token-wbtc', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-usda-5760")).value.value);
    let margin = Math.round(amount * (1 - ltv)); // in BTC
    let leverage = 1 / (1 - ltv);

    console.log("ltv: ", ltv, "; amount (BTC): ", amount, "; margin (BTC): ", margin);
    console.log("leverage: ", leverage, "; trade_price (USD): ", trade_price)

    await flashloan('flash-loan-user-margin-wbtc-usda-5760', 'token-wbtc', (amount - margin));

    console.log("------ Testing Margin Trading (Short BTC vs USD) ------");
    console.log(timestamp());    
    expiry_0 = 5760e+8    
    amount = 1*ONE_8; //gross exposure of 1 BTC
    trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD
    trade_amount = amount; // in BTC
    ltv = Number((await crpGetLtv('token-wbtc', 'token-usda', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-wbtc-5760")).value.value);
    margin = Math.round(amount * (1 - ltv) * Number(wbtcPrice) / ONE_8); // in USD
    leverage = 1 / (1 - ltv);

    console.log("ltv: ", ltv, "; amount (BTC): ", amount, "; margin (USD): ", margin);
    console.log("leverage: ", leverage, "; trade_price (USD): ", trade_price)

    await flashloan('flash-loan-user-margin-usda-wbtc-5760', 'token-usda', (trade_price - margin));    
}

function format_number(number, fixed=2){
    return number.toFixed(fixed).replace(/\d(?=(\d{3})+\.)/g, '$&,');    
}

async function get_pool_details_crp(){
    _list = {
        // test1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 240e+8 },
        // test2: { token: 'token-usda', collateral: 'token-wbtc', expiry: 240e+8 },                        
        1: { token: 'token-wbtc', collateral: 'token-usda', expiry: 5760e+8 },
        2: { token: 'token-usda', collateral: 'token-wbtc', expiry: 5760e+8 },        
        3: { token: 'token-wbtc', collateral: 'token-usda', expiry: 23040e+8 },
        4: { token: 'token-usda', collateral: 'token-wbtc', expiry: 23040e+8 },          
        5: { token: 'token-wbtc', collateral: 'token-usda', expiry: 34560e+8 }, 
        6: { token: 'token-usda', collateral: 'token-wbtc', expiry: 34560e+8 },          
        // 7: { token: 'token-wbtc', collateral: 'token-usda', expiry: 74880e+8 },            
        // 8: { token: 'token-usda', collateral: 'token-wbtc', expiry: 74880e+8 },                                    
    }
    
    for (const key in _list){
        let ltv = await crpGetLtv(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']);
        let details = await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry'])
        let balance_x = details.value.data['balance-x'];
        let balance_y = details.value.data['balance-y'];
        let weight_x = details.value.data['weight-x'];
        let weight_y = details.value.data['weight-y'];
        console.log('ltv: ', format_number(Number(ltv.value.value) / ONE_8),
                    'balance-collateral: ', format_number(Number(balance_x.value) / ONE_8),
                    'balance-token: ', format_number(Number(balance_y.value) / ONE_8),
                    'weights: ', format_number(Number(weight_x.value) / ONE_8),                    
                    '/', format_number(Number(weight_y.value) / ONE_8));
        // printResult(await crpGetPoolDetails(_list[key]['token'], _list[key]['collateral'], _list[key]['expiry']));
    }
}

async function get_pool_details_fwp(){
    let details = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
    let balance_x = details.value.data['balance-x'];
    let balance_y = details.value.data['balance-y'];

    console.log('balance-x: ', format_number(Number(balance_x.value) / ONE_8), 'balance-y: ', format_number(Number(balance_y.value) / ONE_8));
}

async function get_pool_details_ytp(){
    _list = {
        // test1: { yield_token: 'yield-wbtc-240' },
        // test2: { yield_token: 'yield-usda-240' }, 
        1: { yield_token: 'yield-wbtc-5760' },
        2: { yield_token: 'yield-usda-5760' },        
        3: { yield_token: 'yield-wbtc-23040' },
        4: { yield_token: 'yield-usda-23040' },        
        5: { yield_token: 'yield-wbtc-34560' },
        6: { yield_token: 'yield-usda-34560' },        
        // 7: { yield_token: 'yield-wbtc-74880' },
        // 8: { yield_token: 'yield-usda-74880' }
    }
    for (const key in _list){
        let yied = await ytpGetYield(_list[key]['yield_token']);
        let price = await ytpGetPrice(_list[key]['yield_token']);
        let details = await ytpGetPoolDetails(_list[key]['yield_token']);
        let balance_aytoken = details.value.data['balance-aytoken'];
        let balance_virtual = details.value.data['balance-virtual'];
        let balance_token = details.value.data['balance-token'];

        console.log('yield: ', format_number(Number(yied.value.value) / ONE_8, 8), 'price: ', format_number(Number(price.value.value) / ONE_8, 8));
        console.log('balance (yield-token/virtual/token): ', 
                    format_number(Number(balance_aytoken.value) / ONE_8), 
                    format_number(Number(balance_virtual.value) / ONE_8), 
                    format_number(Number(balance_token.value) / ONE_8));
    }
}
async function reduce_position_ytp(percent){
    _list = {
        1: { yield_token: 'yield-wbtc-23040' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-23040-wbtc' },
        2: { yield_token: 'yield-usda-23040' , token: 'token-usda' , pool_token: 'ytp-yield-usda-23040-usda' },
        3: { yield_token: 'yield-wbtc-34560' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-34560-wbtc' },        
        4: { yield_token: 'yield-usda-34560' , token: 'token-usda' , pool_token: 'ytp-yield-usda-34560-usda' },
        // 5: { yield_token: 'yield-usda-74880' , token: 'token-usda' , pool_token: 'ytp-yield-usda-74880-usda' },
        // 6: { yield_token: 'yield-wbtc-74880' , token: 'token-wbtc' , pool_token: 'ytp-yield-wbtc-74880-wbtc' },        
    }
    for(const key in _list){
        await ytpReducePosition(_list[key]['yield_token'], _list[key]['token'], _list[key]['pool_token'], percent);
    }
}

async function reduce_position_crp(percent, _type){
    _list = {
        // test1: { yield_token: 'yield-wbtc-240' , token: 'token-wbtc', target_apy: 0.10, collateral: 'token-usda', key_token: 'key-wbtc-240-usda', expiry: 240e+8 },
        // test2: { yield_token: 'yield-usda-240' , token: 'token-usda', target_apy: 0.10, collateral: 'token-wbtc', key_token: 'key-usda-240-wbtc', expiry: 240e+8 },        
        1: { yield_token: 'yield-wbtc-5760' , token: 'token-wbtc', target_apy: 0.10, collateral: 'token-usda', key_token: 'key-wbtc-5760-usda', expiry: 5760e+8 },
        2: { yield_token: 'yield-usda-5760' , token: 'token-usda', target_apy: 0.10, collateral: 'token-wbtc', key_token: 'key-usda-5760-wbtc', expiry: 5760e+8 },        
        3: { yield_token: 'yield-wbtc-23040' , token: 'token-wbtc', target_apy: 0.15, collateral: 'token-usda', key_token: 'key-wbtc-23040-usda', expiry: 23040e+8 },
        4: { yield_token: 'yield-usda-23040' , token: 'token-usda', target_apy: 0.15, collateral: 'token-wbtc', key_token: 'key-usda-23040-wbtc', expiry: 23040e+8 },        
        5: { yield_token: 'yield-wbtc-34560' , token: 'token-wbtc', target_apy: 0.20, collateral: 'token-usda', key_token: 'key-wbtc-34560-usda', expiry: 34560e+8 },
        6: { yield_token: 'yield-usda-34560' , token: 'token-usda', target_apy: 0.20, collateral: 'token-wbtc', key_token: 'key-usda-34560-wbtc', expiry: 34560e+8 },        
        // 7: { yield_token: 'yield-wbtc-74880' , token: 'token-wbtc', target_apy: 0.30, collateral: 'token-usda', key_token: 'key-wbtc-74880-usda', expiry: 74880e+8 },
        // 8: { yield_token: 'yield-usda-74880' , token: 'token-usda', target_apy: 0.30, collateral: 'token-wbtc', key_token: 'key-usda-74880-wbtc', expiry: 74880e+8 }                                  
    }
    
    for(const key in _list){
        if (_type === 'yield') {
            await crpReducePostionYield(_list[key]['token'], _list[key]['collateral'], _list[key]['yield_token'], ONE_8);
        } else if (_type === 'key') {
            await crpReducePostionKey(_list[key]['token'], _list[key]['collateral'], _list[key]['key_token'], ONE_8);
        }
    }
}

function timestamp() {
    // Create a date object with the current time
      var now = new Date();
    
    // Create an array with the current month, day and time
      var date = [ now.getMonth() + 1, now.getDate(), now.getFullYear() ];
    
    // Create an array with the current hour, minute and second
      var time = [ now.getHours(), now.getMinutes(), now.getSeconds() ];
    
    // Determine AM or PM suffix based on the hour
      var suffix = ( time[0] < 12 ) ? "AM" : "PM";
    
    // Convert hour from military time
      time[0] = ( time[0] < 12 ) ? time[0] : time[0] - 12;
    
    // If hour is 0, set it to 12
      time[0] = time[0] || 12;
    
    // If seconds and minutes are less than 10, add a zero
      for ( var i = 1; i < 3; i++ ) {
        if ( time[i] < 10 ) {
          time[i] = "0" + time[i];
        }
      }
    
    // Return the formatted string
      return date.join("/") + " " + time.join(":") + " " + suffix;
}


_white_list = {
    // Hadan: 'STBAY5N5TRTEHHXRP4MH5H3W5FK2EXJDJWDYFA02',
    // Chiente: 'ST3N9GSEWX710RE5PSD110APZGKSD1EFMBEC7PFWK',
    // Marvin: 'SP1YMQJR0T1P52RT1VVPZZYZEQXQ5HBE6VWR36HFE',
    // James: 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ',
    // Jing: 'ST2Q086N22CPRA5RK306CT5T0QFG6GNMJQBY4HXZC',
    // Chan: 'ST3BQ65DRM8DMTYDD5HWMN60EYC0JFS5NC262MM33', 
    // Chan2: 'STPXVKFHHPJ9FTMQEXCM41PH1042BVG2YMM310TK',
    // Chan3: 'ST2FJ75N8SNQY91W997VEPPCZX41GXBXR8ASX7DK3',
    // Chan4: 'ST1XARV3J1N3SJJBDJCE3WE84KDHZQGMGBAZR2JXT',
    // Chan5: 'ST3SP15W4B0D1DS8R37E85XP9E48FTD2JF30X11D9',
    // Chan6: 'ST37GBP1245R8TCX45YPXG088EDXWWY949J8A7618',
    // Sidney: 'ST14YKBTNC0V2QXS3DSGFVCBJHQ7RM396511TJBTJ',
    // Liming: 'ST27WEWFJ3R3A8P20SRZHYJT1RP7GQRSB999RBN31',
    // Rachel: 'STY8YN3BJBF96FA3T916D5MFQQJ2GMKBNQW10NT5',
    Rachel2: 'ST3N7Y3K01Y24G9JC1XXA13RQXXCY721WATVHV81Y',
    // Tiger: 'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4',
    // Noise: 'ST290HKX9PWEQ7C3T3MFH3GZ4MXDP10F68K5GPSM2',
    // Oscar: 'ST19VTXARP3J5NFH1T69DCVJZ01CYYTWP0ME2VTX0',
    // Oscar2: 'ST2HRPEK5BC4C9CGNRT95Z85M9B9C3M99C6V7A6EZ',
    // Shawn: 'ST27TPYFGSGT3YGTEBTVMHZXD511AE6JGP15XVZDS'    
}

async function run(){
    // await set_faucet_amounts();
    // await see_balance(process.env.DEPLOYER_ACCOUNT_ADDRESS);
    // await update_price_oracle();    
    // await mint_some_tokens(process.env.DEPLOYER_ACCOUNT_ADDRESS);
    // await mint_some_usda(process.env.DEPLOYER_ACCOUNT_ADDRESS + '.alex-reserve-pool');    
    // await mint_some_tokens(process.env.USER_ACCOUNT_ADDRESS);
    // await get_some_token(process.env.USER_ACCOUNT_ADDRESS);
    // await create_fwp(add_only=false);
    // await create_ytp(add_only=false);
    // await create_crp(add_only=false);    
    
    // await arbitrage_fwp(dry_run=false);
    // await arbitrage_crp(dry_run=false);    
    // await arbitrage_ytp(dry_run=false);    
    
    // await test_spot_trading();
    // await test_margin_trading();

    // await create_fwp(add_only=true);
    // await create_crp(add_only=true);     
    // await create_ytp(add_only=true);

    // await arbitrage_fwp(dry_run=true);
    // await arbitrage_crp(dry_run=true);    
    // await arbitrage_ytp(dry_run=true); 
    await get_pool_details_fwp();
    await get_pool_details_crp();
    await get_pool_details_ytp();   

    // await reduce_position_ytp(0.5e+8);
    // await reduce_position_crp(ONE_8, 'yield');
    // await reduce_position_crp(ONE_8, 'key');
    
    // await see_balance(process.env.DEPLOYER_ACCOUNT_ADDRESS + '.alex-vault');        
    // await see_balance(process.env.USER_ACCOUNT_ADDRESS);        

    // for(const key in _white_list){
    //     await get_some_token(_white_list[key]);
    //     // await burn('token-wbtc', _white_list[key], 5);
    //     // await burn('token-usda', _white_list[key], 500000e+6);
    // }
}
run();