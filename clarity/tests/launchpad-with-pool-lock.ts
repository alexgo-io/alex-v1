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
  determineApower,
} from "./models/launchpad-with-pool-lock.ts";
import type {
  Chain,
  Account,
  StandardTestParameters,
} from "./models/launchpad-with-pool-lock.ts";
import {
  determineWinners,
  determineLosers,
  IdoParameters,
  IdoParticipant,
} from "../scripts/launchpad.ts";

const parameters = {
  totalIdoTokens: 40000,
  idoOwner: undefined,
  ticketsForSale: 801,
  idoTokensPerTicket: 50,
  pricePerTicketInFixed: 5000000000,
  activationThreshold: 1,
  ticketRecipients: undefined,
  registrationStartHeight: 20,
  registrationEndHeight: 30,
  claimEndHeight: 40,
  apowerPerTicketInFixed: [
    { tierThreshold: 5, apowerPerTicketInFixed: 10 * ONE_8 },
    { tierThreshold: 10, apowerPerTicketInFixed: 50 * ONE_8 },
    { tierThreshold: 20, apowerPerTicketInFixed: 100 * ONE_8 },
    { tierThreshold: 30, apowerPerTicketInFixed: 150 * ONE_8 },
    { tierThreshold: 40, apowerPerTicketInFixed: 200 * ONE_8 },
    { tierThreshold: 50, apowerPerTicketInFixed: 250 * ONE_8 },
  ],
  registrationMaxTickets: 999999999999,
  feePerTicketInFixed: 0,
  lockPct: 0.1e8,
  lockPeriod: 20
};

Clarinet.test({
  name: "launchpad-with-pool-lock : example claim walk test",
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
        "alex-launchpad-v1-3",
        "add-approved-operator",
        [types.principal(approved_operator.address)],
        deployer.address
      ),
    ]);

      const registrationStartHeight = 20;
      const registrationEndHeight = registrationStartHeight + 10;
      const claimEndHeight = registrationEndHeight + 100;

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
        totalIdoTokens: 50000,
        idoOwner: accountA,
        ticketsForSale: 500,
        idoTokensPerTicket: 100,
        pricePerTicketInFixed: 33e8,
        activationThreshold: 500,
        ticketRecipients: ticketRecipients,
        registrationStartHeight: registrationStartHeight,
        registrationEndHeight: registrationEndHeight,
        claimEndHeight: claimEndHeight,
      };

      const preparation = prepareStandardTest(chain, params, deployer);
      preparation.blocks.map((block) =>
        block.receipts.map(({ result }) => result.expectOk())
      );

      const { idoId } = preparation;

      chain.mineEmptyBlockUntil(registrationStartHeight);
      const registrations = chain.mineBlock(
        ticketRecipients.map((entry) =>
          Tx.contractCall(
            "alex-launchpad-v1-3",
            "register",
            [
              types.uint(idoId),
              types.uint(entry.amount),
              types.principal(contractPrincipal(deployer, "token-wstx")),
            ],
            (entry.recipient as Account).address ||
              (entry.recipient as unknown as string)
          )
        )
      );
      // console.log(registrations.receipts);
      registrations.receipts.map(({ result }) => result.expectOk());
      assertEquals(registrations.receipts.length, ticketRecipients.length);
      for (let i = 0; i < ticketRecipients.length; i++) {
        registrations.receipts[i].events.expectSTXTransferEvent(
          ((ticketRecipients[i]["amount"] *
            params["pricePerTicketInFixed"]) /
            ONE_8) *
            1e6,
          ticketRecipients[i]["recipient"].address,
          deployer.address + ".alex-launchpad-v1-3"
        );

        registrations.receipts[i].events.expectFungibleTokenBurnEvent(
          determineApower(
            ticketRecipients[i]["amount"],
            params["apowerPerTicketInFixed"]
          ),
          ticketRecipients[i]["recipient"].address,
          "apower"
        );
      }

      const bounds = registrations.receipts.map((receipt) =>
        extractBounds(receipt.result)
      );

      chain.mineEmptyBlockUntil(registrationEndHeight + 2);

      const parametersFromChain = chain.callReadOnlyFn(
        "alex-launchpad-v1-3",
        "get-offering-walk-parameters",
        [types.uint(idoId)],
        deployer.address
      );

      const idoParameters: IdoParameters = extractParameters(
        parametersFromChain.result
      );

      const idoParticipants: IdoParticipant[] = ticketRecipients.map(
        (entry, index) => ({
          participant: entry.recipient.address,
          ...bounds[index],
        })
      );

      // console.log(idoParameters);
      // console.log(idoParticipants);

      const dx_expected = (params.pricePerTicketInFixed - params.feePerTicketInFixed) * params.ticketsForSale * params.lockPct / ONE_8;
      const dy_expected = params.idoTokensPerTicket * params.ticketsForSale * params.lockPct;      

      let dx_actual = 0;
      let dy_actual = 0;
      // console.log("determining winners...");
      const winners = determineWinners(idoParameters, idoParticipants);
      // console.log(winners);
      let maxChunkSize = 200;
      for (
        let index = 0;
        index < winners.winners.length;
        index += maxChunkSize
      ) {
        let winners_sliced = winners.winners.slice(index, index + maxChunkSize);
        // console.log(winners_sliced[0], winners_sliced[winners_sliced.length - 1]);
        const claim = chain.mineBlock([
          Tx.contractCall(
            "launchpad-with-pool-lock",
            "claim",
            [
              types.uint(idoId),
              types.list(winners_sliced.map(types.principal)),
              types.principal(contractPrincipal(deployer, "token-wban")),
              types.principal(contractPrincipal(deployer, "token-wstx")),
            ],
            accountC.address
          ),
        ]);    
        winners_list.push(winners.winners.length);
        let events = claim.receipts[0].events;
        const liquidity = claim.receipts[0].result.expectOk().expectTuple();
        const dx = parseInt(liquidity.dx.substring(1));
        const dy = parseInt(liquidity.dy.substring(1));
        dx_actual += dx;
        dy_actual += dy;
        console.log(`${index}, dx = ${dx_actual} vs ${dx_expected}, dy = ${dy_actual} vs. ${dy_expected}`);
        
        // assertEquals(events.length, 1 + winners_sliced.length);
        events.expectSTXTransferEvent(
          ((params["pricePerTicketInFixed"] * winners_sliced.length) /
            ONE_8) *
            1e6,
          deployer.address + ".alex-launchpad-v1-3",
          deployer.address + ".launchpad-with-pool-lock"
        );
        events.expectSTXTransferEvent(
          dx / ONE_8 * 1e6,
          deployer.address + '.launchpad-with-pool-lock',
          deployer.address + '.alex-vault-v1-1'
        );
        events.expectFungibleTokenTransferEvent(
          dy / ONE_8 * 1e6,
          deployer.address + '.launchpad-with-pool-lock',
          deployer.address + '.alex-vault-v1-1',
          "banana"    
        )
        for (let j = 1; j < 1 + winners_sliced.length; j++) {
          events.expectFungibleTokenTransferEvent(
            params["idoTokensPerTicket"] * 1e6,
            deployer.address + ".alex-launchpad-v1-3",
            winners_sliced[j - 1],
            "banana"
          );
        }
      }

      assertEquals(dx_actual, dx_expected);
      assertEquals(dy_actual, dy_expected);

      chain.mineEmptyBlockUntil(registrationEndHeight + 19);
      const reduceFail = chain.mineBlock([
        Tx.contractCall(
          "launchpad-with-pool-lock",
          "reduce-position",
          [
            types.uint(idoId),
            types.principal(contractPrincipal(deployer, "token-wban")),
            types.principal(contractPrincipal(deployer, "token-wstx")),
            types.uint(ONE_8)
          ],
          accountC.address
        ),
      ]);
      reduceFail.receipts[0].result.expectErr().expectUint(2042);   

      chain.mineEmptyBlockUntil(claimEndHeight);
      // console.log("determining losers...");
      const losers = determineLosers(idoParameters, idoParticipants);
      let losers_list = losers.losers.map((e) => {
        return e.recipient;
      });

      for (let index = 0; index < idoParticipants.length; index++) {
        let participant = idoParticipants[index]["participant"];
        let won =
          winners.winners.indexOf(participant) == -1
            ? 0
            : winners.winners.lastIndexOf(participant) -
              winners.winners.indexOf(participant) +
              1;
        let lost =
          losers_list.indexOf(participant) == -1
            ? 0
            : losers.losers[losers_list.indexOf(participant)]["amount"];
        console.log(
          participant,
          "registered:",
          won + lost,
          "won:",
          won,
          "lost:",
          lost
        );
        assertEquals(ticketRecipients[index]["amount"], won + lost);
      }

      maxChunkSize = 5;
      for (let index = 0; index < losers.losers.length; index += maxChunkSize) {
        let losers_sliced = losers.losers.slice(index, index + maxChunkSize);
        // console.log(losers_sliced);
        const claim = chain.mineBlock([
          Tx.contractCall(
            "alex-launchpad-v1-3",
            "refund",
            [
              types.uint(idoId),
              types.list(
                losers_sliced.map((e) => {
                  return types.tuple({
                    recipient: types.principal(e.recipient),
                    amount: types.uint(
                      e.amount * params["pricePerTicketInFixed"]
                    ),
                  });
                })
              ),
              types.principal(contractPrincipal(deployer, "token-wstx")),
            ],
            accountC.address
          ),
        ]);

        let events = claim.receipts[0].events;
        // console.log(index, claim.receipts[0].result);
        assertEquals(events.length, losers_sliced.length);

        for (let j = 0; j < events.length; j++) {
          events.expectSTXTransferEvent(
            ((losers_sliced[j]["amount"] *
              params["pricePerTicketInFixed"]) /
              ONE_8) *
              1e6,
            deployer.address + ".alex-launchpad-v1-3",
            losers_sliced[j]["recipient"]
          );
        }
      }

      const reduceOk = chain.mineBlock([
        Tx.contractCall(
          "launchpad-with-pool-lock",
          "reduce-position",
          [
            types.uint(idoId),
            types.principal(contractPrincipal(deployer, "token-wban")),
            types.principal(contractPrincipal(deployer, "token-wstx")),
            types.uint(ONE_8)
          ],
          accountC.address
        ),
      ]);
      reduceOk.receipts[0].result.expectOk();
      const events = reduceOk.receipts[0].events;
      events.expectSTXTransferEvent(
        dx_expected / ONE_8 * 1e6,
        deployer.address + '.alex-vault-v1-1',
        deployer.address + '.launchpad-with-pool-lock'
      )
      events.expectSTXTransferEvent(
        dx_expected / ONE_8 * 1e6,
        deployer.address + '.launchpad-with-pool-lock',
        accountA.address
      )
      events.expectFungibleTokenTransferEvent(
        dy_expected / ONE_8 * 1e6,
        deployer.address + '.alex-vault-v1-1',
        deployer.address + '.launchpad-with-pool-lock',
        "banana"
      )
      events.expectFungibleTokenTransferEvent(
        dy_expected / ONE_8 * 1e6,
        deployer.address + '.launchpad-with-pool-lock',
        accountA.address,
        "banana"
      )
  },
});
