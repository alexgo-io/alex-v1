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

const DEPLOYER_ACCOUNT_SECRET = () => {
  if (process.env.DEPLOYER_ACCOUNT_SECRET) {
    return process.env.DEPLOYER_ACCOUNT_SECRET;
  }
  throw new Error(`DEPLOYER_ACCOUNT_SECRET is not defined`);
};

const DEPLOYER_ACCOUNT_PASSWORD = () => {
  if (process.env.DEPLOYER_ACCOUNT_PASSWORD) {
    return process.env.DEPLOYER_ACCOUNT_PASSWORD;
  }

  if (process.env.ACCOUNT_PWD) {
    return process.env.ACCOUNT_PWD;
  }
  throw new Error(`DEPLOYER_ACCOUNT_PASSWORD or ACCOUNT_PWD is not defined`);
};

const USER_ACCOUNT_SECRET = () => {
  if (process.env.USER_ACCOUNT_SECRET) {
    return process.env.USER_ACCOUNT_SECRET;
  }
  throw new Error(`USER_ACCOUNT_SECRET is not defined`);
};

const USER_ACCOUNT_PASSWORD = () => {
  if (process.env.USER_ACCOUNT_PASSWORD) {
    return process.env.USER_ACCOUNT_PASSWORD;
  }

  if (process.env.ACCOUNT_PWD) {
    return process.env.ACCOUNT_PWD;
  }
  throw new Error(`USER_ACCOUNT_PASSWORD or ACCOUNT_PWD is not defined`);
};

module.exports = {
  STACKS_API_URL,
  DEPLOYER_ACCOUNT_ADDRESS,
  USER_ACCOUNT_ADDRESS,
  DEPLOYER_ACCOUNT_SECRET,
  DEPLOYER_ACCOUNT_PASSWORD,
  USER_ACCOUNT_SECRET,
  USER_ACCOUNT_PASSWORD,
};
