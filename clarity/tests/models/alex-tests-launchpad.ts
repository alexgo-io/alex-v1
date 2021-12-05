import {
    Account,
    Chain,
    Tx,
    ReadOnlyFn,
    types,
  } from "https://deno.land/x/clarinet@v0.14.0/index.ts";

class ALEXLaunchpad {
    chain: Chain;
    deployer: Account;

    constructor(chain: Chain, deployer: Account) {
        this.chain = chain;
        this.deployer = deployer;
    }

    createPool(token: string, ticket: string, feeToAddress: string, amountPerTicket: number, wstxPerTicketInFixed: number, activationDelay: number, activationThreshold: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "create-pool", [
                    types.principal(token),
                    types.principal(ticket),
                    types.principal(feeToAddress),
                    types.uint(amountPerTicket),
                    types.uint(wstxPerTicketInFixed),
                    types.uint(activationDelay),
                    types.uint(activationThreshold),
                ],
                this.deployer.address
            ),
        ]);
        return block;
    }
    
    addToPosition(token: string, tickets: number ) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "add-to-position", [
                types.principal(token),
                types.uint(tickets),
            ],
            this.deployer.address
        ),
        ]);
        return block;
    }

    register(token: string, ticketTrait: string, ticketAmount: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "register", [
                types.principal(token),
                types.principal(ticketTrait),
                types.uint(ticketAmount),
                ],
                this.deployer.address
            ),
        ]);
        return block.receipts[0].result;
    }

    claim(tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall( "alex-launchpad", "claim", [
                types.principal(tokenTrait),
                types.principal(ticketTrait),
                ],
                this.deployer.address
            ),
        ]);
        return block;
    }

    setTicketTraitOwner (ticketTrait: string, owner: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall(ticketTrait, "set-owner", [
                types.principal(owner)
            ],
            this.deployer.address
            ),
        ]);
        return block;
    }

    getTicketTraitOwner (ticketTrait: string):ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            ticketTrait, 
            "get-owner", 
            [], 
            this.deployer.address
        );
    }

    getActivationBlock(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-activation-block", 
            [
                types.principal(token)
            ], 
            this.deployer.address
        );
    }
    
    getOwner():ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad", 
            "get-owner", 
            [], 
            this.deployer.address
        );
    }

    setOwner(owner: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-launchpad",
                "set-owner",
                [
                    types.principal(owner)
                ],
                this.deployer.address
            )
        ]);
        return block.receipts[0].result;
    }

    getTokenDetails(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-token-details",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    getActivationDelay(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-activation-delay",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    getActivationThreshold(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-activation-threshold",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }
    
    getRegisteredUsersNonce(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-registered-users-nonce",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }
}
export { ALEXLaunchpad }