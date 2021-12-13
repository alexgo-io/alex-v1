import { _deploy, _fwp_pools, ONE_8 } from '../constants';
import { crpAddToPostion, crpCreate } from '../pools-crp';
import { fwpAddToPosition, fwpCreate, fwpSetOracleAverage, fwpSetOracleEnbled } from '../pools-fwp';
import { ytpAddToPosition, ytpCreate } from '../pools-ytp';

export async function create_fwp(
  add_only: boolean,
  _subset = _fwp_pools,
  deployer = false,
) {
  console.log('------ FWP Creation / Add Liquidity ------');

  for (const _key in _subset) {
    const key = _key as '1' | '2';
    if (add_only) {
      await fwpAddToPosition(
        _subset[key]['token_x'],
        _subset[key]['token_y'],
        _subset[key]['weight_x'],
        _subset[key]['weight_y'],
        _subset[key]['pool_token'],
        _subset[key]['left_side'],
        ONE_8 * ONE_8,
        deployer,
      );
    } else {
      await fwpCreate(
        _subset[key]['token_x'],
        _subset[key]['token_y'],
        _subset[key]['weight_x'],
        _subset[key]['weight_y'],
        _subset[key]['pool_token'],
        _subset[key]['multisig'],
        _subset[key]['left_side'],
        _subset[key]['right_side']
      );
      await fwpSetOracleEnbled(
        _subset[key]['token_x'],
        _subset[key]['token_y'],
        _subset[key]['weight_x'],
        _subset[key]['weight_y'],
      );
      await fwpSetOracleAverage(
        _subset[key]['token_x'],
        _subset[key]['token_y'],
        _subset[key]['weight_x'],
        _subset[key]['weight_y'],
        0.95e8,
      );
    }
  }
}

export async function create_ytp(add_only: boolean, _subset = _deploy) {
  console.log('------ YTP Creation / Add Liquidity ------');

  for (const _key in _subset) {
    const key = _key as '0' | '1';

    // @ts-ignore
    if (_subset[key]['pool_token'] != '') {
      if (add_only) {
        await ytpAddToPosition(
          _subset[key]['expiry'],
          _subset[key]['yield_token'],
          _subset[key]['token'],
          _subset[key]['pool_token'],
          _subset[key]['liquidity_ytp'],
        );
      } else {
        await ytpCreate(
          _subset[key]['expiry'],
          _subset[key]['yield_token'],
          _subset[key]['token'],
          _subset[key]['pool_token'],
          _subset[key]['multisig_ytp'],
          _subset[key]['liquidity_ytp'],
          _subset[key]['liquidity_ytp'],
        );
      }
    }
  }
}

export async function create_crp(add_only: boolean, _subset = _deploy) {
  console.log('------ CRP Creation / Add Liquidity ------');

  const conversion_ltv = 0.95 * ONE_8;
  const moving_average = 0.95 * ONE_8;

  for (const _key in _subset) {
    const key = _key as '0' | '1';

    if (add_only) {
      await crpAddToPostion(
        _subset[key]['token'],
        _subset[key]['collateral'],
        _subset[key]['expiry'],
        _subset[key]['yield_token'],
        _subset[key]['key_token'],
        _subset[key]['collateral_crp'],
      );
    } else {
      await crpCreate(
        _subset[key]['token'],
        _subset[key]['collateral'],
        _subset[key]['expiry'],
        _subset[key]['yield_token'],
        _subset[key]['key_token'],
        _subset[key]['multisig_crp'],
        _subset[key]['ltv_0'],
        conversion_ltv,
        _subset[key]['bs_vol'],
        moving_average,
        _subset[key]['token_to_maturity'],
        _subset[key]['collateral_crp'],
      );
    }
  }
}
