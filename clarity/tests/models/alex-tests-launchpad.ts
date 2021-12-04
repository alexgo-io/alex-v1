import { Account, ReadOnlyFn, Tx, types, Chain } from "./deps.ts";
  
class ALEXLaunchpad {
    chain: Chain;
    deployer: Account;
    contractName: string;

    constructor(chain: Chain, deployer: Account, contractName: string) {
        this.chain = chain;
        this.deployer = deployer;
        this.contractName = contractName;
    }

    getOwner(): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            this.contractName, 
            "get-owner", 
            [], 
            this.deployer.address
        );
    }

    setOwner(owner: string): Tx {
        return Tx.contractCall(
            this.contractName,
            "set-owner",
            [
                types.principal(owner)
            ],
            this.deployer.address
        )
    }

    createPool(token: string, ticket: string, feeToAddress: string, amountPerTicket: number, wstxPerTicketInFixed: number, activationDelay: number, activationThreshold: number) : Tx {
        return Tx.contractCall(
            this.contractName,
            "create-pool",
            [
                types.principal(token),
                types.principal(ticket),
                types.principal(feeToAddress),
                types.uint(amountPerTicket),
                types.uint(wstxPerTicketInFixed),
                types.uint(activationDelay),
                types.uint(activationThreshold),
            ],
            this.deployer.address
        )
    }

    addToPosition(token: string, tickets: number): Tx {
        return Tx.contractCall(
            this.contractName,
            "add-to-position",
            [
                types.principal(token),
                types.uint(tickets),
            ],
            this.deployer.address
        )
    }

    //(define-read-only (get-activation-block (token principal))
    getActivationBlock(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            this.contractName, 
            "get-activation-block", 
            [
                types.principal(token)
            ], 
            this.deployer.address
        );
    }
    
    getActicationDeplay(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-activation-delay",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    getActivationThreshold(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-activation-threshold",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }
    
    getTokenDetails(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-token-details",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }
    
    getUserId(token: string, user: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-user-id",
            [
                types.principal(token),
                types.principal(user),
            ],
            this.deployer.address
        )
    }

    getUser(token: string, userId: number): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-user",
            [
                types.principal(token),
                types.uint(userId),
            ],
            this.deployer.address
        )
    }

    getRegisteredUsersNonce(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-registered-users-nonce",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    register(token: string, ticketTrait: number, ticketAmount: number): Tx {
        return Tx.contractCall(
            this.contractName,
            "add-to-position",
            [
                types.principal(token),
                types.uint(ticketTrait),
                types.uint(ticketAmount),
            ],
            this.deployer.address
        )
    }

    getSubscriberAtTokenOrDefault(token: string): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-subscriber-at-token-or-default",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    claim(tokenTrait: string, ticketTrait: string): Tx {
        return Tx.contractCall(
            this.contractName,
            "claim",
            [
                types.principal(tokenTrait),
                types.principal(ticketTrait),
            ],
            this.deployer.address
        )
    }

}
export { ALEXLaunchpad }