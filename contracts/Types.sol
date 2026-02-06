// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

enum MainWeapon {
    Laser,
    Railgun,
    MissileLauncher,
    PlasmaCannon,
    future1,
    future2,
    future3,
    future4
}

// Reduces Damage, Does not Provide Hitpoints
enum Armor {
    None,
    Light,
    Medium,
    Heavy,
    future1,
    future2,
    future3,
    future4
}

// Reduces Damage, Does not Provide Hitpoints
enum Shields {
    None,
    Light,
    Medium,
    Heavy,
    future1,
    future2,
    future3,
    future4
}

enum Special {
    None,
    EMP,
    RepairDrones,
    FlakArray,
    future1,
    future2,
    future3,
    future4
}

// Raw Traits Will Never Change
struct Traits {
    uint256 serialNumber; // Id for random number in commit reveal
    Colors colors;
    uint16 variant; // Which art to use for the ship
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
    uint16 h3;
    uint8 s3;
    uint8 l3;
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
    uint8 maxHullPoints;
    uint8 movement;
    uint8 damageReduction;
    uint8 reactorCriticalTimer;
    uint8[] statusEffects;
}

// Grid position structure
struct Position {
    int16 row;
    int16 col;
}

// Scoring position structure with point value
struct ScoringPosition {
    int16 row;
    int16 col;
    uint8 points; // Number of points available on this tile
    bool onlyOnce; // Whether this tile can only be claimed once
}

// Ship position on the grid
struct ShipPosition {
    uint shipId;
    Position position;
    bool isCreator;
}

// Game metadata - basic game identification and players
struct GameMetadata {
    uint gameId;
    uint lobbyId;
    address creator;
    address joiner;
    uint creatorFleetId;
    uint joinerFleetId;
    bool creatorGoesFirst;
    uint startedAt;
    address winner; // Winner of the game (zero address if game is not over)
}

// Game turn state - turn and timing related data
struct GameTurnState {
    address currentTurn;
    uint turnTime; // Time limit per turn in seconds
    uint turnStartTime; // When current turn started
    uint currentRound;
}

// Game grid dimensions
struct GameGridDimensions {
    int16 gridWidth;
    int16 gridHeight;
}

struct GameData {
    GameMetadata metadata;
    GameTurnState turnState;
    GameGridDimensions gridDimensions;
    uint maxScore; // Maximum score needed to win the game
    uint creatorScore; // Current score of the creator player
    uint joinerScore; // Current score of the joiner player
    LastMove lastMove; // Most recent move in the game
    // Keep all mappings in GameData
    mapping(uint => Attributes) shipAttributes; // shipId => attributes
    // Grid state - grid[row][column] = shipId (0 if empty)
    mapping(int16 row => mapping(int16 column => uint shipId)) grid;
    mapping(uint => Position) shipPositions; // shipId => position
    EnumerableSet.UintSet shipMovedThisRound; // movedShipIds in current round
    EnumerableSet.UintSet shipsWithZeroHP; // shipIds with 0 hull points
    // Store active ship IDs for each player to avoid repeated fleet calls
    mapping(address => EnumerableSet.UintSet) playerActiveShipIds; // player => shipIds
    // Round completion: use counts at round start so destroyed/retreated ships don't shrink the threshold
    uint totalActiveShipsAtRoundStart; // set at start of each round
    uint shipsRemovedThisRound; // destroyed or retreated this round (incremented in _removeShipFromGame)
}

struct GameDataView {
    GameMetadata metadata;
    GameTurnState turnState;
    GameGridDimensions gridDimensions;
    uint maxScore; // Maximum score needed to win the game
    uint creatorScore; // Current score of the creator player
    uint joinerScore; // Current score of the joiner player
    LastMove lastMove; // Most recent move in the game
    // Ship data arrays
    uint[] shipIds;
    Attributes[] shipAttributes; // Combined array of all ship attributes indexed by ship ID
    ShipPosition[] shipPositions; // All ship positions on the grid
    // Active ship IDs for each player
    uint[] creatorActiveShipIds;
    uint[] joinerActiveShipIds;
    // Ships that have moved this round
    uint[] creatorMovedShipIds; // Creator ships that have moved this round
    uint[] joinerMovedShipIds; // Joiner ships that have moved this round
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
    uint16 modified; // 0 = false, anything else = true
    bool shiny;
    bool constructed;
    bool inFleet;
    bool isFreeShip;
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
    uint8 strength;
    int8 movement;
}

struct AttributesVersion {
    uint16 version;
    uint8 baseHull;
    uint8 baseSpeed;
    uint8[] foreAccuracy;
    uint8[] hull;
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

// Basic lobby identification and ownership
struct LobbyBasic {
    uint id;
    address creator;
    uint costLimit;
    uint createdAt;
}

// Player and fleet information
struct LobbyPlayers {
    address joiner;
    address reservedJoiner; // Address of player this lobby is reserved for (if any)
    uint creatorFleetId;
    uint joinerFleetId;
    uint joinedAt;
    uint joinerFleetSetAt;
}

// Game configuration settings
struct LobbyGameConfig {
    bool creatorGoesFirst;
    uint turnTime; // Time in seconds for each turn
    uint selectedMapId; // ID of the preset map to use for this game
    uint maxScore; // Maximum score needed to win the game
}

// Lobby state and status
struct LobbyState {
    LobbyStatus status;
    uint gameStartedAt;
}

// Main lobby struct composed of smaller components
struct Lobby {
    LobbyBasic basic;
    LobbyPlayers players;
    LobbyGameConfig gameConfig;
    LobbyState state;
}

struct Fleet {
    uint id;
    uint lobbyId;
    address owner;
    uint[] shipIds;
    Position[] startingPositions;
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
    Retreat,
    Assist,
    Special,
    ClaimPoints
}

// Last move information stored in game data
struct LastMove {
    uint shipId;
    int16 oldRow;
    int16 oldCol;
    int16 newRow;
    int16 newCol;
    ActionType actionType;
    uint targetShipId;
    uint timestamp; // When the move was made
}

// Player statistics for tracking wins and losses
struct PlayerStats {
    uint wins;
    uint losses;
    uint totalGames;
}

// Game result structure for tracking individual game outcomes
struct GameResult {
    uint gameId;
    address winner;
    address loser;
    uint timestamp;
}
