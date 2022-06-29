import { Clarinet, Tx, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import type { Chain, Account } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

export { Clarinet, Tx, types, assertEquals };
export type { Chain, Account };

export const ONE_8 = 100000000;

export type TicketAllocation = { recipient: Account | string, amount: number };
export type StandardTestParameters = {
	tokensPerTicketInFixed: number,
	registrationStartHeight: number,
	registrationEndHeight: number,
	ticketRecipients: TicketAllocation[],
};

export const contractPrincipal = (address: Account | string, contractName: string) => `${(address as Account).address || address}.${contractName}`;

export function prepareStandardTest(chain: Chain, parameters: StandardTestParameters, deployer: Account) {
	const {
		tokensPerTicketInFixed,
		registrationStartHeight,
		registrationEndHeight,
		ticketRecipients,
	} = parameters;
	const first = chain.mineBlock([		
		Tx.contractCall("token-apower", "add-approved-contract", [types.principal(contractPrincipal(deployer, "alex-lottery"))], deployer.address),
		...ticketRecipients.map(allocation => Tx.contractCall("age000-governance-token", "mint-fixed", [types.uint(allocation.amount * tokensPerTicketInFixed), types.principal((allocation.recipient as Account).address || allocation.recipient as string)], deployer.address)),
		Tx.contractCall("alex-lottery", "create-pool", [
			types.principal(contractPrincipal(deployer, "age000-governance-token")),
			types.tuple({
				"tokens-per-ticket-in-fixed": types.uint(tokensPerTicketInFixed),
				"registration-start-height": types.uint(registrationStartHeight),
				"registration-end-height": types.uint(registrationEndHeight),
			}),
		], deployer.address),
	]);
	const lotteryId = parseInt(first.receipts[first.receipts.length - 1].result.expectOk().toString().substring(1));
	assertEquals(isNaN(lotteryId), false, "failed to get Lottery ID");

	const second = chain.mineBlock([
		Tx.contractCall("alex-lottery", "set-lottery-round",
			[
				types.uint(lotteryId),
				types.uint(1),
				types.uint(registrationEndHeight + 1),
				types.uint(0.2e8),
				types.uint(10),
				types.uint(0.8e8)
			], deployer.address
		),
		Tx.contractCall("alex-lottery", "set-lottery-round",
			[
				types.uint(lotteryId),
				types.uint(2),
				types.uint(registrationEndHeight + 2),
				types.uint(0.3e8),
				types.uint(5),
				types.uint(0.8e8)
			], deployer.address
		),	
		Tx.contractCall("alex-lottery", "set-lottery-round",
			[
				types.uint(lotteryId),
				types.uint(3),
				types.uint(registrationEndHeight + 3),
				types.uint(0.5e8),
				types.uint(2),
				types.uint(0.8e8)
			], deployer.address
		),			
	])
	return { lotteryId, blocks: [first, second] };
}

export function extractBounds(registrationResponse: string) {
	const tuple = registrationResponse.expectOk().expectTuple() as any;
	return {
		start: parseInt(tuple.start.substring(1)),
		end: parseInt(tuple.end.substring(1))
	};
}

export function extractParameters(parametersResponse: string) {
	const tuple = parametersResponse.expectOk().expectTuple() as any;
	return {
		maxStepSize: parseInt(tuple["max-step-size"].substring(1)),
		walkPosition: parseInt(tuple["walk-position"].substring(1)),
		ticketsForSale: parseInt(tuple["total-tickets"].substring(1))
	};
}