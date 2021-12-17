import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';
import { genesis_transfer } from '../init-js-tool/wallet';
import { deployAllContracts } from './deployContractsUtils';

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
  .option('only',  {
    alias: 'o',
    type: 'string',
    description: 'Deploy only some contracts',
  })
  .parse();

const run = async () => {
  const userInput = await argv;
  if (userInput.init) {
    await genesis_transfer();
  }
  
  await deployAllContracts(userInput.only ?? undefined);
};

run().then();
