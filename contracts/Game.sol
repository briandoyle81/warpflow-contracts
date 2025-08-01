// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";
import "./IFleets.sol";

contract Game is Ownable, ReentrancyGuard {
    Ships public ships;
    IFleets public fleets;
    address public lobbiesAddress;

    mapping(uint => GameData) public games;
    uint public gameCount;

    // Attributes version tracking
    mapping(uint16 => AttributesVersion) public attributesVersions;
    uint16 public currentAttributesVersion;

    // Grid constants
    uint8 public constant GRID_WIDTH = 100; // Number of columns
    uint8 public constant GRID_HEIGHT = 50; // Number of rows

    event GameStarted(
        uint indexed gameId,
        uint indexed lobbyId,
        address creator,
        address joiner
    );

    error NotLobbiesContract();
    error GameNotFound();
    error NotInGame();
    error InvalidAttributesVersion();
    error ShipNotFound();
    error InvalidPosition();
    error PositionOccupied();
    error NotYourTurn();
    error ShipNotOwned();
    error ShipAlreadyMoved();
    error MovementExceeded();
    error InvalidMove();
    error ShipDestroyed();
    error ActionRequired();

    constructor(address _ships) Ownable(msg.sender) {
        ships = Ships(_ships);

        // Initialize attributes version 1
        currentAttributesVersion = 1;

        // Set up default attributes version 1
        AttributesVersion storage v1 = attributesVersions[1];
        v1.version = 1;
        v1.baseHull = 100;
        v1.baseSpeed = 5;

        // Fore accuracy bonuses in whole number percentage multipliers
        v1.foreAccuracy.push(0);
        v1.foreAccuracy.push(125);
        v1.foreAccuracy.push(150);

        // Engine speed in raw movement modifier
        v1.engineSpeeds.push(0);
        v1.engineSpeeds.push(2);
        v1.engineSpeeds.push(5);

        // Initialize gun data
        v1.guns.push(GunData(10, 15, 0)); // Laser
        v1.guns.push(GunData(50, 10, 0)); // Railgun
        v1.guns.push(GunData(40, 15, -1)); // MissileLauncher
        v1.guns.push(GunData(4, 25, 0)); // PlasmaCannon

        // Initialize armor data
        v1.armors.push(ArmorData(0, 0)); // None
        v1.armors.push(ArmorData(10, -1)); // Light
        v1.armors.push(ArmorData(20, -2)); // Medium
        v1.armors.push(ArmorData(30, -3)); // Heavy

        // Initialize shield data
        v1.shields.push(ShieldData(0, 0)); // None
        v1.shields.push(ShieldData(10, 0)); // Light
        v1.shields.push(ShieldData(20, -1)); // Medium
        v1.shields.push(ShieldData(30, -2)); // Heavy

        // Initialize special data
        v1.specials.push(SpecialData(0, 0, 0)); // None
        v1.specials.push(SpecialData(1, 1, 0)); // EMP
        v1.specials.push(SpecialData(3, 25, 0)); // RepairDrones
        v1.specials.push(SpecialData(5, 5, 0)); // FlakArray
    }

    function setLobbiesAddress(address _lobbiesAddress) public onlyOwner {
        lobbiesAddress = _lobbiesAddress;
    }

    function setFleetsAddress(address _fleetsAddress) public onlyOwner {
        fleets = IFleets(_fleetsAddress);
    }

    function startGame(
        uint _lobbyId,
        address _creator,
        address _joiner,
        uint _creatorFleetId,
        uint _joinerFleetId,
        bool _creatorGoesFirst
    ) external {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        gameCount++;
        GameData storage game = games[gameCount];
        game.gameId = gameCount;
        game.lobbyId = _lobbyId;
        game.creator = _creator;
        game.joiner = _joiner;
        game.creatorFleetId = _creatorFleetId;
        game.joinerFleetId = _joinerFleetId;
        game.creatorGoesFirst = _creatorGoesFirst;
        game.startedAt = block.timestamp;
        game.currentTurn = _creatorGoesFirst ? _creator : _joiner;

        // Initialize grid dimensions
        game.gridWidth = GRID_WIDTH; // Number of columns
        game.gridHeight = GRID_HEIGHT; // Number of rows

        // Initialize round tracking
        game.currentRound = 1;

        // Calculate fleet attributes and place ships on grid
        _initializeFleetAttributes(gameCount, _creatorFleetId, _joinerFleetId);
        _placeShipsOnGrid(gameCount, _creatorFleetId, _joinerFleetId);

        emit GameStarted(gameCount, _lobbyId, _creator, _joiner);
    }

    // Internal function to initialize fleet attributes
    function _initializeFleetAttributes(
        uint _gameId,
        uint _creatorFleetId,
        uint _joinerFleetId
    ) internal {
        // Get creator fleet ship IDs and calculate attributes
        uint[] memory creatorShipIds = fleets.getFleetShipIds(_creatorFleetId);
        for (uint i = 0; i < creatorShipIds.length; i++) {
            calculateShipAttributes(_gameId, creatorShipIds[i]);
        }

        // Get joiner fleet ship IDs and calculate attributes
        uint[] memory joinerShipIds = fleets.getFleetShipIds(_joinerFleetId);
        for (uint i = 0; i < joinerShipIds.length; i++) {
            calculateShipAttributes(_gameId, joinerShipIds[i]);
        }
    }

    // Internal function to place ships on the grid
    function _placeShipsOnGrid(
        uint _gameId,
        uint _creatorFleetId,
        uint _joinerFleetId
    ) internal {
        // Place creator ships on the left side (column 0)
        uint[] memory creatorShipIds = fleets.getFleetShipIds(_creatorFleetId);
        for (uint i = 0; i < creatorShipIds.length; i++) {
            uint8 row = uint8(i * 2); // Skip a row between each ship (rows 0, 2, 4, ...)
            _placeShipOnGrid(_gameId, creatorShipIds[i], row, 0);
        }

        // Place joiner ships on the right side (column GRID_WIDTH - 1)
        uint[] memory joinerShipIds = fleets.getFleetShipIds(_joinerFleetId);
        for (uint i = 0; i < joinerShipIds.length; i++) {
            uint8 row = uint8(GRID_HEIGHT - 1 - (i * 2)); // Skip a row between each ship (rows 49, 47, 45, ...)
            _placeShipOnGrid(_gameId, joinerShipIds[i], row, GRID_WIDTH - 1);
        }
    }

    // Internal function to place a single ship on the grid
    function _placeShipOnGrid(
        uint _gameId,
        uint _shipId,
        uint8 _row,
        uint8 _column
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
        if (games[_gameId].gameId == 0) revert GameNotFound();
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        GameData storage game = games[_gameId];
        Attributes storage attributes = game.shipAttributes[_shipId];
        // Calculate base attributes from ship traits and equipment
        attributes.version = currentAttributesVersion;
        attributes.range = attributesVersions[currentAttributesVersion]
            .guns[uint8(ship.equipment.mainWeapon)]
            .range;
        attributes.gunDamage = attributesVersions[currentAttributesVersion]
            .guns[uint8(ship.equipment.mainWeapon)]
            .damage;
        attributes.hullPoints = _calculateHullPoints(ship);
        attributes.maxHullPoints = attributes.hullPoints;
        attributes.movement = _calculateMovement(ship);
        attributes.damageReduction = _calculateDamageReduction(ship);
        // Initialize empty status effects array
        attributes.statusEffects = new uint8[](0);
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
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];
        Attributes storage attributes = game.shipAttributes[_shipId];
        if (attributes.version == 0) revert ShipNotFound();
        return attributes;
    }

    // Get all ship attributes for a player in a game
    function getPlayerShipAttributes(
        uint _gameId,
        uint[] memory _shipIds
    ) public view returns (Attributes[] memory) {
        Attributes[] memory attributes = new Attributes[](_shipIds.length);
        for (uint i = 0; i < _shipIds.length; i++) {
            attributes[i] = getShipAttributes(_gameId, _shipIds[i]);
        }
        return attributes;
    }

    // Get ship position on the grid
    function getShipPosition(
        uint _gameId,
        uint _shipId
    ) public view returns (Position memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];
        return game.shipPositions[_shipId];
    }

    // Get ship at a specific grid position
    function getShipAtPosition(
        uint _gameId,
        uint8 _row,
        uint8 _column
    ) public view returns (uint) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        if (_row >= GRID_HEIGHT || _column >= GRID_WIDTH)
            revert InvalidPosition();
        GameData storage game = games[_gameId];
        return game.grid[_row][_column];
    }

    // Get all ship positions for a game
    function getAllShipPositions(
        uint _gameId
    ) public view returns (ShipPosition[] memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Count non-destroyed ships
        uint nonDestroyedShips = _countActiveShips(_gameId);

        ShipPosition[] memory positions = new ShipPosition[](nonDestroyedShips);
        uint index = 0;

        // Add creator ships
        index = _addFleetPositions(
            _gameId,
            game.creatorFleetId,
            positions,
            index,
            true
        );

        // Add joiner ships
        index = _addFleetPositions(
            _gameId,
            game.joinerFleetId,
            positions,
            index,
            false
        );

        return positions;
    }

    // Helper function to count active ships
    function _countActiveShips(uint _gameId) internal view returns (uint) {
        GameData storage game = games[_gameId];
        uint[] memory creatorShipIds = fleets.getFleetShipIds(
            game.creatorFleetId
        );
        uint[] memory joinerShipIds = fleets.getFleetShipIds(
            game.joinerFleetId
        );

        uint count = 0;

        // Count creator ships
        for (uint i = 0; i < creatorShipIds.length; i++) {
            if (_isShipActive(_gameId, creatorShipIds[i])) {
                count++;
            }
        }

        // Count joiner ships
        for (uint i = 0; i < joinerShipIds.length; i++) {
            if (_isShipActive(_gameId, joinerShipIds[i])) {
                count++;
            }
        }

        return count;
    }

    // Helper function to add fleet positions to the array
    function _addFleetPositions(
        uint _gameId,
        uint _fleetId,
        ShipPosition[] memory _positions,
        uint _startIndex,
        bool _isCreator
    ) internal view returns (uint) {
        GameData storage game = games[_gameId];
        uint[] memory shipIds = fleets.getFleetShipIds(_fleetId);
        uint index = _startIndex;

        for (uint i = 0; i < shipIds.length; i++) {
            uint shipId = shipIds[i];
            if (_isShipActive(_gameId, shipId)) {
                _positions[index] = ShipPosition({
                    shipId: shipId,
                    position: game.shipPositions[shipId],
                    isCreator: _isCreator
                });
                index++;
            }
        }

        return index;
    }

    // Helper functions to consolidate fleet iteration logic

    // Helper function to iterate over both fleets and apply a callback function
    function _iterateOverBothFleets(
        uint _gameId,
        function(uint, uint) internal view returns (bool) callback
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        uint[] memory creatorShipIds = fleets.getFleetShipIds(
            game.creatorFleetId
        );
        uint[] memory joinerShipIds = fleets.getFleetShipIds(
            game.joinerFleetId
        );

        // Check creator ships
        for (uint i = 0; i < creatorShipIds.length; i++) {
            uint shipId = creatorShipIds[i];
            if (callback(_gameId, shipId)) {
                return true;
            }
        }

        // Check joiner ships
        for (uint i = 0; i < joinerShipIds.length; i++) {
            uint shipId = joinerShipIds[i];
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
        uint[] memory creatorShipIds = fleets.getFleetShipIds(
            game.creatorFleetId
        );
        uint[] memory joinerShipIds = fleets.getFleetShipIds(
            game.joinerFleetId
        );

        // Check creator ships
        for (uint i = 0; i < creatorShipIds.length; i++) {
            uint shipId = creatorShipIds[i];
            callback(_gameId, shipId);
        }

        // Check joiner ships
        for (uint i = 0; i < joinerShipIds.length; i++) {
            uint shipId = joinerShipIds[i];
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
    function _isShipNotDestroyed(
        uint _gameId,
        uint _shipId
    ) internal view returns (bool) {
        Ship memory ship = ships.getShip(_shipId);
        return ship.shipData.timestampDestroyed == 0;
    }

    // Move a ship to a new position and perform an action (pass or shoot)
    // actionType: ActionType.Pass = 0, ActionType.Shoot = 1
    function moveShip(
        uint _gameId,
        uint _shipId,
        uint8 _newRow,
        uint8 _newCol,
        ActionType actionType,
        uint targetShipId
    ) external {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if it's the player's turn
        if (msg.sender != game.currentTurn) revert NotYourTurn();

        // Check if ship exists and is owned by the current player
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        if (ship.owner != msg.sender) revert ShipNotOwned();

        // Check if ship is destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Check if ship has 0 hull points (treat same as destroyed)
        Attributes storage shipAttrs = game.shipAttributes[_shipId];
        if (shipAttrs.hullPoints == 0) revert ShipDestroyed();

        // Check if ship is in the game (either creator or joiner fleet)
        if (
            !fleets.isShipInFleet(game.creatorFleetId, _shipId) &&
            !fleets.isShipInFleet(game.joinerFleetId, _shipId)
        ) revert ShipNotFound();

        // Check if ship has already moved this round
        if (game.shipMovedThisRound[game.currentRound][_shipId])
            revert ShipAlreadyMoved();

        // Get current position
        Position storage currentPos = game.shipPositions[_shipId];

        // Calculate movement cost
        uint8 movementCost = _calculateMovementCost(
            currentPos,
            _newRow,
            _newCol
        );

        // Get ship's movement attribute
        Attributes storage attributes = game.shipAttributes[_shipId];

        // Check if movement cost exceeds ship's movement
        if (movementCost > attributes.movement) revert MovementExceeded();

        // Validate new position
        if (_newRow >= GRID_HEIGHT || _newCol >= GRID_WIDTH)
            revert InvalidPosition();
        // Allow moving to the current position (no-op move), skip PositionOccupied check and skip _executeMove
        bool isNoOpMove = (currentPos.row == _newRow &&
            currentPos.col == _newCol);
        if (!isNoOpMove && game.grid[_newRow][_newCol] != 0)
            revert PositionOccupied();

        // Perform the move
        _executeMove(_gameId, _shipId, currentPos, _newRow, _newCol);

        // Mark ship as moved this round
        game.shipMovedThisRound[game.currentRound][_shipId] = true;

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
            // End of round: destroy ships with reactorCriticalTimer >= 3
            _destroyShipsWithCriticalReactor(_gameId);

            game.currentRound++;

            // Beginning of new round: increment reactorCriticalTimer for ships with 0 HP
            _incrementReactorCriticalTimerForZeroHPShips(_gameId);

            // Reset turn to the player who goes first
            game.currentTurn = game.creatorGoesFirst
                ? game.creator
                : game.joiner;
        } else {
            // Switch turns only if the other player has unmoved ships
            _switchTurnIfOtherPlayerHasShips(_gameId);
        }
    }

    // Internal function to perform an action (pass or shoot)
    function _performAction(
        GameData storage game,
        uint _gameId,
        uint _shipId,
        uint8 _newRow,
        uint8 _newCol,
        ActionType actionType,
        uint targetShipId
    ) internal {
        if (actionType == ActionType.Pass) {
            // Pass: do nothing
        } else if (actionType == ActionType.Shoot) {
            // Shoot
            // Validate target
            Ship memory targetShip = ships.getShip(targetShipId);
            if (targetShip.id == 0) revert ShipNotFound();
            if (targetShip.shipData.timestampDestroyed != 0)
                revert ShipDestroyed();
            // Must be on the other team (by owner address)
            Ship memory shooterShip = ships.getShip(_shipId);
            if (targetShip.owner == shooterShip.owner) revert InvalidMove();
            // Must be in range (manhattan)
            Position memory shooterPos = Position(_newRow, _newCol);
            Position storage targetPos = game.shipPositions[targetShipId];
            uint8 manhattan = _manhattanDistance(shooterPos, targetPos);
            Attributes storage shooterAttributes = game.shipAttributes[_shipId];
            if (manhattan > shooterAttributes.range) revert InvalidMove();

            // Get target attributes
            Attributes storage targetAttributes = game.shipAttributes[
                targetShipId
            ];

            // Handle ships with 0 hull points - increment reactor critical timer
            if (targetAttributes.hullPoints == 0) {
                targetAttributes.reactorCriticalTimer++;
                return; // No damage calculation needed for 0 HP ships
            }

            // Calculate damage for ships with > 0 hull points
            uint8 baseDamage = shooterAttributes.gunDamage;
            uint8 reduction = targetAttributes.damageReduction;
            uint8 reducedDamage = baseDamage - ((baseDamage * reduction) / 100);
            // Truncate division result
            // Reduce hull points
            if (reducedDamage >= targetAttributes.hullPoints) {
                targetAttributes.hullPoints = 0;
            } else {
                targetAttributes.hullPoints -= reducedDamage;
            }
        } else if (actionType == ActionType.Retreat) {
            // Retreat: remove ship from the game
            _retreatShip(_gameId, _shipId);
        } else if (actionType == ActionType.Assist) {
            // Assist: help a friendly ship with 0 HP retreat
            _performAssist(_gameId, _shipId, _newRow, _newCol, targetShipId);
        } else if (actionType == ActionType.Special) {
            // Special: use special equipment
            _performSpecial(_gameId, _shipId, _newRow, _newCol, targetShipId);
        } else {
            revert InvalidMove();
        }
    }

    // Internal pure function to calculate manhattan distance between two positions
    function _manhattanDistance(
        Position memory a,
        Position memory b
    ) internal pure returns (uint8) {
        uint8 rowDiff = a.row > b.row ? a.row - b.row : b.row - a.row;
        uint8 colDiff = a.col > b.col ? a.col - b.col : b.col - a.col;
        return rowDiff + colDiff;
    }

    // Check if both players have moved all their ships (round complete)
    function _checkRoundComplete(uint _gameId) internal view returns (bool) {
        GameData storage game = games[_gameId];

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
        return !game.shipMovedThisRound[game.currentRound][_shipId];
    }

    // Switch turns only if the other player has unmoved ships
    function _switchTurnIfOtherPlayerHasShips(uint _gameId) internal {
        GameData storage game = games[_gameId];

        if (game.currentTurn == game.creator) {
            // Creator just moved, check if joiner has unmoved ships
            bool joinerHasUnmovedShips = _checkPlayerHasUnmovedShips(
                _gameId,
                game.joinerFleetId
            );
            if (joinerHasUnmovedShips) {
                game.currentTurn = game.joiner;
            }
        } else {
            // Joiner just moved, check if creator has unmoved ships
            bool creatorHasUnmovedShips = _checkPlayerHasUnmovedShips(
                _gameId,
                game.creatorFleetId
            );
            if (creatorHasUnmovedShips) {
                game.currentTurn = game.creator;
            }
        }
    }

    // Helper function to check if a specific fleet has unmoved ships
    function _checkPlayerHasUnmovedShips(
        uint _gameId,
        uint _fleetId
    ) internal view returns (bool) {
        uint[] memory shipIds = fleets.getFleetShipIds(_fleetId);
        GameData storage game = games[_gameId];

        for (uint i = 0; i < shipIds.length; i++) {
            uint shipId = shipIds[i];
            if (
                _isShipActive(_gameId, shipId) &&
                !game.shipMovedThisRound[game.currentRound][shipId]
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
        uint8 _newRow,
        uint8 _newCol,
        uint _targetShipId
    ) internal {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Validate target ship exists
        Ship memory targetShip = ships.getShip(_targetShipId);
        if (targetShip.id == 0) revert ShipNotFound();
        if (targetShip.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Check if using ship has a special
        Ship memory usingShip = ships.getShip(_shipId);
        if (usingShip.equipment.special == Special.None) revert InvalidMove();

        // Validate special-specific requirements
        _validateSpecialRequirements(
            _gameId,
            _shipId,
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
        uint _shipId,
        uint8 _newRow,
        uint8 _newCol,
        uint _targetShipId,
        Ship memory _usingShip,
        Ship memory _targetShip
    ) internal view {
        GameData storage game = games[_gameId];

        if (_usingShip.equipment.special == Special.RepairDrones) {
            // RepairDrones can only target friendly ships
            if (_targetShip.owner != _usingShip.owner) revert InvalidMove();
            _validateSpecialRange(
                _gameId,
                _newRow,
                _newCol,
                _targetShipId,
                _usingShip.equipment.special
            );
        } else if (_usingShip.equipment.special == Special.EMP) {
            // EMP can only target enemy ships
            if (_targetShip.owner == _usingShip.owner) revert InvalidMove();
            _validateSpecialRange(
                _gameId,
                _newRow,
                _newCol,
                _targetShipId,
                _usingShip.equipment.special
            );
        } else if (_usingShip.equipment.special == Special.FlakArray) {
            // FlakArray doesn't need a target - it affects all ships in range
            // No additional validation needed here
        } else {
            revert InvalidMove(); // Other specials not implemented yet
        }
    }

    // Helper function to validate special range
    function _validateSpecialRange(
        uint _gameId,
        uint8 _newRow,
        uint8 _newCol,
        uint _targetShipId,
        Special _special
    ) internal view {
        GameData storage game = games[_gameId];
        Position storage targetPos = game.shipPositions[_targetShipId];
        Position memory usingPos = Position(_newRow, _newCol);
        uint8 specialRange = attributesVersions[currentAttributesVersion]
            .specials[uint8(_special)]
            .range;
        uint8 manhattan = _manhattanDistance(usingPos, targetPos);
        if (manhattan > specialRange) {
            revert InvalidMove();
        }
    }

    // Helper function to execute special actions
    function _executeSpecialAction(
        uint _gameId,
        uint _shipId,
        uint8 _newRow,
        uint8 _newCol,
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

        uint8 repairStrength = _getSpecialStrength(Special.RepairDrones);

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

        uint8 empStrength = _getSpecialStrength(Special.EMP);

        // Increase reactor critical timer by the EMP strength
        targetAttributes.reactorCriticalTimer += empStrength;
    }

    // Helper function to get special strength from attributes version
    function _getSpecialStrength(
        Special _special
    ) internal view returns (uint8) {
        return
            attributesVersions[currentAttributesVersion]
                .specials[uint8(_special)]
                .strength;
    }

    // Internal function to perform FlakArray special
    function _performFlakArray(
        uint _gameId,
        uint _shipId, // The id of the ship using the FlakArray
        uint8 _newRow,
        uint8 _newCol
    ) internal {
        GameData storage game = games[_gameId];

        // Get the range and strength of FlakArray from the attributes version
        uint8 flakRange = attributesVersions[currentAttributesVersion]
            .specials[uint8(Special.FlakArray)]
            .range;
        uint8 flakStrength = attributesVersions[currentAttributesVersion]
            .specials[uint8(Special.FlakArray)]
            .strength;

        // Get both fleet ship IDs to check all ships
        uint[] memory creatorShipIds = fleets.getFleetShipIds(
            game.creatorFleetId
        );
        uint[] memory joinerShipIds = fleets.getFleetShipIds(
            game.joinerFleetId
        );

        // Check all creator ships
        for (uint i = 0; i < creatorShipIds.length; i++) {
            uint shipId = creatorShipIds[i];
            Ship memory ship = ships.getShip(shipId);

            // Skip destroyed ships
            if (ship.shipData.timestampDestroyed != 0) continue;

            // Skip ships with 0 hull points (treat same as destroyed)
            if (game.shipAttributes[shipId].hullPoints == 0) continue;

            // Check if ship is within range
            Position storage shipPos = game.shipPositions[shipId];
            Position memory flakPos = Position(_newRow, _newCol);
            uint8 distance = _manhattanDistance(flakPos, shipPos);

            if (distance <= flakRange && shipId != _shipId) {
                // Apply damage to this ship (but not the ship using the FlakArray)
                Attributes storage shipAttrs = game.shipAttributes[shipId];
                if (flakStrength >= shipAttrs.hullPoints) {
                    shipAttrs.hullPoints = 0;
                } else {
                    shipAttrs.hullPoints -= flakStrength;
                }
            }
        }

        // Check all joiner ships
        for (uint i = 0; i < joinerShipIds.length; i++) {
            uint shipId = joinerShipIds[i];
            Ship memory ship = ships.getShip(shipId);

            // Skip destroyed ships
            if (ship.shipData.timestampDestroyed != 0) continue;

            // Skip ships with 0 hull points (treat same as destroyed)
            if (game.shipAttributes[shipId].hullPoints == 0) continue;

            // Check if ship is within range
            Position storage shipPos = game.shipPositions[shipId];
            Position memory flakPos = Position(_newRow, _newCol);
            uint8 distance = _manhattanDistance(flakPos, shipPos);

            if (distance <= flakRange && shipId != _shipId) {
                // Apply damage to this ship (but not the ship using the FlakArray)
                Attributes storage shipAttrs = game.shipAttributes[shipId];
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
        uint8 _newRow,
        uint8 _newCol,
        uint _targetShipId
    ) internal {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Validate target ship exists
        Ship memory targetShip = ships.getShip(_targetShipId);
        if (targetShip.id == 0) revert ShipNotFound();
        if (targetShip.shipData.timestampDestroyed != 0) revert ShipDestroyed();

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
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if ship exists and is in the game
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();

        // Check if ship is in the game (either creator or joiner fleet)
        bool isCreatorShip = fleets.isShipInFleet(game.creatorFleetId, _shipId);
        bool isJoinerShip = fleets.isShipInFleet(game.joinerFleetId, _shipId);
        if (!isCreatorShip && !isJoinerShip) revert ShipNotFound();

        // Check if ship is already destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Remove ship from grid
        Position storage shipPosition = game.shipPositions[_shipId];
        game.grid[shipPosition.row][shipPosition.col] = 0;

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.currentRound][_shipId] = true;

        // Remove ship from fleet
        if (isCreatorShip) {
            fleets.removeShipFromFleet(game.creatorFleetId, _shipId);
        } else {
            fleets.removeShipFromFleet(game.joinerFleetId, _shipId);
        }

        // Clean up ship data in the game contract
        delete game.shipAttributes[_shipId];
        delete game.shipPositions[_shipId];
    }

    // Internal function to destroy a ship
    function _destroyShip(uint _gameId, uint _shipId) internal {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if ship exists and is in the game
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();

        // Check if ship is in the game (either creator or joiner fleet)
        bool isCreatorShip = fleets.isShipInFleet(game.creatorFleetId, _shipId);
        bool isJoinerShip = fleets.isShipInFleet(game.joinerFleetId, _shipId);
        if (!isCreatorShip && !isJoinerShip) revert ShipNotFound();

        // Check if ship is already destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Remove ship from grid
        Position storage shipPosition = game.shipPositions[_shipId];
        game.grid[shipPosition.row][shipPosition.col] = 0;

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.currentRound][_shipId] = true;

        // Call the Ships contract to mark the ship as destroyed
        ships.setTimestampDestroyed(_shipId);
    }

    // Internal function to destroy ships with reactorCriticalTimer >= 3
    function _destroyShipsWithCriticalReactor(uint _gameId) internal {
        _iterateOverBothFleetsStateful(_gameId, _destroyShipIfCritical);
    }

    // Helper function for _destroyShipsWithCriticalReactor
    function _destroyShipIfCritical(uint _gameId, uint _shipId) internal {
        GameData storage game = games[_gameId];

        // Only check non-destroyed ships
        if (!_isShipNotDestroyed(_gameId, _shipId)) return;

        // Check if ship has critical reactor timer
        if (game.shipAttributes[_shipId].reactorCriticalTimer >= 3) {
            _destroyShip(_gameId, _shipId);
        }
    }

    // Internal function to increment reactorCriticalTimer for ships with 0 HP
    function _incrementReactorCriticalTimerForZeroHPShips(
        uint _gameId
    ) internal {
        _iterateOverBothFleetsStateful(_gameId, _incrementTimerIfZeroHP);
    }

    // Helper function for _incrementReactorCriticalTimerForZeroHPShips
    function _incrementTimerIfZeroHP(uint _gameId, uint _shipId) internal {
        GameData storage game = games[_gameId];

        // Only check non-destroyed ships
        if (!_isShipNotDestroyed(_gameId, _shipId)) return;

        // Increment reactor critical timer for ships with 0 HP
        if (game.shipAttributes[_shipId].hullPoints == 0) {
            game.shipAttributes[_shipId].reactorCriticalTimer++;
        }
    }

    // Debug function to destroy a ship (onlyOwner for testing)
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

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.currentRound][_shipId] = true;
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
        game.shipMovedThisRound[game.currentRound][_shipId] = true;
    }

    // Debug function to set a ship in a specific position (onlyOwner for testing)
    function debugSetShipPosition(
        uint _gameId,
        uint _shipId,
        uint8 _row,
        uint8 _col
    ) external onlyOwner {
        // No checks needed for debug, assume correct info given

        // Set ship position
        games[_gameId].shipPositions[_shipId] = Position(_row, _col);

        // Set ship in grid
        games[_gameId].grid[_row][_col] = _shipId;
    }

    // Internal helper functions

    function _calculateMovementCost(
        Position memory _currentPos,
        uint8 _newRow,
        uint8 _newCol
    ) internal pure returns (uint8) {
        uint8 rowDiff = _currentPos.row > _newRow
            ? _currentPos.row - _newRow
            : _newRow - _currentPos.row;
        uint8 colDiff = _currentPos.col > _newCol
            ? _currentPos.col - _newCol
            : _newCol - _currentPos.col;

        // Only allow orthogonal movement (up, down, left, right)
        if (rowDiff > 0 && colDiff > 0) revert InvalidMove();

        return rowDiff + colDiff;
    }

    function _executeMove(
        uint _gameId,
        uint _shipId,
        Position memory _currentPos,
        uint8 _newRow,
        uint8 _newCol
    ) internal {
        GameData storage game = games[_gameId];

        // Remove ship from current position
        game.grid[_currentPos.row][_currentPos.col] = 0;

        // Place ship at new position
        game.grid[_newRow][_newCol] = _shipId;
        game.shipPositions[_shipId] = Position(_newRow, _newCol);
    }

    // Internal calculation functions

    function _calculateHullPoints(
        Ship memory _ship
    ) internal view returns (uint8) {
        AttributesVersion storage version = attributesVersions[
            currentAttributesVersion
        ];
        uint8 baseHull = version.baseHull;
        uint8 traitBonus = _ship.traits.hull * 10; // Convert trait to hull points
        return baseHull + traitBonus;
    }

    function _calculateMovement(
        Ship memory _ship
    ) internal view returns (uint8) {
        AttributesVersion storage version = attributesVersions[
            currentAttributesVersion
        ];
        int8 baseMovement = int8(version.baseSpeed);

        // Add trait bonus
        baseMovement += int8(_ship.traits.speed);

        // Extract equipment bonuses as int8 to avoid stack-too-deep or type mismatch
        int8 gunMovement = version
            .guns[uint8(_ship.equipment.mainWeapon)]
            .movement;
        int8 armorMovement = version
            .armors[uint8(_ship.equipment.armor)]
            .movement;
        int8 shieldMovement = version
            .shields[uint8(_ship.equipment.shields)]
            .movement;
        int8 specialMovement = version
            .specials[uint8(_ship.equipment.special)]
            .movement;

        baseMovement +=
            gunMovement +
            armorMovement +
            shieldMovement +
            specialMovement;

        return baseMovement > 0 ? uint8(baseMovement) : 0;
    }

    function _calculateDamageReduction(
        Ship memory _ship
    ) internal view returns (uint8) {
        AttributesVersion storage version = attributesVersions[
            currentAttributesVersion
        ];

        uint8 damageReduction = 0;

        damageReduction += version
            .armors[uint8(_ship.equipment.armor)]
            .damageReduction;
        damageReduction += version
            .shields[uint8(_ship.equipment.shields)]
            .damageReduction;

        return damageReduction;
    }

    // Attributes version management
    // TODO: CRITICAL Either enable viaIR or do this the hard way
    // function setAttributesVersion(
    //     AttributesVersion memory _version
    // ) public onlyOwner {
    //     currentAttributesVersion++;
    //     _version.version = currentAttributesVersion;
    //     attributesVersions[currentAttributesVersion] = _version;
    // }

    // View functions
    function getGame(
        uint _gameId,
        uint[] memory _creatorShipIds,
        uint[] memory _joinerShipIds
    ) public view returns (GameDataView memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();

        GameData storage game = games[_gameId];

        // Calculate total number of ships
        uint totalShips = _creatorShipIds.length + _joinerShipIds.length;

        // Get all ship attributes in a single array
        Attributes[] memory shipAttrs = new Attributes[](totalShips);

        // Add creator ship attributes first
        for (uint i = 0; i < _creatorShipIds.length; i++) {
            shipAttrs[i] = game.shipAttributes[_creatorShipIds[i]];
        }

        // Add joiner ship attributes after creator ships
        for (uint i = 0; i < _joinerShipIds.length; i++) {
            shipAttrs[_creatorShipIds.length + i] = game.shipAttributes[
                _joinerShipIds[i]
            ];
        }

        // Get all ship positions
        ShipPosition[] memory shipPositions = getAllShipPositions(_gameId);

        return
            GameDataView({
                gameId: game.gameId,
                lobbyId: game.lobbyId,
                creator: game.creator,
                joiner: game.joiner,
                creatorFleetId: game.creatorFleetId,
                joinerFleetId: game.joinerFleetId,
                creatorGoesFirst: game.creatorGoesFirst,
                startedAt: game.startedAt,
                currentTurn: game.currentTurn,
                shipAttributes: shipAttrs,
                shipPositions: shipPositions,
                gridWidth: game.gridWidth,
                gridHeight: game.gridHeight
            });
    }
}
