import {
  ONE_8,
  Clarinet,
  Tx,
  types,
  assertEquals,
  prepareStandardTest,
  contractPrincipal,
  extractBounds,
  extractParameters,
  Chain,
  Account,
  StandardTestParameters,  
} from "./models/alex-tests-lottery.ts";
import {
  determineWinners,
  determineLosers,
  LotteryParameters,
  LotteryParticipant,
} from "../scripts/lottery.ts";

const parameters = {
  tokensPerTicketInFixed: 50e8,
  registrationStartHeight: 10,
  registrationEndHeight: 20,
};

Clarinet.test({
  name: "alex-lottery : example claim walk test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const [
      deployer,
      accountA,
      accountB,
      accountC,
      accountD,
      accountE,
      accountF,
      accountG,
    ] = [
      "deployer",
      "wallet_1",
      "wallet_2",
      "wallet_3",
      "wallet_4",
      "wallet_5",
      "wallet_6",
      "wallet_7",
    ].map((wallet) => accounts.get(wallet)!);

    let winners_list: number[] = [];

    const approved_operator = accountC;
    const third = chain.mineBlock([
      Tx.contractCall(
        "alex-lottery",
        "add-approved-operator",
        [types.principal(approved_operator.address)],
        deployer.address
      ),
      Tx.contractCall(
        "token-apower",
        "add-approved-contract",
        [types.principal(contractPrincipal(deployer, "alex-lottery"))],
        deployer.address
      ),
      // Tx.contractCall(
      //   "age000-governance-token",
      //   "edg-add-approved-contract",
      //   [types.principal(contractPrincipal(deployer, "alex-lottery"))],
      //   deployer.address
      // ),      
    ]);
    third.receipts.map(({ result }) => result.expectOk());

    for (let t = 0; t < 500; t += 120) {
      const registrationStartHeight = 10 + t;
      const registrationEndHeight = registrationStartHeight + 10;

      const ticketRecipients = [
        { recipient: accountA, amount: 10 },
        { recipient: accountB, amount: 4000 },
        { recipient: accountC, amount: 2000 },
        { recipient: accountD, amount: 50000 },
        { recipient: accountE, amount: 1010 },
        { recipient: accountF, amount: 100000 },
        { recipient: accountG, amount: 10 },
      ];

      const params: StandardTestParameters = {
        ...parameters,
        registrationStartHeight: registrationStartHeight,
        registrationEndHeight: registrationEndHeight,
        ticketRecipients: ticketRecipients,
      };

      const preparation = prepareStandardTest(chain, params, deployer);
      preparation.blocks.map((block) =>
        block.receipts.map(({ result }) => result.expectOk())
      );

      const { lotteryId } = preparation;

      chain.mineEmptyBlockUntil(registrationStartHeight);
      const registrations = chain.mineBlock(
        ticketRecipients.map((entry) =>
          Tx.contractCall(
            "alex-lottery",
            "register",
            [
              types.uint(lotteryId),
              types.uint(entry.amount),
              types.principal(contractPrincipal(deployer, "age000-governance-token")),
              types.uint(0)
            ],
            (entry.recipient as Account).address ||
              (entry.recipient as unknown as string)
          )
        )
      );
      registrations.receipts.map(({ result }) => result.expectOk());
      assertEquals(registrations.receipts.length, ticketRecipients.length);

      for (let i = 0; i < ticketRecipients.length; i++) {
        registrations.receipts[i].events.expectFungibleTokenTransferEvent(          
          ticketRecipients[i]["amount"] * params["tokensPerTicketInFixed"],
          ticketRecipients[i]["recipient"].address,
          deployer.address + ".alex-lottery",
          "alex"
        );
      }

      const bounds = registrations.receipts.map((receipt) =>
        extractBounds(receipt.result)
      );

      for(let k = 0; k < 3; k++){
      chain.mineEmptyBlockUntil(registrationEndHeight + k + 2);

      const parametersFromChain = chain.callReadOnlyFn(
        "alex-lottery",
        "get-lottery-walk-parameters",
        [types.uint(lotteryId), types.uint(k + 1)],
        deployer.address
      );

      const lotteryParameters: LotteryParameters = extractParameters(
        parametersFromChain.result
      );

      const lotteryParticipants: LotteryParticipant[] = ticketRecipients.map(
        (entry, index) => ({
          participant: entry.recipient.address,
          ...bounds[index],
        })
      );
      const winners = determineWinners(lotteryParameters, lotteryParticipants);
      const claim = chain.mineBlock([
          Tx.contractCall(
            "alex-lottery",
            "claim",
            [
              types.uint(lotteryId),
              types.uint(k + 1),
              types.list(winners.winners.map(types.principal)),
              types.principal(contractPrincipal(deployer, "age000-governance-token")),
            ],
            accountC.address
          ),
        ]);
        const events = claim.receipts[0].events;
        const output: any = claim.receipts[0].result.expectOk().expectTuple();
        const gross = Number(output['gross'].toString().substring(1));
        const tax = Number(output['tax'].toString().substring(1));
        const payout = Number(output['payout'].toString().substring(1));

        winners_list.push(winners.winners.length);
        assertEquals(events.length, 1 + winners.winners.length);
        // console.log(events);

        events.expectFungibleTokenTransferEvent(
          tax,
          deployer.address + ".alex-lottery",
          deployer.address,
          "alex"
        );
        for (let j = 0; j < events.length - 1; j++) {
          events.expectFungibleTokenTransferEvent(
            payout,
            deployer.address + ".alex-lottery",
            winners.winners[j],
            "alex"
          );
        }
      }
      }
    console.log(
      "min: ",
      Math.min(...winners_list),
      "median: ",
      winners_list.sort((a, b) => (a > b ? 1 : -1))[
        Math.floor(winners_list.length / 2)
      ],
      "mean: ",
      winners_list.reduce((sum, x) => sum + x, 0) / winners_list.length,
      "max: ",
      Math.max(...winners_list)
    );
  },
});
