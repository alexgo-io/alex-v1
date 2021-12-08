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

    createPool(sender:Account, token: string, ticket: string, feeToAddress: string, amountPerTicket: number, wstxPerTicketInFixed: number, registrationStart: number, registrationEnd: number, claimEnd: number, activationThreshold: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "create-pool", [
                    types.principal(token),
                    types.principal(ticket),
                    types.principal(feeToAddress),
                    types.uint(amountPerTicket),
                    types.uint(wstxPerTicketInFixed),
                    types.uint(registrationStart),
                    types.uint(registrationEnd),
                    types.uint(claimEnd),
                    types.uint(activationThreshold),
                ],
                sender.address
            ),
        ]);
        return block;
    }
    
    addToPosition(sender:Account, token: string, tickets: number ) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "add-to-position", [
                types.principal(token),
                types.uint(tickets),
            ],
            sender.address
        ),
        ]);
        return block;
    }

    register(sender:Account, token: string, ticketTrait: string, ticketAmount: number) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "register", [
                types.principal(token),
                types.principal(ticketTrait),
                types.uint(ticketAmount),
                ],
                sender.address
            ),
        ]);
        return block.receipts[0].result;
    }

    claim(sender: Account, tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall( "alex-launchpad", "claim", [
                types.principal(tokenTrait),
                types.principal(ticketTrait),
                ],
                sender.address
            ),
        ]);
        return block;
    }

    getRegistrationStart(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-registration-start", 
            [
                types.principal(token)
            ], 
            this.deployer.address
        );
    }

    isListingCompleted(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "is-listing-completed", 
            [
                types.principal(token)
            ], 
            this.deployer.address
        );
    }

    isListingActivated(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "is-listing-activated", 
            [
                types.principal(token)
            ], 
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

    setOwner(sender: Account, owner: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-launchpad",
                "set-owner",
                [
                    types.principal(owner)
                ],
                sender.address
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

    getSubscriberAtTokenOrDefault(token: string, userId: number): ReadOnlyFn{
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-subscriber-at-token-or-default",
            [
                types.principal(token),
                types.uint(userId)
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
export { ALEXLaunchpad, ErrCode }

enum ErrCode {
    ERR_TRANSFER_FAILED = 3000,
    ERR_UNAUTHORIZED = 1000,
    ERR_USER_ALREADY_REGISTERED = 10001,
    ERR_USER_ID_NOT_FOUND = 10003,
    ERR_ACTIVATION_THRESHOLD_REACHED = 10004,
    ERR_INVALID_TOKEN = 2026,
    ERR_INVALID_TICKET = 2028,
    ERR_TICKET_TRANSFER_FAILED = 2029,
    ERR_NO_VRF_SEED_FOUND = 2030,
    ERR_CLAIM_NOT_AVAILABLE = 2031,
    ERR_TOKEN_UNDER_SUBSCIBED = 2032,
    ERR_LISTING_FINISHED = 2033,
    ERR_REGISTRATION_NOT_STARTED = 2034,
    ERR_REFUNDS_NOT_AVAILABLE = 2035,
    ERR_LISTING_NOT_ACTIVATED = 2036,
}