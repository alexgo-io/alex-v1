import { readFileSync, writeFileSync } from 'fs';
import { execSync } from 'child_process';

const lines = execSync('grep "(define-constant ERR-" ../clarity -nrH', {
  cwd: __dirname,
})
  .toString()
  .split('\n')
  .filter(Boolean);

const errorCodePath = `${__dirname}/../clarity/errorCodes.json`;
const original = JSON.parse(readFileSync(errorCodePath, 'utf8'));
const result: { [key: string]: { code: string; comment?: string } } = {};
const regex = /define-constant (ERR-[^ ]+) \(err u(\d+)\)/;

for (const line of lines) {
  const [name, code] = line.match(regex)!.slice(1); //?
  if (code in result) {
    continue;
  }
  result[code] = {
    code: name,
    comment: original[code]?.comment ?? name,
  };
}

writeFileSync(errorCodePath, JSON.stringify(result, null, 2), {
  encoding: 'utf-8',
});
