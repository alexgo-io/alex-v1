const {
    getDeployerPK, getUserPK, network
  } = require('./wallet');
  const {
    makeContractCall,
    callReadOnlyFunction,
    AnchorMode,
    PostConditionMode,
    uintCV,
    someCV,
    stringUtf8CV,
    contractPrincipalCV,
    broadcastTransaction,
    ClarityType
  } = require('@stacks/transactions');
  const {wait_until_confirmation} = require('./utils');
const { principalCV } = require('@stacks/transactions/dist/clarity/types/principalCV');

//   (propose (uint (string-utf8 256) (string-utf8 256) uint uint) (response uint uint))
  const multisigPropose = async (contract_name, start_block_height, title, url, new_fee_rate_x, new_fee_rate_y) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] propose...', contract_name, start_block_height, title, url, new_fee_rate_x, new_fee_rate_y);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: contract_name,
        functionName: 'propose',
        functionArgs: [
            uintCV(start_block_height),
            stringUtf8CV(title),
            stringUtf8CV(url),
            uintCV(new_fee_rate_x),
            uintCV(new_fee_rate_y)
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
  }  

//   (vote-for (<ft-trait> uint uint) (response uint uint))  
  const multisigVoteFor = async (contract_name, token, proposal_id, amount) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] vote-for...', contract_name, token, proposal_id, amount);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: contract_name,
        functionName: 'vote-for',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            uintCV(proposal_id),
            uintCV(amount)
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
  }  

//   (vote-against (<ft-trait> uint uint) (response uint uint))  
const multisigVoteAgainst = async (contract_name, token, proposal_id, amount) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] vote-against...', contract_name, token, proposal_id, amount);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: contract_name,
        functionName: 'vote-against',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            uintCV(proposal_id),
            uintCV(amount)
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
  }    

//   (end-proposal (uint) (response bool uint))
const multisigEndProposal = async (contract_name, proposal_id) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] end-proposal...', contract_name, proposal_id);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: contract_name,
        functionName: 'end-proposal',
        functionArgs: [
            uintCV(proposal_id)
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
  }

//   (return-votes-to-member (<ft-trait> uint principal) (response bool uint))
const multisigReturnVotes = async (contract_name, token, proposal_id) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] return-votes-to-member...', contract_name, token, proposal_id);
    const privateKey = await getDeployerPK();
    const txOptions = {
        contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
        contractName: contract_name,
        functionName: 'return-votes-to-member',
        functionArgs: [
            contractPrincipalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS, token),
            uintCV(proposal_id),
            principalCV(process.env.DEPLOYER_ACCOUNT_ADDRESS)
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
  }    
  
  const multisigGetProposalById = async (contract_name, proposal_id) => {
    console.log('--------------------------------------------------------------------------');
    console.log('[multisig] get-proposal-by-id...]', contract_name, proposal_id);
  
    const options = {
      contractAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
      contractName: contract_name,
      functionName: 'get-proposal-by-id',
      functionArgs: [
        uintCV(proposal_id)
      ],
      network: network,
      senderAddress: process.env.DEPLOYER_ACCOUNT_ADDRESS,
    };
    try {
      return callReadOnlyFunction(options);
    } catch (error) {
      console.log(error);
    }
  };  
  
  exports.multisigPropose = multisigPropose;
  exports.multisigVoteFor = multisigVoteFor;
  exports.multisigVoteAgainst = multisigVoteAgainst;
  exports.multisigEndProposal = multisigEndProposal;
  exports.multisigReturnVotes = multisigReturnVotes;
  exports.multisigGetProposalById = multisigGetProposalById;