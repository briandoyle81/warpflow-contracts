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

        // Calculate fleet attributes for both players
        _initializeFleetAttributes(gameCount, _creatorFleetId, _joinerFleetId);

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
                joinerShipAttributes: joinerAttrs
            });
    }
}
