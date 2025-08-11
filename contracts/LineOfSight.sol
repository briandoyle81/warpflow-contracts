// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LineOfSight is Ownable {
    // Grid dimensions
    int16 public constant GRID_WIDTH = 100; // Number of columns
    int16 public constant GRID_HEIGHT = 50; // Number of rows

    // Mapping: gameId => row => column => blocked
    mapping(uint => mapping(int16 => mapping(int16 => bool)))
        public blockedTiles;

    // Custom error for invalid positions
    error InvalidPosition();

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Set a tile as blocked or unblocked for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate (0-49)
     * @param _col The column coordinate (0-99)
     * @param _blocked Whether the tile should be blocked
     */
    function setBlockedTile(
        uint _gameId,
        int16 _row,
        int16 _col,
        bool _blocked
    ) external onlyOwner {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            revert InvalidPosition();
        }
        blockedTiles[_gameId][_row][_col] = _blocked;
    }

    /**
     * @dev Check if a tile is blocked for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate (0-49)
     * @param _col The column coordinate (0-99)
     * @return Whether the tile is blocked
     */
    function isTileBlocked(
        uint _gameId,
        int16 _row,
        int16 _col
    ) public view returns (bool) {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            revert InvalidPosition();
        }
        return blockedTiles[_gameId][_row][_col];
    }

    /**
     * @dev Check if a tile is blocked safely (for internal use in LOS)
     * @param _gameId The game ID
     * @param _row The row coordinate
     * @param _col The column coordinate
     * @return Whether the tile is blocked (treats OOB as blocked)
     */
    function _isTileBlockedSafe(
        uint _gameId,
        int16 _row,
        int16 _col
    ) internal view returns (bool) {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            return true; // Treat out of bounds as blocked
        }
        return blockedTiles[_gameId][_row][_col];
    }

    /**
     * @dev Check if there's a clear line of sight between two points
     * @param _gameId The game ID
     * @param _row0 Starting row coordinate (0-49)
     * @param _col0 Starting column coordinate (0-99)
     * @param _row1 Ending row coordinate (0-49)
     * @param _col1 Ending column coordinate (0-99)
     * @return Whether there's a clear line of sight
     */
    function hasLineOfSight(
        uint _gameId,
        int16 _row0,
        int16 _col0,
        int16 _row1,
        int16 _col1
    ) public view returns (bool) {
        if (
            _row0 < 0 ||
            _row0 >= GRID_HEIGHT ||
            _col0 < 0 ||
            _col0 >= GRID_WIDTH ||
            _row1 < 0 ||
            _row1 >= GRID_HEIGHT ||
            _col1 < 0 ||
            _col1 >= GRID_WIDTH
        ) revert InvalidPosition();

        // Early checks - always check start and end
        if (_isTileBlockedSafe(_gameId, _row0, _col0)) {
            return false;
        }

        if (_row0 == _row1 && _col0 == _col1) {
            return !_isTileBlockedSafe(_gameId, _row1, _col1);
        }

        // Use Bresenham's algorithm for line of sight (always permissive mode)
        return _bresenhamLineOfSight(_gameId, _row0, _col0, _row1, _col1);
    }

    /**
     * @dev Internal function implementing Bresenham's line of sight algorithm
     * Uses permissive corner mode (only blocks if both flankers are blocked)
     * Optimized to avoid stack too deep errors
     */
    function _bresenhamLineOfSight(
        uint _gameId,
        int16 _row0,
        int16 _col0,
        int16 _row1,
        int16 _col1
    ) internal view returns (bool) {
        // Calculate deltas and signs - minimize local variables
        int16 dRow = _row1 > _row0 ? _row1 - _row0 : _row0 - _row1;
        int16 dCol = _col1 > _col0 ? _col1 - _col0 : _col0 - _col1;
        int16 sRow = _row1 > _row0
            ? int16(1)
            : (_row1 < _row0 ? int16(-1) : int16(0));
        int16 sCol = _col1 > _col0
            ? int16(1)
            : (_col1 < _col0 ? int16(-1) : int16(0));

        // Initialize error term and current position
        int16 err = dCol - dRow;
        int16 row = _row0;
        int16 col = _col0;

        while (true) {
            // Check if we've reached the target
            if (row == _row1 && col == _col1) {
                return !_isTileBlockedSafe(_gameId, row, col);
            }

            int16 e2 = err << 1;

            // Handle tie case (corner) - exclusive with other branches
            if (e2 == 0) {
                // Check flankers before moving
                if (
                    _isTileBlockedSafe(_gameId, row, col + sCol) &&
                    _isTileBlockedSafe(_gameId, row + sRow, col)
                ) {
                    return false;
                }

                // Advance diagonally
                col += sCol;
                err -= dRow;
                row += sRow;
                err += dCol;

                // Check new cell unless it's the target
                if (
                    (row != _row1 || col != _col1) &&
                    _isTileBlockedSafe(_gameId, row, col)
                ) {
                    return false;
                }
                continue;
            }

            // Column step
            if (e2 > -dRow) {
                err -= dRow;
                col += sCol;
                if (
                    (row != _row1 || col != _col1) &&
                    _isTileBlockedSafe(_gameId, row, col)
                ) {
                    return false;
                }
            }

            // Row step
            if (e2 < dCol) {
                err += dCol;
                row += sRow;
                if (
                    (row != _row1 || col != _col1) &&
                    _isTileBlockedSafe(_gameId, row, col)
                ) {
                    return false;
                }
            }
        }
    }
}
