import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-gas-reporter";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: process.env.BASECAN_API_KEY || "", // used with npx hardhat verify <address> --network mumbai
    customChains: [
      {
        network: "base-goerli",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
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
  // gasReporter: {
  //   currency: "USD",
  //   L1: "ethereum",
  //   L2: "base",
  //   L1Etherscan: process.env.ETHERSCAN_API_KEY,
  //   L2Etherscan: process.env.BASESCAN_API_KEY,
  //   coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  //   enabled: true,
  // },
};

export default config;
