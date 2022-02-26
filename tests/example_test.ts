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
} from "./deps.ts";
import type { Chain, Account, StandardTestParameters } from "./deps.ts";
import {
  determineWinners,
  determineLosers,
  IdoParameters,
  IdoParticipant,
} from "../lib/launchpad.ts";

Clarinet.test({
  name: "Example claim walk test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const [deployer, accountA, accountB] = [
      "deployer",
      "wallet_1",
      "wallet_2",
    ].map((wallet) => accounts.get(wallet)!);

    let winners_list: number[] = [];

    for (let t = 0; t < 1000; t += 120) {
      const registrationStartHeight = 10 + t;
      const registrationEndHeight = registrationStartHeight + 10;
      const claimEndHeight = registrationEndHeight + 100;

      const ticketRecipients = [
        { recipient: accountA, amount: 10000 * 10000000000 },
        { recipient: accountB, amount: 20000 * 10000000000 },
      ];

      const parameters: StandardTestParameters = {
        totalIdoTokens: 20000,
        idoOwner: accountA,
        ticketsForSale: 1381,
        idoTokensPerTicket: 24,
        pricePerTicketInFixed: 10000000000,
        activationThreshold: 10,
        registrationStartHeight,
        registrationEndHeight,
        claimEndHeight,
        ticketRecipients,
        apowerPerTicketInFixed: 10000000000,
      };
      const preparation = prepareStandardTest(chain, parameters, deployer);
      preparation.blocks.map((block) =>
        block.receipts.map(({ result }) => result.expectOk())
      );

      const { idoId } = preparation;

      chain.mineEmptyBlockUntil(registrationStartHeight);
      const registrations = chain.mineBlock(
        ticketRecipients.map((entry) =>
          Tx.contractCall(
            "lottery",
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
      registrations.receipts.map(({ result }) => result.expectOk());
      assertEquals(registrations.receipts.length, ticketRecipients.length);
      for (let i = 0; i < ticketRecipients.length; i++) {
        registrations.receipts[i].events.expectSTXTransferEvent(
          (((ticketRecipients[i]["amount"] /
            parameters["apowerPerTicketInFixed"]) *
            parameters["pricePerTicketInFixed"]) /
            ONE_8) *
            1e6,
          ticketRecipients[i]["recipient"].address,
          deployer.address + ".lottery"
        );
        registrations.receipts[i].events.expectFungibleTokenBurnEvent(
          ticketRecipients[i]["amount"],
          ticketRecipients[i]["recipient"].address,
          "apower"
        );
      }

      const bounds = registrations.receipts.map((receipt) =>
        extractBounds(receipt.result)
      );

      //FIXME this +2 is needed because the VRF of block registrationEndHeight + 1 is used, we need to guard for this in the contract.
      chain.mineEmptyBlockUntil(registrationEndHeight + 2);

      const parametersFromChain = chain.callReadOnlyFn(
        "lottery",
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
        console.log(winners_sliced[0], winners_sliced[winners_sliced.length - 1]);
        const claim = chain.mineBlock([
          Tx.contractCall(
            "lottery",
            "claim",
            [
              types.uint(idoId),
              types.list(winners_sliced.map(types.principal)),
              types.principal(contractPrincipal(deployer, "token-t-alex")),
              types.principal(contractPrincipal(deployer, "token-wstx")),
            ],
            deployer.address
          ),
        ]);
        // console.log(t, claim.receipts[0].result.expectOk(), winners.winners.length);
        winners_list.push(winners.winners.length);
        let events = claim.receipts[0].events;
        // console.log(index, claim.receipts[0].result);
        assertEquals(events.length, 1 + winners_sliced.length);
        events.expectSTXTransferEvent(
          ((parameters["pricePerTicketInFixed"] * winners_sliced.length) /
            ONE_8) *
            1e6,
          deployer.address + ".lottery",
          accountA.address
        );
        for (let j = 1; j < events.length; j++) {
          events.expectFungibleTokenTransferEvent(
            parameters["idoTokensPerTicket"] * ONE_8,
            deployer.address + ".lottery",
            winners_sliced[j - 1],
            "t-alex"
          );
        }
      }
      chain.mineEmptyBlockUntil(claimEndHeight);

      // console.log("determining losers...");
      const losers = determineLosers(idoParameters, idoParticipants); 
      
      for(let index = 0; index < idoParticipants.length; index++){
        let participant = idoParticipants[index]['participant'];
        let won = winners.winners.indexOf(participant) == -1 ? 0 : winners.winners.lastIndexOf(participant) - winners.winners.indexOf(participant) + 1;
        let lost = losers.losers.length == 0 ? 0 : losers.losers[index]['amount'];
        console.log(
          participant, 
          "registered:", won + lost,
          "won:", won,
          "lost:", lost
        );
        assertEquals(ticketRecipients[index]['amount'] / parameters['apowerPerTicketInFixed'], won + lost);
      }
                   
      maxChunkSize = 1;
      for (
        let index = 0;
        index < losers.losers.length;
        index += maxChunkSize
      ) {
        let losers_sliced = losers.losers.slice(index, index + maxChunkSize);
        console.log(losers_sliced);
        const claim = chain.mineBlock([
          Tx.contractCall(
            "lottery",
            "refund",
            [
              types.uint(idoId),
              types.list(losers_sliced.map(e => { return types.tuple({recipient: types.principal(e.recipient), amount: types.uint(e.amount * parameters["pricePerTicketInFixed"])})})),
              types.principal(contractPrincipal(deployer, "token-wstx")),
            ],
            deployer.address
          ),
        ]);

        let events = claim.receipts[0].events;
        console.log(index, claim.receipts[0].result);
        assertEquals(events.length, losers_sliced.length);
        
        for (let j = 0; j < events.length; j++) {
          events.expectSTXTransferEvent(
            (losers_sliced[j]['amount'] * parameters["pricePerTicketInFixed"] / ONE_8) * 1e6,
            deployer.address + ".lottery",
            losers_sliced[j]['recipient'],
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
