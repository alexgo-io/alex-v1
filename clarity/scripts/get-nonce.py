#!/usr/bin/env python3
import subprocess
import os
import json

res = subprocess.check_output(f"cat ./hex-files/get-nonce/get-nonce.hex | xxd -p -r | curl -H \"Content-Type: application/octet-stream\" -X POST --data-binary @- https://stacks-node-api.regtest.stacks.co/v2/transactions", shell=True)
data = json.loads(res)
expected_nonce = data['reason_data']['expected']
print(f"Nonce is {expected_nonce}")