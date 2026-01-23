# Grid Size Reduction Checklist: 25×13 → 17×11

## Overview
Reducing grid dimensions from:
- **Width:** 25 columns → **17 columns**
- **Height:** 13 rows → **11 rows**
- **Total tiles:** 325 → **187 tiles**

---

## Contract Changes

### 1. `contracts/Maps.sol`
- [ ] **Line 9:** Change `GRID_WIDTH = 25` → `GRID_WIDTH = 17`
- [ ] **Line 10:** Change `GRID_HEIGHT = 13` → `GRID_HEIGHT = 11`
- [ ] All validation checks using `GRID_WIDTH` and `GRID_HEIGHT` will automatically update (lines 105-692)

### 2. `contracts/Game.sol`
- [ ] **Line 30:** Change `GRID_WIDTH = 25` → `GRID_WIDTH = 17`
- [ ] **Line 31:** Change `GRID_HEIGHT = 13` → `GRID_HEIGHT = 11`
- [ ] All validation checks using `GRID_WIDTH` and `GRID_HEIGHT` will automatically update (lines 119-120, 219, 283-284, 297-298, 471)

### 3. `contracts/Fleets.sol`
- [ ] **Line 75-76:** Update creator column validation
  - Current: `if (pos.col < 0 || pos.col > 4)` (columns 0-4)
  - **New:** Need to determine new column range for creator (suggest: columns 0-3 or 0-4)
- [ ] **Line 75-76:** Update joiner column validation
  - Current: `if (pos.col < 20 || pos.col > 24)` (columns 20-24)
  - **New:** Need to determine new column range for joiner (suggest: columns 13-16 or 12-16)
- [ ] **Line 79-80:** Update row bounds validation
  - Current: `if (pos.row < 0 || pos.row > 12)` (rows 0-12)
  - **New:** `if (pos.row < 0 || pos.row > 10)` (rows 0-10)
- [ ] **Line 126:** Update comment about grid size
  - Current: `// Use bitset for 25×13 grid (325 positions max)`
  - **New:** `// Use bitset for 17×11 grid (187 positions max)`
- [ ] **Line 127:** Bitset size can stay the same (2 * 256 = 512 bits > 187 positions)
- [ ] **Line 134:** Update hardcoded multiplier in position key calculation
  - Current: `uint256 key = uint256(int256(pos.row)) * 25 + uint256(int256(pos.col));`
  - **New:** `uint256 key = uint256(int256(pos.row)) * 17 + uint256(int256(pos.col));`

---

## Test File Changes

### 4. `test/Maps.test.ts`
- [ ] **Line 101:** Update expected grid width: `expect(gridWidth).to.equal(25)` → `expect(gridWidth).to.equal(17)`
- [ ] **Line 102:** Update expected grid height: `expect(gridHeight).to.equal(13)` → `expect(gridHeight).to.equal(11)`
- [ ] **Line 833:** Update invalid column test: `{ row: 5, col: 100 }` → `{ row: 5, col: 20 }` (or any value >= 17)
- [ ] **Line 966, 970, 984, 1003, 1012, 1041, 1042, 1169, 1177, 1359, 1360, 1398, 1420, 1492:** Update positions with `row: 12` → `row: 10` (max valid row)
- [ ] **Line 1501:** Update expected row: `expect(retrievedPositions[0].row).to.equal(12)` → `expect(retrievedPositions[0].row).to.equal(10)`
- [ ] Review all test positions to ensure they're within new bounds (row: 0-10, col: 0-16)

### 5. `test/Game.test.ts`
- [ ] **Line 32:** Update creator position generation
  - Current: `positions.push({ row: i, col: i % 5 }); // Use columns 0-4`
  - **New:** Update based on new creator column range (e.g., `col: i % 4` for columns 0-3)
- [ ] **Line 34-35:** Update joiner position generation
  - Current: `positions.push({ row: 12 - i, col: 20 + (i % 5) }); // Use columns 20-24`
  - **New:** Update based on new joiner column range (e.g., `row: 10 - i, col: 13 + (i % 4)` for columns 13-16)
- [ ] **Line 763:** Update expected grid width: `expect(gridGameData.gridDimensions.gridWidth).to.equal(25)` → `expect(gridGameData.gridDimensions.gridWidth).to.equal(17)`
- [ ] **Line 764:** Update expected grid height: `expect(gridGameData.gridDimensions.gridHeight).to.equal(13)` → `expect(gridGameData.gridDimensions.gridHeight).to.equal(11)`
- [ ] **Line 825:** Update comment about ownership pattern if needed
- [ ] **Line 834:** Update row value: `13n` → `11n` (if this is related to grid height)
- [ ] **Line 911-926:** Update joiner column expectations
  - Current: `ship.position.col === 20`, `ship.position.col === 24`, `[20, 21, 22, 23, 24]`
  - **New:** Update to new joiner column range
- [ ] **Line 939:** Update expected columns: `[20, 21, 22, 23, 24]` → new joiner range
- [ ] **Line 944:** Update expected columns: `[0, 1, 2, 3, 4, 20, 21, 22, 23, 24]` → new creator + joiner ranges
- [ ] **Line 1010-1011:** Update position: `row: 12, col: 20` → `row: 10, col: [new joiner start]`
- [ ] **Line 1079-1080:** Update position: `row: 12, col: 20` → `row: 10, col: [new joiner start]`
- [ ] **Line 1725:** Update max column: `const maxCol = 24;` → `const maxCol = 16;`
- [ ] **Line 2433, 4079:** Update position: `row: 0, col: 5` → ensure within bounds
- [ ] **Line 2926, 3153, 3327, 4079, 4921, 4964-4965, 4974, 4985-4986, 4995, 4998:** Review and update all hardcoded positions to be within new grid bounds

### 6. `test/Lobbies.test.ts`
- [ ] **Line 20:** Update creator position generation
  - Current: `positions.push({ row: i, col: i % 5 }); // Use columns 0-4`
  - **New:** Update based on new creator column range
- [ ] **Line 22-23:** Update joiner position generation
  - Current: `positions.push({ row: 12 - i, col: 20 + (i % 5) }); // Use columns 20-24`
  - **New:** Update based on new joiner column range
- [ ] **Line 1100:** Update invalid position test: `{ row: 0, col: 20 }` → `{ row: 0, col: 17 }` (or any value >= 17)

### 7. `test/types.ts`
- [ ] **Line 185-186:** Type definitions should automatically work (no changes needed, but verify)
- [ ] **Line 304-305:** Comments about position bounds should be updated if present

---

## Helper Functions

### 8. `test/Game.test.ts` - `generateStartingPositions` function
- [ ] Update creator column logic (line 32)
- [ ] Update joiner row calculation: `12 - i` → `10 - i`
- [ ] Update joiner column calculation: `20 + (i % 5)` → new joiner start + modulo

### 9. `test/Lobbies.test.ts` - `generateStartingPositions` function
- [ ] Update creator column logic (line 20)
- [ ] Update joiner row calculation: `12 - i` → `10 - i`
- [ ] Update joiner column calculation: `20 + (i % 5)` → new joiner start + modulo

---

## Design Decisions Needed

### Column Distribution
**Current:**
- Creator: columns 0-4 (5 columns)
- Joiner: columns 20-24 (5 columns)
- Middle: columns 5-19 (15 columns)

**New (17 columns total):**
- **Option A:** Creator: 0-3 (4 cols), Joiner: 13-16 (4 cols), Middle: 4-12 (9 cols)
- **Option B:** Creator: 0-4 (5 cols), Joiner: 12-16 (5 cols), Middle: 5-11 (7 cols)
- **Option C:** Creator: 0-3 (4 cols), Joiner: 12-16 (5 cols), Middle: 4-11 (8 cols)

**Recommendation:** Option A (symmetric, 4 columns each)

### Row Distribution
**Current:**
- Rows: 0-12 (13 rows)
- Creator starts at top (row 0)
- Joiner starts at bottom (row 12)

**New:**
- Rows: 0-10 (11 rows)
- Creator starts at top (row 0)
- Joiner starts at bottom (row 10)

---

## Additional Considerations

### 10. Documentation
- [ ] Update any documentation that references grid size (25×13)
- [ ] Update `docs/LineOfSight.md` if it contains grid size references
- [ ] Update README if it mentions grid dimensions

### 11. Comments
- [ ] Update all comments that mention "25 columns" or "13 rows"
- [ ] Update comments about grid size calculations
- [ ] Update comments about position validation ranges

### 12. Bitset Calculation
- [ ] Verify bitset size is still sufficient (2 * 256 = 512 bits > 187 positions) ✓
- [ ] Update multiplier in position key calculation (25 → 17)

### 13. Test Coverage
- [ ] Ensure all test positions are within new bounds
- [ ] Update edge case tests (max row, max col, boundary conditions)
- [ ] Verify line-of-sight tests still work with new dimensions
- [ ] Check movement range tests are appropriate for smaller grid

---

## Summary

**Total files to modify:** 7
- Contracts: 3 files (Maps.sol, Game.sol, Fleets.sol)
- Tests: 4 files (Maps.test.ts, Game.test.ts, Lobbies.test.ts, types.ts)

**Key changes:**
1. Update `GRID_WIDTH` constant: 25 → 17 (2 locations)
2. Update `GRID_HEIGHT` constant: 13 → 11 (2 locations)
3. Update hardcoded column ranges in Fleets.sol (creator and joiner)
4. Update row bounds: 0-12 → 0-10
5. Update position key multiplier: 25 → 17
6. Update all test positions and expectations
7. Update helper functions for position generation

**Estimated impact:** Medium - requires careful testing of all position-related functionality, especially line-of-sight calculations and movement validation.
