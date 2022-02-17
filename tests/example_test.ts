import { Clarinet, Tx, types, assertEquals, prepareStandardTest, contractPrincipal, extractBounds, extractParameters } from "./deps.ts";
import type { Chain, Account, StandardTestParameters } from "./deps.ts";
import { determineWinners, IdoParameters, IdoParticipant } from "../lib/launchpad.ts";

Clarinet.test({
	name: "Example claim walk test",
	async fn(chain: Chain, accounts: Map<string, Account>) {
		const [deployer, accountA, accountB] = ["deployer", "wallet_1", "wallet_2"].map(wallet => accounts.get(wallet)!);

		const registrationStartHeight = 10;
		const registrationEndHeight = 20;
		const claimEndHeight = 30;

		const ticketRecipients = [{ recipient: accountA, amount: 10 }, { recipient: accountB, amount: 20 }];

		const parameters: StandardTestParameters = {
			totalIdoTokens: 200,
			idoOwner: accountA,
			ticketsForSale: 10,
			idoTokensPerTicket: 24,
			pricePerTicketInFixed: 1000000000,
			activationThreshold: 10,
			registrationStartHeight,
			registrationEndHeight,
			claimEndHeight,
			ticketRecipients
		};
		const preparation = prepareStandardTest(chain, parameters, deployer);
		preparation.blocks.map(block => block.receipts.map(({ result }) => result.expectOk()));

		const { idoId } = preparation;

		chain.mineEmptyBlockUntil(registrationStartHeight);
		const registrations = chain.mineBlock(ticketRecipients.map(entry => Tx.contractCall("lottery", "register", [types.uint(idoId), types.uint(entry.amount), types.principal(contractPrincipal(deployer, "ido-ticket")), types.principal(contractPrincipal(deployer, "wrapped-stx"))], (entry.recipient as Account).address || entry.recipient as unknown as string)));
		registrations.receipts.map(({ result }) => result.expectOk());

		const bounds = registrations.receipts.map(receipt => extractBounds(receipt.result));

		//FIXME this +2 is needed because the VRF of block registrationEndHeight + 1 is used, we need to guard for this in the contract.
		chain.mineEmptyBlockUntil(registrationEndHeight + 2);

		const parametersFromChain = chain.callReadOnlyFn("lottery", "get-offering-walk-parameters", [types.uint(idoId)], deployer.address);
		const idoParameters: IdoParameters = extractParameters(parametersFromChain.result);

		const idoParticipants: IdoParticipant[] = ticketRecipients.map((entry, index) => ({ participant: entry.recipient.address, ...bounds[index] }));
		const winners = determineWinners(idoParameters, idoParticipants);
		const maxChunkSize = 200;
		for (let index = 0; index < winners.winners.length; index += maxChunkSize) {
			const claim = chain.mineBlock([
				Tx.contractCall("lottery", "claim-optimal", [types.uint(idoId), types.list(winners.winners.slice(index, index + maxChunkSize).map(types.principal)), types.principal(contractPrincipal(deployer, "ido-token")), types.principal(contractPrincipal(deployer, "wrapped-stx"))], deployer.address)
			]);
			console.log(claim);
			console.log([types.uint(idoId), types.list(winners.winners.slice(index, index + maxChunkSize).map(types.principal)), types.principal(contractPrincipal(deployer, "ido-token")), types.principal(contractPrincipal(deployer, "wrapped-stx"))])
		}



		// assertEquals(block.receipts.length, 0);

	},
});
