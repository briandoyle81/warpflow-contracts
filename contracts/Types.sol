// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

enum MainWeapon {
    Laser,
    Railgun,
    MissileLauncher,
    PlasmaCannon
}

// Reduces Damage, Does not Provide Hitpoints
enum Armor {
    None,
    Light,
    Medium,
    Heavy
}

// Reduces Damage, Does not Provide Hitpoints
enum Shields {
    None,
    Light,
    Medium,
    Heavy
}

enum Special {
    None,
    EMP,
    RepairDrones,
    FlakArray
}

// Raw Traits Will Never Change
struct Traits {
    uint256 serialNumber; // Id for random number in commit reveal
    Colors colors;
    uint8 variant; // Which art to use for the ship
    uint8 accuracy;
    uint8 hull; // Hitpoints
    uint8 speed;
}

struct Colors {
    uint16 h1;
    uint8 s1;
    uint8 l1;
    uint16 h2;
    uint8 s2;
    uint8 l2;
}
struct Equipment {
    MainWeapon mainWeapon;
    Armor armor;
    Shields shields;
    Special special;
}

// Attributes Change on Version
// Attributes will live in the game contract
struct Attributes {
    uint16 version; // Attributes version not cost version
    uint8 range;
    uint8 gunDamage;
    uint8 hullPoints;
    uint8 movement;
    uint8 damageReduction;
    uint8 reactorCriticalTimer;
    uint8[] statusEffects;
}

// Grid position structure
struct Position {
    uint8 row;
    uint8 col;
}

// Ship position on the grid
struct ShipPosition {
    uint shipId;
    Position position;
    bool isCreator;
}

struct GameData {
    uint gameId;
    uint lobbyId;
    address creator;
    address joiner;
    uint creatorFleetId;
    uint joinerFleetId;
    bool creatorGoesFirst;
    uint startedAt;
    address currentTurn;
    mapping(uint => Attributes) shipAttributes; // shipId => attributes
    // Grid state - grid[row][column] = shipId (0 if empty)
    mapping(uint8 row => mapping(uint8 column => uint shipId)) grid;
    mapping(uint => Position) shipPositions; // shipId => position
    uint8 gridWidth;
    uint8 gridHeight;
    // Movement tracking
    uint currentRound;
    mapping(uint => mapping(uint => bool)) shipMovedThisRound; // round => shipId => hasMoved
    // Action tracking
}

struct GameDataView {
    uint gameId;
    uint lobbyId;
    address creator;
    address joiner;
    uint creatorFleetId;
    uint joinerFleetId;
    bool creatorGoesFirst;
    uint startedAt;
    address currentTurn;
    Attributes[] shipAttributes; // Combined array of all ship attributes indexed by ship ID
    // Grid data
    ShipPosition[] shipPositions; // All ship positions on the grid
    uint8 gridWidth;
    uint8 gridHeight;
}

struct Ship {
    string name;
    uint id;
    Equipment equipment;
    Traits traits;
    ShipData shipData;
    address owner;
}

struct ShipData {
    uint32 shipsDestroyed; // +1 for Frigate, +2 for Destroyer, +3 for Cruiser, +4 for Battleship
    uint16 costsVersion;
    uint16 cost;
    bool shiny;
    bool constructed;
    bool inFleet;
    uint timestampDestroyed;
}

struct Costs {
    uint16 version;
    uint8 baseCost;
    uint8[] accuracy;
    uint8[] hull;
    uint8[] speed;
    // Items are uint8[4]
    uint8[] mainWeapon;
    uint8[] armor;
    uint8[] shields;
    uint8[] special;
}

// Be VERY CAREFUL giving negative movement!
// It can result in ships that can't move

// We don't need historical versions because this is just used to calculate
// attributes, which are done at the start of the game and stay the same

struct GunData {
    uint8 range;
    uint8 damage;
    int8 movement;
}

struct ArmorData {
    uint8 damageReduction;
    int8 movement;
}

struct ShieldData {
    uint8 damageReduction;
    int8 movement;
}

struct SpecialData {
    uint8 range;
    int8 movement;
}

struct AttributesVersion {
    uint16 version;
    uint8 baseHull;
    uint8 baseSpeed;
    uint8[] foreAccuracy;
    uint8[] engineSpeeds;
    GunData[] guns;
    ArmorData[] armors;
    ShieldData[] shields;
    SpecialData[] specials;
}

enum LobbyStatus {
    Open, // Lobby is open for joining
    FleetSelection, // Both players have joined, selecting fleets
    InGame // Game has started
}

struct Lobby {
    uint id;
    address creator;
    address joiner;
    uint costLimit;
    LobbyStatus status;
    uint createdAt;
    uint gameStartedAt;
    uint creatorFleetId;
    uint joinerFleetId;
    bool creatorGoesFirst;
    uint turnTime; // Time in seconds for each turn
    uint joinedAt; // When the joiner joined the lobby
    uint joinerFleetSetAt; // When the joiner set their fleet
}

struct Fleet {
    uint id;
    uint lobbyId;
    address owner;
    uint[] shipIds;
    uint totalCost;
    bool isComplete;
}

struct PlayerLobbyState {
    uint activeLobbyId;
    uint activeLobbiesCount; // Track number of active lobbies
    bool hasActiveLobby;
    uint kickCount;
    uint lastKickTime;
}

enum ActionType {
    Pass,
    Shoot,
    Retreat
}
