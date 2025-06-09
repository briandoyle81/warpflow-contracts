// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Types.sol";
import "./IRenderer.sol";
import "./ImageRenderer.sol";

contract RenderMetadata is IRenderMetadata {
    using Strings for uint256;

    ImageRenderer public immutable imageRenderer;

    constructor(address _imageRenderer) {
        imageRenderer = ImageRenderer(_imageRenderer);
    }

    function getBasicTraitsString(
        Ship memory ship
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Serial Number", "value": "',
                    ship.traits.serialNumber.toString(),
                    '"},',
                    '{"trait_type": "Variant", "value": "',
                    Strings.toString(ship.traits.variant),
                    '"},',
                    '{"trait_type": "Accuracy", "value": ',
                    Strings.toString(ship.traits.accuracy),
                    "},",
                    '{"trait_type": "Hull", "value": ',
                    Strings.toString(ship.traits.hull),
                    "},",
                    '{"trait_type": "Speed", "value": ',
                    Strings.toString(ship.traits.speed),
                    "}"
                )
            );
    }

    function getStatusTraitsString(
        Ship memory ship
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Shiny", "value": "',
                    ship.shipData.shiny ? "Yes" : "No",
                    '"},',
                    '{"trait_type": "Ships Destroyed", "value": ',
                    Strings.toString(uint256(ship.shipData.shipsDestroyed)),
                    "},",
                    '{"trait_type": "Cost", "value": ',
                    Strings.toString(uint256(ship.shipData.cost)),
                    "}"
                )
            );
    }

    function getEquipmentTraitsString(
        Ship memory ship
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Main Weapon", "value": "',
                    getMainWeaponString(ship.equipment.mainWeapon),
                    '"},',
                    '{"trait_type": "Armor", "value": "',
                    getArmorString(ship.equipment.armor),
                    '"},',
                    '{"trait_type": "Shields", "value": "',
                    getShieldsString(ship.equipment.shields),
                    '"},',
                    '{"trait_type": "Special", "value": "',
                    getSpecialString(ship.equipment.special),
                    '"}'
                )
            );
    }

    function getTraitsString(
        Ship memory ship
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    getBasicTraitsString(ship),
                    ",",
                    getStatusTraitsString(ship),
                    ",",
                    getEquipmentTraitsString(ship)
                )
            );
    }

    function getMainWeaponString(
        MainWeapon weapon
    ) internal pure returns (string memory) {
        if (weapon == MainWeapon.Laser) return "Laser";
        if (weapon == MainWeapon.Railgun) return "Railgun";
        if (weapon == MainWeapon.MissileLauncher) return "Missile Launcher";
        if (weapon == MainWeapon.PlasmaCannon) return "Plasma Cannon";
        return "Unknown";
    }

    function getArmorString(Armor armor) internal pure returns (string memory) {
        if (armor == Armor.None) return "No Armor";
        if (armor == Armor.Light) return "Light Armor";
        if (armor == Armor.Medium) return "Medium Armor";
        if (armor == Armor.Heavy) return "Heavy Armor";
        return "Unknown";
    }

    function getShieldsString(
        Shields shields
    ) internal pure returns (string memory) {
        if (shields == Shields.None) return "No Shields";
        if (shields == Shields.Light) return "Light Shields";
        if (shields == Shields.Medium) return "Medium Shields";
        if (shields == Shields.Heavy) return "Heavy Shields";
        return "Unknown";
    }

    function getSpecialString(
        Special special
    ) internal pure returns (string memory) {
        if (special == Special.None) return "No Special";
        if (special == Special.EMP) return "EMP";
        if (special == Special.RepairDrones) return "Repair Drones";
        if (special == Special.FlakArray) return "Flak Array";
        return "Unknown";
    }

    function tokenURI(
        Ship memory ship
    ) public view override returns (string memory) {
        if (ship.id == 0) {
            revert("InvalidId");
        }

        string memory imageUri = imageRenderer.renderShip(ship);

        string memory baseJson = string(
            abi.encodePacked(
                '{"name": "',
                ship.name,
                " #",
                ship.id.toString(),
                '","description": "A unique spaceship in the Warpflow universe. Each ship has unique traits, equipment, and stats that determine its capabilities in battle.", "attributes": [',
                getTraitsString(ship),
                '],"image": "',
                imageUri,
                '"}'
            )
        );

        string memory json = Base64.encode(bytes(baseJson));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
