import { _deploy, _fwp_pools, ONE_8 } from '../constants';
import { crpGetLtv, crpGetPoolDetails } from '../pools-crp';
import { format_number } from '../utils';
import { fwpGetPoolDetails } from '../pools-fwp';
import { ytpGetPoolDetails, ytpGetPrice, ytpGetYield } from '../pools-ytp';

export async function get_pool_details_crp(_subset = _deploy) {
  for (const _key in _subset) {
    const key = _key as '0' | '1';
    let ltv = await crpGetLtv(
      _subset[key]['token'],
      _subset[key]['collateral'],
      _subset[key]['expiry'],
    );
    let details = await crpGetPoolDetails(
      _subset[key]['token'],
      _subset[key]['collateral'],
      _subset[key]['expiry'],
    );
    let balance_x = (details as any).value.data['balance-x'];
    let balance_y = (details as any).value.data['balance-y'];
    let weight_x = (details as any).value.data['weight-x'];
    let weight_y = (details as any).value.data['weight-y'];
    console.log(
      'ltv: ',
      format_number(Number((ltv as any).value.value) / ONE_8),
      '; balance-collateral: ',
      format_number(Number(balance_x.value) / ONE_8),
      '; balance-token: ',
      format_number(Number(balance_y.value) / ONE_8),
      '; weights (collateral / token): ',
      format_number(Number(weight_x.value) / ONE_8),
      '/',
      format_number(Number(weight_y.value) / ONE_8),
    );
  }
}

export async function get_pool_details_fwp(_subset = _fwp_pools) {
  for (const _key in _subset) {
    const key = _key as '1' | '2';
    let details = await fwpGetPoolDetails(
      _subset[key]['token_x'],
      _subset[key]['token_y'],
      _subset[key]['weight_x'],
      _subset[key]['weight_y'],
    );
    let balance_x = (details as any).value.data['balance-x'];
    let balance_y = (details as any).value.data['balance-y'];

    console.log(
      'balance-x: ',
      format_number(Number(balance_x.value) / ONE_8),
      'balance-y: ',
      format_number(Number(balance_y.value) / ONE_8),
    );
  }
}

export async function get_pool_details_ytp(_subset = _deploy) {
  for (const _key in _subset) {
    const key = _key as '0' | '1';
    let yied = await ytpGetYield(
      _subset[key]['expiry'],
      _subset[key]['yield_token'],
    );
    let price = await ytpGetPrice(
      _subset[key]['expiry'],
      _subset[key]['yield_token'],
    );
    let details = await ytpGetPoolDetails(
      _subset[key]['expiry'],
      _subset[key]['yield_token'],
    );
    let balance_aytoken = (details as any).value.data['balance-yield-token'];
    let balance_virtual = (details as any).value.data['balance-virtual'];
    let balance_token = (details as any).value.data['balance-token'];
    let total_supply = (details as any).value.data['total-supply'];

    console.log(
      'yield: ',
      format_number(Number((yied as any).value.value) / ONE_8, 8),
      'price: ',
      format_number(Number((price as any).value.value) / ONE_8, 8),
    );
    console.log(
      'balance (yield-token / virtual / token): ',
      format_number(Number(balance_aytoken.value) / ONE_8),
      ' / ',
      format_number(Number(balance_virtual.value) / ONE_8),
      ' / ',
      format_number(Number(balance_token.value) / ONE_8),
    );
    console.log(
      'total-supply: ',
      format_number(Number(total_supply.value) / ONE_8),
    );
  }
}
