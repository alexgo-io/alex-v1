import { Account, Tx, types } from "./deps.ts";
import { Client } from "./client.ts";

enum ContractState {
  STATE_DEPLOYED = 0,
  STATE_ACTIVE,
  STATE_INACTIVE,
}

enum ErrCode {
  ERR_UNAUTHORIZED = 1000,  
  ERR_UNKNOWN_JOB = 9000,
  ERR_JOB_IS_ACTIVE = 9001,
  ERR_JOB_IS_NOT_ACTIVE = 9002,
  ERR_ALREADY_VOTED_THIS_WAY = 9003,
  ERR_JOB_IS_EXECUTED = 9004,
  ERR_JOB_IS_NOT_APPROVED = 9005,
  ERR_ARGUMENT_ALREADY_EXISTS = 9006,
  ERR_NO_ACTIVE_CORE_CONTRACT = 9007,
  ERR_CORE_CONTRACT_NOT_FOUND = 9008,
}

export class AuthClient extends Client {
  static readonly ErrCode = ErrCode;
  static readonly ContractState = ContractState;
  static readonly REQUIRED_APPROVALS = 3;

  getLastJobId() {
    return this.callReadOnlyFn("get-last-job-id");
  }

  createJob(name: string, target: string, sender: Account) {
    return Tx.contractCall(
      this.contractName,
      "create-job",
      [types.ascii(name), types.principal(target)],
      sender.address
    );
  }

  getJob(jobId: number) {
    return this.callReadOnlyFn("get-job", [types.uint(jobId)]);
  }

  activateJob(jobId: number, sender: Account) {
    return Tx.contractCall(
      this.contractName,
      "activate-job",
      [types.uint(jobId)],
      sender.address
    );
  }

  approveJob(jobId: number, approver: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "approve-job",
      [types.uint(jobId)],
      approver.address
    );
  }

  disapproveJob(jobId: number, approver: Account) {
    return Tx.contractCall(
      this.contractName,
      "disapprove-job",
      [types.uint(jobId)],
      approver.address
    );
  }

  isJobApproved(jobId: number) {
    return this.callReadOnlyFn("is-job-approved", [types.uint(jobId)]);
  }

  markJobAsExecuted(jobId: number, sender: Account) {
    return Tx.contractCall(
      this.contractName,
      "mark-job-as-executed",
      [types.uint(jobId)],
      sender.address
    );
  }

  addUIntArgument(
    jobId: number,
    argumentName: string,
    value: number,
    sender: Account
  ) {
    return Tx.contractCall(
      this.contractName,
      "add-uint-argument",
      [types.uint(jobId), types.ascii(argumentName), types.uint(value)],
      sender.address
    );
  }

  getUIntValueByName(jobId: number, argumentName: string) {
    return this.callReadOnlyFn("get-uint-value-by-name", [
      types.uint(jobId),
      types.ascii(argumentName),
    ]);
  }

  getUIntValueById(jobId: number, argumentId: number) {
    return this.callReadOnlyFn("get-uint-value-by-id", [
      types.uint(jobId),
      types.uint(argumentId),
    ]);
  }

  addPrincipalArgument(
    jobId: number,
    argumentName: string,
    value: string,
    sender: Account
  ) {
    return Tx.contractCall(
      this.contractName,
      "add-principal-argument",
      [types.uint(jobId), types.ascii(argumentName), types.principal(value)],
      sender.address
    );
  }

  getPrincipalValueByName(jobId: number, argumentName: string) {
    return this.callReadOnlyFn("get-principal-value-by-name", [
      types.uint(jobId),
      types.ascii(argumentName),
    ]);
  }

  getPrincipalValueById(jobId: number, argumentId: number) {
    return this.callReadOnlyFn("get-principal-value-by-id", [
      types.uint(jobId),
      types.uint(argumentId),
    ]);
  }

  getActiveCoreContract() {
    return this.callReadOnlyFn("get-active-core-contract");
  }

  getCoreContractInfo(targetContract: string) {
    return this.callReadOnlyFn("get-core-contract-info", [
      types.principal(targetContract),
    ]);
  }

  initializeContracts(targetContract: string, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "initialize-contracts",
      [types.principal(targetContract)],
      sender.address
    );
  }

  activateCoreContract(
    targetContract: string,
    stacksHeight: number,
    sender: Account
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "activate-core-contract",
      [types.principal(targetContract), types.uint(stacksHeight)],
      sender.address
    );
  }

  upgradeCoreContract(
    oldContract: string,
    newContract: string,
    sender: Account
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "upgrade-core-contract",
      [types.principal(oldContract), types.principal(newContract)],
      sender.address
    );
  }

  executeUpgradeCoreContractJob(
    jobId: number,
    oldContract: string,
    newContract: string,
    sender: Account
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "execute-upgrade-core-contract-job",
      [
        types.uint(jobId),
        types.principal(oldContract),
        types.principal(newContract),
      ],
      sender.address
    );
  }

  getCityWallet() {
    return this.callReadOnlyFn("get-city-wallet");
  }

  setCityWallet(
    requestor: string,
    newCityWallet: Account,
    sender: Account
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-city-wallet",
      [types.principal(requestor), types.principal(newCityWallet.address)],
      sender.address
    );
  }

  setTokenUri(
    sender: Account,
    target: string,
    newUri: string
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "set-token-uri",
      [
        types.principal(target),
        types.utf8(newUri),
      ],
      sender.address
    );
  }

  executeSetCityWalletJob(
    jobId: number,
    targetContract: string,
    sender: Account
  ): Tx {
    return Tx.contractCall(
      this.contractName,
      "execute-set-city-wallet-job",
      [types.uint(jobId), types.principal(targetContract)],
      sender.address
    );
  }

  isApprover(user: Account) {
    return this.callReadOnlyFn("is-approver", [types.principal(user.address)]);
  }

  executeReplaceApproverJob(jobId: number, sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "execute-replace-approver-job",
      [types.uint(jobId)],
      sender.address
    );
  }

  testSetActiveCoreContract(sender: Account): Tx {
    return Tx.contractCall(
      this.contractName,
      "test-set-active-core-contract",
      [],
      sender.address
    );
  }
}