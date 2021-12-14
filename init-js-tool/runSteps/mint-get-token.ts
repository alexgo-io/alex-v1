import { balance, mint_ft, transferSTX } from '../vault';
import { DEPLOYER_ACCOUNT_ADDRESS, ONE_8 } from '../constants';
import { getSomeTokens, setAlexAmount, setStxAmount, setUsdaAmount, setWbtcAmount } from '../faucet';
import { format_number } from '../utils';

export async function mint_some_tokens(recipient: string) {
  console.log('------ Mint Some Tokens ------');
  await mint_some_usda(recipient);
  await mint_some_wbtc(recipient);
}

export async function mint_some_usda(recipient: string) {
  console.log('------ Mint Some USDA ------');
  // await mint('token-usda', recipient, 200000000000000000n);
  // await mint_ft('token-usda', 10000000000 * ONE_8, recipient);
  await mint_ft('token-usda', 10000000000 * ONE_8, recipient);
  const usda_balance: any = await balance('token-usda', recipient);
  console.log(
    'usda balance: ',
    format_number(Number(usda_balance.value.value) / ONE_8),
  );
}

export async function mint_some_wbtc(recipient: string) {
  console.log('------ Mint Some WBTC ------');
  // await mint_ft('token-wbtc', 5000 * ONE_8, recipient);
  // await mint('token-wbtc', recipient, Math.round(10000000000 * ONE_8 / 61800));
  await mint_ft('token-wbtc', 900000000 * ONE_8, recipient);
  const wbtc_balance = await balance('token-wbtc', recipient);
  console.log(
    'wbtc balance: ',
    format_number(Number(wbtc_balance.value.value) / ONE_8),
  );
}

export async function see_balance(owner: string) {
  console.log('------ See Balance ------');
  const usda_balance = await balance('token-usda', owner);
  console.log(
    'usda balance: ',
    format_number(Number(usda_balance.value.value) / ONE_8),
  );
  const wbtc_balance = await balance('token-wbtc', owner);
  console.log(
    'wbtc balance: ',
    format_number(Number(wbtc_balance.value.value) / ONE_8),
  );
}

export async function set_faucet_amounts() {
  console.log('------ Set Faucet Amounts ------');
  await setUsdaAmount(500000e8);
  await setWbtcAmount(5e8);
  await setStxAmount(250e8);
  await setAlexAmount(10e8);
}

export async function get_some_token(recipient: string) {
  console.log('------ Get Some Tokens ------');
  await see_balance(recipient);
  await getSomeTokens(recipient);
  await see_balance(recipient);
}
