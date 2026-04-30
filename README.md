# Void Tactics Contracts

Smart contracts for Void Tactics, an onchain tactical strategy game with NFT ships, configurable fleets, map/lobby flow, and battle outcomes recorded onchain.

This repository contains the Solidity contracts, Hardhat configuration, and Ignition deployment modules used to deploy and wire the game system.

## Current Status

- Active testnet alpha.
- Contracts and deployment workflows are under active iteration.
- Backward compatibility and storage migration guarantees are not yet finalized.

## Tech Stack

- Solidity `0.8.28`
- Hardhat + Ignition
- Viem tooling via `@nomicfoundation/hardhat-toolbox-viem`
- OpenZeppelin Contracts

## Quick Start

### 1) Install dependencies

```bash
npm install
```

### 2) Configure environment

Create a `.env` file in the repository root:

```env
METAMASK_WALLET_1=0xYOUR_PRIVATE_KEY
```

### 3) Compile contracts

```bash
npx hardhat compile
```

### 4) Run tests

```bash
npx hardhat test
```

## Deployment

Default deployment module:

- `ignition/modules/DeployAndConfig.ts`

Deploy and verify on Flow testnet:

```bash
npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts --network flow-testnet --verify
```

Retry helper script for interrupted Ignition deploys:

```bash
./scripts/ignition-deploy-retry.sh --network flow-testnet --deploy-script ignition/modules/DeployAndConfig.ts
```

## Repository Structure

- `contracts/` - core game contracts and token/NFT logic
- `ignition/modules/` - Hardhat Ignition deployment modules
- `test/` - contract tests
- `scripts/` - deployment and maintenance scripts
- `docs/` - supporting notes and project documentation

## Notes for Reviewers

- The deployment module handles contract orchestration and post-deploy configuration in one flow.
- Contract sizing is enforced during compile via `hardhat-contract-sizer`.
- Several testnets are configured in `hardhat.config.ts` for multi-network iteration.
- Internal planning notes and TODOs are tracked in `docs/internal-todos.md`.

## License / Usage

All rights reserved unless otherwise stated.  
This repository is shared for evaluation and learning; reuse in production or derivative commercial projects requires explicit permission.
