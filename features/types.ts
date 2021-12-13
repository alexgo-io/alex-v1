export type Contract = {
  path: string;
  depends_on: string[];
};
export type Contracts = {
  [key: string]: Contract;
};
