#!/usr/bin/env python3
import subprocess
import os
import json

meta_data = {"Contracts": []}
address = ""
with open('deploy_keychain.json') as file:
    data = json.load(file)
    address = data['keyInfo']['address']

print('Enter the folder name')
folder = input("-")

print('Type Contract Version Number')
version = input("-")

version_folder = folder + "-" + version

res = subprocess.check_output(f"cat ./hex-files/get-nonce/get-nonce.hex | xxd -p -r | curl -H \"Content-Type: application/octet-stream\" -X POST --data-binary @- https://stacks-node-api.regtest.stacks.co/v2/transactions", shell=True)
data = json.loads(res)
expected_nonce = data['reason_data']['expected']
print(f"Nonce is {expected_nonce}")
os.mkdir(f'./hex-files/{version_folder}')

nonce = expected_nonce
contracts = r'./staged-contracts'
for file in os.listdir(contracts):
    clarity_name = file.split('.')[0]
    print(clarity_name)
    res1 = subprocess.check_output(f"stx deploy_contract -x -t ./{contracts}/{file} {clarity_name} 70000 {nonce} $(cat ./deploy_keychain.json | jq -r .keyInfo.privateKey) > ./hex-files/{version_folder}/{clarity_name}.hex", shell=True)
    txid = subprocess.check_output(f"cat ./hex-files/{version_folder}/{clarity_name}.hex | xxd -p -r | curl -H \"Content-Type: application/octet-stream\" -X POST --data-binary @- https://stacks-node-api.regtest.stacks.co/v2/transactions", shell=True)
    meta_data['Contracts'].append({"name": clarity_name, "version": version, "deployer": address, "txid": "0x"+txid.decode('utf-8').strip('"')})
    nonce += 1

print(meta_data)

with open(f'./contract-records/{version_folder}.json', 'w') as f:
    json.dump(meta_data, f)