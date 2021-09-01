import subprocess
import os

#make keychain
subprocess.check_output("stx make_keychain -t | jq . > deploy-keychain.json", shell=True)

#get stx needed for deployment
faucet = subprocess.check_output("curl -s -X POST \"https://stacks-node-api.regtest.stacks.co/extended/v1/faucets/stx?address=$(cat ./deploy-keychain.json | jq -r .keyInfo.address)\" | jq .", shell=True)

#make directories to store contracts and hex files.
os.mkdir('../staged-contracts')
os.mkdir('../contract-records')
os.mkdir('../hex-files')
os.mkdir('../hex-files/get-nonce')