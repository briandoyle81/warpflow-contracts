// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";
import "./Fleets.sol";

contract Game is Ownable, ReentrancyGuard {
    Ships public ships;
    Fleets public fleets;
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
        v1.specials.push(SpecialData(0, 0)); // None
        v1.specials.push(SpecialData(1, 0)); // EMP
        v1.specials.push(SpecialData(1, 0)); // RepairDrones
        v1.specials.push(SpecialData(1, 0)); // FlakArray
    }

    function setLobbiesAddress(address _lobbiesAddress) public onlyOwner {
        lobbiesAddress = _lobbiesAddress;
    }

    function setFleetsAddress(address _fleetsAddress) public onlyOwner {
        fleets = Fleets(_fleetsAddress);
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
        // Get creator fleet and calculate attributes
        Fleet memory creatorFleet = fleets.getFleet(_creatorFleetId);
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            calculateShipAttributes(_gameId, creatorFleet.shipIds[i]);
        }

        // Get joiner fleet and calculate attributes
        Fleet memory joinerFleet = fleets.getFleet(_joinerFleetId);
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            calculateShipAttributes(_gameId, joinerFleet.shipIds[i]);
        }
    }

    // Internal function to place ships on the grid
    function _placeShipsOnGrid(
        uint _gameId,
        uint _creatorFleetId,
        uint _joinerFleetId
    ) internal {
        GameData storage game = games[_gameId];

        // Place creator ships on the left side (column 0)
        Fleet memory creatorFleet = fleets.getFleet(_creatorFleetId);
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            uint8 row = uint8(i * 2); // Skip a row between each ship (rows 0, 2, 4, ...)
            _placeShipOnGrid(_gameId, creatorFleet.shipIds[i], row, 0, true);
        }

        // Place joiner ships on the right side (column GRID_WIDTH - 1)
        Fleet memory joinerFleet = fleets.getFleet(_joinerFleetId);
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint8 row = uint8(GRID_HEIGHT - 1 - (i * 2)); // Skip a row between each ship (rows 49, 47, 45, ...)
            _placeShipOnGrid(
                _gameId,
                joinerFleet.shipIds[i],
                row,
                GRID_WIDTH - 1,
                false
            );
        }
    }

    // Internal function to place a single ship on the grid
    function _placeShipOnGrid(
        uint _gameId,
        uint _shipId,
        uint8 _row,
        uint8 _column,
        bool _isCreator
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
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        GameData storage game = games[_gameId];
        return game.shipAttributes[_shipId];
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

        // Get creator fleet
        Fleet memory creatorFleet = fleets.getFleet(game.creatorFleetId);
        // Get joiner fleet
        Fleet memory joinerFleet = fleets.getFleet(game.joinerFleetId);

        // Count non-destroyed ships
        uint nonDestroyedShips = 0;

        // Count non-destroyed creator ships
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            uint shipId = creatorFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            if (ship.shipData.timestampDestroyed == 0) {
                nonDestroyedShips++;
            }
        }

        // Count non-destroyed joiner ships
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint shipId = joinerFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            if (ship.shipData.timestampDestroyed == 0) {
                nonDestroyedShips++;
            }
        }

        ShipPosition[] memory positions = new ShipPosition[](nonDestroyedShips);
        uint index = 0;

        // Add non-destroyed creator ships
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            uint shipId = creatorFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            if (ship.shipData.timestampDestroyed == 0) {
                positions[index] = ShipPosition({
                    shipId: shipId,
                    position: game.shipPositions[shipId],
                    isCreator: true
                });
                index++;
            }
        }

        // Add non-destroyed joiner ships
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint shipId = joinerFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            if (ship.shipData.timestampDestroyed == 0) {
                positions[index] = ShipPosition({
                    shipId: shipId,
                    position: game.shipPositions[shipId],
                    isCreator: false
                });
                index++;
            }
        }

        return positions;
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

        // Check if ship is in the game (either creator or joiner fleet)
        if (
            !_isShipInFleet(_gameId, _shipId, true) &&
            !_isShipInFleet(_gameId, _shipId, false)
        ) revert ShipNotFound();

        // Check if ship has already moved this round
        if (game.shipMovedThisRound[game.currentRound][_shipId])
            revert ShipAlreadyMoved();

        // Get current position
        Position memory currentPos = game.shipPositions[_shipId];

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
            game.currentRound++;
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
            // Must have > 0 hull points
            Attributes storage targetAttributes = game.shipAttributes[
                targetShipId
            ];
            if (targetAttributes.hullPoints == 0) revert InvalidMove();
            // Must be in range (manhattan)
            Position memory shooterPos = Position(_newRow, _newCol);
            Position memory targetPos = game.shipPositions[targetShipId];
            uint8 manhattan = _manhattanDistance(shooterPos, targetPos);
            Attributes storage shooterAttributes = game.shipAttributes[_shipId];
            if (manhattan > shooterAttributes.range) revert InvalidMove();
            // Calculate damage
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

        // Get both fleets
        Fleet memory creatorFleet = fleets.getFleet(game.creatorFleetId);
        Fleet memory joinerFleet = fleets.getFleet(game.joinerFleetId);

        // Check if all non-destroyed creator ships have moved
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            uint shipId = creatorFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            // Skip destroyed ships
            if (ship.shipData.timestampDestroyed != 0) continue;
            if (!game.shipMovedThisRound[game.currentRound][shipId]) {
                return false;
            }
        }

        // Check if all non-destroyed joiner ships have moved
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint shipId = joinerFleet.shipIds[i];
            Ship memory ship = ships.getShip(shipId);
            // Skip destroyed ships
            if (ship.shipData.timestampDestroyed != 0) continue;
            if (!game.shipMovedThisRound[game.currentRound][shipId]) {
                return false;
            }
        }

        return true;
    }

    // Switch turns only if the other player has unmoved ships
    function _switchTurnIfOtherPlayerHasShips(uint _gameId) internal {
        GameData storage game = games[_gameId];

        // Get both fleets
        Fleet memory creatorFleet = fleets.getFleet(game.creatorFleetId);
        Fleet memory joinerFleet = fleets.getFleet(game.joinerFleetId);

        if (game.currentTurn == game.creator) {
            // Creator just moved, check if joiner has unmoved ships
            for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
                uint shipId = joinerFleet.shipIds[i];
                Ship memory ship = ships.getShip(shipId);
                // Skip destroyed ships
                if (ship.shipData.timestampDestroyed != 0) continue;
                if (!game.shipMovedThisRound[game.currentRound][shipId]) {
                    // Joiner has unmoved ships, switch turn
                    game.currentTurn = game.joiner;
                    return;
                }
            }
            // Joiner has no unmoved ships, keep turn with creator
        } else {
            // Joiner just moved, check if creator has unmoved ships
            for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
                uint shipId = creatorFleet.shipIds[i];
                Ship memory ship = ships.getShip(shipId);
                // Skip destroyed ships
                if (ship.shipData.timestampDestroyed != 0) continue;
                if (!game.shipMovedThisRound[game.currentRound][shipId]) {
                    // Creator has unmoved ships, switch turn
                    game.currentTurn = game.creator;
                    return;
                }
            }
            // Creator has no unmoved ships, keep turn with joiner
        }
    }

    // Internal function to destroy a ship
    function _destroyShip(uint _gameId, uint _shipId) internal {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        GameData storage game = games[_gameId];

        // Check if ship exists and is in the game
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();

        // Check if ship is in the game (either creator or joiner fleet)
        bool isCreatorShip = _isShipInFleet(_gameId, _shipId, true);
        bool isJoinerShip = _isShipInFleet(_gameId, _shipId, false);
        if (!isCreatorShip && !isJoinerShip) revert ShipNotFound();

        // Check if ship is already destroyed
        if (ship.shipData.timestampDestroyed != 0) revert ShipDestroyed();

        // Remove ship from grid
        Position memory shipPosition = game.shipPositions[_shipId];
        game.grid[shipPosition.row][shipPosition.col] = 0;

        // Mark ship as moved this round so it doesn't block round completion
        game.shipMovedThisRound[game.currentRound][_shipId] = true;

        // Call the Ships contract to mark the ship as destroyed
        ships.setTimestampDestroyed(_shipId);
    }

    // Debug function to destroy a ship (onlyOwner for testing)
    function debugDestroyShip(uint _gameId, uint _shipId) external onlyOwner {
        _destroyShip(_gameId, _shipId);
    }

    // Internal helper functions

    function _isShipInFleet(
        uint _gameId,
        uint _shipId,
        bool _isCreator
    ) internal view returns (bool) {
        GameData storage game = games[_gameId];
        Fleet memory fleet = fleets.getFleet(
            _isCreator ? game.creatorFleetId : game.joinerFleetId
        );

        for (uint i = 0; i < fleet.shipIds.length; i++) {
            if (fleet.shipIds[i] == _shipId) {
                return true;
            }
        }
        return false;
    }

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
