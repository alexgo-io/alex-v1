const [, , inputParameters, list] = process.argv;

const idoLcgA = 134775813;
const idoLcgC = 1;
const idoLcgM = 4294967296;

if (!list) {
	console.log('Usage: npm run determine-winners <input parameters JSON> <IDO participant list JSON>');
	console.log('Input parameters JSON is in the following format:');
	console.log('{ "maxStepSize": 30000, "walkPosition": 0 }');
	console.log('IDO participant list JSON is in the following format:');
	console.log('[ {"participant": "SP123...", "start": 0, "end": 100}, {"participant": "SP456...", "start": 100, "end": 200}, ... ]');
	console.log('Example call:');
	console.log(`npm run determine-winners '{"maxStepSize": 600000, "walkPosition": 371421}' '[ {"participant": "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG", "start": 0, "end": 1000000}, {"participant": "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC", "start": 1000000, "end": 3000000} ]'`);
	process.exit(0);
}

class LCG {
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

type IdoParameters = { maxStepSize: number, walkPosition: number };
type IdoParticipant = { participant: string, start: number, end: number };
type IdoWinnersResult = { nextParameters: IdoParameters, winners: string[] };

function determineWinners(lcg: LCG, parameters: IdoParameters, participants: IdoParticipant[]): IdoWinnersResult {
	let { walkPosition, maxStepSize } = parameters;
	let winners: string[] = [];
	participants.sort((a, b) => a.start < b.start ? -1 : 0);
	participants.forEach(entry => {
		while (walkPosition >= entry.start && walkPosition < entry.end) {
			winners.push(entry.participant);
			walkPosition += lcg.next(walkPosition, maxStepSize);
			if (walkPosition >= entry.end)
				return;
		}
		walkPosition += lcg.next(walkPosition, maxStepSize);
	});
	return { nextParameters: { walkPosition, maxStepSize }, winners };
}

function jsonParseSafe(json: string) {
	try {
		return JSON.parse(json);
	}
	catch (e) {
		return null;
	}
}

const lcg = new LCG(idoLcgA, idoLcgC, idoLcgM);

const [inputParametersParsed, listParsed] = [inputParameters, list].map(jsonParseSafe);

if (!inputParametersParsed || !listParsed) {
	console.log('Invalid JSON input, did you make a typo?');
	process.exit(1);
}

const result = determineWinners(lcg, inputParametersParsed, listParsed);

console.log('Parameters:', inputParametersParsed);
console.log('Winner count:', result.winners.length);
console.log('Winners:', result);
