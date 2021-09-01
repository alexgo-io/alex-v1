# Dependencies:
- stacks CLI: https://docs.stacks.co/understand-stacks/command-line-interface#installation
- python3.8+
# Usage
These scripts help you easily interact with and deploy smart contracts to the Stacks Regtest Network. After installing dependencies, navigate to clarity/deploy-util/scripts and run the following commands.

1.  `python3 initialize-account.py` and wait until STX arrive.
    -   This command create a testnet account for you and request stx from the faucet and create the necessary folders.
    -   You can run `python3 get-balance.py` to check your balance. Also, you can check the Stacks Explorer on Regtest.

2.  `python3 initialize-nonce.py`
    -   This deploys a contract to the chain in order to programatically increase the nonce on subsequent deploys.
    -   This is a necessary hack at the moment because the get-latest-nonce endpoint of the Stacks v2 API is currently not working for Regtest. 


#### Next, start deploying!

1. Stage your contracts by moving them in the staged-contracts directory.
2. Run `python3 deploy.py`
   -    This will automatically generate the hex files in the hex-files directory and deploy the contracts to the chain. Also, it will create logs in the contract-records directory.
3. You can then check the status of your deployments with `python3 check.py <transaction-id>`

#Caveats
-   The scripts are set up to deploy your contract with the name of your clarity file. Therefore, if your clarity file is called `hello.clar` the contract will be represented as `<the-stacks-address>.hello`. Note that this means that you cannot re-deploy contracts with the same file name.
-   The scripts do not account for dependencies on contracts. Therefore, you need to make sure that the order of deployment is proper or else your deployments will fail. 



