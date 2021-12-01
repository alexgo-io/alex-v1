
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.14.0/index.ts";

class FuturesPool{
    chain: Chain;
    deployer: Account;

    constructor(chain: Chain, deployer: Account) {
        this.chain = chain;
        this.deployer = deployer;
    }

    //(contract-call? .futures-pool create-pool 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex (list u1) 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex)
    createPool(sender: Account, poxlTokenTrait: string, rewardTokenTrait: string, rewardCycles: Array<string>, yieldToken: string){
        return Tx.contractCall(
            "futures-pool",
            "create-pool",
            [
                types.principal(poxlTokenTrait),
                types.principal(rewardTokenTrait),
                types.list(rewardCycles),
                types.principal(yieldToken),
            ],
            this.deployer.address
        );
    }

    setActivationThreshold(threshold: number): Tx {
        return Tx.contractCall(
            "alex-reserve-pool",
            "set-activation-threshold",
            [
                types.uint(threshold)
            ],
            this.deployer.address
        );
    }

    addToken(token: string): Tx {
        return Tx.contractCall(
            "alex-reserve-pool",
            "add-token",
            [
                types.principal(token)
            ],
            this.deployer.address
        );
    }

    registerUser(token: string, memo: string | undefined = undefined): Tx {
        return Tx.contractCall(
            "alex-reserve-pool",
            "register-user",
            [
                types.principal(token),
                typeof memo == "undefined"
                    ? types.none()
                    : types.some(types.utf8(memo)),
            ],
            this.deployer.address
        );
    }

    //(contract-call? .futures-pool add-to-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex u1000000000)
    addToPosition(sender: Account, token: string, reward: string, startCycle: number, yieldToken: string, dx: number): Tx {
        return Tx.contractCall(
            "futures-pool",
            "add-to-position",
            [
                types.principal(token),
                types.principal(reward),
                types.uint(startCycle),
                types.principal(yieldToken),
                types.uint(dx),
            ],
            sender.address
        );
    }

    //(contract-call? .futures-pool reduce-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.token-alex u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex u10)
    reducePosition(sender: Account, token: string, reward: string, startCycle: number, yieldToken: string, percent: number): Tx {
        return Tx.contractCall(
            "futures-pool",
            "reduce-position",
            [
                types.principal(token),
                types.principal(reward),
                types.uint(startCycle),
                types.principal(yieldToken),
                types.uint(percent),
            ],
            sender.address
        )
    }

    getRewardCycleLength(sender: Account){
        return this.chain.callReadOnlyFn(
            "alex-reserve-pool",
            "get-reward-cycle-length",
            [],sender.address
        )
    }

    getFirstStacksBlockInRewardCycle(sender: Account, token: string, startCycle: number){
        return this.chain.callReadOnlyFn(
            "alex-reserve-pool",
            "get-first-stacks-block-in-reward-cycle",
            [types.principal(token),
            types.uint(startCycle)],
            sender.address
        )
    }

    setCoinbaseAmount(sender: Account, token: string, coinbaseOne: number, coinbaseTwo: number,
      coinbaseThree: number, coinbaseFour: number, coinbaseFive: number): Tx {
      return Tx.contractCall(
        "alex-reserve-pool",
        "set-coinbase-amount",
        [
          types.principal(token), types.uint(coinbaseOne), types.uint(coinbaseTwo), 
          types.uint(coinbaseThree) ,types.uint(coinbaseFour), types.uint(coinbaseFive)
        ],
        sender.address
      );
    }     
}

export { FuturesPool }
