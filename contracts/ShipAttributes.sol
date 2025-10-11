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

    // Cost system
    Costs public costs;

    error InvalidAttributesVersion();
    error ShipNotFound();
    error InvalidCostsVersion();

    constructor(address _ships) Ownable(msg.sender) {
        ships = IShips(_ships);

        // Initialize attributes version 1
        currentAttributesVersion = 1;

        // Initialize cost system
        costs.version = 1;
        costs.baseCost = 50;

        costs.accuracy = [0, 10, 25];
        costs.hull = [0, 10, 25];
        costs.speed = [0, 10, 25];

        costs.mainWeapon = [25, 30, 40, 40];
        costs.armor = [0, 5, 10, 15];
        costs.shields = [0, 10, 20, 30];
        costs.special = [0, 10, 20, 15];

        // Set up default attributes version 1
        AttributesVersion storage v1 = attributesVersions[1];
        v1.version = 1;
        v1.baseHull = 100;
        v1.baseSpeed = 3;

        // Fore accuracy bonuses in whole number percentage multipliers
        v1.foreAccuracy.push(0);
        v1.foreAccuracy.push(125);
        v1.foreAccuracy.push(150);

        // Hull is currently hardcoded to 0%, 10%, 20%

        // Engine speed in raw movement modifier
        v1.engineSpeeds.push(0);
        v1.engineSpeeds.push(1);
        v1.engineSpeeds.push(2);

        // Initialize gun data
        v1.guns.push(GunData(8, 25, 0)); // Laser
        v1.guns.push(GunData(12, 20, 0)); // Railgun
        v1.guns.push(GunData(10, 30, -1)); // MissileLauncher
        v1.guns.push(GunData(4, 40, 0)); // PlasmaCannon

        // Initialize armor data
        v1.armors.push(ArmorData(0, 1)); // None
        v1.armors.push(ArmorData(15, 0)); // Light
        v1.armors.push(ArmorData(30, -1)); // Medium
        v1.armors.push(ArmorData(45, -2)); // Heavy

        // Initialize shield data
        v1.shields.push(ShieldData(0, 1)); // None
        v1.shields.push(ShieldData(15, 1)); // Light
        v1.shields.push(ShieldData(30, 0)); // Medium
        v1.shields.push(ShieldData(45, -1)); // Heavy

        // Initialize special data
        v1.specials.push(SpecialData(0, 0, 0)); // None
        v1.specials.push(SpecialData(1, 1, 0)); // EMP
        v1.specials.push(SpecialData(6, 10, 0)); // RepairDrones
        v1.specials.push(SpecialData(4, 15, 0)); // FlakArray
    }

    function setShipsAddress(address _ships) public onlyOwner {
        ships = IShips(_ships);
    }

    // Calculate attributes for a ship in memory and return Attributes
    function calculateShipAttributes(
        Ship memory _ship
    ) public view returns (Attributes memory) {
        if (_ship.id == 0) revert ShipNotFound();

        uint8 rank = getRank(_ship.shipData.shipsDestroyed);
        uint8 rankMultiplier = 0;
        if (rank == 1) {
            rankMultiplier = 0;
        } else if (rank == 2) {
            rankMultiplier = 10;
        } else if (rank == 3) {
            rankMultiplier = 20;
        } else if (rank == 4) {
            rankMultiplier = 30;
        } else if (rank == 5) {
            rankMultiplier = 40;
        } else if (rank >= 6) {
            rankMultiplier = 50;
        }

        Attributes memory attributes;
        // Calculate base attributes from ship traits and equipment
        attributes.version = currentAttributesVersion;
        attributes.range = attributesVersions[currentAttributesVersion]
            .guns[uint8(_ship.equipment.mainWeapon)]
            .range;
        // Increase range by the rank multiplier as a percentage (avoid overflow)
        uint calculatedBonus = (uint(attributes.range) * rankMultiplier) / 100;
        attributes.range += uint8(calculatedBonus);
        attributes.gunDamage = attributesVersions[currentAttributesVersion]
            .guns[uint8(_ship.equipment.mainWeapon)]
            .damage;
        // Increase damage by the rank multiplier as a percentage (avoid overflow)
        calculatedBonus = (uint(attributes.gunDamage) * rankMultiplier) / 100;
        attributes.gunDamage += uint8(calculatedBonus);
        attributes.hullPoints = _calculateHullPoints(_ship);
        // Increase hull points by the rank multiplier as a percentage (avoid overflow)
        calculatedBonus = (uint(attributes.hullPoints) * rankMultiplier) / 100;
        attributes.hullPoints += uint8(calculatedBonus);
        attributes.maxHullPoints = attributes.hullPoints;
        attributes.movement = _calculateMovement(_ship);
        // Increase movement by the rank multiplier as a percentage (avoid overflow)
        calculatedBonus = (uint(attributes.movement) * rankMultiplier) / 100;
        attributes.movement += uint8(calculatedBonus);
        attributes.damageReduction = _calculateDamageReduction(_ship);
        // Increase damage reduction by the rank multiplier as a percentage (avoid overflow)
        calculatedBonus =
            (uint(attributes.damageReduction) * rankMultiplier) /
            100;
        attributes.damageReduction += uint8(calculatedBonus);
        // Initialize empty status effects array
        attributes.statusEffects = new uint8[](0);

        return attributes;
    }

    function getRank(uint _shipsDestroyed) public pure returns (uint8) {
        // Rank is the number of digits in the number of ships destroyed
        return uint8(countDigits(_shipsDestroyed));
    }

    function countDigits(uint num) public pure returns (uint) {
        if (num == 0) return 1;

        uint digits = 0;
        while (num != 0) {
            digits++;
            num /= 10;
        }
        return digits;
    }

    // Calculate attributes for a ship by ID
    function calculateShipAttributesById(
        uint _shipId
    ) public view returns (Attributes memory) {
        Ship memory ship = ships.getShip(_shipId);
        if (ship.id == 0) revert ShipNotFound();
        return calculateShipAttributes(ship);
    }

    // Calculate attributes for multiple ships by their IDs
    function calculateShipAttributesByIds(
        uint[] memory _shipIds
    ) public view returns (Attributes[] memory) {
        Attributes[] memory results = new Attributes[](_shipIds.length);

        for (uint i = 0; i < _shipIds.length; i++) {
            Ship memory ship = ships.getShip(_shipIds[i]);
            if (ship.id == 0) revert ShipNotFound();
            results[i] = calculateShipAttributes(ship);
        }

        return results;
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

    // Cost calculation functions
    function calculateShipCost(
        Ship memory ship
    ) external view returns (uint16) {
        uint16 unadjustedCost = uint16(
            costs.baseCost +
                costs.accuracy[uint8(ship.traits.accuracy)] +
                costs.hull[uint8(ship.traits.hull)] +
                costs.speed[uint8(ship.traits.speed)] +
                costs.mainWeapon[uint8(ship.equipment.mainWeapon)] +
                costs.armor[uint8(ship.equipment.armor)] +
                costs.shields[uint8(ship.equipment.shields)] +
                costs.special[uint8(ship.equipment.special)]
        );

        // TODO: Add rank-based discounts here if needed
        // For now, return unadjusted cost
        return unadjustedCost;
    }

    function setCosts(Costs memory _costs) external onlyOwner {
        costs.version++;
        costs = _costs;
    }

    function getCosts() external view returns (uint, Costs memory) {
        return (costs.version, costs);
    }

    function getCurrentCostsVersion() external view returns (uint16) {
        return costs.version;
    }

    // Attributes version management functions
    function setCurrentAttributesVersion(uint16 _version) external onlyOwner {
        currentAttributesVersion = _version;
    }

    function setAttributesVersionBase(
        uint16 _version,
        uint8 _baseHull,
        uint8 _baseSpeed
    ) external onlyOwner {
        attributesVersions[_version].version = _version;
        attributesVersions[_version].baseHull = _baseHull;
        attributesVersions[_version].baseSpeed = _baseSpeed;
    }

    function addGunData(
        uint16 _version,
        GunData memory _gunData
    ) external onlyOwner {
        attributesVersions[_version].guns.push(_gunData);
    }

    function addArmorData(
        uint16 _version,
        ArmorData memory _armorData
    ) external onlyOwner {
        attributesVersions[_version].armors.push(_armorData);
    }

    function addShieldData(
        uint16 _version,
        ShieldData memory _shieldData
    ) external onlyOwner {
        attributesVersions[_version].shields.push(_shieldData);
    }

    function addSpecialData(
        uint16 _version,
        SpecialData memory _specialData
    ) external onlyOwner {
        attributesVersions[_version].specials.push(_specialData);
    }

    function addForeAccuracy(
        uint16 _version,
        uint8 _accuracy
    ) external onlyOwner {
        attributesVersions[_version].foreAccuracy.push(_accuracy);
    }

    function addEngineSpeed(uint16 _version, uint8 _speed) external onlyOwner {
        attributesVersions[_version].engineSpeeds.push(_speed);
    }

    function getCurrentAttributesVersion() external view returns (uint16) {
        return currentAttributesVersion;
    }

    function getAttributesVersionBase(
        uint16 _version
    ) external view returns (uint16 version, uint8 baseHull, uint8 baseSpeed) {
        AttributesVersion storage versionData = attributesVersions[_version];
        return (
            versionData.version,
            versionData.baseHull,
            versionData.baseSpeed
        );
    }
}
