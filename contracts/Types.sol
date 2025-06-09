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
    uint8 version; // Attributes version not cost version
    uint8 range;
    uint8 gunDamage;
    uint8 hullPoints;
    uint8 movement;
    uint8[] statusEffects;
}

struct GameData {
    uint gameId;
    Ship ship;
    Attributes attributes;
    uint8 damageTaken;
    bool inLobby;
    bool movedThisTurn;
    bool firedThisTurn;
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
