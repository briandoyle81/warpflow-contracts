// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Import Position struct from Types
import "./Types.sol";

interface IMaps {
    // Grid constants
    function GRID_WIDTH() external view returns (int16);

    function GRID_HEIGHT() external view returns (int16);

    // Blocked tiles mapping
    function blockedTiles(
        uint _gameId,
        int16 _row,
        int16 _col
    ) external view returns (bool);

    // Set a tile as blocked for line of sight
    function setBlockedTile(
        uint _gameId,
        int16 _row,
        int16 _col,
        bool _blocked
    ) external;

    // Set multiple tiles as blocked for line of sight
    function setBlockedTiles(
        uint _gameId,
        int16[] memory _rows,
        int16[] memory _cols,
        bool[] memory _blocked
    ) external;

    // Check if a tile is blocked
    function isTileBlocked(
        uint _gameId,
        int16 _row,
        int16 _col
    ) external view returns (bool);

    // Main line of sight function using Bresenham's algorithm
    function hasMaps(
        uint _gameId,
        int16 _x0,
        int16 _y0,
        int16 _x1,
        int16 _y1
    ) external view returns (bool);

    // Preset map functions
    function createPresetMap(
        Position[] calldata _blockedPositions
    ) external returns (uint);

    function updatePresetMap(
        uint _mapId,
        Position[] calldata _blockedPositions
    ) external;

    function deletePresetMap(uint _mapId) external;

    function applyPresetMapToGame(uint _gameId, uint _mapId) external;

    function getPresetMap(
        uint _mapId
    ) external view returns (Position[] memory);

    function mapExists(uint _mapId) external view returns (bool);

    function mapCount() external view returns (uint);

    // Scoring tile functions
    function setScoringTile(
        uint _gameId,
        int16 _row,
        int16 _col,
        uint8 _points
    ) external;

    function isTileScoring(
        uint _gameId,
        int16 _row,
        int16 _col
    ) external view returns (uint8);

    function isTileScoringSafe(
        uint _gameId,
        int16 _row,
        int16 _col
    ) external view returns (uint8);

    // Preset scoring map functions
    function createPresetScoringMap(
        ScoringPosition[] calldata _scoringPositions
    ) external returns (uint);

    function updatePresetScoringMap(
        uint _mapId,
        ScoringPosition[] calldata _scoringPositions
    ) external;

    function deletePresetScoringMap(uint _mapId) external;

    function applyPresetScoringMapToGame(uint _gameId, uint _mapId) external;

    function getPresetScoringMap(
        uint _mapId
    ) external view returns (ScoringPosition[] memory);
}
