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
}
