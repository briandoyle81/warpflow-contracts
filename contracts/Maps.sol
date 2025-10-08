// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";

contract Maps is Ownable {
    // Grid dimensions
    int16 public constant GRID_WIDTH = 25; // Number of columns
    int16 public constant GRID_HEIGHT = 13; // Number of rows

    // Mapping: gameId => row => column => blocked
    mapping(uint => mapping(int16 => mapping(int16 => bool)))
        public blockedTiles;

    // Preset maps: mapId => row => column => blocked
    mapping(uint => mapping(int16 => mapping(int16 => bool)))
        public presetBlockedMaps;

    // Mapping: gameId => row => column => scoring
    mapping(uint => mapping(int16 => mapping(int16 => uint8)))
        public scoringTiles;

    // Preset maps: mapId => row => column => scoring
    mapping(uint => mapping(int16 => mapping(int16 => uint8)))
        public presetScoringMaps;

    // Mapping: gameId => row => column => onlyOnce
    mapping(uint => mapping(int16 => mapping(int16 => bool)))
        public onlyOnceTiles;

    // Preset maps: mapId => row => column => onlyOnce
    mapping(uint => mapping(int16 => mapping(int16 => bool)))
        public presetOnlyOnceMaps;

    // Counter for preset maps
    uint public mapCount;

    // Address of the Game contract that can apply preset maps
    address public gameAddress;

    // Custom error for invalid positions
    error InvalidPosition();
    error MapNotFound();
    error NotGameContract();

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Set the address of the Game contract
     * @param _gameAddress The address of the Game contract
     */
    function setGameAddress(address _gameAddress) external onlyOwner {
        gameAddress = _gameAddress;
    }

    /**
     * @dev Create a new preset map with both blocked and scoring tiles
     * @param _blockedPositions Array of blocked positions
     * @param _scoringPositions Array of scoring positions with point values
     */
    function createPresetMap(
        Position[] memory _blockedPositions,
        ScoringPosition[] memory _scoringPositions
    ) external onlyOwner {
        _createPresetMapInternal(_blockedPositions, _scoringPositions);
    }

    /**
     * @dev Create a new preset map with only blocked positions
     * @param _blockedPositions Array of blocked positions
     */
    function createPresetMap(
        Position[] memory _blockedPositions
    ) external onlyOwner {
        _createPresetMapInternal(_blockedPositions, new ScoringPosition[](0));
    }

    /**
     * @dev Create a new preset map with only scoring positions
     * @param _scoringPositions Array of scoring positions with point values
     */
    function createPresetScoringMap(
        ScoringPosition[] memory _scoringPositions
    ) external onlyOwner {
        _createPresetMapInternal(new Position[](0), _scoringPositions);
    }

    /**
     * @dev Internal function to create a preset map with both blocked and scoring tiles
     * @param _blockedPositions Array of blocked positions
     * @param _scoringPositions Array of scoring positions with point values
     */
    function _createPresetMapInternal(
        Position[] memory _blockedPositions,
        ScoringPosition[] memory _scoringPositions
    ) internal {
        mapCount++;

        // Set blocked positions
        for (uint i = 0; i < _blockedPositions.length; i++) {
            Position memory pos = _blockedPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetBlockedMaps[mapCount][pos.row][pos.col] = true;
        }

        // Set scoring positions
        for (uint i = 0; i < _scoringPositions.length; i++) {
            ScoringPosition memory pos = _scoringPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetScoringMaps[mapCount][pos.row][pos.col] = pos.points;
            presetOnlyOnceMaps[mapCount][pos.row][pos.col] = pos.onlyOnce;
        }
    }

    /**
     * @dev Update an existing preset map
     * @param _mapId The map ID to update
     * @param _blockedPositions Array of blocked positions
     */
    function updatePresetMap(
        uint _mapId,
        Position[] calldata _blockedPositions
    ) external onlyOwner {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Get the current blocked positions and clear them
        Position[] memory currentPositions = _getPresetMap(_mapId);
        for (uint i = 0; i < currentPositions.length; i++) {
            Position memory pos = currentPositions[i];
            presetBlockedMaps[_mapId][pos.row][pos.col] = false;
        }

        // Set new blocked positions
        for (uint i = 0; i < _blockedPositions.length; i++) {
            Position memory pos = _blockedPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetBlockedMaps[_mapId][pos.row][pos.col] = true;
        }
    }

    /**
     * @dev Update an existing preset scoring map
     * @param _mapId The map ID to update
     * @param _scoringPositions Array of scoring positions with point values
     */
    function updatePresetScoringMap(
        uint _mapId,
        ScoringPosition[] calldata _scoringPositions
    ) external onlyOwner {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Get the current scoring positions and clear them
        ScoringPosition[] memory currentPositions = _getPresetScoringMap(
            _mapId
        );
        for (uint i = 0; i < currentPositions.length; i++) {
            ScoringPosition memory pos = currentPositions[i];
            presetScoringMaps[_mapId][pos.row][pos.col] = 0;
            presetOnlyOnceMaps[_mapId][pos.row][pos.col] = false;
        }

        // Set new scoring positions
        for (uint i = 0; i < _scoringPositions.length; i++) {
            ScoringPosition memory pos = _scoringPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetScoringMaps[_mapId][pos.row][pos.col] = pos.points;
            presetOnlyOnceMaps[_mapId][pos.row][pos.col] = pos.onlyOnce;
        }
    }

    /**
     * @dev Update an existing preset map with both blocked and scoring tiles
     * @param _mapId The map ID to update
     * @param _blockedPositions Array of blocked positions
     * @param _scoringPositions Array of scoring positions with point values
     */
    function updatePresetMap(
        uint _mapId,
        Position[] memory _blockedPositions,
        ScoringPosition[] memory _scoringPositions
    ) external onlyOwner {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Clear existing blocked positions
        Position[] memory currentBlockedPositions = _getPresetMap(_mapId);
        for (uint i = 0; i < currentBlockedPositions.length; i++) {
            Position memory pos = currentBlockedPositions[i];
            presetBlockedMaps[_mapId][pos.row][pos.col] = false;
        }

        // Clear existing scoring positions
        ScoringPosition[] memory currentScoringPositions = _getPresetScoringMap(
            _mapId
        );
        for (uint i = 0; i < currentScoringPositions.length; i++) {
            ScoringPosition memory pos = currentScoringPositions[i];
            presetScoringMaps[_mapId][pos.row][pos.col] = 0;
            presetOnlyOnceMaps[_mapId][pos.row][pos.col] = false;
        }

        // Set new blocked positions
        for (uint i = 0; i < _blockedPositions.length; i++) {
            Position memory pos = _blockedPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetBlockedMaps[_mapId][pos.row][pos.col] = true;
        }

        // Set new scoring positions
        for (uint i = 0; i < _scoringPositions.length; i++) {
            ScoringPosition memory pos = _scoringPositions[i];
            if (
                pos.row < 0 ||
                pos.row >= GRID_HEIGHT ||
                pos.col < 0 ||
                pos.col >= GRID_WIDTH
            ) {
                revert InvalidPosition();
            }
            presetScoringMaps[_mapId][pos.row][pos.col] = pos.points;
            presetOnlyOnceMaps[_mapId][pos.row][pos.col] = pos.onlyOnce;
        }
    }

    /**
     * @dev Apply a preset map to a specific game
     * @param _gameId The game ID
     * @param _mapId The preset map ID to apply
     */
    function applyPresetMapToGame(uint _gameId, uint _mapId) external {
        if (msg.sender != gameAddress && msg.sender != owner())
            revert NotGameContract();
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Get the preset blocked positions and apply them to the game
        Position[] memory blockedPositions = _getPresetMap(_mapId);
        for (uint i = 0; i < blockedPositions.length; i++) {
            Position memory pos = blockedPositions[i];
            blockedTiles[_gameId][pos.row][pos.col] = true;
        }

        // Get the preset scoring positions and apply them to the game
        ScoringPosition[] memory scoringPositions = _getPresetScoringMap(
            _mapId
        );
        for (uint i = 0; i < scoringPositions.length; i++) {
            ScoringPosition memory pos = scoringPositions[i];
            scoringTiles[_gameId][pos.row][pos.col] = presetScoringMaps[_mapId][
                pos.row
            ][pos.col];
            onlyOnceTiles[_gameId][pos.row][pos.col] = presetOnlyOnceMaps[
                _mapId
            ][pos.row][pos.col];
        }
    }

    /**
     * @dev Apply a preset scoring map to a specific game
     * @param _gameId The game ID to apply the map to
     * @param _mapId The preset scoring map ID to apply
     */
    function applyPresetScoringMapToGame(uint _gameId, uint _mapId) external {
        if (msg.sender != gameAddress && msg.sender != owner())
            revert NotGameContract();
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Get the preset scoring positions and apply them to the game
        ScoringPosition[] memory scoringPositions = _getPresetScoringMap(
            _mapId
        );
        for (uint i = 0; i < scoringPositions.length; i++) {
            ScoringPosition memory pos = scoringPositions[i];
            scoringTiles[_gameId][pos.row][pos.col] = presetScoringMaps[_mapId][
                pos.row
            ][pos.col];
            onlyOnceTiles[_gameId][pos.row][pos.col] = presetOnlyOnceMaps[
                _mapId
            ][pos.row][pos.col];
        }
    }

    /**
     * @dev Get a preset map's blocked tiles (external version)
     * @param _mapId The map ID
     * @return Array of blocked positions
     */
    function getPresetMap(
        uint _mapId
    ) external view returns (Position[] memory) {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Count blocked positions first
        uint blockedCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetBlockedMaps[_mapId][row][col]) {
                    blockedCount++;
                }
            }
        }

        // Create array and populate with blocked positions
        Position[] memory blockedPositions = new Position[](blockedCount);
        uint index = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetBlockedMaps[_mapId][row][col]) {
                    blockedPositions[index] = Position(row, col);
                    index++;
                }
            }
        }

        return blockedPositions;
    }

    /**
     * @dev Get a preset map's blocked tiles (internal version)
     * @param _mapId The map ID
     * @return Array of blocked positions
     */
    function _getPresetMap(
        uint _mapId
    ) internal view returns (Position[] memory) {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Count blocked positions first
        uint blockedCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetBlockedMaps[_mapId][row][col]) {
                    blockedCount++;
                }
            }
        }

        // Create array and populate with blocked positions
        Position[] memory blockedPositions = new Position[](blockedCount);
        uint index = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetBlockedMaps[_mapId][row][col]) {
                    blockedPositions[index] = Position(row, col);
                    index++;
                }
            }
        }

        return blockedPositions;
    }

    /**
     * @dev Get a preset scoring map's scoring tiles (external version)
     * @param _mapId The map ID
     * @return Array of scoring positions
     */
    function getPresetScoringMap(
        uint _mapId
    ) external view returns (ScoringPosition[] memory) {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Count scoring positions first
        uint scoringCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetScoringMaps[_mapId][row][col] > 0) {
                    scoringCount++;
                }
            }
        }

        // Create array and populate with scoring positions
        ScoringPosition[] memory scoringPositions = new ScoringPosition[](
            scoringCount
        );
        uint index = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetScoringMaps[_mapId][row][col] > 0) {
                    scoringPositions[index] = ScoringPosition(
                        row,
                        col,
                        presetScoringMaps[_mapId][row][col],
                        presetOnlyOnceMaps[_mapId][row][col]
                    );
                    index++;
                }
            }
        }

        return scoringPositions;
    }

    /**
     * @dev Get a preset scoring map's scoring tiles (internal version)
     * @param _mapId The map ID
     * @return Array of scoring positions
     */
    function _getPresetScoringMap(
        uint _mapId
    ) internal view returns (ScoringPosition[] memory) {
        if (_mapId == 0 || _mapId > mapCount) revert MapNotFound();

        // Count scoring positions first
        uint scoringCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetScoringMaps[_mapId][row][col] > 0) {
                    scoringCount++;
                }
            }
        }

        // Create array and populate with scoring positions
        ScoringPosition[] memory scoringPositions = new ScoringPosition[](
            scoringCount
        );
        uint index = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (presetScoringMaps[_mapId][row][col] > 0) {
                    scoringPositions[index] = ScoringPosition(
                        row,
                        col,
                        presetScoringMaps[_mapId][row][col],
                        presetOnlyOnceMaps[_mapId][row][col]
                    );
                    index++;
                }
            }
        }

        return scoringPositions;
    }

    /**
     * @dev Check if a preset map exists
     * @param _mapId The map ID to check
     * @return Whether the map exists
     */
    function mapExists(uint _mapId) external view returns (bool) {
        return _mapId > 0 && _mapId <= mapCount;
    }

    /**
     * @dev Get all preset maps with both blocked and scoring portions
     * @return mapIds Array of map IDs
     * @return blockedPositions Array of blocked positions for each map
     * @return scoringPositions Array of scoring positions for each map
     */
    function getAllPresetMaps()
        external
        view
        returns (
            uint[] memory mapIds,
            Position[][] memory blockedPositions,
            ScoringPosition[][] memory scoringPositions
        )
    {
        uint totalMaps = mapCount;
        mapIds = new uint[](totalMaps);
        blockedPositions = new Position[][](totalMaps);
        scoringPositions = new ScoringPosition[][](totalMaps);

        for (uint i = 1; i <= totalMaps; i++) {
            mapIds[i - 1] = i;
            blockedPositions[i - 1] = _getPresetMap(i);
            scoringPositions[i - 1] = _getPresetScoringMap(i);
        }
    }

    /**
     * @dev Get all preset map IDs only (gas-efficient)
     * @return mapIds Array of map IDs
     */
    function getAllPresetMapIds() external view returns (uint[] memory mapIds) {
        uint totalMaps = mapCount;
        mapIds = new uint[](totalMaps);

        for (uint i = 1; i <= totalMaps; i++) {
            mapIds[i - 1] = i;
        }
    }

    /**
     * @dev Set a tile as blocked or unblocked for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate (0-19)
     * @param _col The column coordinate (0-39)
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
     * @dev Set a tile as scoring or non-scoring for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate
     * @param _col The column coordinate
     * @param _points The number of points available on this tile (0 for non-scoring)
     */
    function setScoringTile(
        uint _gameId,
        int16 _row,
        int16 _col,
        uint8 _points
    ) external onlyOwner {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            revert InvalidPosition();
        }
        scoringTiles[_gameId][_row][_col] = _points;
    }

    /**
     * @dev Check if a tile is blocked for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate (0-19)
     * @param _col The column coordinate (0-39)
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
     * @dev Check if a tile is scoring for a specific game
     * @param _gameId The game ID
     * @param _row The row coordinate (0-19)
     * @param _col The column coordinate (0-39)
     * @return Whether the tile is scoring
     */
    function isTileScoring(
        uint _gameId,
        int16 _row,
        int16 _col
    ) public view returns (uint8) {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            revert InvalidPosition();
        }
        return scoringTiles[_gameId][_row][_col];
    }

    /**
     * @dev Check if a tile is scoring and zero it out if it has the onlyOnce flag set
     * @param _gameId The game ID
     * @param _row The row coordinate
     * @param _col The column coordinate
     * @return The points on the tile
     */

    function getScoreAndZeroOut(
        uint _gameId,
        int16 _row,
        int16 _col
    ) public returns (uint8) {
        uint8 points = scoringTiles[_gameId][_row][_col];
        if (onlyOnceTiles[_gameId][_row][_col]) {
            scoringTiles[_gameId][_row][_col] = 0;
        }
        return points;
    }

    /**
     * @dev Check if a tile is scoring safely (public version that handles OOB gracefully)
     * @param _gameId The game ID
     * @param _row The row coordinate
     * @param _col The column coordinate
     * @return Whether the tile is scoring (treats OOB as non-scoring)
     */
    function isTileScoringSafe(
        uint _gameId,
        int16 _row,
        int16 _col
    ) public view returns (uint8) {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            return 0; // Treat out of bounds as non-scoring
        }
        return scoringTiles[_gameId][_row][_col];
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
     * @dev Check if a tile is scoring safely (for internal use in LOS)
     * @param _gameId The game ID
     * @param _row The row coordinate
     * @param _col The column coordinate
     * @return Whether the tile is scoring (treats OOB as non-scoring)
     */
    function _isTileScoringSafe(
        uint _gameId,
        int16 _row,
        int16 _col
    ) internal view returns (uint8) {
        if (_row < 0 || _row >= GRID_HEIGHT || _col < 0 || _col >= GRID_WIDTH) {
            return 0; // Treat out of bounds as non-scoring
        }
        return scoringTiles[_gameId][_row][_col];
    }

    /**
     * @dev Check if there's a clear line of sight between two points
     * @param _gameId The game ID
     * @param _row0 Starting row coordinate (0-19)
     * @param _col0 Starting column coordinate (0-39)
     * @param _row1 Ending row coordinate (0-19)
     * @param _col1 Ending column coordinate (0-39)
     * @return Whether there's a clear line of sight
     */
    function hasMaps(
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
        return _bresenhamMaps(_gameId, _row0, _col0, _row1, _col1);
    }

    /**
     * @dev Internal function implementing Bresenham's line of sight algorithm
     * Uses permissive corner mode (only blocks if both flankers are blocked)
     * Optimized to avoid stack too deep errors
     */
    function _bresenhamMaps(
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

    /**
     * @dev Get all blocked and scoring tiles for a specific game
     * @param _gameId The game ID
     * @return blockedPositions Array of blocked tile positions
     * @return scoringPositions Array of scoring tile positions
     */
    function getGameMapState(
        uint _gameId
    )
        external
        view
        returns (
            Position[] memory blockedPositions,
            ScoringPosition[] memory scoringPositions
        )
    {
        // Count blocked positions first
        uint blockedCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (blockedTiles[_gameId][row][col]) {
                    blockedCount++;
                }
            }
        }

        // Count scoring positions
        uint scoringCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                if (scoringTiles[_gameId][row][col] > 0) {
                    scoringCount++;
                }
            }
        }

        // Create arrays and populate with positions
        blockedPositions = new Position[](blockedCount);
        scoringPositions = new ScoringPosition[](scoringCount);

        uint blockedIndex = 0;
        uint scoringIndex = 0;

        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                // Add blocked positions
                if (blockedTiles[_gameId][row][col]) {
                    blockedPositions[blockedIndex] = Position(row, col);
                    blockedIndex++;
                }

                // Add scoring positions
                if (scoringTiles[_gameId][row][col] > 0) {
                    scoringPositions[scoringIndex] = ScoringPosition(
                        row,
                        col,
                        scoringTiles[_gameId][row][col],
                        onlyOnceTiles[_gameId][row][col]
                    );
                    scoringIndex++;
                }
            }
        }
    }
}
