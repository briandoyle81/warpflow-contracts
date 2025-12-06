# Ships.sol Size Optimization Analysis

## Current State
- **Deployed Size**: 24.185 KB (exceeds 24 KB limit by ~185 bytes)
- **Init Size**: 25.653 KB
- **Status**: ⚠️ Exceeds mainnet deployment limit

## Estimated Savings Breakdown

### 1. Public → External + Calldata Optimization

#### Functions to Convert:
1. `constructShips(uint[] memory _ids)` → `constructShips(uint[] calldata _ids) external`
2. `constructAllMyShips()` → `constructAllMyShips() external`
3. `customizeShip(uint _id, Ship memory _ship, bool _rerollName)` → `customizeShip(uint _id, Ship calldata _ship, bool _rerollName) external`
4. `setPurchaseInfo(uint8[] memory _purchaseTiers, uint8[] memory _tierShips, uint[] memory _tierPrices)` → `setPurchaseInfo(uint8[] calldata _purchaseTiers, uint8[] calldata _tierShips, uint[] calldata _tierPrices) external`
5. `getShip(uint _id)` → `getShip(uint _id) external view`
6. `getShipIdsOwned(address _owner)` → `getShipIdsOwned(address _owner) external view`
7. `getShipsByIds(uint[] memory _ids)` → `getShipsByIds(uint[] calldata _ids) external view`
8. `getPurchaseInfo()` → `getPurchaseInfo() external view`
9. `claimFreeShips(uint16 _variant)` → `claimFreeShips(uint16 _variant) external`
10. `shipBreaker(uint[] calldata _shipIds)` → `shipBreaker(uint[] calldata _shipIds) external` (already has calldata, just needs external)

#### Savings Estimate:
- **Public → External**: Each public function generates an internal ABI wrapper (~200-400 bytes per function)
  - 10 functions × ~300 bytes average = **~3,000 bytes saved**

- **Memory → Calldata**: For array/struct parameters, calldata avoids memory allocation overhead
  - `constructShips`: 1 array param = ~50-100 bytes
  - `customizeShip`: 1 struct param = ~100-150 bytes
  - `setPurchaseInfo`: 3 array params = ~150-200 bytes
  - `getShipsByIds`: 1 array param = ~50-100 bytes
  - **Total**: ~350-550 bytes saved

**Subtotal for Section 1: ~3,350 - 3,550 bytes (~3.3 - 3.5 KB)**

---

### 2. Remove Unused State/Functions

#### Unused State:
- `mapping(address => uint) public onboardingStep;` (line 33)
  - Storage slot: 32 bytes (but this is storage, not bytecode)
  - Public getter function overhead: ~200-300 bytes
  - **Savings: ~200-300 bytes**

#### Unused Functions:
- `getTierOfTrait(uint _trait) public pure` (line 668)
  - Not called internally in Ships.sol
  - Used in GenerateNewShip.sol, but that contract has its own implementation
  - Function bytecode: ~150-200 bytes
  - Public ABI wrapper: ~200-300 bytes
  - **Savings: ~350-500 bytes**

**Subtotal for Section 2: ~550-800 bytes (~0.55 - 0.8 KB)**

---

### 3. Consolidate Custom Errors

#### Current Errors (16 total):
```solidity
error InvalidReferral();
error NotAuthorized(address);
error NotYourShip(uint);
error ShipDestroyed();
error MintPaused();
error ShipConstructed(uint);
error ShipInFleet(uint);
error InsufficientPurchases(address);
error InvalidPurchase(uint _tier, uint _amount);
error ArrayLengthMismatch();
error ShipAlreadyDestroyed(uint);
error CannotRecycleFreeShip(uint);
error InvalidVariant(uint16);
error ReferralTransferFailed();
error WithdrawalFailed();
error ClaimCooldownNotPassed();
```

#### Consolidation Options:

**Option A: Single Parameterized Error (Maximum Savings)**
```solidity
error ShipsError(uint8 code, uint256 idOrAmount, address addr);
```
- Current: 16 errors × ~4 bytes selector + metadata = ~64-80 bytes
- Consolidated: 1 error × ~4 bytes = ~4 bytes
- **Savings: ~60-76 bytes**

**Option B: Grouped Errors (Better Readability)**
```solidity
error AuthorizationError(uint8 code, address addr);  // codes: 1=NotAuthorized, 2=InvalidReferral
error ShipStateError(uint8 code, uint id);          // codes: 1=NotYourShip, 2=ShipDestroyed, 3=ShipConstructed, 4=ShipInFleet, 5=ShipAlreadyDestroyed, 6=CannotRecycleFreeShip
error ValidationError(uint8 code, uint256 value);  // codes: 1=MintPaused, 2=InvalidVariant, 3=InvalidPurchase, 4=ArrayLengthMismatch, 5=ClaimCooldownNotPassed
error TransferError(uint8 code);                    // codes: 1=ReferralTransferFailed, 2=WithdrawalFailed
error InsufficientPurchases(address);
```
- Current: 16 errors
- Consolidated: 5 errors
- **Savings: ~44-55 bytes** (11 errors removed)

**Subtotal for Section 3: ~44-76 bytes (~0.04 - 0.08 KB)**

---

## Total Estimated Savings

| Optimization | Low Estimate | High Estimate |
|-------------|--------------|---------------|
| Public → External + Calldata | 3,350 bytes | 3,550 bytes |
| Remove Unused State/Functions | 550 bytes | 800 bytes |
| Consolidate Errors | 44 bytes | 76 bytes |
| **TOTAL** | **~3,944 bytes (~3.9 KB)** | **~4,426 bytes (~4.4 KB)** |

## Projected Final Size

- **Current Deployed**: 24.185 KB
- **After Optimizations**: **~19.8 - 20.2 KB**
- **Savings**: **~16-18% reduction**
- **Status**: ✅ **Well under 24 KB limit** (with ~3.8-4.2 KB headroom)

## Implementation Priority

1. **High Priority** (Biggest impact):
   - Public → External + Calldata conversions
   - Remove unused `onboardingStep` mapping

2. **Medium Priority**:
   - Remove unused `getTierOfTrait` function

3. **Low Priority** (Smallest impact, but easy):
   - Consolidate custom errors (Option B recommended for better readability)

## Notes

- These are **estimates** based on typical Solidity compiler behavior
- Actual savings may vary slightly based on compiler version and optimization settings
- The public → external conversion provides the largest savings
- Error consolidation has minimal bytecode impact but improves maintainability
- All optimizations are **non-breaking** if external interfaces remain the same
