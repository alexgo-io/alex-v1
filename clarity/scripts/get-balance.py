import subprocess

binary_balance = subprocess.check_output("curl -s \"https://stacks-node-api.regtest.stacks.co/v2/accounts/$(cat ./deploy_keychain.json | jq -r .keyInfo.address)?proof=0\" | jq -r .balance", shell=True)
decimal_balance = int(binary_balance, 16)
print(f"Your balance is {decimal_balance}")
