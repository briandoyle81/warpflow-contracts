// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Types.sol";
import "./IShips.sol";
import "./IFleets.sol";
import "./IShipAttributes.sol";
import "./IMaps.sol";
import "./IGameResults.sol";

contract Game is Ownable {
    IShips public ships;
    IFleets public fleets;
    IShipAttributes public shipAttributes;
    IMaps public maps;
    address public lobbiesAddress;
    IGameResults public gameResults;

    mapping(uint => GameData) public games;
    uint public gameCount;

    mapping(address => uint[]) public playerGames;

    // Tracking for last damage for kill credits
    mapping(uint target => uint lastDamager) public lastDamage;

    // Grid constants
    int16 public constant GRID_WIDTH = 40; // Number of columns
    int16 public constant GRID_HEIGHT = 20; // Number of rows

    event GameStarted(
        uint indexed gameId,
        uint indexed lobbyId,
        address creator,
        address joiner
    );

    error NotLobbiesContract();
    error GameNotFound();
    error NotInGame();
    error ShipNotFound();
    error InvalidPosition();
    error PositionOccupied();
    error NotYourTurn();
    error ShipNotOwned();
    error ShipAlreadyMoved();
    error InvalidMove();
    error ShipDestroyed();
    error ActionRequired();
    error TurnTimeoutNotReached();
    error TurnTimeoutExceeded();

    constructor(address _ships, address _shipAttributes) Ownable(msg.sender) {
        ships = IShips(_ships);
        shipAttributes = IShipAttributes(_shipAttributes);
    }

    function setAddresses(
        address _mapsAddress,
        address _lobbiesAddress,
        address _fleetsAddress,
        address _gameResultsAddress,
        address _shipAttributesAddress
    ) public onlyOwner {
        maps = IMaps(_mapsAddress);
        lobbiesAddress = _lobbiesAddress;
        fleets = IFleets(_fleetsAddress);
        gameResults = IGameResults(_gameResultsAddress);
        shipAttributes = IShipAttributes(_shipAttributesAddress);
    }

    function startGame(
        uint _lobbyId,
        address _creator,
        address _joiner,
        uint _creatorFleetId,
        uint _joinerFleetId,
        bool _creatorGoesFirst,
        uint _turnTime,
        uint _selectedMapId,
        uint _maxScore
    ) external {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        gameCount++;
        GameData storage game = games[gameCount];

        // Initialize metadata
        game.metadata.gameId = gameCount;
        game.metadata.lobbyId = _lobbyId;
        game.metadata.creator = _creator;
        game.metadata.joiner = _joiner;
        game.metadata.creatorFleetId = _creatorFleetId;
        game.metadata.joinerFleetId = _joinerFleetId;
        game.metadata.creatorGoesFirst = _creatorGoesFirst;
        game.metadata.startedAt = block.timestamp;

        // Initialize turn state
        game.turnState.currentTurn = _creatorGoesFirst ? _creator : _joiner;
        game.turnState.turnTime = _turnTime;
        game.turnState.turnStartTime = block.timestamp;
        game.turnState.currentRound = 1;

        // Initialize grid dimensions
        game.gridDimensions.gridWidth = GRID_WIDTH; // Number of columns
        game.gridDimensions.gridHeight = GRID_HEIGHT; // Number of rows

        // Set max score for the game
        game.maxScore = _maxScore;

        // Apply the selected preset map to this game if a map was selected
        if (_selectedMapId > 0) {
            maps.applyPresetMapToGame(gameCount, _selectedMapId);
        }

        // Calculate fleet attributes and place ships on grid
        _initializeFleetAttributes(gameCount, _creatorFleetId, _joinerFleetId);
        _placeShipsOnGrid(gameCount, _creatorFleetId, _joinerFleetId);

        // Track game for both players
        playerGames[_creator].push(gameCount);
        playerGames[_joiner].push(gameCount);

        emit GameStarted(gameCount, _lobbyId, _creator, _joiner);
    }

    // Internal function to initialize fleet attributes
    function _initializeFleetAttributes(
        uint _gameId,
        uint _creatorFleetId,
        uint _joinerFleetId
    ) internal {
        GameData storage game = games[_gameId];

        // Get creator fleet ship IDs and calculate attributes
        uint[] memory creatorShipIds = fleets.getFleetShipIds(_creatorFleetId);
        // Store creator ship IDs
        for (uint i = 0; i < creatorShipIds.length; i++) {
            EnumerableSet.add(
                game.playerActiveShipIds[game.metadata.creator],
                creatorShipIds[i]
            );
            calculateShipAttributes(_gameId, creatorShipIds[i]);
        }

        // Get joiner fleet ship IDs and calculate attributes
        uint[] memory joinerShipIds = fleets.getFleetShipIds(_joinerFleetId);
        // Store joiner ship IDs
        for (uint i = 0; i < joinerShipIds.length; i++) {
            EnumerableSet.add(
                game.playerActiveShipIds[game.metadata.joiner],
                joinerShipIds[i]
            );
            calculateShipAttributes(_gameId, joinerShipIds[i]);
        }
    }

    // Internal function to place ships on the grid
    function _placeShipsOnGrid(
        uint _gameId,
        uint /* _creatorFleetId */,
        uint /* _joinerFleetId */
    ) internal {
        GameData storage game = games[_gameId];

        // Place creator ships on the left side (column 0)
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        uint creatorShipCount = EnumerableSet.length(creatorShipIds);
        for (uint i = 0; i < creatorShipCount; i++) {
            uint shipId = EnumerableSet.at(creatorShipIds, i);
            int16 row = int16(uint16(i * 2)); // Skip a row between each ship (rows 0, 2, 4, ...)
            _placeShipOnGrid(_gameId, shipId, row, 0);
        }

        // Place joiner ships on the right side (column GRID_WIDTH - 1)
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];
        uint joinerShipCount = EnumerableSet.length(joinerShipIds);
        for (uint i = 0; i < joinerShipCount; i++) {
            uint shipId = EnumerableSet.at(joinerShipIds, i);
            int16 row = int16(uint16(GRID_HEIGHT - 1 - int16(uint16(i * 2)))); // Skip a row between each ship (rows 39, 37, 35, ...)
            _placeShipOnGrid(_gameId, shipId, row, GRID_WIDTH - 1);
        }
    }

    // Internal function to place a single ship on the grid
    function _placeShipOnGrid(
        uint _gameId,
        uint _shipId,
        int16 _row,
        int16 _column
    ) internal {
        GameData storage game = games[_gameId];

        // Validate position is within grid bounds
        if (_row >= GRID_HEIGHT || _column >= GRID_WIDTH)
            revert InvalidPosition();

        // Check if position is already occupied
        if (game.grid[_row][_column] != 0) revert PositionOccupied();

        // Place ship on grid at specified row and column
        game.grid[_row][_column] = _shipId;
        game.shipPositions[_shipId] = Position(_row, _column);
    }

    // Calculate and store attributes for a ship in a game
    function calculateShipAttributes(uint _gameId, uint _shipId) public {
        GameData storage game = games[_gameId];
        Attributes storage attributes = game.shipAttributes[_shipId];

        // Get calculated attributes from ShipAttributes contract
        Attributes memory calculatedAttributes = shipAttributes
            .calculateShipAttributesById(_shipId);

        // Copy the calculated attributes to game storage
        attributes.version = calculatedAttributes.version;
        attributes.range = calculatedAttributes.range;
        attributes.gunDamage = calculatedAttributes.gunDamage;
        attributes.hullPoints = calculatedAttributes.hullPoints;
        attributes.maxHullPoints = calculatedAttributes.maxHullPoints;
        attributes.movement = calculatedAttributes.movement;
        attributes.damageReduction = calculatedAttributes.damageReduction;
        attributes.statusEffects = calculatedAttributes.statusEffects;
    }

    // Calculate attributes for all ships in a fleet
    function calculateFleetAttributes(
        uint _gameId,
        uint[] memory _shipIds
    ) public {
        for (uint i = 0; i < _shipIds.length; i++) {
            calculateShipAttributes(_gameId, _shipIds[i]);
        }
    }

    // Get ship attributes for a specific game
    function getShipAttributes(
        uint _gameId,
        uint _shipId
    ) public view returns (Attributes memory) {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        Attributes storage attributes = games[_gameId].shipAttributes[_shipId];
        if (attributes.version == 0) revert ShipNotFound();
        return attributes;
    }

    // Get ship position on the grid

    // Get all ship positions for a game
    // External view, memory use ok
    function getAllShipPositions(
        uint _gameId
    ) public view returns (ShipPosition[] memory) {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // First, count how many ships are actually in the grid (including 0 HP ships)
        uint shipCount = 0;
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                uint shipId = game.grid[row][col];
                if (shipId > 0 && _isShipNotDestroyed(shipId)) {
                    shipCount++;
                }
            }
        }

        // Create array with actual count
        ShipPosition[] memory positions = new ShipPosition[](shipCount);
        uint index = 0;

        // Iterate through the grid to find all ships
        for (int16 row = 0; row < GRID_HEIGHT; row++) {
            for (int16 col = 0; col < GRID_WIDTH; col++) {
                uint shipId = game.grid[row][col];
                if (shipId > 0 && _isShipNotDestroyed(shipId)) {
                    // Determine if this is a creator or joiner ship
                    bool isCreator = _isCreatorShip(_gameId, shipId);
                    positions[index] = ShipPosition({
                        shipId: shipId,
                        position: Position({row: row, col: col}),
                        isCreator: isCreator
                    });
                    index++;
                }
            }
        }

        return positions;
    }

    // Helper function to determine if a ship belongs to the creator
    function _isCreatorShip(
        uint _gameId,
        uint _shipId
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        return
            EnumerableSet.contains(
                game.playerActiveShipIds[game.metadata.creator],
                _shipId
            );
    }

    // Helper functions to consolidate fleet iteration logic

    // Helper function to iterate over both fleets and apply a callback function
    function _iterateOverBothFleets(
        uint _gameId,
        function(uint, uint) internal view returns (bool) callback
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];

        // Check creator ships
        uint creatorShipCount = EnumerableSet.length(creatorShipIds);
        for (uint i = 0; i < creatorShipCount; i++) {
            uint shipId = EnumerableSet.at(creatorShipIds, i);
            if (callback(_gameId, shipId)) {
                return true;
            }
        }

        // Check joiner ships
        uint joinerShipCount = EnumerableSet.length(joinerShipIds);
        for (uint i = 0; i < joinerShipCount; i++) {
            uint shipId = EnumerableSet.at(joinerShipIds, i);
            if (callback(_gameId, shipId)) {
                return true;
            }
        }

        return false;
    }

    // Helper function to iterate over both fleets and apply a callback function that can modify state
    function _iterateOverBothFleetsStateful(
        uint _gameId,
        function(uint, uint) internal callback
    ) internal {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];

        // Check creator ships
        uint creatorShipCount = EnumerableSet.length(creatorShipIds);
        for (uint i = 0; i < creatorShipCount; i++) {
            uint shipId = EnumerableSet.at(creatorShipIds, i);
            callback(_gameId, shipId);
        }

        // Check joiner ships
        uint joinerShipCount = EnumerableSet.length(joinerShipIds);
        for (uint i = 0; i < joinerShipCount; i++) {
            uint shipId = EnumerableSet.at(joinerShipIds, i);
            callback(_gameId, shipId);
        }
    }

    // Helper function to check if a ship is active (not destroyed and has hull points)
    function _isShipActive(
        uint _gameId,
        uint _shipId
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        Ship memory ship = ships.getShip(_shipId);

        // Skip destroyed ships
        if (ship.shipData.timestampDestroyed != 0) return false;
        // Skip ships with 0 hull points (treat same as destroyed)
        if (game.shipAttributes[_shipId].hullPoints == 0) return false;

        return true;
    }

    // Helper function to check if a ship is not destroyed (for functions that don't check hull points)
    function _isShipNotDestroyed(uint _shipId) internal view returns (bool) {
        return !ships.isShipDestroyed(_shipId);
    }

    // Helper function to check if a player has any active ships
    function _playerHasActiveShips(
        uint _gameId,
        address _player
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage shipIds = game.playerActiveShipIds[
            _player
        ];

        uint shipCount = EnumerableSet.length(shipIds);
        for (uint i = 0; i < shipCount; i++) {
            uint shipId = EnumerableSet.at(shipIds, i);
            if (_isShipActive(_gameId, shipId)) {
                return true;
            }
        }
        return false;
    }

    // Helper function to check if the game should end due to a player having no active ships
    function _checkGameEndCondition(uint _gameId) internal {
        GameData storage game = games[_gameId];

        // Check if creator has no active ships
        if (!_playerHasActiveShips(_gameId, game.metadata.creator)) {
            _endGame(_gameId, game.metadata.joiner, game.metadata.creator);
            return;
        }

        // Check if joiner has no active ships
        if (!_playerHasActiveShips(_gameId, game.metadata.joiner)) {
            _endGame(_gameId, game.metadata.creator, game.metadata.joiner);
            return;
        }
    }

    // Helper function to end the game and record results
    function _endGame(uint _gameId, address _winner, address _loser) internal {
        GameData storage game = games[_gameId];
        game.metadata.winner = _winner;
        if (address(gameResults) != address(0)) {
            gameResults.recordGameResult(_gameId, _winner, _loser);
        }
        // Remove all ships from fleets when game ends
        _removeShipsFromFleet(
            _gameId,
            game.metadata.creator,
            game.metadata.creatorFleetId
        );
        _removeShipsFromFleet(
            _gameId,
            game.metadata.joiner,
            game.metadata.joinerFleetId
        );
    }

    // Move a ship to a new position and perform an action (pass or shoot)
    // actionType: ActionType.Pass = 0, ActionType.Shoot = 1
    function moveShip(
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        ActionType actionType,
        uint targetShipId
    ) external {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if game has ended
        if (game.metadata.winner != address(0)) revert InvalidMove();

        // Check if it's the player's turn
        if (msg.sender != game.turnState.currentTurn) revert NotYourTurn();

        // Check if ship exists and is owned by the current player
        Ship memory ship = _validateShipExistsAndNotDestroyed(_shipId);
        if (ship.owner != msg.sender) revert ShipNotOwned();

        // Check if ship has 0 hull points (treat same as destroyed)
        Attributes storage shipAttrs = game.shipAttributes[_shipId];
        if (shipAttrs.hullPoints == 0) revert ShipDestroyed();

        // Check if ship is in the game (either creator or joiner fleet)
        if (
            !fleets.isShipInFleet(game.metadata.creatorFleetId, _shipId) &&
            !fleets.isShipInFleet(game.metadata.joinerFleetId, _shipId)
        ) revert ShipNotFound();

        // Check if ship has already moved this round
        if (game.shipMovedThisRound[game.turnState.currentRound][_shipId])
            revert ShipAlreadyMoved();

        // Get current position
        Position storage currentPos = game.shipPositions[_shipId];

        // Allow moving to the current position (no-op move), skip movement validation and PositionOccupied check
        bool isNoOpMove = (currentPos.row == _newRow &&
            currentPos.col == _newCol);

        if (!isNoOpMove) {
            // Calculate movement cost only for actual moves
            uint8 movementCost = _manhattanDistance(
                currentPos,
                Position(_newRow, _newCol)
            );

            // Get ship's movement attribute
            Attributes storage attributes = game.shipAttributes[_shipId];

            // Check if movement cost exceeds ship's movement
            if (movementCost > attributes.movement) revert InvalidMove();

            // Validate new position
            if (_newRow >= GRID_HEIGHT || _newCol >= GRID_WIDTH)
                revert InvalidPosition();

            // Check if position is occupied
            if (game.grid[_newRow][_newCol] != 0) revert PositionOccupied();
        }

        // Perform the move only if it's not a no-op move
        if (!isNoOpMove) {
            _executeMove(_gameId, _shipId, currentPos, _newRow, _newCol);
        }

        // Mark ship as moved this round
        game.shipMovedThisRound[game.turnState.currentRound][_shipId] = true;

        // Perform the action
        _performAction(
            game,
            _gameId,
            _shipId,
            _newRow,
            _newCol,
            actionType,
            targetShipId
        );

        // Check if both players have moved all their ships (round complete)
        if (_checkRoundComplete(_gameId)) {
            _handleEndOfRound(_gameId);
        } else {
            // Switch turns only if the other player has unmoved ships
            _switchTurnIfOtherPlayerHasShips(_gameId);
        }

        // Update turn start time for the new turn
        game.turnState.turnStartTime = block.timestamp;
    }

    // Internal function to perform an action (pass or shoot)
    function _performAction(
        GameData storage game,
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        ActionType actionType,
        uint targetShipId
    ) internal {
        // Get ship data once for all action types
        Ship memory ship = ships.getShip(_shipId);

        if (actionType == ActionType.Pass) {
            // Pass: do nothing
        } else if (actionType == ActionType.Shoot) {
            _performShoot(
                game,
                _gameId,
                _shipId,
                _newRow,
                _newCol,
                targetShipId,
                ship
            );
        } else if (actionType == ActionType.Retreat) {
            // Retreat: remove ship from the game
            _retreatShip(_gameId, _shipId);
        } else if (actionType == ActionType.Assist) {
            // Assist: help a friendly ship with 0 HP retreat
            _performAssist(_gameId, _shipId, _newRow, _newCol, targetShipId);
        } else if (actionType == ActionType.Special) {
            // Special: use special equipment
            _performSpecial(_gameId, _shipId, _newRow, _newCol, targetShipId);
        } else if (actionType == ActionType.ClaimPoints) {
            // ClaimPoints: get points from the tile the ship moved to
            _performClaimPoints(_gameId, ship.owner, _newRow, _newCol);
        } else {
            revert InvalidMove();
        }
    }

    // Internal function to perform shoot action
    function _performShoot(
        GameData storage game,
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        uint targetShipId,
        Ship memory ship
    ) internal {
        // Validate target
        Ship memory targetShip = _validateShipExistsAndNotDestroyed(
            targetShipId
        );
        // Must be on the other team (by owner address)
        if (targetShip.owner == ship.owner) revert InvalidMove();
        // Must be in range (manhattan)
        Position memory shooterPos = Position(_newRow, _newCol);
        Position storage targetPos = game.shipPositions[targetShipId];
        uint8 manhattan = _manhattanDistance(shooterPos, targetPos);
        Attributes storage shooterAttributes = game.shipAttributes[_shipId];
        if (manhattan > shooterAttributes.range) revert InvalidMove();

        // Must have line of sight to target if manhattan > 1, can always see adjacent to shoot
        if (
            manhattan > 1 &&
            !maps.hasMaps(
                _gameId,
                _newRow,
                _newCol,
                targetPos.row,
                targetPos.col
            )
        ) {
            revert InvalidMove();
        }

        // Get target attributes
        Attributes storage targetAttributes = game.shipAttributes[targetShipId];

        // Handle ships with 0 hull points - increment reactor critical timer
        if (targetAttributes.hullPoints == 0) {
            targetAttributes.reactorCriticalTimer++;
            return; // No damage calculation needed for 0 HP ships
        }

        // Calculate damage for ships with > 0 hull points
        uint8 baseDamage = shooterAttributes.gunDamage;
        uint8 reduction = targetAttributes.damageReduction;
        uint16 reducedDamage = baseDamage -
            ((uint16(baseDamage) * reduction) / 100);
        // Truncate division result
        // Reduce hull points
        if (reducedDamage >= targetAttributes.hullPoints) {
            targetAttributes.hullPoints = 0;
            // Track the kill for the shooter
            lastDamage[targetShipId] = _shipId;
        } else {
            targetAttributes.hullPoints -= uint8(reducedDamage);
        }
    }

    // Internal pure function to calculate manhattan distance between two positions
    function _manhattanDistance(
        Position memory a,
        Position memory b
    ) internal pure returns (uint8) {
        uint8 rowDiff = a.row > b.row
            ? uint8(uint16(a.row - b.row))
            : uint8(uint16(b.row - a.row));
        uint8 colDiff = a.col > b.col
            ? uint8(uint16(a.col - b.col))
            : uint8(uint16(b.col - a.col));
        return rowDiff + colDiff;
    }

    // Helper function to copy EnumerableSet to array
    function _copySetToArray(
        EnumerableSet.UintSet storage set
    ) internal view returns (uint[] memory) {
        uint count = EnumerableSet.length(set);
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = EnumerableSet.at(set, i);
        }
        return result;
    }

    // Helper function to validate ship exists and is not destroyed
    function _validateShipExistsAndNotDestroyed(
        uint _shipId
    ) internal view returns (Ship memory) {
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();
        return ship;
    }

    // Check if both players have moved all their ships (round complete)
    function _checkRoundComplete(uint _gameId) internal view returns (bool) {
        // Use helper function to check if any active ship hasn't moved
        bool hasUnmovedShip = _iterateOverBothFleets(_gameId, _checkShipMoved);
        return !hasUnmovedShip;
    }

    // Helper function for _checkRoundComplete
    function _checkShipMoved(
        uint _gameId,
        uint _shipId
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];

        // Only check active ships
        if (!_isShipActive(_gameId, _shipId)) return false;

        // Return true if ship hasn't moved (indicating round is not complete)
        return !game.shipMovedThisRound[game.turnState.currentRound][_shipId];
    }

    // Switch turns only if the other player has unmoved ships
    function _switchTurnIfOtherPlayerHasShips(uint _gameId) internal {
        GameData storage game = games[_gameId];

        if (game.turnState.currentTurn == game.metadata.creator) {
            // Creator just moved, check if joiner has unmoved ships
            bool joinerHasUnmovedShips = _checkPlayerHasUnmovedShips(
                _gameId,
                game.metadata.joiner
            );
            if (joinerHasUnmovedShips) {
                game.turnState.currentTurn = game.metadata.joiner;
            }
        } else {
            // Joiner just moved, check if creator has unmoved ships
            bool creatorHasUnmovedShips = _checkPlayerHasUnmovedShips(
                _gameId,
                game.metadata.creator
            );
            if (creatorHasUnmovedShips) {
                game.turnState.currentTurn = game.metadata.creator;
            }
        }
    }

    // Helper function to check if a specific player has unmoved ships
    function _checkPlayerHasUnmovedShips(
        uint _gameId,
        address _player
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage shipIds = game.playerActiveShipIds[
            _player
        ];

        uint shipCount = EnumerableSet.length(shipIds);
        for (uint i = 0; i < shipCount; i++) {
            uint shipId = EnumerableSet.at(shipIds, i);
            if (
                _isShipActive(_gameId, shipId) &&
                !game.shipMovedThisRound[game.turnState.currentRound][shipId]
            ) {
                return true;
            }
        }
        return false;
    }

    // Internal function to perform special action
    function _performSpecial(
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        uint _targetShipId
    ) internal {
        // Validate target ship exists
        Ship memory targetShip = _validateShipExistsAndNotDestroyed(
            _targetShipId
        );

        // Check if using ship has a special
        Ship memory usingShip = ships.getShip(_shipId);
        if (usingShip.equipment.special == Special.None) revert InvalidMove();

        // Validate special-specific requirements
        _validateSpecialRequirements(
            _gameId,
            _newRow,
            _newCol,
            _targetShipId,
            usingShip,
            targetShip
        );

        // Execute the special action
        _executeSpecialAction(
            _gameId,
            _shipId,
            _newRow,
            _newCol,
            _targetShipId,
            usingShip.equipment.special
        );
    }

    // Helper function to validate special-specific requirements
    function _validateSpecialRequirements(
        uint _gameId,
        int16 _newRow,
        int16 _newCol,
        uint _targetShipId,
        Ship memory _usingShip,
        Ship memory _targetShip
    ) internal view {
        Special special = _usingShip.equipment.special;

        if (special == Special.RepairDrones) {
            // RepairDrones can only target friendly ships
            if (_targetShip.owner != _usingShip.owner) revert InvalidMove();
        } else if (special == Special.EMP) {
            // EMP can only target enemy ships
            if (_targetShip.owner == _usingShip.owner) revert InvalidMove();
        } else if (special == Special.FlakArray) {
            // FlakArray doesn't need a target - it affects all ships in range
            return; // No additional validation needed
        } else {
            revert InvalidMove(); // Other specials not implemented yet
        }

        // Validate range for specials that need targets
        if (special != Special.FlakArray) {
            _validateSpecialRange(
                _gameId,
                _newRow,
                _newCol,
                _targetShipId,
                special
            );
        }
    }

    // Helper function to validate special range
    function _validateSpecialRange(
        uint _gameId,
        int16 _newRow,
        int16 _newCol,
        uint _targetShipId,
        Special _special
    ) internal view {
        GameData storage game = games[_gameId];
        Position storage targetPos = game.shipPositions[_targetShipId];
        Position memory usingPos = Position(_newRow, _newCol);
        uint8 specialRange = shipAttributes.getSpecialRange(_special);
        uint8 manhattan = _manhattanDistance(usingPos, targetPos);
        if (manhattan > specialRange) {
            revert InvalidMove();
        }
    }

    // Helper function to execute special actions
    function _executeSpecialAction(
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        uint _targetShipId,
        Special _special
    ) internal {
        if (_special == Special.RepairDrones) {
            _performRepairDrones(_gameId, _targetShipId);
        } else if (_special == Special.EMP) {
            _performEMP(_gameId, _targetShipId);
        } else if (_special == Special.FlakArray) {
            _performFlakArray(_gameId, _shipId, _newRow, _newCol);
        } else {
            revert InvalidMove(); // Other specials not implemented yet
        }
    }

    // Internal function to perform RepairDrones special
    function _performRepairDrones(uint _gameId, uint _targetShipId) internal {
        GameData storage game = games[_gameId];
        Attributes storage targetAttributes = game.shipAttributes[
            _targetShipId
        ];

        uint8 repairStrength = shipAttributes.getSpecialStrength(
            Special.RepairDrones
        );

        // Increase hull points by the repair strength, but don't exceed max hull points
        uint8 newHullPoints = targetAttributes.hullPoints + repairStrength;
        if (newHullPoints > targetAttributes.maxHullPoints) {
            targetAttributes.hullPoints = targetAttributes.maxHullPoints;
        } else {
            targetAttributes.hullPoints = newHullPoints;
        }
    }

    // Internal function to perform EMP special
    function _performEMP(uint _gameId, uint _targetShipId) internal {
        GameData storage game = games[_gameId];
        Attributes storage targetAttributes = game.shipAttributes[
            _targetShipId
        ];

        uint8 empStrength = shipAttributes.getSpecialStrength(Special.EMP);
        lastDamage[_targetShipId] = _targetShipId;
        // Increase reactor critical timer by the EMP strength
        targetAttributes.reactorCriticalTimer += empStrength;
    }

    // Internal function to perform FlakArray special
    function _performFlakArray(
        uint _gameId,
        uint _shipId, // The id of the ship using the FlakArray
        int16 _newRow,
        int16 _newCol
    ) internal {
        GameData storage game = games[_gameId];

        // Get the range and strength of FlakArray from the attributes version
        uint8 flakRange = shipAttributes.getSpecialRange(Special.FlakArray);
        uint8 flakStrength = shipAttributes.getSpecialStrength(
            Special.FlakArray
        );

        // Process both fleets using the same logic
        _processFlakArrayForFleet(
            _gameId,
            _shipId,
            _newRow,
            _newCol,
            flakRange,
            flakStrength,
            game.playerActiveShipIds[game.metadata.creator]
        );
        _processFlakArrayForFleet(
            _gameId,
            _shipId,
            _newRow,
            _newCol,
            flakRange,
            flakStrength,
            game.playerActiveShipIds[game.metadata.joiner]
        );
    }

    // Helper function to process flak array damage for a single fleet
    function _processFlakArrayForFleet(
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        uint8 flakRange,
        uint8 flakStrength,
        EnumerableSet.UintSet storage shipIds
    ) internal {
        GameData storage game = games[_gameId];
        uint shipCount = EnumerableSet.length(shipIds);
        Position memory flakPos = Position(_newRow, _newCol);

        for (uint i = 0; i < shipCount; i++) {
            uint targetShipId = EnumerableSet.at(shipIds, i);
            Ship memory ship = ships.getShip(targetShipId);

            // Skip destroyed ships
            if (ship.shipData.timestampDestroyed != 0) continue;

            // Skip ships with 0 hull points (treat same as destroyed)
            if (game.shipAttributes[targetShipId].hullPoints == 0) continue;

            // Check if ship is within range and not the ship using flak
            Position storage shipPos = game.shipPositions[targetShipId];
            uint8 distance = _manhattanDistance(flakPos, shipPos);

            if (distance <= flakRange && targetShipId != _shipId) {
                lastDamage[targetShipId] = _shipId;
                // Apply damage to this ship
                Attributes storage shipAttrs = game.shipAttributes[
                    targetShipId
                ];
                if (flakStrength >= shipAttrs.hullPoints) {
                    shipAttrs.hullPoints = 0;
                } else {
                    shipAttrs.hullPoints -= flakStrength;
                }
            }
        }
    }

    // Internal function to perform assist action
    function _performAssist(
        uint _gameId,
        uint _shipId,
        int16 _newRow,
        int16 _newCol,
        uint _targetShipId
    ) internal {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Validate target ship exists
        Ship memory targetShip = _validateShipExistsAndNotDestroyed(
            _targetShipId
        );

        // Must be on the same team (by owner address)
        Ship memory assistingShip = ships.getShip(_shipId);
        if (targetShip.owner != assistingShip.owner) revert InvalidMove();

        // Target ship must have 0 hull points
        Attributes storage targetAttributes = game.shipAttributes[
            _targetShipId
        ];
        if (targetAttributes.hullPoints > 0) revert InvalidMove();

        // Check if assisting ship is adjacent to target ship (orthogonal only, no diagonals)
        Position storage targetPos = game.shipPositions[_targetShipId];
        Position memory assistingPos = Position(_newRow, _newCol);

        // Must be exactly 1 square away orthogonally (not diagonal)
        uint8 manhattan = _manhattanDistance(assistingPos, targetPos);
        if (manhattan != 1) {
            revert InvalidMove();
        }

        // Perform the assist - retreat the target ship
        _retreatShip(_gameId, _targetShipId);
    }

    // Internal function to retreat a ship
    function _retreatShip(uint _gameId, uint _shipId) internal {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if ship exists and is in the game
        Ship memory ship = _validateShipExistsAndNotDestroyed(_shipId);

        // Check if ship is in the game (either creator or joiner fleet)
        bool isCreatorShip = fleets.isShipInFleet(
            game.metadata.creatorFleetId,
            _shipId
        );
        bool isJoinerShip = fleets.isShipInFleet(
            game.metadata.joinerFleetId,
            _shipId
        );
        if (!isCreatorShip && !isJoinerShip) revert ShipNotFound();

        // Check if ship is already destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Remove ship from grid
        Position storage shipPosition = game.shipPositions[_shipId];
        game.grid[shipPosition.row][shipPosition.col] = 0;

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.turnState.currentRound][_shipId] = true;

        // Remove ship from fleet
        if (isCreatorShip) {
            fleets.removeShipFromFleet(game.metadata.creatorFleetId, _shipId);
        } else {
            fleets.removeShipFromFleet(game.metadata.joinerFleetId, _shipId);
        }

        // Clean up ship data in the game contract
        delete game.shipAttributes[_shipId];
        delete game.shipPositions[_shipId];

        // Remove ship from playerActiveShipIds
        _removeShipFromPlayerActiveShips(_gameId, _shipId);

        // Check if the game should end due to a player having no active ships
        _checkGameEndCondition(_gameId);
    }

    // Internal function to destroy a ship
    function _destroyShip(uint _gameId, uint _shipId) internal {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if ship exists and is in the game
        Ship memory ship = _validateShipExistsAndNotDestroyed(_shipId);

        // Check if ship is in the game (either creator or joiner fleet)
        bool isCreatorShip = fleets.isShipInFleet(
            game.metadata.creatorFleetId,
            _shipId
        );
        bool isJoinerShip = fleets.isShipInFleet(
            game.metadata.joinerFleetId,
            _shipId
        );
        if (!isCreatorShip && !isJoinerShip) revert ShipNotFound();

        // Check if ship is already destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Remove ship from grid
        Position storage shipPosition = game.shipPositions[_shipId];
        game.grid[shipPosition.row][shipPosition.col] = 0;

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.turnState.currentRound][_shipId] = true;

        // Call the Ships contract to mark the ship as destroyed
        // For reactor critical destruction, there's no specific destroyer
        ships.setTimestampDestroyed(_shipId, lastDamage[_shipId]);

        // Remove ship from playerActiveShipIds
        _removeShipFromPlayerActiveShips(_gameId, _shipId);

        // Check if the game should end due to a player having no active ships
        _checkGameEndCondition(_gameId);
    }

    // Helper function to remove a ship from playerActiveShipIds
    function _removeShipFromPlayerActiveShips(
        uint _gameId,
        uint _shipId
    ) internal {
        GameData storage game = games[_gameId];

        // Try to remove from creator's ships
        EnumerableSet.remove(
            game.playerActiveShipIds[game.metadata.creator],
            _shipId
        );

        // Try to remove from joiner's ships
        EnumerableSet.remove(
            game.playerActiveShipIds[game.metadata.joiner],
            _shipId
        );
    }

    // Internal function to destroy ships with reactorCriticalTimer >= 3
    function _destroyShipsWithCriticalReactor(uint _gameId) internal {
        GameData storage game = games[_gameId];

        // Get all ships that need to be destroyed
        uint[] memory shipsToDestroy = new uint[](100); // Max reasonable ships
        uint destroyCount = 0;

        // Check creator ships
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        uint creatorShipCount = EnumerableSet.length(creatorShipIds);
        for (uint i = 0; i < creatorShipCount; i++) {
            uint shipId = EnumerableSet.at(creatorShipIds, i);
            if (
                _isShipNotDestroyed(shipId) &&
                game.shipAttributes[shipId].reactorCriticalTimer >= 3
            ) {
                shipsToDestroy[destroyCount] = shipId;
                destroyCount++;
            }
        }

        // Check joiner ships
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];
        uint joinerShipCount = EnumerableSet.length(joinerShipIds);
        for (uint i = 0; i < joinerShipCount; i++) {
            uint shipId = EnumerableSet.at(joinerShipIds, i);
            if (
                _isShipNotDestroyed(shipId) &&
                game.shipAttributes[shipId].reactorCriticalTimer >= 3
            ) {
                shipsToDestroy[destroyCount] = shipId;
                destroyCount++;
            }
        }

        // Destroy all ships that need to be destroyed
        for (uint i = 0; i < destroyCount; i++) {
            _destroyShip(_gameId, shipsToDestroy[i]);
        }
    }

    // Internal function to increment reactorCriticalTimer for ships with 0 HP
    function _incrementReactorCriticalTimerForZeroHPShips(
        uint _gameId
    ) internal {
        GameData storage game = games[_gameId];

        // Check creator ships
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        uint creatorShipCount = EnumerableSet.length(creatorShipIds);
        for (uint i = 0; i < creatorShipCount; i++) {
            uint shipId = EnumerableSet.at(creatorShipIds, i);
            if (
                _isShipNotDestroyed(shipId) &&
                game.shipAttributes[shipId].hullPoints == 0
            ) {
                game.shipAttributes[shipId].reactorCriticalTimer++;
            }
        }

        // Check joiner ships
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];
        uint joinerShipCount = EnumerableSet.length(joinerShipIds);
        for (uint i = 0; i < joinerShipCount; i++) {
            uint shipId = EnumerableSet.at(joinerShipIds, i);
            if (
                _isShipNotDestroyed(shipId) &&
                game.shipAttributes[shipId].hullPoints == 0
            ) {
                game.shipAttributes[shipId].reactorCriticalTimer++;
            }
        }
    }

    function debugDestroyShip(uint _gameId, uint _shipId) external onlyOwner {
        _destroyShip(_gameId, _shipId);
    }

    // Debug function to set a ship's hull points to 0 (onlyOwner for testing)
    function debugSetHullPointsToZero(
        uint _gameId,
        uint _shipId
    ) external onlyOwner {
        GameData storage game = games[_gameId];

        // Set hull points to 0
        game.shipAttributes[_shipId].hullPoints = 0;

        // Don't remove ship from grid to allow testing scenarios where we want
        // to simulate 0 hull points but still have the ship in the game for repair

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.turnState.currentRound][_shipId] = true;

        // Note: We don't remove from playerActiveShipIds to allow testing scenarios
        // where we want to simulate 0 hull points but still have the ship participate
        // in round completion logic (for reactor critical timer increments)
        // We don't call _checkGameEndCondition here to allow testing scenarios
        // where we want to simulate 0 hull points without ending the game
    }

    // Debug function to set a ship's reactor critical timer (onlyOwner for testing)
    function debugSetReactorCriticalTimer(
        uint _gameId,
        uint _shipId,
        uint8 _timer
    ) external onlyOwner {
        GameData storage game = games[_gameId];
        game.shipAttributes[_shipId].reactorCriticalTimer = _timer;
    }

    // Debug function to mark a ship as moved this round (onlyOwner for testing)
    function debugMarkShipAsMoved(
        uint _gameId,
        uint _shipId
    ) external onlyOwner {
        GameData storage game = games[_gameId];
        // Mark ship as moved this round
        game.shipMovedThisRound[game.turnState.currentRound][_shipId] = true;
    }

    // Debug function to set a ship in a specific position (onlyOwner for testing)
    function debugSetShipPosition(
        uint _gameId,
        uint _shipId,
        int16 _row,
        int16 _col
    ) external onlyOwner {
        // No checks needed for debug, assume correct info given

        // Clear old position in grid
        games[_gameId].grid[games[_gameId].shipPositions[_shipId].row][
            games[_gameId].shipPositions[_shipId].col
        ] = 0;

        // Set ship position
        games[_gameId].shipPositions[_shipId] = Position(_row, _col);

        // Set ship in grid
        games[_gameId].grid[_row][_col] = _shipId;
    }

    // Internal helper functions

    function _calculateMovementCost(
        Position memory _currentPos,
        int16 _newRow,
        int16 _newCol
    ) internal pure returns (uint8) {
        uint8 rowDiff = _currentPos.row > _newRow
            ? uint8(uint16(_currentPos.row - _newRow))
            : uint8(uint16(_newRow - _currentPos.row));
        uint8 colDiff = _currentPos.col > _newCol
            ? uint8(uint16(_currentPos.col - _newCol))
            : uint8(uint16(_newCol - _currentPos.col));

        // Allow diagonal movement - cost is Manhattan distance (rowDiff + colDiff)
        return rowDiff + colDiff;
    }

    function _executeMove(
        uint _gameId,
        uint _shipId,
        Position memory _currentPos,
        int16 _newRow,
        int16 _newCol
    ) internal {
        GameData storage game = games[_gameId];

        // Remove ship from current position
        game.grid[_currentPos.row][_currentPos.col] = 0;

        // Place ship at new position
        game.grid[_newRow][_newCol] = _shipId;
        game.shipPositions[_shipId] = Position(_newRow, _newCol);
    }

    // View functions
    function getGame(
        uint _gameId,
        uint[] memory _creatorShipIds,
        uint[] memory _joinerShipIds
    ) public view returns (GameDataView memory) {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();

        GameData storage game = games[_gameId];

        // Calculate total number of ships
        uint totalShips = _creatorShipIds.length + _joinerShipIds.length;

        uint[] memory shipIds = new uint[](totalShips);

        uint indexCursor = 0;

        // Get all ship attributes in a single array
        Attributes[] memory shipAttrs = new Attributes[](totalShips);

        // Add creator ship attributes first
        for (uint i = 0; i < _creatorShipIds.length; i++) {
            shipAttrs[i] = game.shipAttributes[_creatorShipIds[i]];
            shipIds[indexCursor] = _creatorShipIds[i];
            indexCursor++;
        }

        // Add joiner ship attributes after creator ships
        for (uint i = 0; i < _joinerShipIds.length; i++) {
            shipAttrs[_creatorShipIds.length + i] = game.shipAttributes[
                _joinerShipIds[i]
            ];
            shipIds[indexCursor] = _joinerShipIds[i];
            indexCursor++;
        }

        // Get all ship positions
        ShipPosition[] memory shipPositions = getAllShipPositions(_gameId);

        // Get active ship IDs for each player
        EnumerableSet.UintSet storage creatorShipIds = game.playerActiveShipIds[
            game.metadata.creator
        ];
        EnumerableSet.UintSet storage joinerShipIds = game.playerActiveShipIds[
            game.metadata.joiner
        ];

        // Copy active ship IDs using helper function
        uint[] memory creatorActiveShipIds = _copySetToArray(creatorShipIds);
        uint[] memory joinerActiveShipIds = _copySetToArray(joinerShipIds);

        return
            GameDataView({
                metadata: game.metadata,
                turnState: game.turnState,
                gridDimensions: game.gridDimensions,
                maxScore: game.maxScore,
                creatorScore: game.creatorScore,
                joinerScore: game.joinerScore,
                shipAttributes: shipAttrs,
                shipPositions: shipPositions,
                shipIds: shipIds,
                creatorActiveShipIds: creatorActiveShipIds,
                joinerActiveShipIds: joinerActiveShipIds
            });
    }

    // Check if current turn has timed out
    function _isTurnTimedOut(uint _gameId) internal view returns (bool) {
        GameData storage game = games[_gameId];
        return
            block.timestamp >
            game.turnState.turnStartTime + game.turnState.turnTime;
    }

    // Force a move when turn times out (only the other player can call this)
    function forceMoveOnTimeout(uint _gameId) external {
        if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        if (!_isTurnTimedOut(_gameId)) revert TurnTimeoutNotReached();

        GameData storage game = games[_gameId];

        // Only the other player can force a timeout skip
        if (msg.sender == game.turnState.currentTurn) revert NotYourTurn();

        // Must be either the creator or joiner
        if (
            msg.sender != game.metadata.creator &&
            msg.sender != game.metadata.joiner
        ) revert NotInGame();

        // Auto-pass the current player's turn
        _autoPassTurn(_gameId);
    }

    // Flee function - either player can end the game at any time
    function flee(uint _gameId) external {
        // TODO: I think this is fine
        // if (games[_gameId].metadata.gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if game has already ended
        if (game.metadata.winner != address(0)) revert InvalidMove();

        // Must be either the creator or joiner
        if (
            msg.sender != game.metadata.creator &&
            msg.sender != game.metadata.joiner
        ) revert NotInGame();

        // Set the other player as the winner and record the game result
        address winner = msg.sender == game.metadata.creator
            ? game.metadata.joiner
            : game.metadata.creator;
        _endGame(_gameId, winner, msg.sender);
    }

    // Helper function to remove ships from a specific fleet
    function _removeShipsFromFleet(
        uint _gameId,
        address _player,
        uint _fleetId
    ) internal {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage shipIds = game.playerActiveShipIds[
            _player
        ];

        uint shipCount = EnumerableSet.length(shipIds);
        for (uint i = 0; i < shipCount; i++) {
            uint shipId = EnumerableSet.at(shipIds, i);
            fleets.removeShipFromFleet(_fleetId, shipId);
        }
    }

    // Helper function to handle end-of-round logic
    function _handleEndOfRound(uint _gameId) internal {
        GameData storage game = games[_gameId];

        // End of round: destroy ships with reactorCriticalTimer >= 3
        _destroyShipsWithCriticalReactor(_gameId);

        game.turnState.currentRound++;

        // Beginning of new round: increment reactorCriticalTimer for ships with 0 HP
        _incrementReactorCriticalTimerForZeroHPShips(_gameId);

        // Reset turn to the player who goes first
        game.turnState.currentTurn = game.metadata.creatorGoesFirst
            ? game.metadata.creator
            : game.metadata.joiner;
    }

    // Internal function to auto-pass a player's turn when they timeout
    function _autoPassTurn(uint _gameId) internal {
        GameData storage game = games[_gameId];

        // Mark all unmoved ships of the current player as moved (auto-pass)
        if (game.turnState.currentTurn == game.metadata.creator) {
            _autoPassPlayerShips(_gameId, game.metadata.creator);
        } else {
            _autoPassPlayerShips(_gameId, game.metadata.joiner);
        }

        // Check if round is complete after auto-pass
        if (_checkRoundComplete(_gameId)) {
            _handleEndOfRound(_gameId);
        } else {
            // Switch turns only if the other player has unmoved ships
            _switchTurnIfOtherPlayerHasShips(_gameId);
        }

        // Update turn start time for the new turn
        game.turnState.turnStartTime = block.timestamp;
    }

    // Helper function to auto-pass all unmoved ships for a specific player
    function _autoPassPlayerShips(uint _gameId, address _player) internal {
        GameData storage game = games[_gameId];
        EnumerableSet.UintSet storage shipIds = game.playerActiveShipIds[
            _player
        ];

        uint shipCount = EnumerableSet.length(shipIds);
        for (uint i = 0; i < shipCount; i++) {
            uint shipId = EnumerableSet.at(shipIds, i);
            if (
                _isShipActive(_gameId, shipId) &&
                !game.shipMovedThisRound[game.turnState.currentRound][shipId]
            ) {
                // Mark ship as moved (auto-pass)
                game.shipMovedThisRound[game.turnState.currentRound][
                    shipId
                ] = true;
            }
        }
    }

    // Internal function to handle ClaimPoints action
    function _performClaimPoints(
        uint _gameId,
        address _player,
        int16 _row,
        int16 _col
    ) internal {
        GameData storage game = games[_gameId];

        // Get the points from the Maps contract for this tile
        uint8 points = maps.getScoreAndZeroOut(_gameId, _row, _col);

        // If there are points on this tile, claim them
        if (points > 0) {
            // Update the player's score
            if (_player == game.metadata.creator) {
                game.creatorScore += points;
            } else if (_player == game.metadata.joiner) {
                game.joinerScore += points;
            }

            // Check if either player has reached the max score
            if (
                game.creatorScore >= game.maxScore ||
                game.joinerScore >= game.maxScore
            ) {
                // Determine winner based on scores and end the game
                address winner = game.creatorScore >= game.joinerScore
                    ? game.metadata.creator
                    : game.metadata.joiner;
                address loser = winner == game.metadata.creator
                    ? game.metadata.joiner
                    : game.metadata.creator;
                _endGame(_gameId, winner, loser);
            }
        }
    }

    // Player game tracking view functions
    function getGamesFromIds(
        uint[] memory _gameIds
    ) public view returns (GameDataView[] memory) {
        GameDataView[] memory result = new GameDataView[](_gameIds.length);
        for (uint i = 0; i < _gameIds.length; i++) {
            result[i] = getGame(_gameIds[i], new uint[](0), new uint[](0));
        }
        return result;
    }

    function getPlayerGameIds(
        address _player
    ) public view returns (uint[] memory) {
        return playerGames[_player];
    }

    function getGamesForPlayer(
        address _player
    ) public view returns (GameDataView[] memory) {
        uint[] memory gameIds = getPlayerGameIds(_player);
        return getGamesFromIds(gameIds);
    }
}
