import { Clarinet, Tx, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import type { Chain, Account } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.113.0/testing/asserts.ts';

export { Clarinet, Tx, types, assertEquals };
export type { Chain, Account };

export const ONE_8 = 100000000;

export type TicketAllocation = { recipient: Account | string, amount: number };
export type StandardTestParameters = {
	totalIdoTokens: number,
	idoOwner: Account,
	ticketsForSale: number,
	idoTokensPerTicket: number,
	pricePerTicketInFixed: number,
	activationThreshold?: number,
	registrationStartHeight?: number,
	registrationEndHeight?: number,
	claimEndHeight?: number,
	ticketRecipients: TicketAllocation[],
	apowerPerTicketInFixed: any[],
	registrationMaxTickets: number	
};

export const contractPrincipal = (address: Account | string, contractName: string) => `${(address as Account).address || address}.${contractName}`;

export function determineApower(tickets: number, apowerPerTicketInFixed: any[]){
	let apower = 0;
	let remaining_tickets = tickets;
	for(let i = 0; i < apowerPerTicketInFixed.length; i++){
		let tickets_to_process = (remaining_tickets < apowerPerTicketInFixed[i]['tierThreshold'] || i == apowerPerTicketInFixed.length - 1) ? remaining_tickets : apowerPerTicketInFixed[i]['tierThreshold'];
		remaining_tickets -= tickets_to_process;
		apower += apowerPerTicketInFixed[i]['apowerPerTicketInFixed'] * tickets_to_process;
	}
	return apower;
}

export function prepareStandardTest(chain: Chain, parameters: StandardTestParameters, deployer: Account) {
	const {
		totalIdoTokens,
		idoOwner,
		ticketsForSale,
		idoTokensPerTicket,
		pricePerTicketInFixed,
		activationThreshold,
		registrationStartHeight,
		registrationEndHeight,
		claimEndHeight,
		ticketRecipients,
		apowerPerTicketInFixed,
		registrationMaxTickets
	} = parameters;
	const first = chain.mineBlock([		
		Tx.contractCall("token-banana", "mint-fixed", [types.uint(totalIdoTokens * ticketsForSale * ONE_8), types.principal(idoOwner.address)], deployer.address),
		Tx.contractCall("token-apower", "add-approved-contract", [types.principal(contractPrincipal(deployer, "alex-launchpad-v1-1"))], deployer.address),
		...ticketRecipients.map(allocation => Tx.contractCall("token-apower", "mint-fixed", [types.uint(determineApower(allocation.amount, apowerPerTicketInFixed)), types.principal((allocation.recipient as Account).address || allocation.recipient as string)], deployer.address)),
		Tx.contractCall("alex-launchpad-v1-1", "create-pool", [
			types.principal(contractPrincipal(deployer, "token-wban")),
			types.principal(contractPrincipal(deployer, "token-wstx")),
			types.tuple({
				"ido-owner": types.principal(idoOwner.address),
				"ido-tokens-per-ticket": types.uint(idoTokensPerTicket),
				"price-per-ticket-in-fixed": types.uint(pricePerTicketInFixed),
				"activation-threshold": types.uint(activationThreshold || 1),
				"registration-start-height": types.uint(registrationStartHeight || 0),
				"registration-end-height": types.uint(registrationEndHeight || 10),
				"claim-end-height": types.uint(claimEndHeight || 20),
				"apower-per-ticket-in-fixed": types.list(apowerPerTicketInFixed.map(e => { return types.tuple( { 'apower-per-ticket-in-fixed': types.uint(e.apowerPerTicketInFixed), 'tier-threshold': types.uint(e.tierThreshold) } ) })),
				"registration-max-tickets": types.uint(registrationMaxTickets)
			}),
		], deployer.address),
	]);
	const idoId = parseInt(first.receipts[first.receipts.length - 1].result.expectOk().toString().substring(1));
	assertEquals(isNaN(idoId), false, "failed to get IDO ID");
	const second = chain.mineBlock([
		Tx.contractCall("alex-launchpad-v1-1", "add-to-position", [types.uint(idoId), types.uint(ticketsForSale), types.principal(contractPrincipal(deployer, "token-wban"))], idoOwner.address),
	]);
	return { idoId, blocks: [first, second] };
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
		ticketsForSale: parseInt(tuple["total-tickets"].substring(1)),
		activationThreshold: parseInt(tuple["activation-threshold"].substring(1))
	};
}