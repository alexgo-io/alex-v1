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

    createPool(sender: Account, token: string, ticket: string, feeToAddress: string, amountPerTicket: number, wstxPerTicketInFixed: number, registrationStart: number, registrationEnd: number, claimEnd: number, activationThreshold: number) {
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

    addToPosition(sender: Account, token: string, tickets: number) {
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

    register(sender: Account, token: string, ticketTrait: string, ticketAmount: number) {
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

    refund(sender: Account, tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "refund", [
                types.principal(tokenTrait),
                types.principal(ticketTrait)
            ],
                sender.address
            ),
        ]);
        return block;
    }

    claim(sender: Account, tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "claim", [
                types.principal(tokenTrait),
                types.principal(ticketTrait),
            ],
                sender.address
            ),
        ]);
        return block;
    }

    claimNine(sender: Account, tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "claim-nine", [
                types.principal(tokenTrait),
                types.principal(ticketTrait),
            ],
                sender.address
            ),
        ]);
        return block;
    }    

    claimTen(sender: Account, tokenTrait: string, ticketTrait: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall("alex-launchpad", "claim-ten", [
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

    getOwner(): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-contract-owner",
            [],
            this.deployer.address
        );
    }

    setOwner(sender: Account, owner: string) {
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-launchpad",
                "set-contract-owner",
                [
                    types.principal(owner)
                ],
                sender.address
            )
        ]);
        return block.receipts[0].result;
    }

    getListingDetails(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-listing-details",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    getSubscriberAtTokenOrDefault(token: string, userId: number): ReadOnlyFn {
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

    getActivationThreshold(token: string): ReadOnlyFn {
        return this.chain.callReadOnlyFn(
            "alex-launchpad",
            "get-activation-threshold",
            [
                types.principal(token)
            ],
            this.deployer.address
        )
    }

    getRegisteredUsersNonce(token: string): ReadOnlyFn {
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
    ERR_NO_VRF_SEED_FOUND = 2030,
    ERR_CLAIM_NOT_AVAILABLE = 2031,
    ERR_LISTING_FINISHED = 2032,
    ERR_REGISTRATION_STARTED = 2033,
    ERR_REGISTRATION_NOT_STARTED = 2034,
    ERR_REGISTRATION_ENDED = 2038,
    ERR_LISTING_ACTIVATED = 2035,
    ERR_LISTING_NOT_ACTIVATED = 2036,
    ERR_REGISTRATION_NOT_ENDED = 2039,
    ERR_INVALID_REGISTRATION_PERIOD = 2037,
    ERR_CLAIM_ENDED = 2040,
    ERR_CLAIM_NOT_ENDED = 2041,
    ERR_INVALID_CLAIM_PERIOD = 2042,
}