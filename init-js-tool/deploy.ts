import { exit } from 'process';
import { DEPLOYER_ACCOUNT_ADDRESS, STACKS_API_URL } from './constants';
import { broadcastTransaction, makeContractDeploy } from '@stacks/transactions';
import fs from 'fs';
import path from 'path';

import { getDeployerPK, network, genesis_transfer } from './wallet';

require('dotenv').config();

let contract_records: {
  Contracts: { name: string; deployer: string; version: string }[];
} = { Contracts: [] };
let VERSION = '0';
let contract_paths = [
  'lib/math-log-exp.clar',
  'lib/math-fixed-point.clar',
  'traits/trait-sip-010.clar',
  'traits/trait-semi-fungible.clar',
  'traits/trait-flash-loan-user.clar',
  'traits/trait-oracle.clar',
  'traits/trait-ownable.clar',
  'traits/trait-vault.clar',
  'traits/trait-multisig-vote.clar',
  'equations/weighted-equation.clar',
  'equations/yield-token-equation.clar',
  'token/token-alex.clar',
  'token/token-usda.clar',
  'token/token-wbtc.clar',
  'token/token-t-alex.clar',
  'alex-vault.clar',
  'wrapped-token/token-wstx.clar',
  'open-oracle.clar',
  'pool/alex-reserve-pool.clar',
  'pool/fixed-weight-pool.clar',
  'pool/liquidity-bootstrapping-pool.clar',
  'pool/yield-token-pool.clar',
  'pool/collateral-rebalancing-pool.clar',
  'faucet.clar',

  'pool-token/fwp-wstx-usda-50-50.clar',
  'pool-token/fwp-wstx-wbtc-50-50.clar',
  'pool-token/lbp-alex-usda-90-10.clar',
  'multisig/multisig-fwp-wstx-usda-50-50.clar',
  'multisig/multisig-fwp-wstx-wbtc-50-50.clar',
  'multisig/multisig-lbp-alex-usda-90-10.clar',

  'yield-token/yield-wbtc.clar',
  'yield-token/yield-usda.clar',
  'key-token/key-usda-wbtc.clar',
  'key-token/key-wbtc-usda.clar',
  'pool-token/ytp-yield-wbtc.clar',
  'pool-token/ytp-yield-usda.clar',
  'multisig/multisig-crp-wbtc-usda.clar',
  'multisig/multisig-crp-usda-wbtc.clar',
  'multisig/multisig-ytp-yield-wbtc.clar',
  'multisig/multisig-ytp-yield-usda.clar',
  'flash-loan-user-margin-usda-wbtc.clar',
  'flash-loan-user-margin-wbtc-usda.clar',

  'pool/alex-launchpad.clar',
  'lottery-tokens/lottery-t-alex.clar',
  'helpers/staking-helper.clar',
  'helpers/margin-helper.clar',
];

function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
async function walkDir() {
  console.log(contract_paths);

  for (const filePath of contract_paths) {
    const contactName = path.basename(filePath).split('.')[0];
    console.log(`deploying ${filePath}, ${contactName}`);
    const targetPath = path.resolve(
      __dirname,
      '../clarity/contracts',
      filePath,
    );
    if (targetPath != null) {
      await deploy(targetPath, contactName);
    } else {
      console.log(`file not found: ${filePath}`);
    }
  }
  // contract_paths.reduce(async (memo, path) => {
  //     await memo
  //     let contract_file = path.split('/').at(-1)
  //     let contract_name = contract_file.split('.')[0]
  //     await deploy("../clarity/contracts/" + path, contract_name)
  // }, undefined);
}

async function deploy(filePath: string, contractName: string) {
  console.log('Deploying:: ', contractName);
  let privatekey = await getDeployerPK();
  const txOptions = {
    contractName: contractName,
    codeBody: fs.readFileSync(filePath).toString(),
    senderKey: privatekey,
    network,
  };
  const transaction = await makeContractDeploy(txOptions as any);
  const broadcast_id = await broadcastTransaction(transaction, network);
  // console.log(broadcast_id)
  console.log(`${STACKS_API_URL()}/extended/v1/tx/0x${broadcast_id.txid}`);
  while (true) {
    await sleep(3000);
    let truth = await fetch(
      `${STACKS_API_URL()}/extended/v1/tx/${broadcast_id.txid}`,
    );
    let res = await truth.json();
    console.log(`Waiting... ${broadcast_id.txid}`);
    if (res['tx_status'] === 'success') {
      console.log('Contract Deployed Successfully');
      contract_records['Contracts'].push({
        name: contractName,
        version: VERSION,
        deployer: DEPLOYER_ACCOUNT_ADDRESS(),
      });
      break;
    } else if (res['tx_status'] === 'abort_by_response') {
      console.log('Transaction aborted: ', res['tx_result']['repr']);
      break;
    } else if (res.hasOwnProperty('error')) {
      console.log('Transaction aborted: ', res['error']);
      break;
    }
  }
}

async function run() {
  // VERSION = await get_version()
  await genesis_transfer();
  //walk the batches directory and deploy
  await walkDir();
  //write to file
  console.log(contract_records);
  fs.writeFile(
    './contract-records.json',
    JSON.stringify(contract_records),
    'utf8',
    function (err) {
      if (err) throw err;
      console.log('File created');
      exit();
    },
  );
}
run();
