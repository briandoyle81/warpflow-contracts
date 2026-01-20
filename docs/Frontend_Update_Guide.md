# Frontend Update Guide - Contract Changes

## Overview
This document outlines the breaking changes and new features in the Ships contract that require frontend updates.

**Last Deployment:** October 17, 2025 (Commit: d4fd6a5 - "bugfix and redeploy")
**Current State:** December 2025 (Commit: "Refactor tiers to 0-based indexing and remove purchaseTiers array")

## Complete Function Change List

### Functions with Signature Changes (BREAKING)

#### `createShips` - Ships.sol
**Previous:**
```solidity
function createShips(address _to, uint _amount) public
```

**Current:**
```solidity
function createShips(address _to, uint _amount, uint16 _variant, uint8 _tier) external
```

**Changes:**
- Added `_variant` parameter (uint16)
- Added `_tier` parameter (uint8)
- Changed visibility: `public` → `external`

#### `purchaseWithFlow` - Ships.sol
**Previous:**
```solidity
function purchaseWithFlow(address _to, uint _tier, address _referral) public payable
```

**Current:**
```solidity
function purchaseWithFlow(address _to, uint8 _tier, address _referral, uint16 _variant) external payable
```

**Changes:**
- `_tier` type: `uint` → `uint8`
- Added `_variant` parameter (uint16)
- Changed visibility: `public` → `external`

#### `purchaseWithUC` - ShipPurchaser.sol
**Previous:**
```solidity
function purchaseWithUC(address _to, uint _tier, address _referral) public nonReentrant
```

**Current:**
```solidity
function purchaseWithUC(address _to, uint8 _tier, address _referral, uint16 _variant) public nonReentrant
```

**Changes:**
- `_tier` type: `uint` → `uint8`
- Added `_variant` parameter (uint16)

#### `constructSpecificShip` → `customizeShip` - Ships.sol
**Previous:**
```solidity
function constructSpecificShip(uint _id, Ship memory _ship) public
```

**Current:**
```solidity
function customizeShip(uint _id, Ship calldata _ship) external
```

**Changes:**
- Function renamed: `constructSpecificShip` → `customizeShip`
- Removed reroll parameters (was: `bool _rerollName, bool _rerollColors`)
- Parameter type: `Ship memory` → `Ship calldata`
- Changed visibility: `public` → `external`
- Behavior changed: No longer requires ship to be unconstructed

#### `claimFreeShips` - Ships.sol
**Previous:**
```solidity
function claimFreeShips() public
```

**Current:**
```solidity
function claimFreeShips(uint16 _variant) external
```

**Changes:**
- Added `_variant` parameter (uint16)
- Changed visibility: `public` → `external`

#### `constructShips` - Ships.sol
**Previous:**
```solidity
function constructShips(uint[] memory _ids) public
```

**Current:**
```solidity
function constructShips(uint[] calldata _ids) external
```

**Changes:**
- Parameter type: `uint[] memory` → `uint[] calldata`
- Changed visibility: `public` → `external`

### Functions with Visibility Changes Only (Non-Breaking)

These functions changed from `public` to `external` but maintain the same signature:

- `constructAllMyShips()` - Ships.sol
- `setCostOfShip(uint _id)` - Ships.sol
- `setInFleet(uint _id, bool _inFleet)` - Ships.sol
- `setTimestampDestroyed(uint _id, uint _destroyerId)` - Ships.sol
- `setPaused(bool _paused)` - Ships.sol
- `withdraw()` - Ships.sol
- `setRecycleReward(uint _newReward)` - Ships.sol
- `getShip(uint _id)` - Ships.sol
- `isShipDestroyed(uint _id)` - Ships.sol
- `getTierOfTrait(uint _trait)` - Ships.sol

### Functions Removed

- `getCurrentCostsVersion()` - Ships.sol (removed from IShips interface)
- `setNumberOfVariants(uint8 _numberOfVariants)` - Ships.sol (replaced by `setMaxVariant`)
- `setUniversalCredits(address _universalCredits)` - Ships.sol (now set via `setConfig`)

### Functions Added

- `_getKillsForRank(uint8 rank)` - Ships.sol (internal, pure)
- `_calculateModifications(Ship storage, Ship memory)` - Ships.sol (internal, view)
- `setClaimCooldownPeriod(uint256 _period)` - Ships.sol (external, onlyOwner)
- `purchaseUTCWithFlow(address _to, uint _tier)` - ShipPurchaser.sol (public, payable)
  - **Note**: Now mints UTC 1:1 with FLOW price (not based on recycle rewards)
- `withdrawFlow()` - ShipPurchaser.sol (public, onlyOwner)

### Functions with Internal Changes Only

- `_mintShip` - Ships.sol
  - **Previous:** `function _mintShip(address _to) internal`
  - **Current:** `function _mintShip(address _to, uint16 _variant, uint16 _shipsDestroyed) internal`
  - Added `_variant` and `_shipsDestroyed` parameters

- `_processReferral` - Ships.sol
  - Referral percentage logic changed (0% default instead of 1%)
  - Removed 100 ships threshold

- `constructShip` - Ships.sol
  - Now preserves existing `shipsDestroyed` if > 0 (for tier-based purchases)

## Breaking Changes

### 1. `createShips` Function Signature Changed

**Previous Signature:**
```solidity
function createShips(address _to, uint _amount, uint16 _variant) external
```

**New Signature:**
```solidity
function createShips(address _to, uint _amount, uint16 _variant, uint8 _tier) external
```

**Impact:**
- All calls to `createShips` must now include a `_tier` parameter
- `_tier` parameter (0-based indexing):
  - `0` = Tier 0: 1 ship with Rank 1, rest random
  - `1` = Tier 1: 2 ships with Rank 2 and Rank 1, rest random
  - `2` = Tier 2: 3 ships with Rank 3, Rank 2, Rank 1, rest random
  - `3` = Tier 3: 4 ships with Rank 4, Rank 3, Rank 2, Rank 1, rest random
  - `4` = Tier 4: 5 ships with Rank 5, Rank 4, Rank 3, Rank 2, Rank 1, rest random

**Migration:**
```typescript
// OLD
await ships.write.createShips([to, amount, variant]);

// NEW
await ships.write.createShips([to, amount, variant, tier]);
```

### 2. `customizeShip` Function Signature Changed

**Previous Signature:**
```solidity
function customizeShip(uint _id, Ship memory _ship, bool _rerollName, bool _rerollColors) external
```

**New Signature:**
```solidity
function customizeShip(uint _id, Ship calldata _ship) external
```

**Impact:**
- Removed `_rerollName` and `_rerollColors` parameters
- Name and color rerolling functionality has been removed
- Names and colors are now always preserved from the provided `_ship` parameter

**Migration:**
```typescript
// OLD
await ships.write.customizeShip([id, ship, true, false]);

// NEW
await ships.write.customizeShip([id, ship]);
```

### 3. `purchaseWithFlow` and `purchaseWithUC` Tier Parameter Type Changed

**Previous:**
```solidity
function purchaseWithFlow(address _to, uint _tier, address _referral, uint16 _variant) external payable
```

**New:**
```solidity
function purchaseWithFlow(address _to, uint8 _tier, address _referral, uint16 _variant) external payable
```

**Impact:**
- `_tier` parameter is now `uint8` instead of `uint`
- TypeScript/JavaScript calls should use number type (0-255) instead of BigInt

**Migration:**
```typescript
// OLD (may have worked with number, but now explicitly uint8)
await ships.write.purchaseWithFlow([to, tier, referral, variant], { value: price });

// NEW (same, but ensure tier is a number 0-255)
await ships.write.purchaseWithFlow([to, tier as number, referral, variant], { value: price });
```

## New Features

### 1. Tier-Based Rank Distribution System

When purchasing ships by tier, the first N ships receive preset ranks based on the tier purchased.

**⚠️ BREAKING CHANGE: Tiers are now 0-based (0-4) instead of 1-based (1-5)**

**Rank Distribution:**
- **Tier 0** (index 0): 5 ships total → 1 Rank 1 ship, 4 random
- **Tier 1** (index 1): 11 ships total → 1 Rank 2 ship, 1 Rank 1 ship, 9 random
- **Tier 2** (index 2): 28 ships total → 1 Rank 3 ship, 1 Rank 2 ship, 1 Rank 1 ship, 25 random
- **Tier 3** (index 3): 60 ships total → 1 Rank 4 ship, 1 Rank 3 ship, 1 Rank 2 ship, 1 Rank 1 ship, 56 random
- **Tier 4** (index 4): 125 ships total → 1 Rank 5 ship, 1 Rank 4 ship, 1 Rank 3 ship, 1 Rank 2 ship, 1 Rank 1 ship, 120 random

**Rank Thresholds:**
- **Rank 1**: 0-9 kills (0% bonus)
- **Rank 2**: 10-29 kills (10% bonus)
- **Rank 3**: 30-99 kills (20% bonus)
- **Rank 4**: 100-299 kills (30% bonus)
- **Rank 5**: 300-999 kills (40% bonus)
- **Rank 6**: 1000+ kills (50% bonus)

**Implementation Details:**
- Ships with preset ranks have their `shipsDestroyed` value set at mint time
- These kills are preserved during `constructShip` (not overwritten by random generation)
- `claimFreeShips` always generates random ships (no tier-based ranks)

**Frontend Impact:**
- ⚠️ **CRITICAL**: Update all tier references from 1-5 to 0-4
- When displaying purchased ships, the first N ships (where N = tier + 1) will have preset ranks
- UI should indicate which ships have preset ranks vs random generation
- Rank calculation uses new thresholds (not digit-based)
- Update tier selection UI to show "Tier 0", "Tier 1", etc. (0-based)

### 2. Updated Referral System

**Previous System:**
- Default: 1% for all referrals
- Tiers: 100, 1000, 10000, 50000, 100000 ships
- Percentages: 1%, 10%, 20%, 35%, 50%

**New System:**
- Default: 0% for referrals with < 1000 ships sold
- Tiers: 1000, 10000, 50000, 100000 ships
- Percentages: 0%, 10%, 20%, 35%, 50%

**Frontend Impact:**
- Update referral percentage display logic
- Remove 100 ships threshold from UI
- Show 0% for referrers with < 1000 ships sold
- Update referral tier progression display

## Function Visibility Changes

The following functions were changed from `public` to `external` (no impact on frontend, but listed for completeness):
- `createShips`
- `purchaseWithFlow`
- `setCostOfShip`
- `setInFleet`
- `setTimestampDestroyed`
- `setPaused`
- `withdraw`
- `setMaxVariant`
- `setRecycleReward`
- `isShipDestroyed`
- `getTierOfTrait`

**Impact:** None for frontend - these are still callable externally, just more gas-efficient.

## Removed Functions/Features

### 1. Name Rerolling
- `_rerollName` parameter removed from `customizeShip`
- Names can no longer be rerolled
- Names are always preserved from the provided ship data

### 2. Color Rerolling
- `_rerollColors` parameter removed from `customizeShip`
- Colors can no longer be rerolled
- Colors are always preserved from the provided ship data

**Frontend Impact:**
- Remove any UI elements for name/color rerolling
- Remove reroll checkboxes or toggles from ship customization UI
- Update ship customization forms to not include reroll options

## Updated Rank Calculation

**Previous System:**
- Rank = number of digits in `shipsDestroyed`
- Example: 100 kills = 3 digits = Rank 3

**New System:**
- Rank based on threshold ranges:
  - 0-9 kills → Rank 1
  - 10-29 kills → Rank 2
  - 30-99 kills → Rank 3
  - 100-299 kills → Rank 4
  - 300-999 kills → Rank 5
  - 1000+ kills → Rank 6

**Frontend Impact:**
- Update rank calculation logic in frontend
- Replace digit-counting with threshold-based lookup
- Update rank display to show correct ranks for all kill counts

## Ship Generation Changes

**Random Generation:**
- Still uses weighted distribution
- 75%: Rank 1 (1-9 kills)
- 15%: Rank 2 (10-29 kills)
- 5%: Rank 3 (30-99 kills)
- 4%: Rank 4 (100-299 kills)
- 1%: Rank 5 (300-999 kills)
- 0%: Rank 6 (cannot be randomly generated)

**Tier-Based Generation:**
- First N ships (N = tier) get preset ranks
- Remaining ships are random
- Example: Tier 5 purchase gives 6 ships total:
  1. Rank 6 (1000 kills)
  2. Rank 5 (300 kills)
  3. Rank 4 (100 kills)
  4. Rank 3 (30 kills)
  5. Rank 2 (10 kills)
  6. Random (0-999 kills)

## Testing Checklist

When updating the frontend, verify:

1. ✅ All `createShips` calls include `_tier` parameter
2. ✅ All `customizeShip` calls removed reroll parameters
3. ✅ Ship purchase flows work with new tier-based rank distribution
4. ✅ Rank calculation uses new thresholds
5. ✅ Referral percentage display shows 0% for < 1000 ships
6. ✅ Ship customization UI removed reroll options
7. ✅ Tier purchase displays show which ships have preset ranks
8. ✅ Free ship claims generate random ships (no tier ranks)

## State Variable Changes

### Ships.sol

**Removed:**
- `mapping(address => bool) public hasClaimedFreeShips` → Replaced with `lastClaimTimestamp`
- `mapping(address => uint) public onboardingStep` → Removed
- `uint8[] public referralPercentages` → Hardcoded in `_processReferral` function
- `uint32[] public referralStages` → Hardcoded in `_processReferral` function
- `uint16 numberOfVariants` → Replaced with `maxVariant`

**Added:**
- `mapping(address => uint256) public lastClaimTimestamp` → Tracks last free ship claim time
- `uint256 public claimCooldownPeriod = 28 days` → Cooldown period for free ship claims
- `uint16 public maxVariant = 1` → Maximum variant number

**Frontend Impact:**
- Update free ship claim logic to use `lastClaimTimestamp` instead of `hasClaimedFreeShips`
- Remove any references to `onboardingStep`
- Referral tiers are now hardcoded (no need to read from state)

### ShipPurchaser.sol

**Changed:**
- `referralStages` array: Removed `100` threshold (now starts at `1000`)
- `referralPercentages` default: Changed from `1` to `0` in `_processReferral`

**Added:**
- `IUniversalCredits public immutable universalCreditsMintable` → For direct UTC purchases

## Contract Addresses

**Last Deployment (October 17, 2025):**
- Ships: `0x4eEC90082Af04fb9E4E57da108Aaa14Ac6853488`
- ShipPurchaser: `0x5DA856DbF3b88893748F8F0e6d733d63325252FC`
- ShipAttributes: `0xFb735aa5171B5ccA2aE6dD97D6D7926FBa93aEEd`

*Note: These addresses will change after redeployment. Use addresses from your deployment configuration.*

## Additional Notes

- The `locked` function (ERC-5192) is commented out but still present in code
- All events remain the same
- ERC-721 interface remains unchanged
- Ship data structure (`Ship` struct) remains unchanged
- `getCurrentCostsVersion()` removed from IShips interface (still exists in ShipAttributes contract)
