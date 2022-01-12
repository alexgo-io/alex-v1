import { Account, Chain, Tx, it } from "./deps.ts";
import { CoreClient } from "./core-client.ts";
import { TokenClient } from "./token-client.ts";

class Accounts extends Map<string, Account> {}

interface Clients {
  core: CoreClient;
  token: TokenClient;
  apower: TokenClient;
}

function _it(
  name: string,
  fn: (chain: Chain, accounts: Accounts, clients: Clients) => void
) {
  it(name, async () => {
    let chain: Chain;
    let accounts: Accounts;
    let deployer: Account;
    let clients: Clients;

    (Deno as any).core.ops();
    let transactions: Array<Tx> = [];
    let result = JSON.parse(
      (Deno as any).core.opSync("setup_chain", {
        name: "alex-reserve-pool",
        transactions: transactions,
      })
    );

    chain = new Chain(result["session_id"]);
    accounts = new Map();

    for (let account of result["accounts"]) {
      accounts.set(account.name, account);
    }

    deployer = accounts.get("deployer")!;
    clients = {
      core: new CoreClient("alex-reserve-pool", chain, deployer),
      token: new TokenClient("age000-governance-token", chain, deployer),
      apower: new TokenClient("token-apower", chain, deployer)
    };

    await fn(chain, accounts, clients);
  });
}

export { _it as it };