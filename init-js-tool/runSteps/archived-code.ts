import { fetch_in_usd, initCoinPrice, setOpenOracle } from '../oracles';
import { format_number, timestamp } from '../utils';
import { ClarityType } from '@stacks/transactions';
import { ONE_8 } from '../constants';
import { fwpGetYgivenX } from '../pools-fwp';
import { crpGetLtv } from '../pools-crp';
import { ytpGetPrice } from '../pools-ytp';

const printResult = (result: any) => {
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
};

async function update_price_oracle() {
  console.log('------ Update Price Oracle ------');
  const { usdc, btc } = await initCoinPrice();
  await setOpenOracle('WBTC', 'coingecko', btc);
  await setOpenOracle('USDA', 'coingecko', usdc);
}

async function test_spot_trading() {
  console.log('------ Testing Spot Trading ------');
  console.log(timestamp());
  let wbtcPrice = await fetch_in_usd('bitcoin');
  let usdaPrice = await fetch_in_usd('usd-coin');
  
  let from_amount = ONE_8;
  let to_amount = parseInt(
    (
      (await fwpGetYgivenX(
        'token-wbtc',
        'token-usda',
        0.5e8,
        0.5e8,
        from_amount,
      )) as any
    ).value.value,
  );
  let exchange_rate = parseInt(
    await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e8, 0.5e8, ONE_8),
  );
  await fwpSwapXforY(
    'token-wbtc',
    'token-usda',
    0.5e8,
    0.5e8,
    from_amount,
    to_amount * 0.99,
  );
  
  from_amount = Number(wbtcPrice) * ONE_8;
  to_amount = await fwpGetXgivenY(
    'token-wbtc',
    'token-usda',
    0.5e8,
    0.5e8,
    from_amount,
  );
  exchange_rate = parseInt(
    await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e8, 0.5e8, ONE_8),
  );
  if (to_amount.type === 7) {
    await fwpSwapYforX(
      'token-wbtc',
      'token-usda',
      0.5e8,
      0.5e8,
      from_amount,
      to_amount * 0.99,
    );
  } else {
    console.log('error: ', to_amount.value.value);
  }
}

async function test_margin_trading() {
  console.log('------ Testing Margin Trading (Long BTC vs USD) ------');
  console.log(timestamp());
  let wbtcPrice = await fetch_in_usd('bitcoin');
  let usdaPrice = await fetch_in_usd('usd-coin');
  let wstxPrice = await fetch_in_usd('blockstack');

  let expiry_0 = 34560e8;
  let amount = 1 * ONE_8; //gross exposure of 1 BTC
  let trade_price = Number(
    (
      (await fwpGetYgivenX(
        'token-wbtc',
        'token-usda',
        0.5e8,
        0.5e8,
        amount,
      )) as any
    ).value.value,
  ); // in USD
  let trade_amount = amount; // in BTC
  let ltv = Number(
    ((await crpGetLtv('token-usda', 'token-wbtc', expiry_0)) as any).value
      .value,
  );

  const p = await ytpGetPrice(expiry_0, 'yield-usda');
  ltv /= Number((p as any).value.value);
  let margin = Math.round(amount * (1 - ltv)); // in BTC
  let leverage = 1 / (1 - ltv);

  console.log(
    'ltv: ',
    format_number(ltv, 2),
    '; amount (BTC): ',
    format_number(amount, 8),
    '; margin (BTC): ',
    format_number(margin, 8),
  );
  console.log(
    'leverage: ',
    format_number(leverage, 2),
    '; trade_price (USD): ',
    format_number(trade_price, 2),
  );

  // Next reboot: wbtc-usda should flip to usda-wbtcawait flashloan(
  //   'flash-loan-user-margin-usda-wbtc',
  //   'token-wbtc',
  //   amount - margin,
  //   expiry_0,
  // );

  console.log('------ Testing Margin Trading (Short BTC vs USD) ------');
  console.log(timestamp());
  amount = 1 * ONE_8; //gross exposure of 1 BTC
  trade_price = Number(
    (
      (await fwpGetYgivenX(
        'token-wbtc',
        'token-usda',
        0.5e8,
        0.5e8,
        amount,
      )) as any
    ).value.value,
  ); // in USD
  trade_amount = amount; // in BTC
  ltv = Number(
    ((await crpGetLtv('token-wbtc', 'token-usda', expiry_0)) as any).value
      .value,
  );
  ltv /= Number(
    ((await ytpGetPrice(expiry_0, 'yield-wbtc')) as any).value.value,
  );
  margin = Math.round((amount * (1 - ltv) * Number(wbtcPrice)) / ONE_8); // in USD
  leverage = 1 / (1 - ltv);

  console.log(
    'ltv: ',
    format_number(ltv, 2),
    '; amount (BTC): ',
    format_number(amount, 8),
    '; margin (USD): ',
    format_number(margin, 2),
  );
  console.log(
    'leverage: ',
    format_number(leverage, 2),
    '; trade_price (USD): ',
    format_number(trade_price, 2),
  );

  // Next reboot: wbtc-usda should flip to usda-wbtcawait flashloan(
  //   'flash-loan-user-margin-wbtc-usda',
  //   'token-usda',
  //   trade_price - margin,
  //   expiry_0
  // );
}
