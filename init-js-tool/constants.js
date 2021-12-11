const STACKS_API_URL = () => {
  if (process.env.STACKS_API_URL) {
    return process.env.STACKS_API_URL;
  }

  throw new Error(`STACKS_API_URL is not defined`);
};

const DEPLOYER_ACCOUNT_ADDRESS = () => {
  if (process.env.DEPLOYER_ACCOUNT_ADDRESS) {
    return process.env.DEPLOYER_ACCOUNT_ADDRESS;
  }
  throw new Error(`DEPLOYER_ACCOUNT_ADDRESS is not defined`);
};

const USER_ACCOUNT_ADDRESS = () => {
  if (process.env.USER_ACCOUNT_ADDRESS) {
    return process.env.USER_ACCOUNT_ADDRESS;
  }
  throw new Error(`USER_ACCOUNT_ADDRESS is not defined`);
};

module.exports = {
  STACKS_API_URL,
  DEPLOYER_ACCOUNT_ADDRESS,
  USER_ACCOUNT_ADDRESS,
};
