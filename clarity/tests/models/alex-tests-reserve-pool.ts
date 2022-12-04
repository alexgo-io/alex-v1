
import {Clarinet, Tx, Chain, Account, types} from "https://deno.land/x/clarinet@v0.31.1/index.ts";

class ReservePool{
    chain: Chain;

    constructor(chain: Chain) {
        this.chain = chain;
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

    setApowerMultiplierInFixed(sender: Account, token: string, apower: number): Tx {
        return Tx.contractCall(
          "alex-reserve-pool",
          "set-apower-multiplier-in-fixed",
          [
            types.principal(token),
            types.uint(apower)
          ],
          sender.address
        );
      }      
    
}

export { ReservePool }
