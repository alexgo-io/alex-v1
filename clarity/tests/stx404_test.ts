/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/ban-types */
/* eslint-disable @typescript-eslint/no-non-null-assertion */
import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
} from 'https://deno.land/x/clarinet@v1.2.0/index.ts';

const contractNames = {
    amm: 'amm-swap-pool-v1-1',
    stx404: 'token-stx404',
    wstx404: 'token-wstx404',
    wstx: 'token-wstx',
};

const uintCV = types.uint;
const principalCV = types.principal;
const noneCV = types.none;
const someCV = types.some;
const bufferCV = types.buff;
const tupleCV = types.tuple;
const boolCV = types.bool;

Clarinet.test({
    name: 'stx404 works',
    fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_4')!;

        const responses = chain.mineBlock([
            Tx.contractCall(
                contractNames.stx404,
                'mint',
                [principalCV(deployer.address)],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.stx404,
                'transfer',
                [
                    uintCV(0),
                    principalCV(deployer.address),
                    principalCV(user.address),                    
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.amm,
                'create-pool',
                [
                    principalCV(deployer.address + '.' + contractNames.wstx),
                    principalCV(deployer.address + '.' + contractNames.wstx404),
                    uintCV(1e8),
                    principalCV(deployer.address),
                    uintCV(1e8),
                    uintCV(1e8),
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.amm,
                'create-pool',
                [
                    principalCV(deployer.address + '.' + contractNames.wstx),
                    principalCV(deployer.address + '.' + contractNames.wstx404),
                    uintCV(1e8),
                    principalCV(user.address),
                    uintCV(1e8),
                    uintCV(1e8),
                ],
                user.address,
            ),
            Tx.contractCall(
                contractNames.stx404,
                'mint',
                [principalCV(deployer.address)],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.stx404,
                'mint',
                [principalCV(deployer.address)],
                deployer.address,
            ),            
            Tx.contractCall(
                contractNames.stx404,
                'transfer',
                [
                    uintCV(1.1e8),
                    principalCV(deployer.address),
                    principalCV(user.address),                    
                ],
                deployer.address,
            ), 
            Tx.contractCall(
                contractNames.stx404,
                'transfer',
                [
                    uintCV(0.9e8),
                    principalCV(deployer.address),
                    principalCV(user.address),                    
                ],
                deployer.address,
            ),                      
        ]);
        // console.log(responses.receipts[0].events);
        responses.receipts[0].result.expectOk();
        responses.receipts[1].result.expectOk();
        responses.receipts[2].result.expectErr().expectUint(1);
        responses.receipts[3].result.expectOk();
        responses.receipts[4].result.expectOk();
        responses.receipts[5].result.expectOk();
        responses.receipts[6].result.expectOk();
        responses.receipts[7].result.expectOk();
        console.log(responses.receipts[6].events);
        console.log(responses.receipts[7].events);
    },
});
