// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";

contract Game is Ownable, ReentrancyGuard {
    Ships public ships;
    address public lobbiesAddress;

    mapping(uint => GameData) public games;
    uint public gameCount;

    // Attributes version tracking
    mapping(uint8 => AttributesVersion) public attributesVersions;
    uint8 public currentAttributesVersion;

    event GameStarted(
        uint indexed gameId,
        uint indexed lobbyId,
        address creator,
        address joiner
    );

    event AttributesVersionUpdated(uint8 indexed version);

    error NotLobbiesContract();
    error GameNotFound();
    error NotInGame();
    error InvalidAttributesVersion();

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
        v1.foreAccuracy = [0, 125, 150];

        // Engine speed in raw movement modifier
        v1.engineSpeeds = [0, 2, 5];

        // Gun data
        v1.guns = [
            GunData(10, 15, 0), // Laser
            GunData(50, 10, 0), // Railgun
            GunData(40, 15, -1), // MissileLauncher
            GunData(4, 25, 0) // PlasmaCannon
        ];

        // Armor data
        v1.armors = [
            ArmorData(0, 0), // None
            ArmorData(10, -1), // Light
            ArmorData(20, -2), // Medium
            ArmorData(30, -3) // Heavy
        ];

        // Shield data
        v1.shields = [
            ShieldData(0, 0), // None
            ShieldData(10, 0), // Light
            ShieldData(20, -1), // Medium
            ShieldData(30, -2) // Heavy
        ];

        // Special data
        v1.specials = [
            SpecialData(0, 0), // None
            SpecialData(1, 0), // EMP
            SpecialData(1, 0), // RepairDrones
            SpecialData(1, 0) // FlakArray
        ];
    }

    function setLobbiesAddress(address _lobbiesAddress) public onlyOwner {
        lobbiesAddress = _lobbiesAddress;
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

        emit GameStarted(gameCount, _lobbyId, _creator, _joiner);
    }

    // Attributes version management
    function setAttributesVersion(
        AttributesVersion memory _version
    ) public onlyOwner {
        uint8 version = _version.version;
        if (version == 0) revert InvalidAttributesVersion();

        attributesVersions[version] = _version;
        currentAttributesVersion = version;

        emit AttributesVersionUpdated(version);
    }

    function getAttributesVersion(
        uint8 _version
    ) public view returns (AttributesVersion memory) {
        if (_version == 0 || attributesVersions[_version].version == 0) {
            revert InvalidAttributesVersion();
        }
        return attributesVersions[_version];
    }

    function getCurrentAttributesVersion()
        public
        view
        returns (AttributesVersion memory)
    {
        return attributesVersions[currentAttributesVersion];
    }

    // View functions
    function getGame(uint _gameId) public view returns (GameData memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        return games[_gameId];
    }
}
