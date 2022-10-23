
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.31.1/index.ts";

class FuturesPool{
    chain: Chain;

    constructor(chain: Chain) {
        this.chain = chain;
    }

    //(contract-call? .futures-pool create-pool 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token (list u1) 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex)
    createPool(sender: Account, poxlTokenTrait: string, rewardCycles: Array<string>, yieldToken: string){
        return Tx.contractCall(
            "futures-pool",
            "create-pool",
            [
                types.principal(poxlTokenTrait),
                types.list(rewardCycles),
                types.principal(yieldToken),
            ],
            sender.address
        );
    }

    setActivationBlock(sender: Account, token: string, block: number): Tx {
        return Tx.contractCall(
            "alex-reserve-pool",
            "set-activation-block",
            [
                types.principal(token),
                types.uint(block)
            ],
            sender.address
        );
    }

    //(contract-call? .alex-reserve-pool add-token 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token u1)
    addToken(sender: Account, token: string): Tx {
        return Tx.contractCall(
            "alex-reserve-pool",
            "add-token",
            [
                types.principal(token)
            ],
            sender.address
        );
    }

    //(contract-call? .futures-pool add-to-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex u1000000000)
    addToPosition(sender: Account, token: string, startCycle: number, yieldToken: string, dx: number): Tx {
        return Tx.contractCall(
            "futures-pool",
            "add-to-position",
            [
                types.principal(token),
                types.uint(startCycle),
                types.principal(yieldToken),
                types.uint(dx),
            ],
            sender.address
        );
    }   

    //(contract-call? .futures-pool reduce-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.age000-governance-token u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.stacked-alex u10)
    reducePosition(sender: Account, token: string, startCycle: number, yieldToken: string, percent: number): Tx {
        return Tx.contractCall(
            "futures-pool",
            "reduce-position",
            [
                types.principal(token),
                types.uint(startCycle),
                types.principal(yieldToken),
                types.uint(percent),
            ],
            sender.address
        )
    }

    //(define-public (claim-and-stake (staked-token-trait <ft-trait>) (start-cycle uint))
    claimAndStake(sender: Account, token: string, startCycle: number): Tx {
        return Tx.contractCall(
            "futures-pool",
            "claim-and-stake",
            [
                types.principal(token),
                types.uint(startCycle)
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

    getUserId(sender: Account, token: string, user: string){
        return this.chain.callReadOnlyFn(
            "alex-reserve-pool",
            "get-user-id",
            [types.principal(token),
            types.principal(user)],
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
