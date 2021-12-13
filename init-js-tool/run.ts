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
  reserveGetStakerAtCycleOrDefault
} from './reserve';
import {
  test_spot_trading,
  test_margin_trading
} from './runSteps/archived-code';


async function run_mint_initial_tokens() {
  await set_faucet_amounts();
  await mint_some_tokens(DEPLOYER_ACCOUNT_ADDRESS());
  await mint_some_tokens(USER_ACCOUNT_ADDRESS());
  await get_some_token(USER_ACCOUNT_ADDRESS());
}

async function run() {
  // await run_mint_initial_tokens();

  // const _pools = { 0:_deploy[4], 1:_deploy[5] };
  const _pools = _deploy;
  
  // await create_fwp(false);
  // await create_ytp(false, _pools);
  // await create_crp(false, _pools);

  // await arbitrage_fwp(false);
  // await arbitrage_crp(false, _pools);
  // await arbitrage_ytp(false, _pools);
  // await arbitrage_fwp(false);

  await test_spot_trading();
  // await test_margin_trading();

  // await create_fwp(true, _fwp_pools, true);
  // await create_crp(true, _pools);
  // await create_ytp(true, _pools);

  // await arbitrage_fwp(dry_run=true);
  // await arbitrage_crp(dry_run=true, _pools);
  // await arbitrage_ytp(dry_run=true, _pools);
  // await get_pool_details_fwp();
  // await get_pool_details_crp(_pools);
  // await get_pool_details_ytp(_pools);

  // await reduce_position_fwp(0.5 * ONE_8, deployer=true);

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

  // _list = ['fwp-wbtc-usda-50-50', 'ytp-yield-wbtc-92160-wbtc', 'ytp-yield-usda-92160-usda']
  // for (let i = 0; i < _list.length; i++){
  //     // result = await balance(_list[i], DEPLOYER_ACCOUNT_ADDRESS());
  //     // console.log(result);
  //     await transfer(_list[i], 'STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ', ONE_8, deployer=true);
  // }
  // let _list = ['fwp-wbtc-usda-50-50']; //, 'ytp-yield-wbtc-92160-wbtc', 'ytp-yield-usda-92160-usda'];
  // for(let i = 0; i < _list.length; i++) {
  //   await reserveAddToken(_list[i]);
  //   await reserveSetActivationThreshold(1);
  //   await reserveSetActivationDelay(1);
  //   await reserveSetRewardCycleLength(525);
  //   await reserveRegisterUser(_list[i]);
  //   await reserveSetCoinbaseAmount(_list[i], 500e8, 250e8, 125e8, 62e8, 37e8);
  // }

  // await multisigPropose('multisig-fwp-wbtc-usda-50-50', 42610, 'update fee', '', 0.003 * ONE_8, 0.003 * ONE_8);
  // result = await balance('fwp-wbtc-usda-50-50', DEPLOYER_ACCOUNT_ADDRESS());
  // result = await multisigVoteFor('multisig-fwp-wbtc-usda-50-50', 'fwp-wbtc-usda-50-50', 2, 19502551000000);
  // result = await multisigEndProposal('multisig-fwp-wbtc-usda-50-50', 1);
  // result = await multisigGetProposalById('multisig-fwp-wbtc-usda-50-50', 2);
  // console.log(result);
  // result = await multisigVoteFor('multisig-fwp-wbtc-usda-50-50', 'fwp-wbtc-usda-50-50', 1, 19502551000000);
  // console.log(result);
  // result = await multisigEndProposal('multisig-fwp-wbtc-usda-50-50', 2);
  // console.log(result);
  // result = await multisigGetProposalById('multisig-fwp-wbtc-usda-50-50', 1);
  // console.log(result);

  // tiger ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4
  // james STCTK0C1JAFK3JVM95TFV6EB16579WRCEYN10CTQ
  // _list = ['key-usda-wbtc', 'key-wbtc-usda', 'key-wbtc-wbtc', 'yield-wbtc', 'yield-usda', 'ytp-yield-wbtc', 'ytp-yield-usda']
  // for (let i = 0; i < _list.length; i++) {
  //     await mint_sft(_list[i], 34560, 1000e8, 'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4');
  // }

  // _list = ['ST3MZM9WJ34Y4311XBJDBKQ41SXX5DY68406J26WJ', 'ST3QR9G3XJ2J0HH1EEER1V648HDJQN2W46KHSXTW8', 'ST3DNHSRVVT9BJEG2A7VTD06F8PJNAS9YAVWT8N1G'];
  // let _list = [ 'ST17MVDJT37DGB5QRRS1H4HQ4MKVFKA3KAA4YGFH4' ];
  // for (let i = 0; i < _list.length; i++) {
  //     await get_some_token(_list[i]);
  //     // mint_ft('lottery-t-alex', 100e8, _list[i]);
  // }
  // await get_some_token('ST3DNHSRVVT9BJEG2A7VTD06F8PJNAS9YAVWT8N1G');
  // await mint_ft('token-t-alex', 90000e8, process.env.DEPLOYER_ACCOUNT_ADDRESS);
  // await mint_ft('lottery-t-alex', 100e8, process.env.DEPLOYER_ACCOUNT_ADDRESS);
  // await mint_ft('lottery-t-alex', 10000e8, process.env.USER_ACCOUNT_ADDRESS);
  // result = await launchCreate(
  //     'token-t-alex',
  //     'lottery-t-alex',
  //     DEPLOYER_ACCOUNT_ADDRESS(),
  //     100,
  //     25e8,
  //     23000,
  //     33000,
  //     43000,
  //     100
  //     );
  // await launchAddToPosition('token-t-alex', 1000);
  // await launchRegister('token-t-alex', 'lottery-t-alex', 100);
  // await launchRegister('token-t-alex', 'lottery-t-alex', 90, deployer=false);
  // result = await launchGetTokenDetails("token-t-alex");
  // console.log(result.value.data);
  // result = await launchGetSubscriberAtToken('token-t-alex', 1);
  // console.log(result.data);
  // result = await launchGetSubscriberAtToken('token-t-alex', 2);
  // console.log(result.data);
}
run();
