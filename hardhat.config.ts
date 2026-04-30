import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-gas-reporter";

require("hardhat-contract-sizer");
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      // viaIR: true, // Yul stack issues in this repo; runs:1 keeps Game under 24 KiB
      optimizer: {
        enabled: true,
        runs: 1,
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
        chainId: 202601,
        urls: {
          apiURL: "https://saigon-testnet.roninchain.com/rpc",
          browserURL: "https://saigon-explorer.roninchain.com/",
        },
      },
      {
        network: "polygon-amoy",
        chainId: 80002,
        urls: {
          apiURL: "	https://polygon-amoy.drpc.org",
          browserURL: "https://amoy.polygonscan.com",
        },
      },
      {
        network: "xai-testnet",
        chainId: 37714555429,
        urls: {
          apiURL: "https://testnet-v2.xai-chain.net/rpc",
          browserURL: "https://testnet-explorer-v2.xai-chain.net",
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
    "ronin-saigon": {
      url: "https://saigon-testnet.roninchain.com/rpc",
      accounts: [process.env.METAMASK_WALLET_1 as string],
      // Large Ignition deploys: default fee estimates can be "underpriced"; the tx may never
      // enter the mempool but Ignition still advances local nonce state → IGN411 on retry.
      ignition: {
        maxPriorityFeePerGas: 20_000_000_000n, // 20 gwei; raise if mempool still rejects
        maxFeePerGasLimit: 2_000_000_000_000n, // 2000 gwei ceiling for getNetworkFees guard only
      },
    },
    "polygon-amoy": {
      url: "https://polygon-amoy.drpc.org",
      accounts: [process.env.METAMASK_WALLET_1 as string],
    },
    "xai-testnet": {
      url: "https://testnet-v2.xai-chain.net/rpc",
      accounts: [process.env.METAMASK_WALLET_1 as string],
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
