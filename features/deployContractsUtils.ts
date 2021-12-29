import PQueue from 'p-queue';
import toml from '@iarna/toml';
import path from 'path';
import fs from 'fs';
import { uniq } from 'lodash';
import { broadcastTransaction, makeContractDeploy } from '@stacks/transactions';
import chalk from 'chalk';
import { Contracts } from './types';

import { sleep } from './utils';

import { getDeployerPK, network } from './wallet';

import {
  DEPLOYER_ACCOUNT_ADDRESS,
  STACKS_API_URL,
} from './constants';

const contract_records: {
  Contracts: {
    name: string;
    deployer: string;
    version: number;
  }[];
} = { Contracts: [] };

let VERSION = 0;

function checkDependencies(contractName: string, contracts: Contracts) {
  const content = fs.readFileSync(
    path.resolve(__dirname, '../clarity/' + contracts[contractName].path),
    'utf8',
  );

  const regex = /contract-call\? \.([\w|-]*) /gm;
  /*? contractName*/
  const contractCalls = uniq(
    Array.from(content.matchAll(regex)).map(m => m[1]),
  ); /*?*/

  contractCalls.forEach(calledContract => {
    if (!contracts[contractName].depends_on.includes(calledContract)) {
      console.log(
        `contract: ${chalk.blue(contractName)} called: [${chalk.red(
          calledContract,
        )}] but not in dependencies. fixed in: ${contracts[contractName].path}`,
      );
    }
  });
}

function checkAllDependencies(contracts: Contracts) {
  Object.keys(contracts).forEach(contractName => {
    checkDependencies(contractName, contracts);
  });
}

export async function deployAllContracts(only?: string) {
  const clarinetConfig = toml.parse(
    fs.readFileSync(
      path.resolve(__dirname, '../clarity/Clarinet.toml'),
      'utf8',
    ),
  );

  const contracts = clarinetConfig.contracts as Contracts;

  checkAllDependencies(contracts);
  const contractsKeys = Object.keys(contracts).filter(
    c =>
      only == null ||
      only.split(',').some(o => c.toLowerCase().includes(o.toLowerCase())),
  );

  function findDeps(name: string): string[] {
    const contract = contracts[name].depends_on;
    return [...contract.flatMap(findDeps), name];
  }

  const sortedContractNames = uniq(contractsKeys.flatMap(findDeps));
  const inQueue = new Set();

  const queue = new PQueue({ concurrency: 1 });

  sortedContractNames.forEach((contractName, index) => {
    queue.add(async () => {
      if (inQueue.has(contractName)) {
        return;
      }
      inQueue.add(contractName);

      console.log(
        `Deploying - ${chalk.yellow(
          `${index + 1}/${sortedContractNames.length}`,
        )} - ${contractName}`,
      );
      await deployContract(contractName, contracts[contractName].path);
    });
  });

  await queue.onIdle();
}

export async function deployContract(contractName: string, contractPath: string) {
  let privatekey = await getDeployerPK();
  const transaction = await makeContractDeploy({
    contractName: contractName,
    codeBody: fs
      .readFileSync(path.resolve(__dirname, `../clarity/`, contractPath))
      .toString(),
    senderKey: privatekey,
    network,
    anchorMode: undefined as any, //TODO: makeContractDeploy does support anchorMode is undefined
  });
  const broadcast_id = await broadcastTransaction(transaction, network);
  console.log(`${STACKS_API_URL()}/extended/v1/tx/0x${broadcast_id.txid}`);
  let counter = 0;
  while (true) {
    await sleep(2000);
    let truth = await fetch(
      `${STACKS_API_URL()}/extended/v1/tx/${broadcast_id.txid}`,
    );
    let res = await truth.json();
    console.log(
      `[${counter++}] Waiting... ${broadcast_id.txid} - ${contractName}`,
    );
    if (res['tx_status'] === 'success') {
      console.log(
        `Contract ${chalk.blue(contractName)} Deployed ${chalk.green(
          'Successfully',
        )}`,
      );
      contract_records['Contracts'].push({
        name: contractName,
        version: VERSION,
        deployer: DEPLOYER_ACCOUNT_ADDRESS(),
      });
      break;
    } else if (res['tx_status'] === 'abort_by_response') {
      console.log(
        `Contract ${chalk.red(contractName)} - Transaction aborted: `,
        res['tx_result']['repr'],
      );
      break;
    } else if (res.hasOwnProperty('error')) {
      console.log(
        `Contract ${chalk.redBright(contractName)} Transaction error: `,
        res['error'],
      );
      break;
    }
  }
}
