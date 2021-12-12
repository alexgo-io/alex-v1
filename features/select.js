#!/usr/bin/env node

const toml = require('@iarna/toml');
const fs = require('fs');
const path = require('path');
const { pick } = require('lodash');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

function extract(targetContracts, filePath) {
  const clarinetConfig = toml.parse(fs.readFileSync(filePath));
  const contracts = clarinetConfig.contracts;

  if (targetContracts == null) {
    return clarinetConfig;
  }

  const dependencies = [];

  for (const targetContract of targetContracts) {
    contracts[targetContract].depends_on.forEach(contract => {
      dependencies.push(contract);
    });
  }
  const buildContracts = new Set();

  const addDependencyRecursively = targetContracts => {
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

const baseContentPath = path.join(__dirname, 'Clarinet.base.toml');

function load(env) {
  const clarinetConfig = toml.parse(
    fs.readFileSync(path.resolve(__dirname, `Clarinet.${env}.toml`)),
  );

  return extract(clarinetConfig.contracts, baseContentPath);
}

function save(tomlContent, filePath) {
  fs.writeFileSync(filePath, toml.stringify(tomlContent));
}

const argv = yargs(hideBin(process.argv))
  .option('env', {
    alias: 'e',
    describe: 'clarity env',
    type: 'string',
    default: 'dev',
  })
  .option('verbose', {
    alias: 'v',
    type: 'boolean',
    description: 'Run with verbose logging',
  })
  .parse();

// check if env file exists
const selectedEnv = argv.env;
if (
  selectedEnv !== 'base' &&
  !fs.existsSync(path.resolve(__dirname, `Clarinet.${selectedEnv}.toml`))
) {
  console.error(
    `features/Clarinet.${selectedEnv}.toml does not exist. Please setup this file first.`,
  );
  process.exit(1);
}
console.log(`selecting env: ${selectedEnv}`);
const targetToml = '../clarity/Clarinet.toml';
if (selectedEnv === 'base') {
  save(extract(null, baseContentPath), path.resolve(__dirname, targetToml));
} else {
  save(load(selectedEnv), path.resolve(__dirname, targetToml));
}
