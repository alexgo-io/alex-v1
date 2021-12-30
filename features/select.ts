import toml from '@iarna/toml';
import fs from 'fs-extra';
import path from 'path';
import { pick } from 'lodash';
import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';
import { Contracts } from './types';

function extract(targetContracts: string[] | null, filePath: string) {
  const clarinetConfig = toml.parse(fs.readFileSync(filePath, 'utf8'));
  const contracts = clarinetConfig.contracts as Contracts;

  if (targetContracts == null) {
    return clarinetConfig;
  }

  const dependencies = [];

  for (const targetContract of targetContracts) {
    contracts[targetContract].depends_on.forEach(contract => {
      dependencies.push(contract);
    });
  }
  const buildContracts = new Set<string>();

  const addDependencyRecursively = (targetContracts: string[]) => {
    targetContracts.forEach(t => buildContracts.add(t));
    targetContracts.forEach(t => {
      addDependencyRecursively(contracts[t].depends_on);
    });
  };

  addDependencyRecursively(targetContracts);
  /*? Array.from(buildContracts)*/
  const targetConfig = {
    ...clarinetConfig,
    contracts: pick(contracts, Array.from(buildContracts)),
  };

  return targetConfig; /*?*/
}

const baseContentPath = path.join(__dirname, '../clarity/Clarinet.toml');

function load(env: string) {
  const clarinetConfig = toml.parse(
    fs.readFileSync(path.resolve(__dirname, `Clarinet.${env}.toml`), 'utf8'),
  );
  const contracts = clarinetConfig.contracts;
  // throw error if contracts is array and length > 1 and is array of string
  if (!(contracts && Array.isArray(contracts) && contracts.length > 1)) {
    throw new Error('Clarinet.toml: contracts is array and length > 1.');
  }

  return extract(contracts as string[], baseContentPath);
}

function save(tomlContent: any, filePath: string) {
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
  fs.writeFileSync(filePath, toml.stringify(tomlContent));
  fs.chmodSync(filePath, 0o400);
}

function cpContracts(env: string) {
  const envFolder = path.resolve(__dirname, `../.clarinet_alex/${env}`);
  if (fs.existsSync(envFolder)) {
    fs.removeSync(envFolder);
  }
  fs.copySync(path.resolve(__dirname, `../clarity`), envFolder);
}

async function run() {
  const argv = yargs(hideBin(process.argv))
    .option('env', {
      alias: 'e',
      describe: 'clarity env',
      type: 'string',
      default: 'base',
    })
    .option('verbose', {
      alias: 'v',
      type: 'boolean',
      description: 'Run with verbose logging',
    })
    .parse();

  const inputs = await argv;

  // check if env file exists
  const selectedEnv = inputs.env;
  console.log(`selecting ${selectedEnv}`);
  if (
    selectedEnv !== 'base' &&
    !fs.existsSync(path.resolve(__dirname, `Clarinet.${selectedEnv}.toml`))
  ) {
    console.error(
      `features/Clarinet.${selectedEnv}.toml does not exist. Please setup this file first.`,
    );
    process.exit(1);
  }

  cpContracts(selectedEnv);
  const targetToml = `../.clarinet_alex/${selectedEnv}/Clarinet.toml`;
  if (selectedEnv === 'base') {
    // base means all contracts, do nothing
    // save(extract(null, baseContentPath), path.resolve(__dirname, targetToml));
  } else {
    save(load(selectedEnv), path.resolve(__dirname, targetToml));
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});
