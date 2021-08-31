# Usage
These scripts help you easily interact with and deploy smart contracts to the Stacks Regtest Network. After installing dependencies, make a deploy-keychain.json file at the root of this directory of the following structure:\
{\
&emsp; "mnemonic": "your mnemonic",\
&emsp; "keyInfo": {\
&emsp;&emsp; "privateKey": "your private key",\
&emsp;&emsp; "address": "your address (likely testnet address)"\
&emsp; }\
}

You can use stacks-gen to generate your private key from your mnemonic:\
https://github.com/psq/stacks-gen

# Commands
- run   `python3 get-nonce.py` to get the current nonce.
- run    `python3 get-balance.py` to get your balance.
- `python3 deploy.py` will loop through the Clarity contracts in the contracts directory, generate hex files for each of them and add them to the hex-files directory and then attempt to deploy them. You may need to adjust the fee in the script on line 41 depending on how large any individual contract is. Default is 50,000 uSTX. Records of each contract's deployment will be written to the contract-records directory as a json file. The batches gives your guidance on the order to deploy the contracts.


# Dependencies:
- stacks CLI: https://docs.stacks.co/understand-stacks/command-line-interface#installation
- python3.8+
