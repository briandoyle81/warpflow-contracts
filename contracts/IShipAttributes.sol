// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";

interface IShipAttributes {
    function calculateShipAttributes(
        Ship memory _ship
    ) external view returns (Attributes memory);

    function calculateShipAttributesById(
        uint _shipId
    ) external view returns (Attributes memory);

    function calculateShipAttributesByIds(
        uint[] memory _shipIds
    ) external view returns (Attributes[] memory);

    function getSpecialRange(Special _special) external view returns (uint8);

    function getSpecialStrength(Special _special) external view returns (uint8);

    function getGunData(
        MainWeapon _weapon
    ) external view returns (GunData memory);

    function getArmorData(
        Armor _armor
    ) external view returns (ArmorData memory);

    function getShieldData(
        Shields _shields
    ) external view returns (ShieldData memory);

    function getSpecialData(
        Special _special
    ) external view returns (SpecialData memory);

    // Cost calculation functions
    function calculateShipCost(Ship memory ship) external view returns (uint16);

    function setCosts(Costs memory _costs) external;

    function getCosts() external view returns (uint, Costs memory);

    function getCurrentCostsVersion() external view returns (uint16);

    // Attributes version management functions
    function setCurrentAttributesVersion(uint16 _version) external;

    function setAttributesVersionBase(
        uint16 _version,
        uint8 _baseHull,
        uint8 _baseSpeed
    ) external;

    function addGunData(uint16 _version, GunData memory _gunData) external;

    function addArmorData(
        uint16 _version,
        ArmorData memory _armorData
    ) external;

    function addShieldData(
        uint16 _version,
        ShieldData memory _shieldData
    ) external;

    function addSpecialData(
        uint16 _version,
        SpecialData memory _specialData
    ) external;

    function addForeAccuracy(uint16 _version, uint8 _accuracy) external;

    function addEngineSpeed(uint16 _version, uint8 _speed) external;

    function getCurrentAttributesVersion() external view returns (uint16);

    function getAttributesVersionBase(
        uint16 _version
    ) external view returns (uint16 version, uint8 baseHull, uint8 baseSpeed);
}
