import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.34.0/index.ts";

const cycle1 = 103825;
const cycle2 = 104305;

Clarinet.test({
    name: "auto-alex-buyback-helper : works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const wallet_1 = accounts.get("wallet_1")!;
        const dx = 50000e8;

        let block = chain.mineBlock([
            Tx.contractCall(
                "age000-governance-token",
                "mint-fixed",
                [
                    types.uint(dx),
                    types.principal(deployer.address + '.auto-alex-buyback-helper')                    
                ],
                deployer.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-rate-103825",
                [types.uint(2e8)],
                deployer.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-rate-104305",
                [types.uint(1e8)],
                deployer.address
            )
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });  
        
        block = chain.mineBlock([
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-contract-owner",
                [types.principal(wallet_1.address)],
                wallet_1.address
            ),            
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-rate-103825",
                [types.uint(2e8)],
                wallet_1.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-rate-104305",
                [types.uint(1e8)],
                wallet_1.address
            ),        
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-buyback",
                [types.list(
                    [
                        types.tuple(
                            {
                                cycle: types.uint(cycle1),
                                user: types.principal(wallet_1.address),
                                amount: types.uint(100e8)
                            }
                        )
                    ]
                )],
                wallet_1.address
            ),                 
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "transfer-alex",
                [types.uint(1e8)],
                wallet_1.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "transfer-autoalex",
                [types.uint(1e8)],
                wallet_1.address
            ),              
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1000) });       

        block = chain.mineBlock([      
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-buyback",
                [types.list(
                    [
                        types.tuple(
                            {
                                cycle: types.uint(cycle1 - 1),
                                user: types.principal(wallet_1.address),
                                amount: types.uint(100e8)
                            }
                        )
                    ]
                )],
                deployer.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1001) });  
        
        block = chain.mineBlock([     
            Tx.contractCall(
                "auto-alex",
                "mint-fixed",
                [
                    types.uint(200e8),
                    types.principal(wallet_1.address)
                ],
                deployer.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "set-buyback",
                [types.list(
                    [
                        types.tuple(
                            {
                                cycle: types.uint(cycle1),
                                user: types.principal(wallet_1.address),
                                amount: types.uint(70e8)
                            }
                        ),
                        types.tuple(
                            {
                                cycle: types.uint(cycle2),
                                user: types.principal(wallet_1.address),
                                amount: types.uint(30e8)
                            }
                        )                        
                    ]
                )],
                deployer.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });    
        block.receipts[0].events.expectFungibleTokenMintEvent(
            200e8,
            wallet_1.address,
            "auto-alex"
        );           
        
        block = chain.mineBlock([     
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "claim",
                [types.uint(201e8)],
                wallet_1.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1002) });

        block = chain.mineBlock([     
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "claim",
                [types.uint(10e8)],
                wallet_1.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            10e8,
            wallet_1.address,
            deployer.address + '.auto-alex-buyback-helper',
            "auto-alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            20e8,
            deployer.address + '.auto-alex-buyback-helper',
            wallet_1.address,
            "alex"
        );
        
        block = chain.mineBlock([     
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "claim",
                [types.uint(101e8)],
                wallet_1.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectErr().expectUint(1003) });   

        block = chain.mineBlock([     
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "claim",
                [types.uint(90e8)],
                wallet_1.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "transfer-alex",
                [types.uint(dx - 170e8)],
                deployer.address
            ),
            Tx.contractCall(
                "auto-alex-buyback-helper",
                "transfer-autoalex",
                [types.uint(100e8)],
                deployer.address
            )           
        ]);
        block.receipts.forEach(e => { e.result.expectOk() });   
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            90e8,
            wallet_1.address,
            deployer.address + '.auto-alex-buyback-helper',
            "auto-alex"
        );
        block.receipts[0].events.expectFungibleTokenTransferEvent(
            120e8 + 30e8,
            deployer.address + '.auto-alex-buyback-helper',
            wallet_1.address,
            "alex"
        );
        block.receipts[1].events.expectFungibleTokenTransferEvent(
            dx - 170e8,
            deployer.address + '.auto-alex-buyback-helper',
            deployer.address,
            "alex"
        );   
        block.receipts[2].events.expectFungibleTokenTransferEvent(
            100e8,
            deployer.address + '.auto-alex-buyback-helper',
            deployer.address,
            "auto-alex"
        );             

    }
})
