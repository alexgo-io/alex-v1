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
    endpoint: 'stx20-bridge-endpoint-v1-02',
    registry: 'stx20-bridge-registry-v1-01',
    stxs: 'stx20-stxs',
    wstx: 'token-wstx',
};

const uintCV = types.uint;
const principalCV = types.principal;
const noneCV = types.none;
const someCV = types.some;
const bufferCV = types.buff;
const tupleCV = types.tuple;
const boolCV = types.bool;
const stringAsciiCV = types.ascii;

Clarinet.test({
    name: 'stx20-bridge works',
    fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const operator = accounts.get('wallet_1')!;
        const user = accounts.get('wallet_4')!;

        let responses = chain.mineBlock([
            Tx.contractCall(
                contractNames.stxs,
                'set-approved-contract',
                [
                    principalCV(deployer.address + '.' + contractNames.endpoint),
                    boolCV(true),
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.registry,
                'set-approved-contract',
                [
                    principalCV(deployer.address + '.' + contractNames.endpoint),
                    boolCV(true),                   
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.registry,
                'set-ticker-to-token',
                [
                    stringAsciiCV('STXS'),
                    principalCV(deployer.address + '.' + contractNames.stxs)
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.registry,
                'set-approved-operator',
                [
                    principalCV(operator.address),
                    boolCV(true),
                ],
                deployer.address,
            )                    
        ]);
        responses.receipts.map((e: any) => e.result.expectOk());

        responses = chain.mineBlock([
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-in',
                [
                    tupleCV({
                        txid: bufferCV('0x00'),
                        from: principalCV(user.address),
                        to: principalCV(deployer.address + '.' + contractNames.registry),
                        ticker: stringAsciiCV('STXS'),
                        amount: uintCV(1),
                    }),
                    principalCV(deployer.address + '.' + contractNames.stxs),
                ],
                user.address,
            ),
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-in',
                [
                    tupleCV({
                        txid: bufferCV('0x00'),
                        from: principalCV(user.address),
                        to: principalCV(operator.address),
                        ticker: stringAsciiCV('STXS'),
                        amount: uintCV(1),
                    }),
                    principalCV(deployer.address + '.' + contractNames.stxs),
                ],
                operator.address,
            ),  
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-in',
                [
                    tupleCV({
                        txid: bufferCV('0x00'),
                        from: principalCV(user.address),
                        to: principalCV(deployer.address + '.' + contractNames.registry),
                        ticker: stringAsciiCV('STXS'),
                        amount: uintCV(1),
                    }),
                    principalCV(deployer.address + '.' + contractNames.wstx),
                ],
                operator.address,
            ),  
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-in',
                [
                    tupleCV({
                        txid: bufferCV('0x00'),
                        from: principalCV(user.address),
                        to: principalCV(deployer.address + '.' + contractNames.registry),
                        ticker: stringAsciiCV('STXS'),
                        amount: uintCV(1),
                    }),
                    principalCV(deployer.address + '.' + contractNames.stxs),
                ],
                operator.address,
            ),  
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-in',
                [
                    tupleCV({
                        txid: bufferCV('0x00'),
                        from: principalCV(user.address),
                        to: principalCV(deployer.address + '.' + contractNames.registry),
                        ticker: stringAsciiCV('STXS'),
                        amount: uintCV(1),
                    }),
                    principalCV(deployer.address + '.' + contractNames.stxs),
                ],
                operator.address,
            ), 
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-out',
                [
                    principalCV(deployer.address + '.' + contractNames.stxs),
                    uintCV(2e8)
                ],
                user.address
            ),
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-out',
                [
                    principalCV(deployer.address + '.' + contractNames.wstx),
                    uintCV(1e8)
                ],
                user.address
            ), 
            Tx.contractCall(
                contractNames.endpoint,
                'finalize-peg-out',
                [
                    principalCV(deployer.address + '.' + contractNames.stxs),
                    uintCV(1e8)
                ],
                user.address
            ),
        ]);
        responses.receipts[0].result.expectErr(1000);
        responses.receipts[1].result.expectErr(1002);
        responses.receipts[2].result.expectErr(1001); 
        responses.receipts[3].result.expectOk();
        responses.receipts[4].result.expectErr(1003);              
        responses.receipts[5].result.expectErr(1);
        responses.receipts[6].result.expectErr(1001);
        responses.receipts[7].result.expectOk();
        console.log(responses.receipts[3].events);
        console.log(responses.receipts[7].events);
    },
});
