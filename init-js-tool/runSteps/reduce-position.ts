import { balance } from '../vault';
import { DEPLOYER_ACCOUNT_ADDRESS, ONE_8, USER_ACCOUNT_ADDRESS } from '../constants';
import { format_number, timestamp } from '../utils';
import { ytpGetPositionGivenBurn, ytpReducePosition } from '../pools-ytp';
import { fwpReducePosition } from '../pools-fwp';
import { crpReducePostionKey, crpReducePostionYield } from '../pools-crp';

export async function reduce_position_fwp(percent: number, deployer = false) {
  console.log('------ Reducing FWP Positions ------');
  console.log(timestamp());
  await fwpReducePosition(
    'token-wbtc',
    'token-usda',
    0.5e8,
    0.5e8,
    'fwp-wbtc-usda-50-50',
    percent,
    deployer,
  );
}

export async function reduce_position_ytp(
  _reduce: any,
  percent: number,
  deployer = false,
) {
  console.log('------ Reducing YTP Positions ------');
  console.log(timestamp());

  for (const key in _reduce) {
    let total_shares = await balance(
      _reduce[key]['pool_token'],
      deployer ? DEPLOYER_ACCOUNT_ADDRESS() : USER_ACCOUNT_ADDRESS(),
    );
    let shares = Math.round(
      (percent * Number(total_shares.value.value)) / ONE_8,
    );
    console.log(shares);
    console.log(
      'total shares: ',
      format_number(Number(total_shares.value.value) / ONE_8),
      'shares: ',
      format_number(shares / ONE_8),
    );
    let pos = (await ytpGetPositionGivenBurn(
      _reduce[key]['expiry'],
      _reduce[key]['yield_token'],
      shares,
    )) as any;
    if (shares > 0 && pos.type == 7) {
      console.log(
        'reducing yield-token / virtual / token:',
        format_number(Number(pos.value.data['dy-act'].value) / ONE_8),
        '/',
        format_number(Number(pos.value.data['dy-vir'].value) / ONE_8),
        '/',
        format_number(Number(pos.value.data['dx'].value) / ONE_8),
      );
      await ytpReducePosition(
        _reduce[key]['expiry'],
        _reduce[key]['yield_token'],
        _reduce[key]['token'],
        _reduce[key]['pool_token'],
        percent,
        deployer,
      );
    } else {
      console.error('error: ', pos);
    }
  }
}

export async function reduce_position_crp(
  _reduce: any,
  percent: number,
  _type: 'yield' | 'key',
  deployer = false,
) {
  console.log('------ Reducing CRP Positions ------');
  console.log(timestamp());
  for (const key in _reduce) {
    if (_type === 'yield') {
      await crpReducePostionYield(
        _reduce[key]['token'],
        _reduce[key]['collateral'],
        // FIXME: typescript migrate;
        // added 0 for fixing typescript error
        0,
        _reduce[key]['yield_token'],
        percent,
        deployer,
      );
    } else if (_type === 'key') {
      await crpReducePostionKey(
        _reduce[key]['token'],
        _reduce[key]['collateral'],
        // FIXME: typescript migrate;
        // added 0 for fixing typescript error
        0,
        _reduce[key]['key_token'],
        // FIXME: typescript migrate;
        percent,
        deployer,
      );
    }
  }
}
