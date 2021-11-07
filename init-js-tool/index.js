require('dotenv').config();
const { ClarityType, getNonce } = require('@stacks/transactions');
const { initCoinPrice, setOpenOracle, getOpenOracle } = require('./oracles').default
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
const { flashloan, getBalance, mint, burn, balance, transfer } = require('./vault')
const { setUsdaAmount, setWbtcAmount, setStxAmount, getSomeTokens, setAlexAmount } = require('./faucet')
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
    ytpGetYgivenYield,
    ytpGetPositionGivenBurn
} = require('./pools-ytp')

const _deploy = {
    0: {token: 'token-wbtc',
        collateral: 'token-usda',
        yield_token: 'yield-wbtc-11520',
        key_token: 'key-wbtc-11520-usda',
        pool_token: 'ytp-yield-wbtc-11520-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-11520-wbtc',
        multisig_crp: 'multisig-crp-wbtc-11520-usda',
        liquidity_ytp: 100e+8,
        collateral_crp: 1500000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.06354,
        expiry: 11520e+8,
    },
    1: {token: 'token-usda',
        collateral: 'token-wbtc',
        yield_token: 'yield-usda-11520',
        key_token: 'key-usda-11520-wbtc',
        pool_token: 'ytp-yield-usda-11520-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-11520-usda',
        multisig_crp: 'multisig-crp-usda-11520-wbtc',
        liquidity_ytp: 6000000e+8,
        collateral_crp: 25e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.086475,
        expiry: 11520e+8,
    },
    2: {
        token: 'token-wbtc',
        collateral: 'token-usda',
        yield_token: 'yield-wbtc-51840',
        key_token: 'key-wbtc-51840-usda',
        pool_token: 'ytp-yield-wbtc-51840-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-51840-wbtc',
        multisig_crp: 'multisig-crp-wbtc-51840-usda',
        liquidity_ytp: 100e+8,
        collateral_crp: 1500000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.093486,
        expiry: 51840e+8,
    },
    3: {
        token: 'token-usda',
        collateral: 'token-wbtc',
        yield_token: 'yield-usda-51840',
        key_token: 'key-usda-51840-wbtc',
        pool_token: 'ytp-yield-usda-51840-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-51840-usda',
        multisig_crp: 'multisig-crp-usda-51840-wbtc',
        liquidity_ytp: 6000000e+8,
        collateral_crp: 25e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.10768,
        expiry: 51840e+8,
    },
    4: {token: 'token-wbtc',
        collateral: 'token-usda',
        yield_token: 'yield-wbtc-92160',
        key_token: 'key-wbtc-92160-usda',
        pool_token: 'ytp-yield-wbtc-92160-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-92160-wbtc',
        multisig_crp: 'multisig-crp-wbtc-92160-usda',
        liquidity_ytp: 100e+8,
        collateral_crp: 1500000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.09469,
        expiry: 92160e+8,
    },
    5: {token: 'token-usda',
        collateral: 'token-wbtc',
        yield_token: 'yield-usda-92160',
        key_token: 'key-usda-92160-wbtc',
        pool_token: 'ytp-yield-usda-92160-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-92160-usda',
        multisig_crp: 'multisig-crp-usda-92160-wbtc',
        liquidity_ytp: 6000000e+8,
        collateral_crp: 25e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.10950,
        expiry: 92160e+8,
    },     
    6: {token: 'token-wbtc',
        collateral: 'token-usda',
        yield_token: 'yield-wbtc-132481',
        key_token: 'key-wbtc-132481-usda',
        pool_token: 'ytp-yield-wbtc-132481-wbtc',
        multisig_ytp: 'multisig-ytp-yield-wbtc-132481-wbtc',
        multisig_crp: 'multisig-crp-wbtc-132481-usda',
        liquidity_ytp: 100e+8,
        collateral_crp: 1500000e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.18469,
        expiry: 132481e+8,
    },
    7: {token: 'token-usda',
        collateral: 'token-wbtc',
        yield_token: 'yield-usda-132481',
        key_token: 'key-usda-132481-wbtc',
        pool_token: 'ytp-yield-usda-132481-usda',
        multisig_ytp: 'multisig-ytp-yield-usda-132481-usda',
        multisig_crp: 'multisig-crp-usda-132481-wbtc',
        liquidity_ytp: 6000000e+8,
        collateral_crp: 25e+8,
        ltv_0: 0.7e+8,
        bs_vol: 0.8e+8,
        target_apy: 0.16950,
        expiry: 132481e+8,
    },      
}

const ONE_8 = 100000000

const printResult = (result) => {
    if (result.type === ClarityType.ResponseOk) {
        if (result.value.type == ClarityType.UInt) {
            console.log(result.value);
        } else if (result.value.type == ClarityType.Tuple) {
            console.log('|');
            for (const key in result.value.data) {
                console.log('---', key, ':', result.value.data[key]);
            }
        }
    }
}

async function update_price_oracle() {
    console.log("------ Update Price Oracle ------")
    const { usdc, btc } = await initCoinPrice()
    await setOpenOracle('WBTC', 'coingecko', btc);
    await setOpenOracle('USDA', 'coingecko', usdc);
}

async function mint_some_tokens(recipient) {
    console.log('------ Mint Some Tokens ------');
    await mint_some_usda(recipient);
    await mint_some_wbtc(recipient);
}

async function mint_some_usda(recipient) {
    console.log('------ Mint Some USDA ------');
    // await mint('token-usda', recipient, 200000000000000000n);
    await mint('token-usda', recipient, 10000000000 * ONE_8);
    usda_balance = await balance('token-usda', recipient);
    console.log('usda balance: ', format_number(Number(usda_balance.value.value) / ONE_8));
}

async function mint_some_wbtc(recipient) {
    console.log('------ Mint Some WBTC ------');
    await mint('token-wbtc', recipient, 50000000000);
    // await mint('token-wbtc', recipient, Math.round(10000000000 * ONE_8 / 61800));
    wbtc_balance = await balance('token-wbtc', recipient);
    console.log('wbtc balance: ', format_number(Number(wbtc_balance.value.value) / ONE_8));
}

async function see_balance(owner) {
    console.log('------ See Balance ------');
    usda_balance = await balance('token-usda', owner);
    console.log('usda balance: ', format_number(Number(usda_balance.value.value) / ONE_8));
    wbtc_balance = await balance('token-wbtc', owner);
    console.log('wbtc balance: ', format_number(Number(wbtc_balance.value.value) / ONE_8));
}

async function create_fwp(add_only) {
    console.log("------ FWP Creation / Add Liquidity ------");
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;

    _pools = {
        1: {
            token_x: 'token-wbtc',
            token_y: 'token-usda',
            weight_x: 0.5e+8,
            weight_y: 0.5e+8,
            pool_token: 'fwp-wbtc-usda-50-50',
            multisig: 'multisig-fwp-wbtc-usda-50-50',
            // left_side: Math.round(Number(100000000000000000) / 2 * ONE_8 / Number(wbtcPrice)),
            // right_side: Number(100000000000000000) / 2
            left_side: Math.round(10000000000 * ONE_8 * ONE_8 / Number(wbtcPrice)),
            right_side: 10000000000 * ONE_8            
        },
    }

    for (const key in _pools) {
        if (add_only) {
            await fwpAddToPosition(_pools[key]['token_x'], _pools[key]['token_y'], _pools[key]['weight_x'], _pools[key]['weight_y'], _pools[key]['pool_token'], _pools[key]['left_side'], _pools[key]['right_side']);
        } else {
            await fwpCreate(_pools[key]['token_x'], _pools[key]['token_y'], _pools[key]['weight_x'], _pools[key]['weight_y'], _pools[key]['pool_token'], _pools[key]['multisig'], _pools[key]['left_side'], _pools[key]['right_side']);
        }
    }
}

async function create_ytp(add_only, _subset=_deploy) {
    console.log("------ YTP Creation / Add Liquidity ------");

    for (const key in _subset) {
        if (_subset[key]['pool_token'] != '') {
            if (add_only) {
                await ytpAddToPosition(_subset[key]['yield_token'], _subset[key]['token'], _subset[key]['pool_token'], _subset[key]['liquidity_ytp']);
            } else {
                await ytpCreate(_subset[key]['yield_token'], _subset[key]['token'], _subset[key]['pool_token'], _subset[key]['multisig_ytp'], _subset[key]['liquidity_ytp'], _subset[key]['liquidity_ytp']);
            }
        }
    }
}

async function create_crp(add_only, _subset=_deploy) {
    console.log("------ CRP Creation / Add Liquidity ------");

    const conversion_ltv = 0.95 * ONE_8
    const moving_average = 0.95 * ONE_8

    for (const key in _subset) {
        if (add_only) {
            await crpAddToPostion(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['yield_token'], _subset[key]['key_token'], _subset[key]['collateral_crp']);
        } else {
            await crpCreate(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['yield_token'], _subset[key]['key_token'], _subset[key]['multisig_crp'], _subset[key]['ltv_0'], conversion_ltv, _subset[key]['bs_vol'], moving_average, _subset[key]['collateral_crp']);
        }
    }
}

async function set_faucet_amounts() {
    console.log('------ Set Faucet Amounts ------');
    await setUsdaAmount(500000e+8);
    await setWbtcAmount(5e+8);
    await setStxAmount(250e+8);
    await setAlexAmount(10e+8)
}

async function get_some_token(recipient) {
    console.log("------ Get Some Tokens ------")
    await see_balance(recipient);
    await getSomeTokens(recipient);
    await see_balance(recipient);
}

async function arbitrage_fwp(dry_run = true) {
    console.log("------ FWP Arbitrage ------")
    console.log(timestamp());

    const threshold = 0.002;

    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;

    let printed = parseFloat(wbtcPrice / usdaPrice);

    let result = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
    let balance_x = result.value.data['balance-x'].value;
    let balance_y = result.value.data['balance-y'].value;

    let implied = Number(balance_y) / Number(balance_x);
    console.log("printed: ", format_number(printed, 8), "implied:", format_number(implied, 8));

    if (!dry_run) {
        let diff = Math.abs(printed - implied) / implied;
        if (diff > threshold) {
            if (printed < implied) {
                let dx = await fwpGetXGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, Math.round(printed * ONE_8));

                if (dx.type === 7 && dx.value.value > 0n) {
                    let dy = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx.value.value);
                    if (dy.type == 7) {
                        await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx.value.value, 0);
                    } else {
                        console.log('error: ', dy.value.value);
                        let dx_i = Math.round(Number(dx.value.value) / 4);
                        for (let i = 0; i < 4; i++) {
                            let dy_i = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx_i);
                            if (dy_i.type == 7) {
                                await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dx_i, 0);
                            }
                        }
                    }
                } else {
                    console.log('error (or zero): ', dx.value.value);
                }
            } else {
                let dy = await fwpGetYGivenPrice('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, Math.round(printed * ONE_8));

                if (dy.type === 7 && dy.value.value > 0n) {
                    let dx = await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy.value.value);
                    if (dx.type == 7) {
                        await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy.value.value, 0);
                    } else {
                        console.log('error: ', dx.value.value);
                        let dy_i = Math.round(Number(dy.value.value) / 4);
                        for (let i = 0; i < 4; i++) {
                            let dx_i = await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy_i);
                            if (dx_i.type == 7) {
                                await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, dy_i, 0);
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
            console.log('post arb implied: ', format_number(Number(balance_y / balance_x), 8));
            console.log(timestamp());
        }
    }
}

async function arbitrage_crp(dry_run = true, _subset=_deploy) {
    console.log("------ CRP Arbitrage ------")
    console.log(timestamp());

    const threshold = 0.002;
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;

    for (const key in _subset) {
        // console.log(_subset[key]);
        printed = Number(usdaPrice) / Number(wbtcPrice);
        if (_subset[key]['token'] === 'token-usda') {
            printed = Number(wbtcPrice) / Number(usdaPrice);
        }

        let node_info = await (await fetch('https://regtest-2.alexgo.io/v2/info')).json();
        let time_to_maturity = (Math.round(_subset[key]['expiry'] / ONE_8) - node_info['burn_block_height']) / 2102400;

        if (time_to_maturity > 0) {

            result = await crpGetPoolDetails(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry']);
            balance_x = result.value.data['balance-x'].value;
            balance_y = result.value.data['balance-y'].value;
            weight_x = result.value.data['weight-x'].value;
            weight_y = result.value.data['weight-y'].value;

            implied = Number(balance_y) * Number(weight_x) / Number(balance_x) / Number(weight_y);
            console.log("printed: ", format_number(printed, 8), "implied:", format_number(implied, 8));

            if (!dry_run) {
                let diff = Math.abs(implied - printed) / implied;
                if (diff > threshold) {
                    if (printed < implied) {
                        let dx = await crpGetXgivenPrice(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], Math.round(printed * ONE_8));

                        if (dx.type === 7 && dx.value.value > 0n) {
                            let dy = await crpGetYgivenX(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dx.value.value);
                            if (dy.type == 7) {
                                await crpSwapXforY(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dx.value.value, 0);
                            } else {
                                console.log('error: ', dy.value.value);
                                let dx_i = Math.round(Number(dx.value.value) / 4);
                                for (let i = 0; i < 4; i++) {
                                    let dy_i = await crpGetYgivenX(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dx_i);
                                    if (dy_i.type == 7) {
                                        await crpSwapXforY(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dx_i, 0);
                                    } else {
                                        console.log('error: ', dy_i.value.value);
                                        break;
                                    }
                                }
                            }
                        } else {
                            console.log('error (or zero): ', dx.value.value);
                        }
                    } else {
                        let dy = await crpGetYgivenPrice(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], Math.round(printed * ONE_8));

                        if (dy.type === 7 && dy.value.value > 0n) {
                            let dx = await crpGetXgivenY(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dy.value.value);
                            if (dx.type == 7) {
                                await crpSwapYforX(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dy.value.value, 0);
                            } else {
                                console.log('error: ', dx.value.value);
                                let dy_i = Math.round(Number(dy.value.value) / 4);
                                for (let i = 0; i < 4; i++) {
                                    let dx_i = await crpGetXgivenY(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dy_i);
                                    if (dx_i.type == 7) {
                                        await crpSwapYforX(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'], dy_i, 0);
                                    } else {
                                        console.log('error: ', dx_i.value.value);
                                        break;
                                    }
                                }
                            }
                        } else {
                            console.log('error (or zero): ', dy.value.value);
                        }
                    }
                    result = await crpGetPoolDetails(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry']);
                    balance_x = result.value.data['balance-x'].value;
                    balance_y = result.value.data['balance-y'].value;
                    weight_x = result.value.data['weight-x'].value;
                    weight_y = result.value.data['weight-y'].value;
                    implied = Number(balance_y) * Number(weight_x) / Number(balance_x) / Number(weight_y);
                    console.log('post arb implied: ', format_number(implied, 8));
                    console.log(timestamp());
                }
            }
        }
    }
}

async function arbitrage_ytp(dry_run = true, _subset=_deploy) {
    console.log("------ YTP Arbitrage ------")
    console.log(timestamp());
    const threshold = 0.05;

    for (const key in _subset) {
        // console.log(_subset[key]);
        result = await ytpGetYield(_subset[key]['yield_token']);
        implied_yield = Number(result.value.value) / ONE_8;

        let node_info = await (await fetch('https://regtest-2.alexgo.io/v2/info')).json();
        let time_to_maturity = (Math.round(_subset[key]['expiry'] / ONE_8) - node_info['burn_block_height']) / 2102400;

        if (time_to_maturity > 0) {
            target_yield = Math.max(0, _subset[key]['target_apy'] * time_to_maturity);
            let diff = Math.abs(target_yield - implied_yield) / implied_yield;
            if (diff > threshold) {
                console.log("target: ", format_number(target_yield, 8), "implied:", format_number(implied_yield, 8));

                if (!dry_run) {
                    if (target_yield < implied_yield) {
                        let dx = await ytpGetXgivenYield(_subset[key]['yield_token'], Math.round(target_yield * ONE_8));

                        if (dx.type === 7 && dx.value.value > 0n) {
                            let dy = await ytpGetYgivenX(_subset[key]['yield_token'], dx.value.value);
                            if (dy.type == 7) {
                                await ytpSwapXforY(_subset[key]['yield_token'], _subset[key]['token'], dx.value.value, 0);
                            } else {
                                console.log('error: ', dy.value.value);
                                dx_i = Math.round(Number(dx.value.value) / 10);
                                for (let i = 0; i < 10; i++) {
                                    let dy_i = await ytpGetYgivenX(_subset[key]['yield_token'], dx_i);
                                    if (dy_i.type == 7) {
                                        await ytpSwapXforY(_subset[key]['yield_token'], _subset[key]['token'], dx_i, 0);
                                    } else {
                                        console.log('error: ', dy_i.value.value);
                                        break;
                                    }
                                }
                            }
                        } else {
                            console.log('error (or zero):', dx.value.value);
                        }
                    } else {
                        let dy = await ytpGetYgivenYield(_subset[key]['yield_token'], Math.round(target_yield * ONE_8));

                        if (dy.type === 7 && dy.value.value > 0n) {
                            let spot = Number((await crpGetSpot(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'])).value.value) / ONE_8;
                            let dy_collateral = Number(dy.value.value) * spot;
                            let ltv = Number((await crpGetLtv(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'])).value.value);
                            ltv /= Number((await ytpGetPrice(_subset[key]['yield_token'])).value.value);
                            let dy_ltv = Math.round(dy_collateral / ltv);
                            let dx = await ytpGetXgivenY(_subset[key]['yield_token'], Math.round(Number(dy.value.value) / ltv));
                            let dx_fwp;
                            if (_subset[key]['collateral'] == 'token-usda') {
                                dx_fwp = await fwpGetXgivenY(_subset[key]['token'], _subset[key]['collateral'], 0.5e+8, 0.5e+8, dy_ltv);
                            } else {
                                dx_fwp = await fwpGetYgivenX(_subset[key]['collateral'], _subset[key]['token'], 0.5e+8, 0.5e+8, dy_ltv);
                            }
                            if (dx.type == 7 && dx_fwp.type == 7) {
                                await crpAddToPostionAndSwitch(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['yield_token'], _subset[key]['key_token'], dy_ltv);
                            } else {
                                console.log('error (ytp): ', dx.value.value, 'error (fwp): ', dx_fwp.value.value);
                                dy_ltv = Math.round(dy_ltv / 10);
                                dy_i = Math.round(Number(dy.value.value) / 10);
                                for (let i = 0; i < 4; i++) {
                                    let dx_i = await ytpGetXgivenY(_subset[key]['yield_token'], dy_i);
                                    let dx_fwp_i;
                                    if (_subset[key]['collateral'] == 'token-usda') {
                                        dx_fwp_i = await fwpGetXgivenY(_subset[key]['token'], _subset[key]['collateral'], 0.5e+8, 0.5e+8, dy_ltv);
                                    } else {
                                        dx_fwp_i = await fwpGetYgivenX(_subset[key]['collateral'], _subset[key]['token'], 0.5e+8, 0.5e+8, dy_ltv);
                                    }
                                    if (dx_i.type == 7 && dx_fwp_i.type == 7) {
                                        await crpAddToPostionAndSwitch(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['yield_token'], _subset[key]['key_token'], dy_ltv);
                                    } else {
                                        console.log('error (ytp): ', dx_i.value.value, 'error (fwp): ', dx_fwp_i.value.value);
                                        break;
                                    }
                                }
                            }
                        } else {
                            console.log('error (or zero): ', dy.value.value);
                        }
                    }

                    result = await ytpGetYield(_subset[key]['yield_token']);
                    implied_yield = Number(result.value.value) / ONE_8;
                    console.log('post arb implied: ', format_number(implied_yield, 8));
                    console.log(timestamp());
                }
            }
        }
    }
}

async function test_spot_trading() {
    console.log("------ Testing Spot Trading ------");
    console.log(timestamp());
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;

    let from_amount = ONE_8;
    let to_amount = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount)).value.value);
    let exchange_rate = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, ONE_8)));
    await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount, 0);

    from_amount = Number(wbtcPrice);
    to_amount = (await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount));
    exchange_rate = parseInt((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, ONE_8)));
    if (to_amount.type === 7) {
        await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, from_amount, 0);
    } else {
        console.log('error: ', to_amount.value.value);
    }
}

async function test_margin_trading() {
    console.log("------ Testing Margin Trading (Long BTC vs USD) ------");
    console.log(timestamp());
    let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
    let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;

    let expiry_0 = 11520e+8
    let amount = 1 * ONE_8; //gross exposure of 1 BTC
    let trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD    
    let trade_amount = amount; // in BTC
    let ltv = Number((await crpGetLtv('token-usda', 'token-wbtc', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-usda-11520")).value.value);
    let margin = Math.round(amount * (1 - ltv)); // in BTC
    let leverage = 1 / (1 - ltv);

    console.log("ltv: ", format_number(ltv, 2), "; amount (BTC): ", format_number(amount, 8), "; margin (BTC): ", format_number(margin, 8));
    console.log("leverage: ", format_number(leverage, 2), "; trade_price (USD): ", format_number(trade_price, 2));

    await flashloan('flash-loan-user-margin-wbtc-usda-11520', 'token-wbtc', (amount - margin));

    console.log("------ Testing Margin Trading (Short BTC vs USD) ------");
    console.log(timestamp());
    expiry_0 = 11520e+8
    amount = 1 * ONE_8; //gross exposure of 1 BTC
    trade_price = Number((await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, amount)).value.value); // in USD
    trade_amount = amount; // in BTC
    ltv = Number((await crpGetLtv('token-wbtc', 'token-usda', expiry_0)).value.value);
    ltv /= Number((await ytpGetPrice("yield-wbtc-11520")).value.value);
    margin = Math.round(amount * (1 - ltv) * Number(wbtcPrice) / ONE_8); // in USD
    leverage = 1 / (1 - ltv);

    console.log("ltv: ", format_number(ltv, 2), "; amount (BTC): ", format_number(amount, 8), "; margin (USD): ", format_number(margin, 2));
    console.log("leverage: ", format_number(leverage, 2), "; trade_price (USD): ", format_number(trade_price, 2))

    await flashloan('flash-loan-user-margin-usda-wbtc-11520', 'token-usda', (trade_price - margin));
}

function format_number(number, fixed = 2) {
    return number.toFixed(fixed).replace(/\d(?=(\d{3})+\.)/g, '$&,');
}

async function get_pool_details_crp(_subset=_deploy) {
    for (const key in _subset) {
        let ltv = await crpGetLtv(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry']);
        let details = await crpGetPoolDetails(_subset[key]['token'], _subset[key]['collateral'], _subset[key]['expiry'])
        let balance_x = details.value.data['balance-x'];
        let balance_y = details.value.data['balance-y'];
        let weight_x = details.value.data['weight-x'];
        let weight_y = details.value.data['weight-y'];
        console.log('ltv: ', format_number(Number(ltv.value.value) / ONE_8),
            '; balance-collateral: ', format_number(Number(balance_x.value) / ONE_8),
            '; balance-token: ', format_number(Number(balance_y.value) / ONE_8),
            '; weights (collateral / token): ', format_number(Number(weight_x.value) / ONE_8),
            '/', format_number(Number(weight_y.value) / ONE_8));
    }
}

async function get_pool_details_fwp() {
    let details = await fwpGetPoolDetails('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8);
    let balance_x = details.value.data['balance-x'];
    let balance_y = details.value.data['balance-y'];

    console.log('balance-x: ', format_number(Number(balance_x.value) / ONE_8), 'balance-y: ', format_number(Number(balance_y.value) / ONE_8));
}

async function get_pool_details_ytp(_subset=_deploy) {
    for (const key in _subset) {
        let yied = await ytpGetYield(_subset[key]['yield_token']);
        let price = await ytpGetPrice(_subset[key]['yield_token']);
        let details = await ytpGetPoolDetails(_subset[key]['yield_token']);
        let balance_aytoken = details.value.data['balance-aytoken'];
        let balance_virtual = details.value.data['balance-virtual'];
        let balance_token = details.value.data['balance-token'];
        let total_supply = details.value.data['total-supply'];

        console.log('yield: ', format_number(Number(yied.value.value) / ONE_8, 8), 'price: ', format_number(Number(price.value.value) / ONE_8, 8));
        console.log('balance (yield-token / virtual / token): ',
            format_number(Number(balance_aytoken.value) / ONE_8),
            ' / ',
            format_number(Number(balance_virtual.value) / ONE_8),
            ' / ',
            format_number(Number(balance_token.value) / ONE_8));
        console.log('total-supply: ', format_number(Number(total_supply.value) / ONE_8));
    }
}

async function reduce_position_fwp(percent, deployer=false) {
    console.log("------ Reducing FWP Positions ------");
    console.log(timestamp());
    await fwpReducePosition('token-wbtc', 'token-usda', 0.5e+8, 0.5e+8, 'fwp-wbtc-usda-50-50', percent, deployer);
}

async function reduce_position_ytp(_reduce, percent, deployer=false) {
    console.log("------ Reducing YTP Positions ------");
    console.log(timestamp());

    for (const key in _reduce) {

        let total_shares = await balance(_reduce[key]['pool_token'], (deployer) ? process.env.DEPLOYER_ACCOUNT_ADDRESS : process.env.USER_ACCOUNT_ADDRESS);
        let shares = Math.round(percent * Number(total_shares.value.value) / ONE_8);
        console.log(shares);
        console.log('total shares: ', format_number(Number(total_shares.value.value) / ONE_8), 'shares: ', format_number(shares / ONE_8));
        let pos = await ytpGetPositionGivenBurn(_reduce[key]['yield_token'], shares);
        if (shares > 0 && pos.type == 7){
            console.log('reducing yield-token / virtual / token:', 
            format_number(Number(pos.value.data['dy-act'].value) / ONE_8),        
            '/',                        
            format_number(Number(pos.value.data['dy-vir'].value) / ONE_8),                        
            '/',                        
            format_number(Number(pos.value.data['dx'].value) / ONE_8));            
            await ytpReducePosition(_reduce[key]['yield_token'], _reduce[key]['token'], _reduce[key]['pool_token'], percent, deployer);
        } else {
            console.error('error: ', pos);
        }
    }
}

async function reduce_position_crp(_reduce, percent, _type, deployer=false) {
    console.log("------ Reducing CRP Positions ------");
    console.log(timestamp());
    for (const key in _reduce) {
        if (_type === 'yield') {
            await crpReducePostionYield(_reduce[key]['token'], _reduce[key]['collateral'], _reduce[key]['yield_token'], percent, deployer);
        } else if (_type === 'key') {
            await crpReducePostionKey(_reduce[key]['token'], _reduce[key]['collateral'], _reduce[key]['key_token'], percent, deployer);
        }
    }
}

function timestamp() {
    // Create a date object with the current time
    var now = new Date();

    // Create an array with the current month, day and time
    var date = [now.getMonth() + 1, now.getDate(), now.getFullYear()];

    // Create an array with the current hour, minute and second
    var time = [now.getHours(), now.getMinutes(), now.getSeconds()];

    // Determine AM or PM suffix based on the hour
    var suffix = (time[0] < 12) ? "AM" : "PM";

    // Convert hour from military time
    time[0] = (time[0] < 12) ? time[0] : time[0] - 12;

    // If hour is 0, set it to 12
    time[0] = time[0] || 12;

    // If seconds and minutes are less than 10, add a zero
    for (var i = 1; i < 3; i++) {
        if (time[i] < 10) {
            time[i] = "0" + time[i];
        }
    }

    // Return the formatted string
    return date.join("/") + " " + time.join(":") + " " + suffix;
}


_white_list = {
}

async function run() {
    // await set_faucet_amounts();
    // await get_some_token('STR3ZNZ7VZGAJFVBS69DQ1Z5APW0MWS7E2P4EFP6');
    // await see_balance(process.env.DEPLOYER_ACCOUNT_ADDRESS);
    // await update_price_oracle();    
    // await mint_some_tokens(process.env.DEPLOYER_ACCOUNT_ADDRESS);
    // await mint_some_usda(process.env.DEPLOYER_ACCOUNT_ADDRESS + '.alex-reserve-pool');    
    // await mint_some_tokens(process.env.USER_ACCOUNT_ADDRESS);
    // await get_some_token(process.env.USER_ACCOUNT_ADDRESS);

    // const _pools = {    0:_deploy[2], 
    //                     1:_deploy[3], 
    //                     2:_deploy[4], 
    //                     3:_deploy[5], 
    //                     4:_deploy[6], 
    //                     5:_deploy[7],
    //                     6:_deploy[8],
    //                     7:_deploy[9],
    //                     8:_deploy[10],
    //                     9:_deploy[11]
    //                 };
    // const _pools = { 0:_deploy[6], 1:_deploy[7] };
    const _pools = { 0:_deploy[0], 1:_deploy[1], 2:_deploy[2], 3:_deploy[3]};
    // const _pools = _deploy;

    // await create_fwp(add_only=false);
    // await create_ytp(add_only=false, _pools);
    // await create_crp(add_only=false, _pools);    

    // await arbitrage_fwp(dry_run = false);
    // await arbitrage_crp(dry_run = false, _pools);
    // await arbitrage_ytp(dry_run = false, _pools);
    // await arbitrage_fwp(dry_run = false);

    // await test_spot_trading();
    // await test_margin_trading();

    // await create_fwp(add_only=true);
    // await create_crp(add_only=true, _pools);     
    // await create_ytp(add_only=true, _pools);

    // await arbitrage_fwp(dry_run=true);
    // await arbitrage_crp(dry_run=true, _pools);    
    // await arbitrage_ytp(dry_run=true, _pools); 
    // await get_pool_details_fwp();
    // await get_pool_details_crp(_pools);
    // await get_pool_details_ytp(_pools);   

    // await reduce_position_fwp(0.9 * ONE_8);

    // const _reduce = { 0: _deploy[14] , 1: _deploy[15] };
    // await reduce_position_ytp(_reduce, 0.9*ONE_8, deployer=true);
    // await get_pool_details_ytp(_subset=_reduce);   

    // await reduce_position_ytp(_pools, 0.1*ONE_8, deployer=true);
    // await reduce_position_crp(_pools, ONE_8, 'yield');
    // await reduce_position_crp(_pools, ONE_8, 'key');    
    // await reduce_position_crp(_pools, 0.8*ONE_8, 'yield', deployer=true);
    // await reduce_position_crp(_pools, 0.8*ONE_8, 'key', deployer=true);    

    // await see_balance(process.env.DEPLOYER_ACCOUNT_ADDRESS + '.alex-vault');           
    
    // await mint_some_tokens(process.env.USER_ACCOUNT_ADDRESS);
    // await get_some_token('ST32AK70FP7VNAD68KVDQF3K8XSFG99WKVEHVAPFA');
    // await burn('token-wbtc', 'STZP1114C4EA044RE54M6G5ZC2NYK9SAHB5QVE1', 9995719169074);
    // await burn('token-usda', 'STZP1114C4EA044RE54M6G5ZC2NYK9SAHB5QVE1', 399709145833000000);    

    // result = await ytpGetYgivenX('yield-wbtc-51840', 1e8);
    // console.log(result);

    // result = await fwpGetXgivenY('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 500000000e8);
    // console.log(result);
    // await fwpSwapYforX('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 500000000e8, 0);
    // await arbitrage_fwp(dry_run = false);
    // await mint_some_wbtc('ST32AK70FP7VNAD68KVDQF3K8XSFG99WKVEHVAPFA');    
    // await see_balance(process.env.USER_ACCOUNT_ADDRESS);   
    // result = await ytpGetPositionGivenBurn('yield-wbtc-200335', 625000000000, deployer=true);      
    // console.log(result);

    // result = await balance('key-usda-11520-wbtc', process.env.USER_ACCOUNT_ADDRESS);
    // console.log(result);
    // await transfer('key-usda-11520-wbtc', 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ', 10668690600000);

    // _list = ['fwp-wbtc-usda-50-50', 'ytp-yield-wbtc-92160-wbtc', 'ytp-yield-usda-92160-usda']
    // for (let i = 0; i < _list.length; i++){
    //     // result = await balance(_list[i], process.env.DEPLOYER_ACCOUNT_ADDRESS);
    //     // console.log(result);
    //     await transfer(_list[i], 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ', ONE_8, deployer=true);
    // }
}
run();
