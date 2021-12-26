const {versions, c32addressDecode, c32address} = require('c32check');

const testnet_address = 'ST2X2FYCY01Y7YR2TGC2Y6661NFF3SMH0NGXPWTV5';

const [version, hash160] = c32addressDecode(testnet_address);

let singlesig = true;

switch (version)
	{
	case versions.mainnet.p2pkh:
		console.log('mainnet single-sig');
		break;
	case versions.mainnet.p2sh:
		console.log('mainnet multi-sig');
		singlesig = false;
		break;
	case versions.testnet.p2pkh:
		console.log('testnet single-sig');
		break;
	case versions.testnet.p2sh:
		console.log('testnet multi-sig');
		singlesig = false;
		break;
	}

console.log('hash160: ', hash160);

const type = singlesig ? 'p2pkh' : 'p2sh';

console.log('Mainnet: ', c32address(versions.mainnet[type], hash160));
console.log('Testnet: ', c32address(versions.testnet[type], hash160));

console.log('Test ', c32address(versions.mainnet['p2sh'], '0bc3535944ad536a585c9eb2e705cf890e1fd1ea'));