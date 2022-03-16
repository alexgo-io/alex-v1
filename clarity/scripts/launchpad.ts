export class LCG {
	a: number;
	c: number;
	m: number;

	constructor(a: number, c: number, m: number) {
		this.a = a;
		this.c = c;
		this.m = m;
	}

	next(current: number, maxStep: number = 0) {
		// to avoid overflow, cast numbers to bigint first.
		const next = (BigInt(current) * BigInt(this.a) + BigInt(this.c)) % BigInt(this.m);
		return maxStep > 1 ? Number(next % BigInt(maxStep)) : Number(next);
	}
}

export const walkResolution = 100000;

const idoLcgA = 134775813;
const idoLcgC = 1;
const idoLcgM = 4294967296;

export class IDOLCG extends LCG {
	constructor() {
		super(idoLcgA, idoLcgC, idoLcgM);
	}
}

export type IdoParameters = { maxStepSize: number, walkPosition: number, ticketsForSale: number, activationThreshold: number };
export type IdoParticipant = { participant: string, start: number, end: number };
export type IdoResult = { nextParameters: IdoParameters, winners: string[], losers: { recipient: string, amount: number }[] };
export type IdoWinnersResult = { nextParameters: IdoParameters, winners: string[] };
export type IdoLosersResult = { nextParameters: IdoParameters, losers: { recipient: string, amount: number }[] };

/**
 * Takes walk parameters and a participant list and will return a winners list that can be submitted
 * to the claim-* IDO contract functions directly. It also returns updated walk parameters to be
 * set for the next iteration in case winners are deteremined in chunks.
 * @param parameters Initial walk parameters (or continued walk parameters)
 * @param participants A list of participants, sorted in order. There should be no gaps in the bounds.
 * @returns A winners result set and walk parameters for the next iteration.
 */
export function determineOutcome(parameters: IdoParameters, participants: IdoParticipant[]): IdoResult {
	let { walkPosition, maxStepSize, ticketsForSale, activationThreshold } = parameters;
	let winners: string[] = [];
	let losers: { recipient: string, amount: number }[] = [];
	const lcg = new IDOLCG();
	participants.sort((a, b) => a.start < b.start ? -1 : 0);
	let lastUpperBound = 0;	
	const succeeded = participants[participants.length - 1]['end'] / walkResolution >= activationThreshold;
	participants.forEach(entry => {
		if (lastUpperBound !== entry.start)
			throw new Error(`Error, gap in bound detected for boundary ${entry.start}`);
		let ticketsLost = (entry.end - entry.start) / walkResolution;
		if (succeeded) {
			while (walkPosition >= entry.start && walkPosition < entry.end && winners.length < ticketsForSale && ticketsLost > 0) {	
				--ticketsLost;
				winners.push(entry.participant);
				walkPosition = (Math.floor(walkPosition / walkResolution) + 1) * walkResolution + lcg.next(walkPosition, maxStepSize);		
			}
		}		
		if (ticketsLost > 0) losers.push({ recipient: entry.participant, amount: ticketsLost });
		lastUpperBound = entry.end;
	});
	return { nextParameters: { walkPosition, maxStepSize, ticketsForSale, activationThreshold }, winners, losers };
}

export function determineWinners(parameters: IdoParameters, participants: IdoParticipant[]): IdoWinnersResult {
	let idoResult: IdoResult = determineOutcome(parameters, participants);
	return {nextParameters: idoResult.nextParameters, winners: idoResult.winners};
}

export function determineLosers(parameters: IdoParameters, participants: IdoParticipant[]): IdoLosersResult {
	let idoResult: IdoResult = determineOutcome(parameters, participants);
	return {nextParameters: idoResult.nextParameters, losers: idoResult.losers};
}
