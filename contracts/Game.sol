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
            calculateShipAttributes(_gameId, creatorFleet.shipIds[i], true);
        }

        // Get joiner fleet and calculate attributes
        Fleet memory joinerFleet = fleets.getFleet(_joinerFleetId);
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            calculateShipAttributes(_gameId, joinerFleet.shipIds[i], false);
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
            uint8 row = uint8(i); // Start from top row (row 0) and move down
            _placeShipOnGrid(_gameId, creatorFleet.shipIds[i], row, 0, true);
        }

        // Place joiner ships on the right side (column GRID_WIDTH - 1)
        Fleet memory joinerFleet = fleets.getFleet(_joinerFleetId);
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint8 row = uint8(GRID_HEIGHT - 1 - i); // Start from bottom row (row GRID_HEIGHT - 1) and move up
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
    function calculateShipAttributes(
        uint _gameId,
        uint _shipId,
        bool _isCreator
    ) public {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        GameData storage game = games[_gameId];
        Attributes storage attributes = _isCreator
            ? game.creatorShipAttributes[_shipId]
            : game.joinerShipAttributes[_shipId];
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
        // Initialize empty status effects array
        attributes.statusEffects = new uint8[](0);
    }

    // Calculate attributes for all ships in a fleet
    function calculateFleetAttributes(
        uint _gameId,
        uint[] memory _shipIds,
        bool _isCreator
    ) public {
        for (uint i = 0; i < _shipIds.length; i++) {
            calculateShipAttributes(_gameId, _shipIds[i], _isCreator);
        }
    }

    // Get ship attributes for a specific game
    function getShipAttributes(
        uint _gameId,
        uint _shipId,
        bool _isCreator
    ) public view returns (Attributes memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        GameData storage game = games[_gameId];
        return
            _isCreator
                ? game.creatorShipAttributes[_shipId]
                : game.joinerShipAttributes[_shipId];
    }

    // Get all ship attributes for a player in a game
    function getPlayerShipAttributes(
        uint _gameId,
        uint[] memory _shipIds,
        bool _isCreator
    ) public view returns (Attributes[] memory) {
        Attributes[] memory attributes = new Attributes[](_shipIds.length);
        for (uint i = 0; i < _shipIds.length; i++) {
            attributes[i] = getShipAttributes(_gameId, _shipIds[i], _isCreator);
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

        uint totalShips = creatorFleet.shipIds.length +
            joinerFleet.shipIds.length;
        ShipPosition[] memory positions = new ShipPosition[](totalShips);

        uint index = 0;

        // Add creator ships
        for (uint i = 0; i < creatorFleet.shipIds.length; i++) {
            uint shipId = creatorFleet.shipIds[i];
            positions[index] = ShipPosition({
                shipId: shipId,
                position: game.shipPositions[shipId],
                isCreator: true
            });
            index++;
        }

        // Add joiner ships
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            uint shipId = joinerFleet.shipIds[i];
            positions[index] = ShipPosition({
                shipId: shipId,
                position: game.shipPositions[shipId],
                isCreator: false
            });
            index++;
        }

        return positions;
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

        // Get creator ship attributes
        Attributes[] memory creatorAttrs = new Attributes[](
            _creatorShipIds.length
        );
        for (uint i = 0; i < _creatorShipIds.length; i++) {
            creatorAttrs[i] = game.creatorShipAttributes[_creatorShipIds[i]];
        }

        // Get joiner ship attributes
        Attributes[] memory joinerAttrs = new Attributes[](
            _joinerShipIds.length
        );
        for (uint i = 0; i < _joinerShipIds.length; i++) {
            joinerAttrs[i] = game.joinerShipAttributes[_joinerShipIds[i]];
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
                creatorShipAttributes: creatorAttrs,
                joinerShipAttributes: joinerAttrs,
                shipPositions: shipPositions,
                gridWidth: game.gridWidth,
                gridHeight: game.gridHeight
            });
    }
}
