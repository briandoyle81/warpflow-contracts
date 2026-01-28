import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-gas-reporter";

require("hardhat-contract-sizer");
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      // viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    // only: [":ERC20$"],
  },
  etherscan: {
    apiKey: {
      "flow-testnet": "abc",
      flow: "abc",
    },
    customChains: [
      {
        network: "flow",
        chainId: 747,
        urls: {
          apiURL: "https://evm.flowscan.io/api",
          browserURL: "https://evm.flowscan.io",
        },
      },
      {
        network: "flow-testnet",
        chainId: 545,
        urls: {
          apiURL: "https://evm-testnet.flowscan.io/api",
          browserURL: "https://evm-testnet.flowscan.io",
        },
      },
      {
        network: "ronin-saigon",
        chainId: 2021,
        urls: {
          apiURL: "https://saigon-testnet.roninchain.com/rpc",
          browserURL: "https://saigon-app.roninchain.com/",
        },
      },
    ],
  },
  networks: {
    // for testnet
    "base-sepolia": {
      url: "https://sepolia.base.org",
      accounts: [process.env.METAMASK_WALLET_1 as string],
    },
    "flow-testnet": {
      url: "https://testnet.evm.nodes.onflow.org",
      accounts: [process.env.METAMASK_WALLET_1 as string],
      gas: 500000,
    },
    // CRITICAL: CHANGE NAMES CONTRACT ADDRESS BEFORE ADDING AND DEPLOYING ON MAINNET
  },
  gasReporter: {
    // currency: "USD",
    // L1: "ethereum",
    // L2: "base",
    // L1Etherscan: process.env.ETHERSCAN_API_KEY,
    // L2Etherscan: process.env.BASESCAN_API_KEY,
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: true,
  },
};

export default config;
