
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";

class YieldVault{
    chain: Chain;

    constructor(chain: Chain) {
        this.chain = chain;
    }

    // (define-public (add-to-position (dx uint))
    addToPosition(sender: Account, dx: number){
        return Tx.contractCall(
            "alex-yield-vault",
            "add-to-position",
            [
                types.uint(dx)
            ],
            sender.address
        );
    }

    claimAndStake(sender: Account, reward_cycle: number){
        return Tx.contractCall(
            "alex-yield-vault",
            "claim-and-stake",
            [
                types.uint(reward_cycle)
            ],
            sender.address
        )
    }

    reducePosition(sender: Account){
        return Tx.contractCall(
            "alex-yield-vault",
            "reduce-position",
            [],
            sender.address
        )
    }

    setActivated(sender: Account, activated: boolean){
        return Tx.contractCall(
            "alex-yield-vault",
            "set-activated",
            [
                types.bool(activated)
            ],
            sender.address
        )
    }

    getNextBase(sender: Account){
        return this.chain.callReadOnlyFn(
            "alex-yield-vault",
            "get-next-base",
            [],
            sender.address
        )
    }   
}

export { YieldVault }
