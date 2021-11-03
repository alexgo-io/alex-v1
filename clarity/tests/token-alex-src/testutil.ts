import { Account, Chain, Tx, it } from "./deps.ts";
import { TokenClient } from "./token-client.ts";
import { CoreClient } from "./core-client.ts";
import { TestUtilsClient } from "./test-utils-client.ts";

class Accounts extends Map<string, Account> {}

interface Clients {
  token: TokenClient;
  core: CoreClient;
  testUtils: TestUtilsClient;
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
        name: "alexcoin",
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
      token: new TokenClient("token-alex", chain, deployer),
      core: new CoreClient("token-alex-core-v1", chain, deployer),
      testUtils: new TestUtilsClient("test-utils", chain, deployer),
    };

    await fn(chain, accounts, clients);
  });
}

export { _it as it };