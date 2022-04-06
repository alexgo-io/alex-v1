
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";

class YieldVault{
    chain: Chain;
    contractName: string;

    constructor(chain: Chain, contractName: string) {
        this.chain = chain;
        this.contractName = contractName;
    }

    // (define-public (add-to-position (dx uint))
    addToPosition(sender: Account, dx: number){
        return Tx.contractCall(
            this.contractName,
            "add-to-position",
            [
                types.uint(dx)
            ],
            sender.address
        );
    }

    claimAndStake(sender: Account, reward_cycle: number){
        return Tx.contractCall(
            this.contractName,
            "claim-and-stake",
            [
                types.uint(reward_cycle)
            ],
            sender.address
        )
    }

    reducePosition(sender: Account){
        return Tx.contractCall(
            this.contractName,
            "reduce-position",
            [],
            sender.address
        )
    }

    setActivated(sender: Account, activated: boolean){
        return Tx.contractCall(
            this.contractName,
            "set-activated",
            [
                types.bool(activated)
            ],
            sender.address
        )
    }

    getNextBase(sender: Account){
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-next-base",
            [],
            sender.address
        )
    }
    
    SetBountyInFixed(sender: Account, bounty_in_fixed: number){
        return Tx.contractCall(
            this.contractName,
            "set-bounty-in-fixed",
            [
                types.uint(bounty_in_fixed)
            ],
            sender.address
        )
    }
    
    getBountyInFixed(sender: Account){
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-bounty-in-fixed",
            [],
            sender.address
        )
    }     
}

export { YieldVault }
