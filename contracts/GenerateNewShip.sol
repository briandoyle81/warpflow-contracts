// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Types.sol";
import "./IOnchainRandomShipNames.sol";

contract GenerateNewShip {
    IOnchainRandomShipNames public immutable shipNames;

    constructor(address _shipNames) {
        shipNames = IOnchainRandomShipNames(_shipNames);
    }

    function generateSpecificShip(
        uint id,
        uint,
        Ship memory ship
    ) external pure returns (Ship memory) {
        ship.id = id;
        ship.traits.serialNumber = 0;
        return ship;
    }

    function generateShip(
        uint id,
        uint serialNumber,
        uint64 randomBase,
        uint16 variant
    ) external view returns (Ship memory) {
        Ship memory newShip;
        newShip.id = id;
        newShip.traits.serialNumber = serialNumber;
        randomBase++;
        newShip.name = shipNames.getRandomShipName(
            bytes32(uint256(keccak256(abi.encodePacked(randomBase))))
        );

        // r g b 1 and 2 values are 0 to 255
        randomBase++;
        newShip.traits.colors.h1 = uint16(
            uint(keccak256(abi.encodePacked(randomBase))) % 360
        );

        randomBase++;
        newShip.traits.colors.s1 = uint8(
            uint(keccak256(abi.encodePacked(randomBase))) % 100
        );

        randomBase++;
        newShip.traits.colors.l1 = uint8(
            uint(keccak256(abi.encodePacked(randomBase))) % 100
        );

        randomBase++;
        newShip.traits.colors.h2 = uint16(
            uint(keccak256(abi.encodePacked(randomBase))) % 360
        );

        randomBase++;
        newShip.traits.colors.s2 = uint8(
            uint(keccak256(abi.encodePacked(randomBase))) % 100
        );

        randomBase++;
        newShip.traits.colors.l2 = uint8(
            uint(keccak256(abi.encodePacked(randomBase))) % 100
        );

        randomBase++;
        newShip.traits.accuracy = uint8(
            getTierOfTrait(uint(keccak256(abi.encodePacked(randomBase))) % 100)
        );

        randomBase++;
        newShip.traits.hull = uint8(
            getTierOfTrait(uint(keccak256(abi.encodePacked(randomBase))) % 100)
        );

        randomBase++;
        newShip.traits.speed = uint8(
            getTierOfTrait(uint(keccak256(abi.encodePacked(randomBase))) % 100)
        );

        randomBase++;
        newShip.traits.variant = variant;

        randomBase++;
        newShip.equipment.mainWeapon = MainWeapon(
            uint(keccak256(abi.encodePacked(randomBase))) % 4
        );

        // Flip a coin to determine if a ship has armor or shields
        randomBase++;
        bool hasArmor = uint(keccak256(abi.encodePacked(randomBase))) % 2 == 0;
        randomBase++;
        if (hasArmor) {
            newShip.equipment.armor = Armor(
                uint(keccak256(abi.encodePacked(randomBase))) % 4
            );
        } else {
            newShip.equipment.shields = Shields(
                uint(keccak256(abi.encodePacked(randomBase))) % 4
            );
        }

        randomBase++;
        newShip.equipment.special = Special(
            uint(keccak256(abi.encodePacked(randomBase))) % 4
        );

        // TODO: Should it be adjustable chance for shiny?
        uint shinyChance = uint(keccak256(abi.encodePacked(randomBase))) % 100;
        if (shinyChance <= 8) {
            newShip.shipData.shiny = true;
        }

        // Generated a weighted random number to determine the starting number of enemies destroyed
        // Distribution maintains similar probabilities to original but with new rank thresholds:
        // 75% chance: Rank 1 (1-9 kills)
        // 15% chance: Rank 2 (10-29 kills)
        // 5% chance: Rank 3 (30-99 kills)
        // 4% chance: Rank 4 (100-299 kills)
        // 1% chance: Rank 5 (300-999 kills)
        // Rank 6 (1000+) cannot be created, must be earned through gameplay

        randomBase++;
        uint shipsDestroyed = uint(keccak256(abi.encodePacked(randomBase))) %
            100;
        if (shipsDestroyed < 75) {
            // 75% chance: Rank 1 (1-9 kills)
            newShip.shipData.shipsDestroyed = uint16(1 + (shipsDestroyed % 9));
        } else if (shipsDestroyed < 90) {
            // 15% chance: Rank 2 (10-29 kills)
            newShip.shipData.shipsDestroyed = uint16(10 + (shipsDestroyed % 20));
        } else if (shipsDestroyed < 95) {
            // 5% chance: Rank 3 (30-99 kills)
            newShip.shipData.shipsDestroyed = uint16(30 + (shipsDestroyed % 70));
        } else if (shipsDestroyed < 99) {
            // 4% chance: Rank 4 (100-299 kills)
            newShip.shipData.shipsDestroyed = uint16(100 + (shipsDestroyed % 200));
        } else {
            // 1% chance: Rank 5 (300-999 kills)
            newShip.shipData.shipsDestroyed = uint16(300 + (shipsDestroyed % 700));
        }

        return newShip;
    }

    // WARNING: This function is duplicated in Ships.sol
    function getTierOfTrait(uint _trait) public pure returns (uint8) {
        if (_trait < 50) {
            return 0;
        } else if (_trait < 80) {
            return 1;
        } else {
            return 2;
        }
    }
}
