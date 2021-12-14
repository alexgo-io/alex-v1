import { _deploy, _fwp_pools, ONE_8, STACKS_API_URL } from '../constants';
import { fetch_in_usd } from '../oracles';
import {
  crpAddToPostionAndSwitch,
  crpGetLtv,
  crpGetPoolDetails,
  crpGetSpot,
  crpGetXgivenPrice,
  crpGetXgivenY,
  crpGetYgivenPrice,
  crpGetYgivenX,
  crpSwapXforY,
  crpSwapYforX,
} from '../pools-crp';
import { format_number, timestamp } from '../utils';
import {
  fwpGetPoolDetails,
  fwpGetXGivenPrice,
  fwpGetXgivenY,
  fwpGetYGivenPrice,
  fwpGetYgivenX,
  fwpSwapXforY,
  fwpSwapYforX,
} from '../pools-fwp';
import {
  ytpGetPrice,
  ytpGetXgivenY,
  ytpGetXgivenYield,
  ytpGetYgivenX,
  ytpGetYgivenYield,
  ytpGetYield,
  ytpSwapXforY,
} from '../pools-ytp';

export async function arbitrage_fwp(dry_run = true, _subset = _fwp_pools) {
  console.log('------ FWP Arbitrage ------');
  console.log(timestamp());

  const threshold = 0.002;
  let wbtcPrice = await fetch_in_usd('bitcoin');
  let usdaPrice = await fetch_in_usd('usd-coin');
  let wstxPrice = await fetch_in_usd('blockstack');

  for (const _key in _subset) {
    const key = _key as '1' | '2';
    let printed =
      _subset[key]['token_y'] == 'token-usda'
        ? parseFloat(`${wstxPrice / usdaPrice}`)
        : parseFloat(`${wstxPrice / wbtcPrice}`);

    let result = await fwpGetPoolDetails(
      _subset[key]['token_x'],
      _subset[key]['token_y'],
      _subset[key]['weight_x'],
      _subset[key]['weight_y'],
    );
    let balance_x = (result as any).value.data['balance-x'].value;
    let balance_y = (result as any).value.data['balance-y'].value;

    let implied = Number(balance_y) / Number(balance_x);
    console.log(
      'printed: ',
      format_number(printed, 8),
      'implied:',
      format_number(implied, 8),
    );

    if (!dry_run) {
      let diff = Math.abs(printed - implied) / implied;
      if (diff > threshold) {
        if (printed < implied) {
          let dx = (await fwpGetXGivenPrice(
            _subset[key]['token_x'],
            _subset[key]['token_y'],
            _subset[key]['weight_x'],
            _subset[key]['weight_y'],
            Math.round(printed * ONE_8),
          )) as any;

          if (dx.type === 7 && dx.value.value > 0n) {
            let dy = (await fwpGetYgivenX(
              _subset[key]['token_x'],
              _subset[key]['token_y'],
              _subset[key]['weight_x'],
              _subset[key]['weight_y'],
              dx.value.value,
            )) as any;
            if (dy.type == 7) {
              await fwpSwapXforY(
                _subset[key]['token_x'],
                _subset[key]['token_y'],
                _subset[key]['weight_x'],
                _subset[key]['weight_y'],
                dx.value.value,
                0,
              );
            } else {
              console.log('error: ', dy.value.value);
              let dx_i = Math.round(Number(dx.value.value) / 4);
              for (let i = 0; i < 4; i++) {
                let dy_i = (await fwpGetYgivenX(
                  _subset[key]['token_x'],
                  _subset[key]['token_y'],
                  _subset[key]['weight_x'],
                  _subset[key]['weight_y'],
                  dx_i,
                )) as any;
                if (dy_i.type == 7) {
                  await fwpSwapXforY(
                    _subset[key]['token_x'],
                    _subset[key]['token_y'],
                    _subset[key]['weight_x'],
                    _subset[key]['weight_y'],
                    dx_i,
                    0,
                  );
                }
              }
            }
          } else {
            console.log('error (or zero): ', dx.value.value);
          }
        } else {
          let dy = (await fwpGetYGivenPrice(
            _subset[key]['token_x'],
            _subset[key]['token_y'],
            _subset[key]['weight_x'],
            _subset[key]['weight_y'],
            Math.round(printed * ONE_8),
          )) as any;

          if (dy.type === 7 && dy.value.value > 0n) {
            let dx = (await fwpGetXgivenY(
              _subset[key]['token_x'],
              _subset[key]['token_y'],
              _subset[key]['weight_x'],
              _subset[key]['weight_y'],
              dy.value.value,
            )) as any;
            if (dx.type == 7) {
              await fwpSwapYforX(
                _subset[key]['token_x'],
                _subset[key]['token_y'],
                _subset[key]['weight_x'],
                _subset[key]['weight_y'],
                dy.value.value,
                0,
              );
            } else {
              console.log('error: ', dx.value.value);
              let dy_i = Math.round(Number(dy.value.value) / 4) as any;
              for (let i = 0; i < 4; i++) {
                let dx_i = (await fwpGetXgivenY(
                  _subset[key]['token_x'],
                  _subset[key]['token_y'],
                  _subset[key]['weight_x'],
                  _subset[key]['weight_y'],
                  dy_i,
                )) as any;
                if (dx_i.type == 7) {
                  await fwpSwapYforX(
                    _subset[key]['token_x'],
                    _subset[key]['token_y'],
                    _subset[key]['weight_x'],
                    _subset[key]['weight_y'],
                    dy_i,
                    0,
                  );
                }
              }
            }
          } else {
            console.log('error (or zero): ', dy.value.value);
          }
        }
        result = await fwpGetPoolDetails(
          _subset[key]['token_x'],
          _subset[key]['token_y'],
          _subset[key]['weight_x'],
          _subset[key]['weight_y'],
        );
        balance_x = (result as any).value.data['balance-x'].value;
        balance_y = (result as any).value.data['balance-y'].value;
        console.log(
          'post arb implied: ',
          format_number(Number(balance_y / balance_x), 8),
        );
        console.log(timestamp());
      }
    }
  }
}

export async function arbitrage_crp(dry_run = true, _subset = _deploy) {
  console.log('------ CRP Arbitrage ------');
  console.log(timestamp());

  const threshold = 0.002;
  // let wbtcPrice = (await getOpenOracle('coingecko', 'WBTC')).value.value;
  // let usdaPrice = (await getOpenOracle('coingecko', 'USDA')).value.value;
  let wbtcPrice = (await fetch_in_usd('bitcoin')) * 1e8;
  let usdaPrice = (await fetch_in_usd('usd-coin')) * 1e8;

  for (const _key in _subset) {
    const key = _key as '0' | '1';
    // console.log(_subset[key]);
    let printed = Number(usdaPrice) / Number(wbtcPrice);
    if (_subset[key]['token'] === 'token-usda') {
      printed = Number(wbtcPrice) / Number(usdaPrice);
    }

    let node_info = await (await fetch(`${STACKS_API_URL()}/v2/info`)).json();
    let time_to_maturity =
      (Math.round(_subset[key]['expiry'] / ONE_8) -
        node_info['burn_block_height']) /
      2102400;

    if (time_to_maturity > 0) {
      let result = await crpGetPoolDetails(
        _subset[key]['token'],
        _subset[key]['collateral'],
        _subset[key]['expiry'],
      );

      const balance_x = (result as any).value.data['balance-x'].value;
      const balance_y = (result as any).value.data['balance-y'].value;
      const weight_x = (result as any).value.data['weight-x'].value;
      const weight_y = (result as any).value.data['weight-y'].value;

      let implied =
        (Number(balance_y) * Number(weight_x)) /
        Number(balance_x) /
        Number(weight_y);
      console.log(
        'printed: ',
        format_number(printed, 8),
        'implied:',
        format_number(implied, 8),
      );

      if (!dry_run) {
        let diff = Math.abs(implied - printed) / implied;
        if (diff > threshold) {
          if (printed < implied) {
            let dx = (await crpGetXgivenPrice(
              _subset[key]['token'],
              _subset[key]['collateral'],
              _subset[key]['expiry'],
              Math.round(printed * ONE_8),
            )) as any;

            if (dx.type === 7 && dx.value.value > 0n) {
              let dy = (await crpGetYgivenX(
                _subset[key]['token'],
                _subset[key]['collateral'],
                _subset[key]['expiry'],
                dx.value.value,
              )) as any;
              if (dy.type == 7) {
                await crpSwapXforY(
                  _subset[key]['token'],
                  _subset[key]['collateral'],
                  _subset[key]['expiry'],
                  dx.value.value,
                  0,
                );
              } else {
                console.log('error: ', dy.value.value);
                let dx_i = Math.round(Number(dx.value.value) / 4);
                for (let i = 0; i < 4; i++) {
                  let dy_i = (await crpGetYgivenX(
                    _subset[key]['token'],
                    _subset[key]['collateral'],
                    _subset[key]['expiry'],
                    dx_i,
                  )) as any;
                  if (dy_i.type == 7) {
                    await crpSwapXforY(
                      _subset[key]['token'],
                      _subset[key]['collateral'],
                      _subset[key]['expiry'],
                      dx_i,
                      0,
                    );
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
            let dy = (await crpGetYgivenPrice(
              _subset[key]['token'],
              _subset[key]['collateral'],
              _subset[key]['expiry'],
              Math.round(printed * ONE_8),
            )) as any;

            if (dy.type === 7 && dy.value.value > 0n) {
              let dx = (await crpGetXgivenY(
                _subset[key]['token'],
                _subset[key]['collateral'],
                _subset[key]['expiry'],
                dy.value.value,
              )) as any;
              if (dx.type == 7) {
                await crpSwapYforX(
                  _subset[key]['token'],
                  _subset[key]['collateral'],
                  _subset[key]['expiry'],
                  dy.value.value,
                  0,
                );
              } else {
                console.log('error: ', dx.value.value);
                let dy_i = Math.round(Number(dy.value.value) / 4);
                for (let i = 0; i < 4; i++) {
                  let dx_i = (await crpGetXgivenY(
                    _subset[key]['token'],
                    _subset[key]['collateral'],
                    _subset[key]['expiry'],
                    dy_i,
                  )) as any;
                  if (dx_i.type == 7) {
                    await crpSwapYforX(
                      _subset[key]['token'],
                      _subset[key]['collateral'],
                      _subset[key]['expiry'],
                      dy_i,
                      0,
                    );
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
          result = await crpGetPoolDetails(
            _subset[key]['token'],
            _subset[key]['collateral'],
            _subset[key]['expiry'],
          );
          const balance_x = (result as any).value.data['balance-x'].value;
          const balance_y = (result as any).value.data['balance-y'].value;
          const weight_x = (result as any).value.data['weight-x'].value;
          const weight_y = (result as any).value.data['weight-y'].value;
          implied =
            (Number(balance_y) * Number(weight_x)) /
            Number(balance_x) /
            Number(weight_y);
          console.log('post arb implied: ', format_number(implied, 8));
          console.log(timestamp());
        }
      }
    }
  }
}

export async function arbitrage_ytp(dry_run = true, _subset = _deploy) {
  console.log('------ YTP Arbitrage ------');
  console.log(timestamp());
  const threshold = 0.05;

  for (const _key in _subset) {
    const key = _key as '0' | '1';
    // console.log(_subset[key]);
    let result = await ytpGetYield(
      _subset[key]['expiry'],
      _subset[key]['yield_token'],
    );
    let implied_yield = Number((result as any).value.value) / ONE_8;

    let node_info = await (await fetch(`${STACKS_API_URL()}/v2/info`)).json();
    let time_to_maturity =
      (Math.round(_subset[key]['expiry'] / ONE_8) -
        node_info['burn_block_height']) /
      2102400;

    if (time_to_maturity > 0) {
      const target_yield = Math.max(
        0,
        _subset[key]['target_apy'] * time_to_maturity,
      );
      let diff = Math.abs(target_yield - implied_yield) / implied_yield;
      if (diff > threshold) {
        console.log(
          'target: ',
          format_number(target_yield, 8),
          'implied:',
          format_number(implied_yield, 8),
        );

        if (!dry_run) {
          if (target_yield < implied_yield) {
            let dx = (await ytpGetXgivenYield(
              _subset[key]['expiry'],
              _subset[key]['yield_token'],
              Math.round(target_yield * ONE_8),
            )) as any;

            if (dx.type === 7 && dx.value.value > 0n) {
              let dy = (await ytpGetYgivenX(
                _subset[key]['expiry'],
                _subset[key]['yield_token'],
                dx.value.value,
              )) as any;
              if (dy.type == 7) {
                await ytpSwapXforY(
                  _subset[key]['expiry'],
                  _subset[key]['yield_token'],
                  _subset[key]['token'],
                  dx.value.value,
                  0,
                );
              } else {
                console.log('error: ', dy.value.value);
                const dx_i = Math.round(Number(dx.value.value) / 10);
                for (let i = 0; i < 10; i++) {
                  let dy_i = (await ytpGetYgivenX(
                    _subset[key]['expiry'],
                    _subset[key]['yield_token'],
                    dx_i,
                  )) as any;
                  if (dy_i.type == 7) {
                    await ytpSwapXforY(
                      _subset[key]['expiry'],
                      _subset[key]['yield_token'],
                      _subset[key]['token'],
                      dx_i,
                      0,
                    );
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
            let dy = (await ytpGetYgivenYield(
              _subset[key]['expiry'],
              _subset[key]['yield_token'],
              Math.round(target_yield * ONE_8),
            )) as any;

            if (dy.type === 7 && dy.value.value > 0n) {
              let spot =
                Number(
                  (
                    (await crpGetSpot(
                      _subset[key]['token'],
                      _subset[key]['collateral'],
                    )) as any
                  ).value.value,
                ) / ONE_8;
              let dy_collateral = Number(dy.value.value) * spot;
              let ltv = Number(
                (
                  (await crpGetLtv(
                    _subset[key]['token'],
                    _subset[key]['collateral'],
                    _subset[key]['expiry'],
                  )) as any
                ).value.value,
              );
              ltv /= Number(
                (
                  (await ytpGetPrice(
                    _subset[key]['expiry'],
                    _subset[key]['yield_token'],
                  )) as any
                ).value.value,
              );
              let dy_ltv = Math.round(dy_collateral / ltv);
              let dx = (await ytpGetXgivenY(
                _subset[key]['expiry'],
                _subset[key]['yield_token'],
                Math.round(Number(dy.value.value) / ltv),
              )) as any;
              let dx_fwp;
              if (_subset[key]['collateral'] == 'token-usda') {
                dx_fwp = await fwpGetXgivenY(
                  _subset[key]['token'],
                  _subset[key]['collateral'],
                  0.5e8,
                  0.5e8,
                  dy_ltv,
                );
              } else {
                dx_fwp = (await fwpGetYgivenX(
                  _subset[key]['collateral'],
                  _subset[key]['token'],
                  0.5e8,
                  0.5e8,
                  dy_ltv,
                )) as any;
              }
              if (dx.type == 7 && dx_fwp.type == 7) {
                await crpAddToPostionAndSwitch(
                  _subset[key]['token'],
                  _subset[key]['collateral'],
                  _subset[key]['expiry'],
                  _subset[key]['yield_token'],
                  _subset[key]['key_token'],
                  dy_ltv,
                );
              } else {
                console.log(
                  'error (ytp): ',
                  dx.value.value,
                  'error (fwp): ',
                  dx_fwp.value.value,
                );
                dy_ltv = Math.round(dy_ltv / 10);
                const dy_i = Math.round(Number(dy.value.value) / 10);
                for (let i = 0; i < 4; i++) {
                  let dx_i = (await ytpGetXgivenY(
                    _subset[key]['expiry'],
                    _subset[key]['yield_token'],
                    dy_i,
                  )) as any;
                  let dx_fwp_i: any;
                  if (_subset[key]['collateral'] == 'token-usda') {
                    dx_fwp_i = await fwpGetXgivenY(
                      _subset[key]['token'],
                      _subset[key]['collateral'],
                      0.5e8,
                      0.5e8,
                      dy_ltv,
                    );
                  } else {
                    dx_fwp_i = await fwpGetYgivenX(
                      _subset[key]['collateral'],
                      _subset[key]['token'],
                      0.5e8,
                      0.5e8,
                      dy_ltv,
                    );
                  }
                  if (dx_i.type == 7 && dx_fwp_i.type == 7) {
                    await crpAddToPostionAndSwitch(
                      _subset[key]['token'],
                      _subset[key]['collateral'],
                      _subset[key]['expiry'],
                      _subset[key]['yield_token'],
                      _subset[key]['key_token'],
                      dy_ltv,
                    );
                  } else {
                    console.log(
                      'error (ytp): ',
                      dx_i.value.value,
                      'error (fwp): ',
                      dx_fwp_i.value.value,
                    );
                    break;
                  }
                }
              }
            } else {
              console.log('error (or zero): ', dy.value.value);
            }
          }

          result = await ytpGetYield(
            _subset[key]['expiry'],
            _subset[key]['yield_token'],
          );
          implied_yield = Number((result as any).value.value) / ONE_8;
          console.log('post arb implied: ', format_number(implied_yield, 8));
          console.log(timestamp());
        }
      }
    }
  }
}
