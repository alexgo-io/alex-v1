const sleep = (ms) => {
        return new Promise(
            resolve => setTimeout(resolve, ms)
        )
}

const wait_until_confirmation = async(txid) => {
    while (true){
        await sleep(3000)
        let truth = await fetch(`https://regtest-2.alexgo.io/extended/v1/tx/0x${txid}`)
        let res = await truth.json();
        console.log(`Waiting for confirmation... ${txid}`)
        if (res['tx_status'] === 'success'){
            console.log('Transaction completed successfully')
            return true;
        } else if (res['tx_status'] === 'abort_by_response'){
            console.log('Transaction aborted: ', res['tx_result']['repr'])
            return false;
        } else if (res.hasOwnProperty('error')){
            console.log('Transaction aborted: ', res['error']);
            return false;
        }        
    }    
}

exports.sleep = sleep;
exports.wait_until_confirmation = wait_until_confirmation;