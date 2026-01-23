# Tier Structure Recommendation - Gas Constrained

## Gas Cost Analysis

**Per-ship gas cost:**
- First ship: ~194,000 gas (cold storage)
- Subsequent ships: ~153,000 gas each (warm storage)
- Formula: `194,000 + (n-1) × 153,000` where n = number of ships

**Gas costs by ship count:**
- 5 ships: 194,000 + (4 × 153,000) = **806,000 gas** ✓
- 10 ships: 194,000 + (9 × 153,000) = **1,571,000 gas** ✓
- 20 ships: 194,000 + (19 × 153,000) = **3,101,000 gas** ✓
- 30 ships: 194,000 + (29 × 153,000) = **4,631,000 gas** ✓
- 40 ships: 194,000 + (39 × 153,000) = **6,161,000 gas** ✓
- 50 ships: 194,000 + (49 × 153,000) = **7,691,000 gas** ✓
- 60 ships: 194,000 + (59 × 153,000) = **9,221,000 gas** ✓
- 70 ships: 194,000 + (69 × 153,000) = **10,751,000 gas** ⚠️ (approaching limits)
- 80 ships: 194,000 + (79 × 153,000) = **12,281,000 gas** ✗ (too high)

**Maximum safe limit: ~60 ships per transaction**

---

## Recommended Tier Structure

### Option 1: Conservative (5 tiers, max 50 ships)

**Tier 0:** 5 ships for **4.99 FLOW**
- Gas: ~806,000 ✓
- Guaranteed: 1 Rank 1 ship
- Value: ~1.00 FLOW per ship

**Tier 1:** 10 ships for **9.99 FLOW**
- Gas: ~1,571,000 ✓
- Guaranteed: 1 Rank 2, 1 Rank 1
- Value: ~1.00 FLOW per ship

**Tier 2:** 20 ships for **19.99 FLOW**
- Gas: ~3,101,000 ✓
- Guaranteed: 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~1.00 FLOW per ship

**Tier 3:** 35 ships for **34.99 FLOW**
- Gas: ~5,414,000 ✓
- Guaranteed: 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~1.00 FLOW per ship

**Tier 4:** 50 ships for **49.99 FLOW**
- Gas: ~7,691,000 ✓
- Guaranteed: 1 Rank 5, 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~1.00 FLOW per ship

**Total ships across all tiers: 120 ships**

---

### Option 2: Aggressive (5 tiers, max 60 ships) ⭐ **RECOMMENDED**

**Tier 0:** 5 ships for **4.99 FLOW**
- Gas: ~806,000 ✓
- Guaranteed: 1 Rank 1 ship
- Value: ~1.00 FLOW per ship

**Tier 1:** 11 ships for **9.99 FLOW**
- Gas: ~1,724,000 ✓
- Guaranteed: 1 Rank 2, 1 Rank 1
- Value: ~0.91 FLOW per ship

**Tier 2:** 22 ships for **19.99 FLOW**
- Gas: ~3,407,000 ✓
- Guaranteed: 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~0.91 FLOW per ship

**Tier 3:** 40 ships for **34.99 FLOW**
- Gas: ~6,161,000 ✓
- Guaranteed: 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~0.87 FLOW per ship

**Tier 4:** 60 ships for **49.99 FLOW**
- Gas: ~9,221,000 ✓
- Guaranteed: 1 Rank 5, 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1
- Value: ~0.83 FLOW per ship

**Total ships across all tiers: 138 ships**

**Benefits:**
- Better value per ship at higher tiers (incentivizes upgrades)
- More ships per tier = more guaranteed high-rank ships
- Still well within gas limits
- Maintains clear progression

---

### Option 3: Minimal (4 tiers, max 50 ships)

**Tier 0:** 5 ships for **4.99 FLOW**
- Gas: ~806,000 ✓
- Guaranteed: 1 Rank 1 ship

**Tier 1:** 12 ships for **9.99 FLOW**
- Gas: ~1,877,000 ✓
- Guaranteed: 1 Rank 2, 1 Rank 1

**Tier 2:** 25 ships for **24.99 FLOW**
- Gas: ~3,857,000 ✓
- Guaranteed: 1 Rank 3, 1 Rank 2, 1 Rank 1

**Tier 3:** 50 ships for **49.99 FLOW**
- Gas: ~7,691,000 ✓
- Guaranteed: 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1

**Total ships across all tiers: 92 ships**

**Note:** This option removes Rank 5 guaranteed ships (only available through gameplay)

---

## Economic Considerations

### Current System (for comparison):
- Tier 0: 5 ships @ 4.99 = **0.998 FLOW/ship**
- Tier 1: 11 ships @ 9.99 = **0.908 FLOW/ship**
- Tier 2: 28 ships @ 24.99 = **0.892 FLOW/ship**
- Tier 3: 60 ships @ 49.99 = **0.833 FLOW/ship**
- Tier 4: 125 ships @ 99.99 = **0.800 FLOW/ship** ✗ (too many ships)

### Recommended Pricing Strategy:

**Option A: Flat rate (~1.00 FLOW per ship)**
- Simple, predictable
- No discount for bulk purchases
- Less incentive to upgrade tiers

**Option B: Decreasing rate (better value at higher tiers)** ⭐ **RECOMMENDED**
- Tier 0: ~1.00 FLOW/ship
- Tier 1: ~0.91 FLOW/ship
- Tier 2: ~0.87 FLOW/ship
- Tier 3: ~0.83 FLOW/ship
- Tier 4: ~0.83 FLOW/ship
- Incentivizes players to buy higher tiers
- Maintains economic balance

**Option C: Premium pricing (higher margins)**
- Tier 0: 5 ships @ 5.99 = 1.20 FLOW/ship
- Tier 1: 11 ships @ 11.99 = 1.09 FLOW/ship
- Tier 2: 22 ships @ 24.99 = 1.14 FLOW/ship
- Tier 3: 40 ships @ 44.99 = 1.12 FLOW/ship
- Tier 4: 60 ships @ 64.99 = 1.08 FLOW/ship

---

## Recommendation: **Option 2 (Aggressive)**

### Implementation:

```solidity
tierShips = [5, 11, 22, 40, 60];
tierPrices = [
    4.99 ether,   // Tier 0: 5 ships
    9.99 ether,   // Tier 1: 11 ships
    19.99 ether,  // Tier 2: 22 ships
    34.99 ether,  // Tier 3: 40 ships
    49.99 ether   // Tier 4: 60 ships
];
```

### Rank Distribution:
- **Tier 0:** 1 Rank 1, 4 random
- **Tier 1:** 1 Rank 2, 1 Rank 1, 9 random
- **Tier 2:** 1 Rank 3, 1 Rank 2, 1 Rank 1, 19 random
- **Tier 3:** 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1, 36 random
- **Tier 4:** 1 Rank 5, 1 Rank 4, 1 Rank 3, 1 Rank 2, 1 Rank 1, 55 random

### Gas Safety:
- All tiers well under 10M gas limit
- Tier 4 (max) uses ~9.2M gas (30% buffer)
- Room for referral processing and transaction overhead

### Economic Benefits:
- Clear value progression (better per-ship price at higher tiers)
- Maintains guaranteed high-rank ships
- Total of 138 ships across all tiers (vs. 229 in old system)
- Still provides good bulk value

---

## Alternative: If You Need More Ships

If you absolutely need more than 60 ships per purchase, consider:

1. **Split purchases:** Allow users to purchase multiple times
2. **Batch system:** Separate function for very large purchases (70-100 ships) with higher gas costs
3. **Two-tier system:** 
   - Standard tiers (5-60 ships)
   - Premium tier (100+ ships) with explicit gas warning

However, **Option 2 (60 ships max) is recommended** as it:
- Fits comfortably within gas limits
- Provides good value
- Maintains guaranteed high-rank ships
- Keeps transaction costs reasonable
