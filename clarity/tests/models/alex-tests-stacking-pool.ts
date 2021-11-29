
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";

class StackingPool{
    chain: Chain;
    deployer: Account;

    constructor(chain: Chain, deployer: Account) {
        this.chain = chain;
        this.deployer = deployer;
    }

    createPool(poxlTokenTrait: string, rewardTokenTrait: string, rewardCycles: number[], yieldToken: string){
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "stacking-pool",
                "create-pool",
                [
                    types.principal(poxlTokenTrait),
                    types.principal(rewardTokenTrait),
                    types.list(rewardCycles),
                    types.principal(yieldToken),
                ],
                this.deployer.address
            ),
        ]);
        return block.receipts[0].result;
    }

    setActivationThreshold(activationThreshold: number){
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-reserve-pool",
                "set-activation-threshold",
                [types.uint(activationThreshold)],
                this.deployer.address
            )
        ])
        return block.receipts[0].result;
    }

    addToken(token: string, activationBlockBeforeDelay: number){
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-reserve-pool",
                "add-token",
                [types.principal(token), types.uint(activationBlockBeforeDelay)],
                this.deployer.address
            )
        ])
        return block.receipts[0].result;
    }

    registerUser(token: string, memo: string){
        let block = this.chain.mineBlock([
            Tx.contractCall(
                "alex-reserve-pool",
                "register-user",
                [types.principal(token), types.some(types.utf8(memo))],
                this.deployer.address
            )
        ])
        return block.receipts[0].result;
    }
}

export { StackingPool }
