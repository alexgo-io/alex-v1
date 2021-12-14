import CoinGecko from 'coingecko-api';
import {
  AnchorMode,
  broadcastTransaction,
  callReadOnlyFunction,
  makeContractCall,
  stringAsciiCV,
  uintCV,
} from '@stacks/transactions';
import { wait_until_confirmation } from './utils';
import { getDeployerPK, network } from './wallet';
import { DEPLOYER_ACCOUNT_ADDRESS, USER_ACCOUNT_ADDRESS } from './constants';

const CoinGeckoClient = new CoinGecko();

//Use CoinGeckoClient to fetch current prices of btc & usdc
export const initCoinPrice = async () => {
  console.log('Updating coin market price...');
  // FIXME: typescript migrate;
  const btc = await CoinGeckoClient.coins.fetch('bitcoin', {
    vs_currency: 'usd',
    from: new Date(Date.now() - 60 * 1000).getTime(),
    to: Date.now(),
  } as any);
  // FIXME: typescript migrate;
  const usdc = await CoinGeckoClient.coins.fetch('usd-coin', {
    vs_currency: 'usd',
    from: new Date(Date.now() - 60 * 1000).getTime(),
    to: Date.now(),
  } as any);
  const usdcPrice = usdc.data.market_data.current_price.usd * 1e8;
  const btcPrice = btc.data.market_data.current_price.usd * 1e8;
  return {
    usdc: usdcPrice,
    btc: btcPrice,
  };
};

//Call open-oracle to set price
export const setOpenOracle = async (
  symbol: string,
  src: string,
  price: number,
) => {
  console.log('Setting oracle...', symbol, src, price);
  const privateKey = await getDeployerPK();

  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'open-oracle',
    functionName: 'update-price',
    functionArgs: [stringAsciiCV(symbol), stringAsciiCV(src), uintCV(price)],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

//Call open-oracle to get price
export const getOpenOracle = async (src: string, symbol: string) => {
  console.log('Getting oracle...', src, symbol);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: 'open-oracle',
    functionName: 'get-price',
    functionArgs: [stringAsciiCV(src), stringAsciiCV(symbol)],
    network: network,
    senderAddress: USER_ACCOUNT_ADDRESS(),
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

export const fetch_price = async (token: string, against: string): Promise<number> => {
  console.log('fetching price from coingecko...', token, against);
  // FIXME: typescript migrate;
  return (
    await CoinGeckoClient.coins.fetch(token, {
      vs_currency: against,
      from: new Date(Date.now() - 60 * 1000).getTime(),
      to: Date.now(),
    } as any)
  ).data.market_data.current_price.usd;
};

export const fetch_btc = async (against: string) => {
  return await fetch_price('bitcoin', against);
};

export const fetch_usdc = async (against: string) => {
  return await fetch_price('usd-coin', against);
};

export const fetch_in_usd = async (token: string) => {
  return await fetch_price(token, 'usd');
};
