
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.31.1/index.ts";

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

    reducePosition(sender: Account, reduce_supply: number){
        return Tx.contractCall(
            this.contractName,
            "reduce-position",
            [
                types.uint(reduce_supply)
            ],
            sender.address
        )
    }

    setStartBlock(sender: Account, start_block: number){
        return Tx.contractCall(
            this.contractName,
            "set-start-block",
            [
                types.uint(start_block)
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
    
    setBountyInFixed(sender: Account, bounty_in_fixed: number){
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
    
    setEndCycle(sender: Account, end_cycle: number){
        return Tx.contractCall(
            this.contractName,
            "set-end-cycle",
            [
                types.uint(end_cycle)
            ],
            sender.address
        )
    }
    
    getEndCycle(sender: Account){
        return this.chain.callReadOnlyFn(
            this.contractName,
            "get-end-cycle",
            [],
            sender.address
        )
    }       
}

class YieldVaultFarm{
    chain: Chain;

    constructor(chain: Chain) {
        this.chain = chain;
    }

    addToken(sender: Account, token: string){
        return Tx.contractCall(
            "auto-farm",
            "add-token",
            [
                types.principal(token)
            ],
            sender.address
        );
    }

    // (define-public (add-to-position (dx uint))
    addToPosition(sender: Account, token: string, dx: number){
        return Tx.contractCall(
            "auto-farm",
            "add-to-position",
            [
                types.principal(token),
                types.uint(dx)
            ],
            sender.address
        );
    }

    claimAndStake(sender: Account, token: string, reward_cycle: number){
        return Tx.contractCall(
            "auto-farm",
            "claim-and-stake",
            [
                types.principal(token),
                types.uint(reward_cycle)
            ],
            sender.address
        )
    }

    reducePosition(sender: Account, token: string){
        return Tx.contractCall(
            "auto-farm",
            "reduce-position",
            [
                types.principal(token),
            ],
            sender.address
        )
    }

    setStartBlock(sender: Account, token: string, start_block: boolean){
        return Tx.contractCall(
            "auto-farm",
            "set-start-block",
            [
                types.principal(token),
                types.bool(start_block)
            ],
            sender.address
        )
    }

    getNextBase(sender: Account, token: string){
        return this.chain.callReadOnlyFn(
            "auto-farm",
            "get-next-base",
            [
                types.principal(token),
            ],
            sender.address
        )
    }
    
    setBountyInFixed(sender: Account, token: string, bounty_in_fixed: number){
        return Tx.contractCall(
            "auto-farm",
            "set-bounty-in-fixed",
            [
                types.principal(token),
                types.uint(bounty_in_fixed)
            ],
            sender.address
        )
    }
    
    getBountyInFixed(sender: Account, token: string){
        return this.chain.callReadOnlyFn(
            "auto-farm",
            "get-bounty-in-fixed",
            [
                types.principal(token),
            ],
            sender.address
        )
    }    
}

export { YieldVault, YieldVaultFarm }
