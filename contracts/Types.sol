// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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
    uint8 r1;
    uint8 g1;
    uint8 b1;
    uint8 r2;
    uint8 g2;
    uint8 b2;
    uint8 variant; // Which art to use for the ship
    uint8 accuracy;
    uint8 hull; // Hitpoints
    uint8 speed;
}

struct Equipment {
    MainWeapon mainWeapon;
    Armor armor;
    Shields shields;
    Special special;
}

// Attributes Change on Version
struct Attributes {
    uint8 version;
    uint8 range;
    uint8 gunDamage;
    uint8 hullPoints;
    uint8 movement;
    uint8[] statusEffects;
}

struct GameData {
    uint gameId; // 0 if not in a game
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
    GameData gameData;
    uint32 shipsDestroyed; // +1 for Frigate, +2 for Destroyer, +3 for Cruiser, +4 for Battleship
    uint16 costsVersion;
    uint16 cost;
    bool shiny;
    bool constructed;
    uint timestampDestroyed;
    address owner;
}

struct Costs {
    uint16 version;
    uint8 baseCost;
    uint8[] accuracy;
    uint8[] brawling;
    uint8[] hull;
    uint8[] speed;
    // Items are uint8[4]
    uint8[] mainWeapon;
    uint8[] pointDefense;
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
