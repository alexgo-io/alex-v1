import { ONE_8, Clarinet, Tx, types, assertEquals, prepareStandardTest, contractPrincipal, extractBounds, extractParameters } from "./deps.ts";
import type { Chain, Account, StandardTestParameters } from "./deps.ts";
import { determineWinners, IdoParameters, IdoParticipant } from "../lib/launchpad.ts";

Clarinet.test({
	name: "Example claim walk test",
	async fn(chain: Chain, accounts: Map<string, Account>) {
		const [deployer, accountA, accountB] = ["deployer", "wallet_1", "wallet_2"].map(wallet => accounts.get(wallet)!);

		const registrationStartHeight = 10;
		const registrationEndHeight = 20;
		const claimEndHeight = 30;		

		const ticketRecipients = [{ recipient: accountA, amount: 100000000000 }, { recipient: accountB, amount: 200000000000 }];

		const parameters: StandardTestParameters = {
			totalIdoTokens: 200,
			idoOwner: accountA,
			ticketsForSale: 10,
			idoTokensPerTicket: 24,
			pricePerTicketInFixed: 10000000000,
			activationThreshold: 10,
			registrationStartHeight,
			registrationEndHeight,
			claimEndHeight,
			ticketRecipients,
			apowerPerTicketInFixed: 10000000000
		};
		const preparation = prepareStandardTest(chain, parameters, deployer);
		preparation.blocks.map(block => block.receipts.map(({ result }) => result.expectOk()));

		const { idoId } = preparation;

		chain.mineEmptyBlockUntil(registrationStartHeight);
		const registrations = chain.mineBlock(ticketRecipients.map(entry => Tx.contractCall("lottery", "register", [types.uint(idoId), types.uint(entry.amount), types.principal(contractPrincipal(deployer, "token-wstx"))], (entry.recipient as Account).address || entry.recipient as unknown as string)));
		registrations.receipts.map(({ result }) => result.expectOk());
		assertEquals(registrations.receipts.length, ticketRecipients.length);
		for(let i = 0; i < ticketRecipients.length; i++) {
			registrations.receipts[i].events.expectSTXTransferEvent(
				ticketRecipients[i]['amount'] / parameters['apowerPerTicketInFixed'] * parameters['pricePerTicketInFixed'] / ONE_8 * 1e6,
				ticketRecipients[i]['recipient'].address,
				deployer.address + ".lottery"
			)
			registrations.receipts[i].events.expectFungibleTokenBurnEvent(
				ticketRecipients[i]['amount'],
				ticketRecipients[i]['recipient'].address,
				"apower"
			)			
		}

		const bounds = registrations.receipts.map(receipt => extractBounds(receipt.result));

		//FIXME this +2 is needed because the VRF of block registrationEndHeight + 1 is used, we need to guard for this in the contract.
		chain.mineEmptyBlockUntil(registrationEndHeight + 2);

		const parametersFromChain = chain.callReadOnlyFn("lottery", "get-offering-walk-parameters", [types.uint(idoId)], deployer.address);
		const idoParameters: IdoParameters = extractParameters(parametersFromChain.result);

		const idoParticipants: IdoParticipant[] = ticketRecipients.map((entry, index) => ({ participant: entry.recipient.address, ...bounds[index] }));
		const winners = determineWinners(idoParameters, idoParticipants);
		console.log(winners);
		
		const maxChunkSize = 200;
		for (let index = 0; index < winners.winners.length; index += maxChunkSize) {
			let winners_sliced = winners.winners.slice(index, index + maxChunkSize);
			const claim = chain.mineBlock([
				Tx.contractCall(
					"lottery", 
					"claim-fallback", 
					[
						types.uint(idoId), 
						types.list(winners_sliced.map(types.principal)), 
						types.principal(contractPrincipal(deployer, "token-t-alex")), 
						types.principal(contractPrincipal(deployer, "token-wstx"))
					], 
					deployer.address)
			]);
			let events = claim.receipts[0].events;
			assertEquals(events.length, 1 + winners_sliced.length);
			events.expectSTXTransferEvent(
				(parameters['pricePerTicketInFixed'] * winners_sliced.length / ONE_8 * 1e6),
				deployer.address + ".lottery",
				accountA.address,
			);
			for (let j = 1; j < events.length; j++) {
				events.expectFungibleTokenTransferEvent(
					parameters['idoTokensPerTicket'] * ONE_8,
					deployer.address + ".lottery",
					winners_sliced[j - 1],
					"t-alex"
				)					
			}

		}

	},
});
