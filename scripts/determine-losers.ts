import { determineLosers } from "../lib/launchpad.ts";

const [, , inputParameters, list] = process.argv;

if (!list) {
	console.log('Usage: npm run determine-losers <input parameters JSON> <IDO participant list JSON>');
	console.log('Input parameters JSON is in the following format:');
	console.log('{ "maxStepSize": 30000, "walkPosition": 0 }');
	console.log('IDO participant list JSON is in the following format:');
	console.log('[ {"participant": "SP123...", "start": 0, "end": 100}, {"participant": "SP456...", "start": 100, "end": 200}, ... ]');
	console.log('Example call:');
	console.log(`npm run determine-losers '{"maxStepSize": 600000, "walkPosition": 371421, "ticketsForSale": 10}' '[ {"participant": "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG", "start": 0, "end": 1000000}, {"participant": "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC", "start": 1000000, "end": 3000000} ]'`);
	process.exit(0);
}

function jsonParseSafe(json: string) {
	try {
		return JSON.parse(json);
	}
	catch (e) {
		return null;
	}
}

const [inputParametersParsed, listParsed] = [inputParameters, list].map(jsonParseSafe);

if (!inputParametersParsed || !listParsed) {
	console.log('Invalid JSON input, did you make a typo?');
	process.exit(1);
}

const result = determineLosers(inputParametersParsed, listParsed);

console.log('Parameters:', inputParametersParsed);
console.log('Loser count:', result.losers.length);
console.log('Losers:', result);
