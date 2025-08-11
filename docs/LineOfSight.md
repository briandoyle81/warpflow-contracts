# Line of Sight System

This document describes the line-of-sight (LOS) system implemented as a separate contract using Bresenham's algorithm.

## Overview

The line-of-sight system determines whether a clear path exists between two points on the game grid, taking into account blocking tiles. It uses Bresenham's algorithm for efficient integer-based line traversal.

## Key Features

- **Separate Contract**: Modular design with LOS logic isolated in its own contract
- **Integer Grid**: Works on a 255x255 integer grid
- **Bresenham Algorithm**: Uses the classic Bresenham line algorithm for accurate line traversal
- **Permissive Corner Handling**: Single corner contact does not block line of sight
- **Always Check Start/End**: Both start and end positions are always checked for blocking
- **Reusable**: Can be used by multiple game contracts

## Architecture

The line-of-sight system is implemented as a separate contract (`Maps.sol`) that can be used by multiple game contracts. The Game contract calls the Maps contract for all LOS calculations.

## Data Structures

### Blocked Tiles Mapping

```solidity
mapping(uint => mapping(int16 row => mapping(int16 col => bool))) blockedTiles;
```

## Core Functions

### Setting Up the System

The Maps contract is automatically deployed and configured when using the Ignition deployment script:

```bash
# Deploy all contracts including Maps
npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts
```

For manual deployment:

```solidity
// Deploy Maps contract
Maps maps = new Maps();

// Set the Maps contract address in Game contract
game.setMapsAddress(address(maps));

// Set individual blocked tile
maps.setBlockedTile(uint _gameId, int16 _row, int16 _col, bool _blocked);

// Set multiple blocked tiles at once
maps.setBlockedTiles(uint _gameId, int16[] memory _rows, int16[] memory _cols, bool[] memory _blocked);
```

### Checking Line of Sight

```solidity
// Main LOS function (called from Game contract)
maps.hasMaps(
    uint _gameId,
    int16 _x0, int16 _y0,    // Start position
    int16 _x1, int16 _y1     // End position
) public view returns (bool)

// Check LOS between two ships (Game contract wrapper)
game.hasMapsBetweenShips(
    uint _gameId,
    uint _shipId1,
    uint _shipId2
) public view returns (bool)
```

## Corner Handling

The system uses permissive corner handling:

- Single corner contact does not block line of sight
- Only blocks if both flanking tiles are blocked
- Feels more fair and human-like

## Algorithm Details

The system uses Bresenham's algorithm with the following modifications:

1. **Step Types**: Each iteration categorizes as X-step, Y-step, or TIE (diagonal)
2. **Blocking Checks**:
   - X/Y steps: Check if the next cell is blocked
   - TIE steps: Apply corner rules based on flanking tiles
3. **Corner Rules**:
   - Only fail if both flankers are blocked (permissive mode)

## Integration with Game Mechanics

### Shooting

Line of sight is automatically checked when ships attempt to shoot:

```solidity
// Must have line of sight to target
if (!maps.hasMaps(_gameId, _newCol, _newRow, targetPos.col, targetPos.row)) {
    revert InvalidMove();
}
```

### Special Abilities

Special abilities do not require line of sight and can be used regardless of blocking tiles:

- RepairDrones
- EMP
- FlakArray

## Usage Examples

### Basic Setup

```solidity
// Add some blocking tiles
await game.setBlockedTile(gameId, 5, 5, true);
await game.setBlockedTile(gameId, 5, 6, true);
```

### Checking Line of Sight

```solidity
// Check if there's clear LOS from (0,0) to (10,10)
bool hasLOS = await maps.hasMaps(gameId, 0, 0, 10, 10);

// Check LOS between two ships
bool canShoot = await game.hasMapsBetweenShips(gameId, shipId1, shipId2);
```

## Test Cases

The system handles all the specified test cases:

1. **Straight line with wall**: Blocked
2. **Perfect diagonal with one flanking tile blocked**: Clear (permissive mode)
3. **Perfect diagonal with both flanking tiles blocked**: Blocked
4. **Keyhole**: Clear
5. **Start position blocked**: Blocked
6. **End position blocked**: Blocked

## Performance Considerations

- Bresenham's algorithm is O(max(dx, dy)) where dx, dy are the differences in coordinates
- Integer-only operations for efficiency
- No floating-point calculations
- Suitable for real-time game mechanics

## Limitations

- Grid size limited to 255x255 (fits in uint8)
- Only axis-aligned unit tiles supported
- No diagonal movement through walls (as per specification)
