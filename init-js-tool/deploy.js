require('dotenv').config();
const { makeContractDeploy, broadcastTransaction, AnchorMode } = require('@stacks/transactions');
const walkSync = require('walk-sync');
const BigNum = require('bn.js');
const fs = require('fs')
const path = require('path')

const {
    getPK, network
  } = require('./wallet');

function sleep(ms) {
return new Promise(
    resolve => setTimeout(resolve, ms)
);
}
async function walkDir() {
    const paths = walkSync('./batches', {includeBasePath: true, directories: false})
    // console.log(paths)
    await paths.reduce(async (memo, path) => {
        await memo
        let contract_file = path.split('/')[3]
        let contract_name = contract_file.split('.')[0]
        await deploy(path, contract_name)
    }, undefined);
  };

async function deploy(filePath, contractName){
    console.log("Deploying:: ", contractName )
    let privatekey = await getPK();
    const txOptions = {
      contractName: contractName,
      codeBody: fs.readFileSync(filePath).toString(),
      senderKey: privatekey,
      network,
    };
    const transaction = await makeContractDeploy(txOptions);
    const broadcast_id = await broadcastTransaction(transaction, network);
    // console.log(broadcast_id)
    console.log(`https://regtest-2.alexgo.io/extended/v1/tx/0x${broadcast_id.txid}`)
    while (true){
        let truth = await fetch(`https://regtest-2.alexgo.io/extended/v1/tx/0x${broadcast_id.txid}`)
        let res = await truth.json();
        console.log("Waiting...")
        if (res['tx_status'] === 'success'){
            break;
        }
        await sleep(3000)
    }
    console.log("Contract Deployed Successfully")
}

function run(){
    walkDir();
}
run()