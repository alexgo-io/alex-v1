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
		const next = (current * this.a + this.c) % this.m;
		return maxStep > 1 ? next % maxStep : next;
	}
}

export type IdoParameters = { maxStepSize: number, walkPosition: number, ticketsForSale: number };
export type IdoParticipant = { participant: string, start: number, end: number };
export type IdoWinnersResult = { nextParameters: IdoParameters, winners: string[] };

export function determineWinners(lcg: LCG, parameters: IdoParameters, participants: IdoParticipant[]): IdoWinnersResult {
	let { walkPosition, maxStepSize, ticketsForSale } = parameters;
	let winners: string[] = [];
	participants.sort((a, b) => a.start < b.start ? -1 : 0);
	participants.forEach(entry => {
		while (walkPosition >= entry.start && walkPosition < entry.end) {
			if (winners.length >= ticketsForSale)
				return;
			winners.push(entry.participant);
			walkPosition += lcg.next(walkPosition, maxStepSize);
			if (walkPosition >= entry.end)
				return;
		}
		walkPosition += lcg.next(walkPosition, maxStepSize);
	});
	return { nextParameters: { walkPosition, maxStepSize, ticketsForSale }, winners };
}
