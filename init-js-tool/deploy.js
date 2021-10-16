require('dotenv').config();
const { makeContractDeploy, broadcastTransaction, AnchorMode } = require('@stacks/transactions');
const fs = require('fs')
const {
    getDeployerPK, getUserPK, network
  } = require('./wallet');
const readline = require('readline-promise').default;
const { exit } = require('process');


let contract_records = {"Contracts":[]}
let VERSION;
let contract_paths = [
    // "lib/math-log-exp.clar",
    // "lib/math-fixed-point.clar",
    // "traits/trait-sip-010.clar",    
    // "traits/trait-flash-loan-user.clar",
    // "traits/trait-oracle.clar",
    // "traits/trait-pool-token.clar",
    // "traits/trait-yield-token.clar",
    // "traits/trait-ownable.clar",
    // "traits/trait-vault.clar",
    // "traits/trait-multisig-vote.clar",
    // "equations/weighted-equation.clar",
    // "equations/yield-token-equation.clar",    
    // "token/token-alex.clar",
    // "token/token-usda.clar",
    // "token/token-wbtc.clar",
    // "alex-vault.clar",    
    // "open-oracle.clar",    
    // "pool/alex-reserve-pool.clar",
    // "pool/fixed-weight-pool.clar",
    // "pool/liquidity-bootstrapping-pool.clar",
    // "pool/yield-token-pool.clar",
    // "pool/collateral-rebalancing-pool.clar",
    // "faucet.clar",
    // "pool-token/fwp-wbtc-usda-50-50.clar",    
    // "multisig/multisig-fwp-wbtc-usda-50-50.clar",  
    

    // "yield-token/yield-wbtc-40555.clar",
    // "yield-token/yield-usda-40555.clar",    
    // "key-token/key-usda-40555-wbtc.clar",        
    // "key-token/key-wbtc-40555-usda.clar",   
    // "pool-token/ytp-yield-wbtc-40555-wbtc.clar",   
    // "pool-token/ytp-yield-usda-40555-usda.clar",       
    // "multisig/multisig-crp-wbtc-40555-usda.clar",  
    // "multisig/multisig-crp-usda-40555-wbtc.clar",      
    // "multisig/multisig-ytp-yield-wbtc-40555-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-40555-usda.clar",    
    // "flash-loan-user-margin-usda-wbtc-40555.clar", 
    // "flash-loan-user-margin-wbtc-usda-40555.clar",      
    
    // "yield-token/yield-wbtc-5760.clar",
    // "yield-token/yield-usda-5760.clar",    
    // "key-token/key-usda-5760-wbtc.clar",        
    // "key-token/key-wbtc-5760-usda.clar",   
    // "pool-token/ytp-yield-wbtc-5760-wbtc.clar",   
    // "pool-token/ytp-yield-usda-5760-usda.clar",       
    // "multisig/multisig-crp-wbtc-5760-usda.clar",  
    // "multisig/multisig-crp-usda-5760-wbtc.clar",      
    // "multisig/multisig-ytp-yield-wbtc-5760-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-5760-usda.clar",    
    // "flash-loan-user-margin-usda-wbtc-5760.clar", 
    // "flash-loan-user-margin-wbtc-usda-5760.clar",    

    // "yield-token/yield-wbtc-80875.clar",
    // "yield-token/yield-usda-80875.clar",    
    // "key-token/key-usda-80875-wbtc.clar",        
    // "key-token/key-wbtc-80875-usda.clar",   
    // "pool-token/ytp-yield-wbtc-80875-wbtc.clar",   
    // "pool-token/ytp-yield-usda-80875-usda.clar",       
    // "multisig/multisig-crp-wbtc-80875-usda.clar",  
    // "multisig/multisig-crp-usda-80875-wbtc.clar",      
    // "multisig/multisig-ytp-yield-wbtc-80875-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-80875-usda.clar",    
    "flash-loan-user-margin-usda-wbtc-80875.clar", 
    "flash-loan-user-margin-wbtc-usda-80875.clar",      
    
    // "pool-token/ytp-yield-wbtc-23040-wbtc.clar",    
    // "yield-token/yield-wbtc-23040.clar",
    // "key-token/key-wbtc-23040-usda.clar",    
    // "multisig/multisig-crp-wbtc-23040-usda.clar",  
    // "multisig/multisig-ytp-yield-wbtc-23040-wbtc.clar",  
    // "flash-loan-user-margin-usda-wbtc-23040.clar",       
    // "pool-token/ytp-yield-usda-23040-usda.clar",    
    // "yield-token/yield-usda-23040.clar",
    // "key-token/key-usda-23040-wbtc.clar",    
    // "multisig/multisig-crp-usda-23040-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-23040-usda.clar",      
    // "flash-loan-user-margin-wbtc-usda-23040.clar",       
    
    // "pool-token/ytp-yield-wbtc-34560-wbtc.clar",    
    // "yield-token/yield-wbtc-34560.clar",
    // "key-token/key-wbtc-34560-usda.clar",    
    // "multisig/multisig-crp-wbtc-34560-usda.clar",  
    // "multisig/multisig-ytp-yield-wbtc-34560-wbtc.clar",  
    // "flash-loan-user-margin-usda-wbtc-34560.clar",     
    // "pool-token/ytp-yield-usda-34560-usda.clar",    
    // "yield-token/yield-usda-34560.clar",
    // "key-token/key-usda-34560-wbtc.clar",    
    // "multisig/multisig-crp-usda-34560-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-34560-usda.clar",    
    // "flash-loan-user-margin-wbtc-usda-34560.clar",  
    
    // "pool-token/ytp-yield-wbtc-121195-wbtc.clar",    
    // "yield-token/yield-wbtc-121195.clar",
    // "key-token/key-wbtc-121195-usda.clar",    
    // "multisig/multisig-crp-wbtc-121195-usda.clar",  
    // "multisig/multisig-ytp-yield-wbtc-121195-wbtc.clar",  
    "flash-loan-user-margin-usda-wbtc-121195.clar",     
    // "pool-token/ytp-yield-usda-121195-usda.clar",
    // "key-token/key-usda-121195-wbtc.clar",    
    // "yield-token/yield-usda-121195.clar",    
    // "multisig/multisig-crp-usda-121195-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-121195-usda.clar",    
    "flash-loan-user-margin-wbtc-usda-121195.clar",       
    
    // "pool-token/ytp-yield-wbtc-161515-wbtc.clar",    
    // "yield-token/yield-wbtc-161515.clar",
    // "key-token/key-wbtc-161515-usda.clar",    
    // "multisig/multisig-crp-wbtc-161515-usda.clar",  
    // "multisig/multisig-ytp-yield-wbtc-161515-wbtc.clar",  
    "flash-loan-user-margin-usda-wbtc-161515.clar",     
    // "pool-token/ytp-yield-usda-161515-usda.clar",
    // "key-token/key-usda-161515-wbtc.clar",    
    // "yield-token/yield-usda-161515.clar",    
    // "multisig/multisig-crp-usda-161515-wbtc.clar",  
    // "multisig/multisig-ytp-yield-usda-161515-usda.clar",    
    "flash-loan-user-margin-wbtc-usda-161515.clar",              
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
    //console.log(`https://regtest-2.alexgo.io/extended/v1/tx/0x${broadcast_id.txid}`)
    while (true){
        await sleep(3000);
        let truth = await fetch(`https://regtest-2.alexgo.io/extended/v1/tx/${broadcast_id.txid}`)
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
    VERSION = await get_version()
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