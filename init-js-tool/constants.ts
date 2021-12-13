import path from 'path';

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

export const STACKS_API_URL = () => {
  if (process.env.STACKS_API_URL) {
    return process.env.STACKS_API_URL;
  }

  throw new Error(`STACKS_API_URL is not defined`);
};

export const DEPLOYER_ACCOUNT_ADDRESS = () => {
  if (process.env.DEPLOYER_ACCOUNT_ADDRESS) {
    return process.env.DEPLOYER_ACCOUNT_ADDRESS;
  }
  throw new Error(`DEPLOYER_ACCOUNT_ADDRESS is not defined`);
};

export const USER_ACCOUNT_ADDRESS = () => {
  if (process.env.USER_ACCOUNT_ADDRESS) {
    return process.env.USER_ACCOUNT_ADDRESS;
  }
  throw new Error(`USER_ACCOUNT_ADDRESS is not defined`);
};

export const DEPLOYER_ACCOUNT_SECRET = () => {
  if (process.env.DEPLOYER_ACCOUNT_SECRET) {
    return process.env.DEPLOYER_ACCOUNT_SECRET;
  }
  throw new Error(`DEPLOYER_ACCOUNT_SECRET is not defined`);
};

export const DEPLOYER_ACCOUNT_PASSWORD = () => {
  if (process.env.DEPLOYER_ACCOUNT_PASSWORD) {
    return process.env.DEPLOYER_ACCOUNT_PASSWORD;
  }

  if (process.env.ACCOUNT_PWD) {
    return process.env.ACCOUNT_PWD;
  }
  throw new Error(`DEPLOYER_ACCOUNT_PASSWORD or ACCOUNT_PWD is not defined`);
};

export const USER_ACCOUNT_SECRET = () => {
  if (process.env.USER_ACCOUNT_SECRET) {
    return process.env.USER_ACCOUNT_SECRET;
  }
  throw new Error(`USER_ACCOUNT_SECRET is not defined`);
};

export const USER_ACCOUNT_PASSWORD = () => {
  if (process.env.USER_ACCOUNT_PASSWORD) {
    return process.env.USER_ACCOUNT_PASSWORD;
  }

  if (process.env.ACCOUNT_PWD) {
    return process.env.ACCOUNT_PWD;
  }
  throw new Error(`USER_ACCOUNT_PASSWORD or ACCOUNT_PWD is not defined`);
};
export const ONE_8 = 100000000;
export const _fwp_pools = {
  1: {
    token_x: 'token-wstx',
    token_y: 'token-usda',
    weight_x: 0.5e8,
    weight_y: 0.5e8,
    pool_token: 'fwp-wstx-usda-50-50',
    multisig: 'multisig-fwp-wstx-usda-50-50',
    left_side: 10000000e8,
    right_side: 10000000e8 / 2
  },
  2: {
    token_x: 'token-wstx',
    token_y: 'token-wbtc',
    weight_x: 0.5e8,
    weight_y: 0.5e8,
    pool_token: 'fwp-wstx-wbtc-50-50',
    multisig: 'multisig-fwp-wstx-wbtc-50-50',
    left_side: 10000000e8,
    right_side: 10000000e8 / 2 / 50000
  },
} as const;
export const _deploy = {
  0: {
    token: 'token-wbtc',
    collateral: 'token-usda',
    yield_token: 'yield-wbtc',
    key_token: 'key-wbtc-usda',
    pool_token: 'ytp-yield-wbtc',
    multisig_ytp: 'multisig-ytp-yield-wbtc',
    multisig_crp: 'multisig-crp-wbtc-usda',
    liquidity_ytp: 200e8,
    collateral_crp: 150000e8,
    ltv_0: 0.7e8,
    bs_vol: 0.8e8,
    target_apy: 0.06354,
    expiry: 34560e8,
    token_to_maturity: 11520e8,
  },
  1: {
    token: 'token-usda',
    collateral: 'token-wbtc',
    yield_token: 'yield-usda',
    key_token: 'key-usda-wbtc',
    pool_token: 'ytp-yield-usda',
    multisig_ytp: 'multisig-ytp-yield-usda',
    multisig_crp: 'multisig-crp-usda-wbtc',
    liquidity_ytp: 10000000e8,
    collateral_crp: 2e8,
    ltv_0: 0.7e8,
    bs_vol: 0.8e8,
    target_apy: 0.086475,
    expiry: 34560e8,
    token_to_maturity: 11520e8,
  },
} as const;
