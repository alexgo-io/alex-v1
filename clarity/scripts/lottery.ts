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

const lotteryLcgA = 134775813;
const lotteryLcgC = 1;
const lotteryLcgM = 4294967296;

export class LotteryLCG extends LCG {
	constructor() {
		super(lotteryLcgA, lotteryLcgC, lotteryLcgM);
	}
}

export type LotteryParameters = { maxStepSize: number, walkPosition: number, ticketsForSale: number };
export type LotteryParticipant = { participant: string, start: number, end: number };
export type LotteryResult = { nextParameters: LotteryParameters, winners: string[], losers: { recipient: string, amount: number }[] };
export type LotteryWinnersResult = { nextParameters: LotteryParameters, winners: string[] };
export type LotteryLosersResult = { nextParameters: LotteryParameters, losers: { recipient: string, amount: number }[] };


export function determineOutcome(parameters: LotteryParameters, participants: LotteryParticipant[]): LotteryResult {
	let { walkPosition, maxStepSize, ticketsForSale } = parameters;
	let winners: string[] = [];
	let losers: { recipient: string, amount: number }[] = [];
	const lcg = new LotteryLCG();
	participants.sort((a, b) => a.start < b.start ? -1 : 0);
	let lastUpperBound = 0;	
	participants.forEach(entry => {
		if (lastUpperBound !== entry.start)
			throw new Error(`Error, gap in bound detected for boundary ${entry.start}`);
		let ticketsLost = (entry.end - entry.start) / walkResolution;
		while (walkPosition >= entry.start && walkPosition < entry.end && winners.length < ticketsForSale && ticketsLost > 0) {	
			--ticketsLost;
			winners.push(entry.participant);
			walkPosition = (Math.floor(walkPosition / walkResolution) + 1) * walkResolution + lcg.next(walkPosition, maxStepSize);		
		}	
		if (ticketsLost > 0) losers.push({ recipient: entry.participant, amount: ticketsLost });
		lastUpperBound = entry.end;
	});
	return { nextParameters: { walkPosition, maxStepSize, ticketsForSale }, winners, losers };
}

export function determineWinners(parameters: LotteryParameters, participants: LotteryParticipant[]): LotteryWinnersResult {
	let lotteryResult: LotteryResult = determineOutcome(parameters, participants);
	return {nextParameters: lotteryResult.nextParameters, winners: lotteryResult.winners};
}

export function determineLosers(parameters: LotteryParameters, participants: LotteryParticipant[]): LotteryLosersResult {
	let lotteryResult: LotteryResult = determineOutcome(parameters, participants);
	return {nextParameters: lotteryResult.nextParameters, losers: lotteryResult.losers};
}
