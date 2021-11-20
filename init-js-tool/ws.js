const { connectWebSocketClient } = require('@stacks/blockchain-api-client');

async function testWSS(){
    try {
      const client = await connectWebSocketClient('wss://regtest-3.alexgo.io/')
      const sub = await client.subscribeAddressTransactions('STZP1114C4EA044RE54M6G5ZC2NYK9SAHB5QVE1',(event)=>{
        console.log(event);
      })
    } catch (error) {
      console.log(error.message);
    }
  }
testWSS();