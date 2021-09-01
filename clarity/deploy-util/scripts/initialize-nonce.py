#Since the get-latest-nonce API endpoint is not working, we will initialize the nonce 

import subprocess

#deploy the first nonce contract
subprocess.check_output("stx deploy_contract -x -t ./get-nonce.clar  get-nonce0 2000 0 $(cat ./deploy-keychain.json | jq -r .keyInfo.privateKey) > ../hex-files/get-nonce/get-nonce0.hex", shell=True)
txn = subprocess.check_output("cat ../hex-files/get-nonce/get-nonce0.hex | xxd -p -r | curl -H \"Content-Type: application/octet-stream\" -X POST --data-binary @- https://stacks-node-api.regtest.stacks.co/v2/transactions", shell=True)
print(txn)

#generate hex of the second, but with the same nonce 
subprocess.check_output("stx deploy_contract -x -t ./get-nonce.clar  get-nonce1 2000 0 $(cat ./deploy-keychain.json | jq -r .keyInfo.privateKey) > ../hex-files/get-nonce/get-nonce1.hex", shell=True)