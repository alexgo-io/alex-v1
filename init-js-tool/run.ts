import {
  _deploy,
  _fwp_pools,
  DEPLOYER_ACCOUNT_ADDRESS,
  USER_ACCOUNT_ADDRESS,
} from './constants';
import {
  get_some_token,
  mint_some_tokens,
  set_faucet_amounts,
} from './runSteps/mint-get-token';
import {
  create_crp,
  create_fwp,
  create_ytp
} from './runSteps/create-pools'
import {
  arbitrage_fwp,
  arbitrage_crp,
  arbitrage_ytp
} from './runSteps/arbitrage';
import {
  get_pool_details_crp,
  get_pool_details_fwp,
  get_pool_details_ytp
} from './runSteps/get-pool-details';
import {
  reserveAddToken,
  reserveGetUserId,
  reserveSetActivationDelay,
  reserveSetCoinbaseAmount,
  reserveRegisterUser,
  reserveSetActivationThreshold,
  reserveSetRewardCycleLength,
  reserveGetStakerAtCycleOrDefault,
  reserveGetStaked,
  reserveGetStakingStatsCoinbaseAsList,
  reserveGetStakingRewards,
  reserveStakeTokens
} from './reserve';
import {
  test_spot_trading,
  test_margin_trading
} from './runSteps/archived-code';
import { transferSTX, balance, transfer } from './vault';
import {
  mint_ft,
  mint_sft,
} from './vault';
import {
  launchCreate,
  launchAddToPosition,
  launchGetSubscriberAtToken,
  launchGetTokenDetails,
  launchRegister
} from './pools-launch';
import { 
  multisigEndProposal,
  multisigGetProposalById,
  multisigPropose,
  multisigReturnVotes,
  multisigVoteAgainst,
  multisigVoteFor
} from './multisigs';
import { fwpGetPoolDetails, fwpSetFeeRebate } from './pools-fwp';
import {
  reduce_position_crp,
  reduce_position_fwp,
  reduce_position_ytp
} from './runSteps/reduce-position'




async function run_mint_initial_tokens() {
  await set_faucet_amounts();
  await transferSTX("ST1J2JTYXGRMZYNKE40GM87ZCACSPSSEEQVSNB7DC.faucet", 100000000e6);
  await mint_some_tokens(DEPLOYER_ACCOUNT_ADDRESS());
  await mint_some_tokens(USER_ACCOUNT_ADDRESS());
  await get_some_token(USER_ACCOUNT_ADDRESS());
}

async function run() {
  // await run_mint_initial_tokens();
  // await mint_some_tokens(USER_ACCOUNT_ADDRESS());
  // await transferSTX(USER_ACCOUNT_ADDRESS(), 100000000e6)

  // const _pools = { 0:_deploy[4], 1:_deploy[5] };
  const _pools = _deploy;
  
  // await create_fwp(false);
  // await create_fwp(true, {0:_fwp_pools[0]}, true);

  // await create_ytp(false, _pools);
  // await create_crp(false, _pools);

  // let _list = ['token-t-alex', 'fwp-wstx-usda-50-50', 'fwp-wstx-wbtc-50-50', 'ytp-yield-wbtc', 'ytp-yield-usda'];
  // for(let i = 0; i < _list.length; i++) {
  //   await reserveAddToken(_list[i]);
  //   await reserveSetActivationThreshold(1);
  //   await reserveSetActivationDelay(1);
  //   await reserveSetRewardCycleLength(525);
  //   await reserveRegisterUser(_list[i]);
  //   await reserveSetCoinbaseAmount(_list[i], 1000e8, 1000e8, 1000e8, 1000e8, 1000e8);
  // }

  // await arbitrage_fwp(false);
  // await arbitrage_crp(false, {0:_pools[1]});
  // await arbitrage_ytp(false, _pools);
  // await arbitrage_fwp(false);

  // await test_spot_trading();
  // await test_margin_trading();

  // await create_crp(true, _pools);
  // await create_ytp(true, _pools);

  // await arbitrage_fwp(dry_run=true);
  // await arbitrage_crp(dry_run=true, _pools);
  // await arbitrage_ytp(dry_run=true, _pools);
  // await get_pool_details_fwp();

  // await get_pool_details_crp(_pools);
  // await get_pool_details_ytp(_pools);

  // await reduce_position_fwp({0:_fwp_pools[1]}, 0.5e8, true);

  // const _reduce = { 0: _deploy[14] , 1: _deploy[15] };
  // await reduce_position_ytp(_reduce, 0.9*ONE_8, deployer=true);
  // await get_pool_details_ytp(_subset=_reduce);

  // await reduce_position_ytp(_pools, 0.1*ONE_8, deployer=true);
  // await reduce_position_crp(_pools, ONE_8, 'yield');
  // await reduce_position_crp(_pools, ONE_8, 'key');
  // await reduce_position_crp(_pools, 0.8*ONE_8, 'yield', deployer=true);
  // await reduce_position_crp(_pools, 0.8*ONE_8, 'key', deployer=true);

  // await see_balance(DEPLOYER_ACCOUNT_ADDRESS());
  // await mint_some_tokens(DEPLOYER_ACCOUNT_ADDRESS());
  //
  // await see_balance(DEPLOYER_ACCOUNT_ADDRESS());
  // await mint_some_tokens(DEPLOYER_ACCOUNT_ADDRESS() + '.alex-vault');
  //
  // await see_balance(DEPLOYER_ACCOUNT_ADDRESS() + '.alex-vault');

  // await see_balance(DEPLOYER_ACCOUNT_ADDRESS() + '.alex-vault');
  // await get_some_token(DEPLOYER_ACCOUNT_ADDRESS() + '.alex-vault');

  // await mint_some_wbtc(USER_ACCOUNT_ADDRESS());
  // await get_some_token('ST32AK70FP7VNAD68KVDQF3K8XSFG99WKVEHVAPFA');
  // await burn('token-wbtc', 'STZP1114C4EA044RE54M6G5ZC2NYK9SAHB5QVE1', 9995719169074);
  // await burn('token-usda', 'STZP1114C4EA044RE54M6G5ZC2NYK9SAHB5QVE1', 399709145833000000);

  // result = await ytpGetYgivenX('yield-wbtc-51840', 1e8);
  // console.log(result);

  // result = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 0.01e8);
  // console.log(result);

  // await fwpSwapXforY('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 0.01e8, 56319120000);
  // result = await fwpGetYgivenX('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 1000000);
  // console.log(result);

  // await arbitrage_fwp(dry_run = false);
  // await mint_some_wbtc('ST32AK70FP7VNAD68KVDQF3K8XSFG99WKVEHVAPFA');
  // await see_balance(USER_ACCOUNT_ADDRESS());

  // result = await fwpGetPositionGivenBurn('token-wbtc', 'token-usda', 0.5e8, 0.5e8, 325.48 * 1e3 * 1e8);
  // printResult(result);
  // result = await ytpGetPositionGivenBurn('yield-wbtc-92160', 0.5 * 1e8);
  // printResult(result);

  // result = await balance('key-usda-34560-wbtc', USER_ACCOUNT_ADDRESS());
  // console.log(result);
  // await transfer('key-usda-34560-wbtc', 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ', 10668690600000);


  // let result:any = await reserveGetStaked('token-t-alex', [0,1,2,3,4,5,6,7,8,9,10]);
  // let result:any = await reserveGetStakingStatsCoinbaseAsList('fwp-wstx-wbtc-50-50', [2,3,4,5,6,7,8,9,10]);
  // let result:any = await reserveGetStakingRewards('token-t-alex', [2,3,4,5,6,7,8,9,10])
  // let result:any = await balance('fwp-wstx-wbtc-50-50', DEPLOYER_ACCOUNT_ADDRESS());
  // console.log(result)
  // let result:any = await reserveStakeTokens('fwp-wstx-wbtc-50-50', 100e8, 32);
  // console.log(result);
  // let result:any = await reserveGetStakingRewards('fwp-wstx-wbtc-50-50', [10,20,30,40,50])
  // for (const item in result.list ){
  //   console.log(result.list[item]);
  // }  

  // await multisigPropose('multisig-fwp-wstx-wbtc-50-50', 6030, 'update fee', '', 0.003e8, 0.003e8);
  // let result:any = await balance('fwp-wstx-wbtc-50-50', DEPLOYER_ACCOUNT_ADDRESS());
  // console.log(result)
  // let result:any = await multisigVoteFor('multisig-fwp-wstx-usda-50-50', 'fwp-wstx-usda-50-50', 1, 17907343375660777);
  // result = await multisigEndProposal('multisig-fwp-wstx-usda-50-50', 1);
  // result = await multisigGetProposalById('multisig-fwp-wstx-usda-50-50', 2);
  // console.log(result);
  // result = await multisigVoteFor('multisig-fwp-wstx-usda-50-50', 'fwp-wstx-usda-50-50', 1, 19502551000000);
  // console.log(result);
  // let result:any = await multisigEndProposal('multisig-fwp-wstx-wbtc-50-50', 1);
  // console.log(result);
  // let result:any = await multisigGetProposalById('multisig-fwp-wstx-wbtc-50-50', 1);
  // console.log(result);
  
  // await multisigReturnVotes('multisig-fwp-wstx-wbtc-50-50', 'fwp-wstx-wbtc-50-50', 1);
  // await fwpSetFeeRebate('token-wstx', 'token-wbtc', 0.5e8, 0.5e8, 0.5e8);
  // let result:any = await fwpGetPoolDetails('token-wstx', 'token-wbtc', 0.5e8, 0.5e8);
  // console.log(result.value.data);

  // let result:any = await fwpGetPoolDetails('token-wstx', 'token-wbtc', 0.5e8, 0.5e8);
  // console.log(result.value.data);

  // tiger ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4
  // james STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ
  // lynn ST2PMTQVZVCVSMH5XHYYES3EV9JW22G0VT2C56AY4
  // ali ST1D0QCNK85ZZDNHEV5DTDCD9G2Q043CK967ZST9K

  // _list = ['key-usda-wbtc', 'key-wbtc-usda', 'key-wbtc-wbtc', 'yield-wbtc', 'yield-usda', 'ytp-yield-wbtc', 'ytp-yield-usda']
  // for (let i = 0; i < _list.length; i++) {
  //     await mint_sft(_list[i], 34560, 1000e8, 'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4');
  // }

  // let _list = [
  //     'ST20F5HAX0W3AEG8M5C9J2880132CQTP6TZFAT3YF', 
  //     'ST34CGPP646BN5RBEC0GK1BSWWY9G1HW1HHC7H4DP', 
  //     'STHB7WGM8DRFVGTVKHNVZXEVSPKKPCPEGGN27RWM',
  //     'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4',
  //     'ST1D0QCNK85ZZDNHEV5DTDCD9G2Q043CK967ZST9K',
  //     'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ'
  //   ];  
  // for (let i = 0; i < _list.length; i++) {
  //     await get_some_token(_list[i]);
  //     // mint_ft('lottery-t-alex', 100e8, _list[i]);
  // }
  // await set_faucet_amounts();
  // await get_some_token('ST1XARV3J1N3SJJBDJCE3WE84KDHZQGMGBAZR2JXT');
  // await get_some_token('ST11KFHZRN7ANRRPDK0HJXG243EJBFBAFRB27NPK8');
  // await mint_ft('lottery-t-alex', 100e8, 'ST1XARV3J1N3SJJBDJCE3WE84KDHZQGMGBAZR2JXT');
  await mint_ft('lottery-t-alex', 100e8, 'ST11KFHZRN7ANRRPDK0HJXG243EJBFBAFRB27NPK8');
  await transferSTX('ST11KFHZRN7ANRRPDK0HJXG243EJBFBAFRB27NPK8', 250000e8);

  // await mint_ft('token-t-alex', 90000e8, DEPLOYER_ACCOUNT_ADDRESS());
  // await mint_ft('lottery-t-alex', 100e8, DEPLOYER_ACCOUNT_ADDRESS());
  // await mint_ft('lottery-t-alex', 10000e8, USER_ACCOUNT_ADDRESS());
  // await mint_ft('lottery-t-alex', 100e8, 'ST34CGPP646BN5RBEC0GK1BSWWY9G1HW1HHC7H4DP')
  // await mint_ft('lottery-t-alex', 100e8, 'STHB7WGM8DRFVGTVKHNVZXEVSPKKPCPEGGN27RWM')
  // let result:any = await launchCreate(
  //     'token-t-alex',
  //     'lottery-t-alex',
  //     DEPLOYER_ACCOUNT_ADDRESS(),
  //     100,
  //     25e8,
  //     3600,
  //     4200,
  //     4600,
  //     100
  //     );
  // await launchAddToPosition('token-t-alex', 1000);
  // await launchRegister('token-t-alex', 'lottery-t-alex', 100);
  // await launchRegister('token-t-alex', 'lottery-t-alex', 90, false);
  // result = await launchGetTokenDetails("token-t-alex");
  // console.log(result.value.data);
  // result = await launchGetSubscriberAtToken('token-t-alex', 1);
  // console.log(result.data);
  // result = await launchGetSubscriberAtToken('token-t-alex', 2);
  // console.log(result.data);
}
run();
