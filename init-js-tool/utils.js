
const sleep = (ms) => {
        return new Promise(
            resolve => setTimeout(resolve, ms)
        )
}

const wait_until_confirmation = async(txid) => {
    while (true){
        let truth = await fetch(`https://regtest-2.alexgo.io/extended/v1/tx/0x${txid}`)
        let res = await truth.json();
        console.log(`Waiting for confirmation... ${txid}`)
        if (res['tx_status'] === 'success'){
            break;
        }
        await sleep(3000)
    }
    console.log('Transaction Confirmed')
}

exports.sleep = sleep;
exports.wait_until_confirmation = wait_until_confirmation;