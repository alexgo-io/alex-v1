// deno-lint-ignore-file no-explicit-any
import {
    Account,
    Chain,
    Clarinet,
    Tx,
    types,
} from 'https://deno.land/x/clarinet@v1.7.1/index.ts';
export { assertEquals } from 'https://deno.land/std@0.166.0/testing/asserts.ts';
export {
    Chain,
    Clarinet,
    Tx,
    contractNames,
    noneCV,
    principalCV,
    someCV,
    tupleCV,
    types,
    uintCV,
};
export type { Account };

const contractNames = {
    helper: 'event-claim-helper-v1-01',
    eventToken: 'age000-governance-token',
};

const uintCV = types.uint;
const principalCV = types.principal;
const noneCV = types.none;
const someCV = types.some;
const bufferCV = types.buff;
const tupleCV = types.tuple;

export const buff = (input: string | ArrayBuffer) =>
    typeof input === 'string'
        ? input.length >= 2 && input[1] === 'x'
            ? input
            : `0x${input}`
        : bufferCV(input);

export function prepare(
    chain: Chain,
    accounts: Map<string, Account>,
) {
    const deployer = accounts.get('deployer')!;

    const startTimestamp = Math.floor(Date.now() / 1000);
    const endTimestamp = startTimestamp + 24000;

    return chain.mineBlock([
        Tx.contractCall(
            contractNames.eventToken,
            'mint-fixed',
            [types.uint(10000e8), types.principal(deployer.address)],
            deployer.address,
        ),
        Tx.contractCall(
            contractNames.helper,
            'create-event',
            [
                '.' + contractNames.eventToken, 
                types.uint(5000e8),
                types.uint(startTimestamp),
                types.uint(endTimestamp)
            ],
            deployer.address,
        ),
    ]);
}

Clarinet.test({
    name: 'event-claim-helper: update-event works',
    fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const claimer = accounts.get('wallet_1')!;

        const eventToken = types.principal(
            deployer.address + '.' + contractNames.eventToken,
        );

        let results = prepare(chain, accounts);
        results.receipts.forEach((e: any) => {
            e.result.expectOk();
        });

        const eventDetails = chain.callReadOnlyFn(
            contractNames.helper,
            'get-event-details-or-fail',
            [types.uint(1)],
            deployer.address
        )!.result.expectOk().expectTuple();

        results = chain.mineBlock([
            Tx.contractCall(
                contractNames.helper,
                'update-event',
                [types.uint(0), eventToken, types.uint(0), eventDetails["start-timestamp"], eventDetails["end-timestamp"]],
                claimer.address,
            ),
            Tx.contractCall(
                contractNames.helper,
                'update-event',
                [types.uint(1), eventToken, types.uint(0), eventDetails["start-timestamp"], eventDetails["end-timestamp"]],
                claimer.address,
            ),
            Tx.contractCall(
                contractNames.helper,
                'update-event',
                [types.uint(1), eventToken, types.uint(0), eventDetails["end-timestamp"], eventDetails["start-timestamp"]],
                deployer.address,
            ),   
            Tx.contractCall(
                contractNames.helper,
                'update-event',
                [types.uint(1), eventToken, types.uint(1), eventDetails["start-timestamp"], eventDetails["end-timestamp"]],
                deployer.address,
            ),                                 
        ]);
        results.receipts[0].result.expectErr().expectUint(1002);
        results.receipts[1].result.expectErr().expectUint(1000);
        results.receipts[2].result.expectErr().expectUint(1001);
        results.receipts[3].result.expectOk();
    },
});

Clarinet.test({
    name: 'event-claim-helper: set-claim-many works',
    fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const claimer = accounts.get('wallet_1')!;
        const claimer2 = accounts.get('wallet_2')!;

        const eventToken = types.principal(
            deployer.address + '.' + contractNames.eventToken,
        );

        let results = prepare(chain, accounts);
        results.receipts.forEach((e: any) => {
            e.result.expectOk();
        });

        const eventDetails = chain.callReadOnlyFn(
            contractNames.helper,
            'get-event-details-or-fail',
            [types.uint(1)],
            deployer.address
        )!.result.expectOk().expectTuple();

        const wrongClaim = [
            { claimer: claimer.address, amount: 1e8 },
            { claimer: claimer2.address, amount: 5000e8 }
        ]

        const correctClaim = [
            { claimer: claimer.address, amount: 1e8 },
            { claimer: claimer2.address, amount: 4999e8 }
        ]        

        results = chain.mineBlock([
            Tx.contractCall(
                contractNames.helper,
                'set-claim-many',
                [
                    types.uint(1), 
                    types.list(wrongClaim.map(e => types.tuple({ claimer: types.principal(e.claimer), amount: types.uint(e.amount) })))
                ],
                deployer.address,
            ),
            Tx.contractCall(
                contractNames.helper,
                'set-claim-many',
                [
                    types.uint(1), 
                    types.list(correctClaim.map(e => types.tuple({ claimer: types.principal(e.claimer), amount: types.uint(e.amount) })))
                ],
                deployer.address,
            ),                               
        ]);
        results.receipts[0].result.expectErr().expectUint(1004);
        results.receipts[1].result.expectOk();
    },
});

Clarinet.test({
    name: 'event-claim-helper: claim-for-claimer and send-excess-token work',
    fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const claimer = accounts.get('wallet_1')!;
        const claimer2 = accounts.get('wallet_2')!;

        const eventToken = types.principal(
            deployer.address + '.' + contractNames.eventToken,
        );

        let results = prepare(chain, accounts);
        results.receipts.forEach((e: any) => {
            e.result.expectOk();
        });

        const eventDetails = chain.callReadOnlyFn(
            contractNames.helper,
            'get-event-details-or-fail',
            [types.uint(1)],
            deployer.address
        )!.result.expectOk().expectTuple();

        const claimList = [
            { claimer: claimer.address, amount: 1e8 },
            { claimer: claimer2.address, amount: 4999e8 }
        ]        

        results = chain.mineBlock([
            Tx.contractCall(
                contractNames.helper,
                'set-claim-many',
                [
                    types.uint(1), 
                    types.list(claimList.map(e => types.tuple({ claimer: types.principal(e.claimer), amount: types.uint(e.amount) })))
                ],
                deployer.address,
            ),                               
        ]);
        results.receipts[0].result.expectOk();    

        results = chain.mineBlock([
            Tx.contractCall(
                contractNames.helper,
                'claim-for-claimer',
                [
                    types.uint(1), 
                    types.principal(claimer.address),
                    eventToken
                ],
                claimer.address,
            )                                                            
        ]);
        results.receipts[0].result.expectOk();

        // const blockTimestamp = chain.callReadOnlyFn(
        //     contractNames.helper,
        //     'block-timestamp',
        //     [],
        //     deployer.address
        // )!.result.expectOk();
        // console.log(blockTimestamp);  

        chain.mineEmptyBlock(1000); // enough to go beyond endTimestamp

        results = chain.mineBlock([
            Tx.contractCall(
                contractNames.helper,
                'claim-for-claimer',
                [
                    types.uint(1), 
                    types.principal(claimer2.address),
                    eventToken
                ],
                claimer2.address,
            ),    
            Tx.contractCall(
                contractNames.helper,
                'send-excess-token',
                [
                    types.uint(1), 
                    eventToken,
                    types.principal(deployer.address),                    
                ],
                deployer.address,
            ),                                                                 
        ]);
        results.receipts[0].result.expectErr().expectUint(1001);
        results.receipts[1].result.expectOk();                
    },
});

