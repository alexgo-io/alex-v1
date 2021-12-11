const { getDeployerPK, getUserPK, network } = require("./wallet");
const {
  makeContractCall,
  callReadOnlyFunction,
  AnchorMode,
  PostConditionMode,
  uintCV,
  someCV,
  contractPrincipalCV,
  broadcastTransaction,
  ClarityType,
} = require("@stacks/transactions");
const { wait_until_confirmation } = require("./utils");
const {
  principalCV,
} = require("@stacks/transactions/dist/clarity/types/principalCV");
const { DEPLOYER_ACCOUNT_ADDRESS } = require("./constants");

const ytpCreate = async (
  expiry,
  yiedToken,
  token,
  poolToken,
  multiSig,
  dx,
  dy
) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log(
    "[YTP] create-pool...",
    expiry,
    yiedToken,
    token,
    poolToken,
    multiSig,
    dx,
    dy
  );
  const privateKey = await getDeployerPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "create-pool",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), multiSig),
      uintCV(dx),
      uintCV(dy),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

const ytpAddToPosition = async (
  expiry,
  yiedToken,
  token,
  poolToken,
  dx,
  deployer = false
) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] add-to-position...", yiedToken, token, poolToken, dx);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "add-to-position",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
      uintCV(dx),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

const ytpReducePosition = async (
  expiry,
  yiedToken,
  token,
  poolToken,
  percent,
  deployer = false
) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] reduce-position...", yiedToken, token, poolToken, percent);
  const privateKey = deployer ? await getDeployerPK() : await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "reduce-position",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), poolToken),
      uintCV(percent),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetPrice = async (expiry, yieldToken) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-price...", yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-price",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetYield = async (expiry, yieldToken) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-yield...", yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-yield",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpSwapXforY = async (expiry, yiedToken, token, dx, min_dy) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] swap-x-for-y...", yiedToken, token, dx);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "swap-x-for-y",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(dx),
      someCV(uintCV(min_dy)),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

const ytpSwapYforX = async (expiry, yiedToken, token, dy, min_dx) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] swap-y-for-x...", yiedToken, token, dy);
  const privateKey = await getUserPK();
  const txOptions = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "swap-y-for-x",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yiedToken),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), token),
      uintCV(dy),
      someCV(uintCV(min_dx)),
    ],
    senderKey: privateKey,
    validateWithAbi: true,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };
  try {
    const transaction = await makeContractCall(txOptions);
    const broadcastResponse = await broadcastTransaction(transaction, network);
    console.log(broadcastResponse);
    return await wait_until_confirmation(broadcastResponse.txid);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetXgivenY = async (expiry, yieldToken, dy) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-x-given-y...", yieldToken, dy);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-x-given-y",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(dy),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetYgivenX = async (expiry, yieldToken, dx) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-y-given-x...", yieldToken, dx);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-y-given-x",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(dx),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetXgivenYield = async (expiry, yieldToken, yied) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-x-given-yield...", yieldToken, yied);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-x-given-yield",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(yied),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetYgivenYield = async (expiry, yieldToken, yied) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-y-given-yield...", yieldToken, yied);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-y-given-yield",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(yied),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetPositionGivenBurn = async (expiry, yieldToken, shares) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-position-given-burn...", yieldToken, shares);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-position-given-burn",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
      uintCV(shares),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const ytpGetPoolDetails = async (expiry, yieldToken) => {
  console.log(
    "--------------------------------------------------------------------------"
  );
  console.log("[YTP] get-pool-details...", yieldToken);

  const options = {
    contractAddress: DEPLOYER_ACCOUNT_ADDRESS(),
    contractName: "yield-token-pool",
    functionName: "get-pool-details",
    functionArgs: [
      uintCV(expiry),
      contractPrincipalCV(DEPLOYER_ACCOUNT_ADDRESS(), yieldToken),
    ],
    network: network,
    senderAddress: process.env.USER_ACCOUNT_ADDRESS,
  };
  try {
    return callReadOnlyFunction(options);
  } catch (error) {
    console.log(error);
  }
};

const printResult = (result) => {
  if (result.type === ClarityType.ResponseOk) {
    if (result.value.type == ClarityType.UInt) {
      console.log(result.value);
    } else if (result.value.type == ClarityType.Tuple) {
      console.log("|");
      for (const key in result.value.data) {
        console.log("---", key, ":", result.value.data[key]);
      }
    }
  }
};

exports.ytpCreate = ytpCreate;
exports.ytpGetPrice = ytpGetPrice;
exports.ytpGetYield = ytpGetYield;
exports.ytpSwapXforY = ytpSwapXforY;
exports.ytpSwapYforX = ytpSwapYforX;
exports.ytpGetYgivenX = ytpGetYgivenX;
exports.ytpGetXgivenY = ytpGetXgivenY;
exports.ytpGetPoolDetails = ytpGetPoolDetails;
exports.ytpAddToPosition = ytpAddToPosition;
exports.ytpReducePosition = ytpReducePosition;
exports.ytpGetXgivenYield = ytpGetXgivenYield;
exports.ytpGetYgivenYield = ytpGetYgivenYield;
exports.ytpGetPositionGivenBurn = ytpGetPositionGivenBurn;
