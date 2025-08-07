// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./IShips.sol";
import "./IShipAttributes.sol";

contract ShipAttributes is IShipAttributes, Ownable {
    IShips public ships;

    // Attributes version tracking
    mapping(uint16 => AttributesVersion) public attributesVersions;
    uint16 public currentAttributesVersion;

    error InvalidAttributesVersion();
    error ShipNotFound();

    constructor(address _ships) Ownable(msg.sender) {
        ships = IShips(_ships);

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

    function setShipsAddress(address _ships) public onlyOwner {
        ships = IShips(_ships);
    }

    // Calculate attributes for a ship in memory and return Attributes
    function calculateShipAttributes(
        Ship memory _ship
    ) public view returns (Attributes memory) {
        if (_ship.id == 0) revert ShipNotFound();

        Attributes memory attributes;
        // Calculate base attributes from ship traits and equipment
        attributes.version = currentAttributesVersion;
        attributes.range = attributesVersions[currentAttributesVersion]
            .guns[uint8(_ship.equipment.mainWeapon)]
            .range;
        attributes.gunDamage = attributesVersions[currentAttributesVersion]
            .guns[uint8(_ship.equipment.mainWeapon)]
            .damage;
        attributes.hullPoints = _calculateHullPoints(_ship);
        attributes.maxHullPoints = attributes.hullPoints;
        attributes.movement = _calculateMovement(_ship);
        attributes.damageReduction = _calculateDamageReduction(_ship);
        // Initialize empty status effects array
        attributes.statusEffects = new uint8[](0);

        return attributes;
    }

    // Calculate attributes for a ship by ID
    function calculateShipAttributesById(
        uint _shipId
    ) public view returns (Attributes memory) {
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        return calculateShipAttributes(ship);
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

    // Get special range from attributes version
    function getSpecialRange(Special _special) public view returns (uint8) {
        return
            attributesVersions[currentAttributesVersion]
                .specials[uint8(_special)]
                .range;
    }

    // Get special strength from attributes version
    function getSpecialStrength(Special _special) public view returns (uint8) {
        return
            attributesVersions[currentAttributesVersion]
                .specials[uint8(_special)]
                .strength;
    }

    // Get gun data from attributes version
    function getGunData(
        MainWeapon _weapon
    ) public view returns (GunData memory) {
        return
            attributesVersions[currentAttributesVersion].guns[uint8(_weapon)];
    }

    // Get armor data from attributes version
    function getArmorData(Armor _armor) public view returns (ArmorData memory) {
        return
            attributesVersions[currentAttributesVersion].armors[uint8(_armor)];
    }

    // Get shield data from attributes version
    function getShieldData(
        Shields _shields
    ) public view returns (ShieldData memory) {
        return
            attributesVersions[currentAttributesVersion].shields[
                uint8(_shields)
            ];
    }

    // Get special data from attributes version
    function getSpecialData(
        Special _special
    ) public view returns (SpecialData memory) {
        return
            attributesVersions[currentAttributesVersion].specials[
                uint8(_special)
            ];
    }
}
