const toml = require("@iarna/toml");
const fs = require("fs");
const path = require("path");
const { pick } = require("lodash");

function extract(targetContracts, filePath) {
  const clarinetConfig = toml.parse(fs.readFileSync(filePath));
  const contracts = clarinetConfig.contracts;

  const dependencies = [];

  for (const targetContract of targetContracts) {
    contracts[targetContract].depends_on.forEach((contract) => {
      dependencies.push(contract);
    });
  }

  const buildContracts = new Set();

  const addDependencyRecursively = (targetContracts) => {
    targetContracts.forEach((t) => buildContracts.add(t));
    targetContracts.forEach((t) => {
      addDependencyRecursively(contracts[t].depends_on);
    });
  };

  addDependencyRecursively(targetContracts);
  /*? Array.from(buildContracts)*/
  const targetConfig = {
    ...clarinetConfig,
    contracts: pick(contracts, Array.from(buildContracts)),
  };

  return targetConfig; /*?*/
}

function load(env) {
  const clarinetConfig = toml.parse(
    fs.readFileSync(path.resolve(__dirname, `Clarinet.${env}.toml`))
  );
  if (env === "dev") {
    return extract(
      clarinetConfig.contracts,
      path.join(__dirname, "Clarinet.base.toml"),
      "utf8"
    );
  }
}

function save(tomlContent, filePath) {
  fs.writeFileSync(filePath, toml.stringify(tomlContent));
}

save(load("dev"), path.resolve(__dirname, "Clarinet.toml"));
