require('dotenv').config();
const { makeContractDeploy, broadcastTransaction, AnchorMode } = require('@stacks/transactions');
const fs = require('fs')
const {
    getDeployerPK, getUserPK, network, genesis_transfer
  } = require('./wallet');
const readline = require('readline-promise').default;
const { exit } = require('process');


let contract_records = {"Contracts":[]}
let VERSION;
let contract_paths = [
    // "lib/math-log-exp.clar",
    // "lib/math-fixed-point.clar",
    // "traits/trait-sip-010.clar",
    // "traits/trait-semi-fungible-token.clar",    
    // "traits/trait-flash-loan-user.clar",
    // "traits/trait-oracle.clar",
    // "traits/trait-ownable.clar",
    // "traits/trait-vault.clar",
    // "traits/trait-multisig-vote.clar",
    // "equations/weighted-equation.clar",
    // "equations/yield-token-equation.clar",    
    // "token/token-alex.clar",
    // "token/token-usda.clar",
    // "token/token-wbtc.clar",
    // "token/token-t-alex.clar",
    // "alex-vault.clar",    
    // "token/token-wstx.clar",    
    // "open-oracle.clar",    
    // "pool/alex-reserve-pool.clar",
    // "pool/fixed-weight-pool.clar",
    // "pool/liquidity-bootstrapping-pool.clar",
    // "pool/yield-token-pool.clar",
    // "pool/collateral-rebalancing-pool.clar",
    // "faucet.clar",
    "pool-token/fwp-wstx-usda-50-50.clar",
    "pool-token/fwp-wstx-wbtc-50-50.clar",
    "pool-token/lbp-alex-usda-90-10.clar",
    "multisig/multisig-fwp-wstx-usda-50-50.clar",
    "multisig/multisig-fwp-wstx-wbtc-50-50.clar",
    "multisig/multisig-lbp-alex-usda-90-10.clar",

    "yield-token/yield-wbtc.clar",
    "yield-token/yield-usda.clar",    
    "key-token/key-usda-wbtc.clar",        
    "key-token/key-wbtc-usda.clar",   
    "pool-token/ytp-yield-wbtc.clar",   
    "pool-token/ytp-yield-usda.clar",       
    "multisig/multisig-crp-wbtc-usda.clar",  
    "multisig/multisig-crp-usda-wbtc.clar",      
    "multisig/multisig-ytp-yield-wbtc.clar",  
    "multisig/multisig-ytp-yield-usda.clar",    
    "flash-loan-user-margin-usda-wbtc.clar", 
    "flash-loan-user-margin-wbtc-usda.clar",

    "helpers/alex-staking-helper.clar"
]

async function get_version(){
    const rlp = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        terminal: true
      });
    let answer = await rlp.questionAsync('What is the version number? ')
    return answer
}

function sleep(ms) {
    return new Promise(
        resolve => setTimeout(resolve, ms)
    );
}
async function walkDir() {
    // console.log(paths)
    await contract_paths.reduce(async (memo, path) => {
        await memo
        let contract_file = path.split('/').at(-1)
        let contract_name = contract_file.split('.')[0]
        await deploy("../clarity/contracts/"+path, contract_name)
    }, undefined);
  };

async function deploy(filePath, contractName){
    console.log("Deploying:: ", contractName )
    let privatekey = await getDeployerPK();
    const txOptions = {
      contractName: contractName,
      codeBody: fs.readFileSync(filePath).toString(),
      senderKey: privatekey,
      network,
    };
    const transaction = await makeContractDeploy(txOptions);
    const broadcast_id = await broadcastTransaction(transaction, network);
    // console.log(broadcast_id)
    //console.log(`https://regtest-3.alexgo.io/extended/v1/tx/0x${broadcast_id.txid}`)
    while (true){
        await sleep(3000);
        let truth = await fetch(`https://regtest-3.alexgo.io/extended/v1/tx/${broadcast_id.txid}`)
        let res = await truth.json();
        console.log(`Waiting... ${broadcast_id.txid}`)
        if (res['tx_status'] === 'success'){
            console.log("Contract Deployed Successfully")
            let contract_record = {}
            contract_record['name'] = contractName
            contract_record['version'] = VERSION
            contract_record['deployer'] = process.env.DEPLOYER_ACCOUNT_ADDRESS
            contract_records['Contracts'].push(contract_record)            
            break;
        } else if (res['tx_status'] === 'abort_by_response'){
            console.log('Transaction aborted: ', res['tx_result']['repr'])
            break;
        } else if (res.hasOwnProperty('error')){
            console.log('Transaction aborted: ', res['error']);
            break;
        }        
    }
}

async function run(){
    // VERSION = await get_version()
    // await genesis_transfer();
    //walk the batches directory and deploy
    await walkDir();
    //write to file
    console.log(contract_records)
    fs.writeFile('./contract-records.json', JSON.stringify(contract_records), 'utf8', function (err){
        if (err) throw err
        console.log("File created")
        exit()
    });

}
run()
