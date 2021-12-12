import PQueue from 'p-queue';
import toml from '@iarna/toml';
import path from 'path';
import fs from 'fs';
import { uniq } from 'lodash';
import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';
import { broadcastTransaction, makeContractDeploy } from '@stacks/transactions';
import { exit } from 'process';
import chalk from 'chalk';
import { Contracts } from './types';

require('dotenv').config();

const { sleep } = require('../init-js-tool/utils');
const {
  getDeployerPK,
  network,
  genesis_transfer,
} = require('../init-js-tool/wallet');

const {
  STACKS_API_URL,
  DEPLOYER_ACCOUNT_ADDRESS,
} = require('../init-js-tool/constants');

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

async function deployAllContracts() {
  const clarinetConfig = toml.parse(
    fs.readFileSync(
      path.resolve(__dirname, '../clarity/Clarinet.toml'),
      'utf8',
    ),
  );

  const contracts = clarinetConfig.contracts as Contracts;

  checkAllDependencies(contracts);
  const contractsKeys = Object.keys(contracts);

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
      await deployContracts(contracts, contractName);
    });
  });

  await queue.onIdle();
}

async function deployContracts(contracts: Contracts, contractName: string) {
  const contract = contracts[contractName];
  if (contract == null) {
    throw new Error(`Contract ${contractName} not found`);
  }
  const contractPath = contract.path;

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

const argv = yargs(hideBin(process.argv))
  .option('init', {
    alias: 'i',
    describe: 'genesis transfer',
    type: 'boolean',
    default: false,
  })
  .option('verbose', {
    alias: 'v',
    type: 'boolean',
    description: 'Run with verbose logging',
  })
  .parse();

const run = async () => {
  const userInput = await argv;

  if (userInput.init) {
    await genesis_transfer();
  }

  await deployAllContracts();

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
};

run().then();
